import SwiftSyntax

/// Reads the members `fake()` has to cover, and renders the method source.
enum FakeGenerator {

    // MARK: - Extraction

    /// The stored properties `fake()` takes a parameter for, in declaration
    /// order, for each build configuration the struct's `#if` blocks describe.
    ///
    /// These are exactly the properties the memberwise initializer takes, since
    /// that is what the generated method calls. Type-level properties, computed
    /// properties, and constants that already have a value are all left out for
    /// that reason.
    ///
    /// A property whose type is inferred is also left out: the macro reads
    /// syntax, not types, so there is nothing to write a parameter type from.
    ///
    /// A property marked `@FakeValue` defaults to the value the attribute
    /// holds, ahead of anything else.
    ///
    /// A `var` that declares its own value defaults to that value, the way the
    /// memberwise initializer does, so a fake starts from the state the model
    /// itself describes. `accessLevel` is the level of the generated method,
    /// which decides whether the value can be used (see
    /// ``declaredDefault(of:accessLevel:)``).
    static func storedPropertyLayout(
        of structDecl: StructDeclSyntax,
        accessLevel: AccessLevel
    ) -> StoredPropertyLayout {
        layout(
            of: Array(structDecl.memberBlock.members),
            after: [],
            genericParameterNames: structDecl.genericParameterClause.parameterNames,
            accessLevel: accessLevel
        )
    }

    /// The layout of `members`, with `prefix` already declared ahead of them.
    ///
    /// A `#if` block splits the layout: each clause continues with its own
    /// members followed by everything after the block, since the memberwise
    /// initializer of that configuration takes both. A block without `#else`
    /// gains one, because the configuration where no clause holds has an
    /// initializer too. A block whose clauses all end up with the same
    /// properties, such as one holding only methods, is not split at all.
    private static func layout(
        of members: [MemberBlockItemSyntax],
        after prefix: [StoredProperty],
        genericParameterNames: Set<String>,
        accessLevel: AccessLevel
    ) -> StoredPropertyLayout {
        var properties = prefix

        for (index, member) in members.enumerated() {
            guard let ifConfig = member.decl.as(IfConfigDeclSyntax.self) else {
                properties += storedProperties(
                    in: member,
                    genericParameterNames: genericParameterNames,
                    accessLevel: accessLevel
                )
                continue
            }

            let remainder = Array(members[(index + 1)...])
            func clauseLayout(_ clauseMembers: [MemberBlockItemSyntax]) -> StoredPropertyLayout {
                layout(
                    of: clauseMembers + remainder,
                    after: properties,
                    genericParameterNames: genericParameterNames,
                    accessLevel: accessLevel
                )
            }

            var clauses = ifConfig.clauses.map { clause in
                StoredPropertyLayout.Clause(
                    keyword: clause.poundKeyword.text,
                    condition: clause.condition?.trimmedDescription,
                    layout: clauseLayout(clause.memberItems)
                )
            }
            if !ifConfig.clauses.contains(where: { $0.poundKeyword.tokenKind == .poundElse }) {
                clauses.append(
                    StoredPropertyLayout.Clause(
                        keyword: "#else",
                        condition: nil,
                        layout: clauseLayout([])
                    )
                )
            }

            if let first = clauses.first, clauses.allSatisfy({ $0.layout == first.layout }) {
                return first.layout
            }
            return .conditional(clauses)
        }

        return .unconditional(properties)
    }

    /// The stored properties a single member declares.
    private static func storedProperties(
        in member: MemberBlockItemSyntax,
        genericParameterNames: Set<String>,
        accessLevel: AccessLevel
    ) -> [StoredProperty] {
        guard let variable = member.decl.as(VariableDeclSyntax.self), !variable.isStatic else {
            return []
        }

        return variable.bindingsWithResolvedTypes.compactMap { binding, type -> StoredProperty? in
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                let type,
                binding.isStored,
                !(variable.isConstant && binding.initializer != nil)
            else {
                return nil
            }

            return StoredProperty(
                name: identifier.identifier.text,
                type: type.isFunction
                    ? "@escaping \(type.trimmedDescription)"
                    : type.trimmedDescription,
                defaultValue: variable.fakeValue?.trimmedDescription
                    ?? declaredDefault(of: binding, accessLevel: accessLevel)
                    ?? DefaultValue.resolve(
                        for: type,
                        genericParameterNames: genericParameterNames
                    )
            )
        }
    }

    /// The value the property declares for itself, when `fake()` can use it as
    /// a default argument.
    ///
    /// A `public` method's default arguments are emitted into its callers, so
    /// they may reference only public declarations. The macro cannot tell
    /// whether `var page: Int = firstPage` names one, so a `public fake()` uses
    /// a declared value only when it is a literal, and falls back to the type's
    /// default otherwise. Every other access level takes the value as written.
    private static func declaredDefault(
        of binding: PatternBindingSyntax,
        accessLevel: AccessLevel
    ) -> String? {
        guard let value = binding.initializer?.value,
            accessLevel != .public || value.isLiteral
        else {
            return nil
        }
        return value.trimmedDescription
    }

    /// The `init` that keeps the memberwise initializer from existing, or `nil`
    /// when `fake()` has an initializer to call.
    ///
    /// Swift synthesizes the memberwise initializer only for a struct that
    /// declares no `init` in its body. One declared there can still stand in
    /// for it when it takes exactly the stored properties as labels, in order,
    /// and can be called as `Self(...)` with nothing more: it is not failable,
    /// not `throws`, and not `async`. Every configuration in `layout` needs
    /// such an `init`. Otherwise the first `init` is returned, so the
    /// diagnostic can point at it.
    static func initializerBlockingMemberwise(
        of structDecl: StructDeclSyntax,
        layout: StoredPropertyLayout
    ) -> InitializerDeclSyntax? {
        let initializers = structDecl.memberBlock.members.compactMap {
            $0.decl.as(InitializerDeclSyntax.self)
        }

        guard let first = initializers.first else {
            return nil
        }

        let isCovered = layout.configurations.allSatisfy { properties in
            let labels = properties.map(\.name)
            return initializers.contains { $0.standsInForMemberwise(labels: labels) }
        }
        return isCovered ? nil : first
    }

    /// The cases marked `@FakeCase`, each with the attribute that marks it,
    /// in declaration order.
    static func markedCases(
        of enumDecl: EnumDeclSyntax
    ) -> [(fakeCase: EnumCase, attribute: AttributeSyntax)] {
        let genericParameterNames = enumDecl.genericParameterClause.parameterNames

        return enumDecl.memberBlock.members.compactMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
                let attribute = caseDecl.attributes.attribute(named: "FakeCase"),
                let element = caseDecl.elements.first
            else {
                return nil
            }

            let fakeCase = EnumCase(
                name: element.name.text,
                associatedValues: element.parameterClause.map {
                    associatedValues(of: $0, genericParameterNames: genericParameterNames)
                } ?? []
            )
            return (fakeCase: fakeCase, attribute: attribute)
        }
    }

    /// The `@FakeCase` attributes on cases declared inside `#if`, at any depth.
    ///
    /// Cases inside `#if` are not considered when choosing what `fake()`
    /// returns, so a marker there would otherwise be ignored without a word.
    static func conditionalFakeCaseAttributes(of enumDecl: EnumDeclSyntax) -> [AttributeSyntax] {
        func attributes(in members: MemberBlockItemListSyntax, isConditional: Bool) -> [AttributeSyntax] {
            members.flatMap { member -> [AttributeSyntax] in
                if let ifConfig = member.decl.as(IfConfigDeclSyntax.self) {
                    return ifConfig.clauses.flatMap { clause -> [AttributeSyntax] in
                        guard case .decls(let clauseMembers) = clause.elements else {
                            return []
                        }
                        return attributes(in: clauseMembers, isConditional: true)
                    }
                }
                guard isConditional,
                    let attribute = member.decl.as(EnumCaseDeclSyntax.self)?.attributes
                        .attribute(named: "FakeCase")
                else {
                    return []
                }
                return [attribute]
            }
        }
        return attributes(in: enumDecl.memberBlock.members, isConditional: false)
    }

    /// The case `fake()` returns when none is marked `@FakeCase`.
    ///
    /// A case without associated values is preferred, wherever it appears, since
    /// it needs no values invented for it. Only when every case carries
    /// associated values does the first case whose values can all be written
    /// win, with values filled in.
    static func fakeCase(of enumDecl: EnumDeclSyntax) -> EnumCase? {
        let members = enumDecl.memberBlock.members

        for member in members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                for element in caseDecl.elements where element.parameterClause == nil {
                    return EnumCase(name: element.name.text, associatedValues: [])
                }
            }
        }

        // Otherwise take the first case whose values can all be written. When
        // none can be, hand back the first candidate anyway so the caller has
        // something to report the failure against.
        let genericParameterNames = enumDecl.genericParameterClause.parameterNames
        var firstCandidate: EnumCase?

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            for element in caseDecl.elements {
                guard let parameterClause = element.parameterClause else {
                    continue
                }

                let candidate = EnumCase(
                    name: element.name.text,
                    associatedValues: associatedValues(
                        of: parameterClause,
                        genericParameterNames: genericParameterNames
                    )
                )

                if candidate.associatedValues.allSatisfy({ $0.value != nil }) {
                    return candidate
                }

                firstCandidate = firstCandidate ?? candidate
            }
        }

        // `nil` only when the enum has no cases at all.
        return firstCandidate
    }

    private static func associatedValues(
        of parameterClause: EnumCaseParameterClauseSyntax,
        genericParameterNames: Set<String>
    ) -> [AssociatedValue] {
        parameterClause.parameters.map { parameter in
            AssociatedValue(
                label: parameter.firstName?.text,
                value: DefaultValue.resolve(
                    for: parameter.type,
                    genericParameterNames: genericParameterNames
                )
            )
        }
    }

    // MARK: - Rendering

    /// The struct `fake()` source, with one method per configuration in
    /// `layout`, each inside the `#if` clause that selects it.
    static func fakeMethod(
        for layout: StoredPropertyLayout,
        accessLevel: AccessLevel,
        condition: CompilationCondition
    ) -> String {
        condition.guarding(render(layout, accessLevel: accessLevel))
    }

    private static func render(_ layout: StoredPropertyLayout, accessLevel: AccessLevel) -> String {
        switch layout {
        case .unconditional(let properties):
            return fakeMethod(for: properties, accessLevel: accessLevel)
        case .conditional(let clauses):
            let branches = clauses.map { clause in
                let directive = clause.condition.map { "\(clause.keyword) \($0)" } ?? clause.keyword
                return "\(directive)\n\(render(clause.layout, accessLevel: accessLevel))"
            }
            return (branches + ["#endif"]).joined(separator: "\n")
        }
    }

    private static func fakeMethod(
        for properties: [StoredProperty],
        accessLevel: AccessLevel
    ) -> String {
        // A configuration may have no stored properties at all, and then the
        // memberwise initializer takes no arguments.
        guard !properties.isEmpty else {
            return """
                \(accessLevel.modifier)static func fake() -> Self {
                    Self()
                }
                """
        }

        var parameters: [String] = []
        var assignments: [String] = []

        for property in properties {
            // A property with no value the macro can write becomes a required
            // parameter rather than a defaulted one.
            if let defaultValue = property.defaultValue {
                parameters.append("    \(property.name): \(property.type) = \(defaultValue)")
            } else {
                parameters.append("    \(property.name): \(property.type)")
            }
            assignments.append("        \(property.name): \(property.name)")
        }

        let parametersString = parameters.joined(separator: ",\n")
        let assignmentsString = assignments.joined(separator: ",\n")

        return """
            \(accessLevel.modifier)static func fake(
            \(parametersString)
            ) -> Self {
                Self(
            \(assignmentsString)
                )
            }
            """
    }

    /// The enum `fake()` source, or `nil` when no value can be written for one
    /// of the case's associated values.
    static func enumFakeMethod(
        for fakeCase: EnumCase,
        accessLevel: AccessLevel,
        condition: CompilationCondition
    ) -> String? {
        if fakeCase.associatedValues.isEmpty {
            return condition.guarding(
                """
                \(accessLevel.modifier)static func fake() -> Self {
                    .\(fakeCase.name)
                }
                """
            )
        }

        // Fill each associated value in from its type.
        var renderedValues: [String] = []
        for associatedValue in fakeCase.associatedValues {
            guard let value = associatedValue.value else {
                return nil
            }
            renderedValues.append(associatedValue.label.map { "\($0): \(value)" } ?? value)
        }

        return condition.guarding(
            """
            \(accessLevel.modifier)static func fake() -> Self {
                .\(fakeCase.name)(\(renderedValues.joined(separator: ", ")))
            }
            """
        )
    }
}
