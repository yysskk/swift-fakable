import SwiftSyntax

/// Reads a struct's stored properties and renders the `fake()` built from them.
///
/// The access level and the compilation condition are the same for every step,
/// so they are state here rather than arguments threaded through each of them.
struct StructFakeBuilder {
    private let structDecl: StructDeclSyntax
    private let accessLevel: AccessLevel
    private let condition: CompilationCondition

    /// The stored properties `fake()` takes a parameter for, in declaration
    /// order, for each build configuration the struct's `#if` blocks describe.
    ///
    /// Read once, since the diagnostics and the rendering both ask about it.
    let layout: StoredPropertyLayout

    init(
        of structDecl: StructDeclSyntax,
        accessLevel: AccessLevel,
        condition: CompilationCondition
    ) {
        self.structDecl = structDecl
        self.accessLevel = accessLevel
        self.condition = condition
        self.layout = StoredPropertyReader(
            genericParameterNames: structDecl.genericParameterClause.parameterNames,
            accessLevel: accessLevel
        )
        .layout(of: structDecl)
    }

    // MARK: - Diagnostics

    /// Whether any configuration has a property to take a parameter for.
    ///
    /// A struct with none gives `fake()` nothing to do, which the macro warns
    /// about rather than generating `Self()`.
    var hasStoredProperties: Bool {
        layout.configurations.contains { !$0.isEmpty }
    }

    /// The `init` that keeps the memberwise initializer from existing, or `nil`
    /// when `fake()` has an initializer to call.
    ///
    /// Swift synthesizes the memberwise initializer only for a struct that
    /// declares no `init` in its body. One declared there can still stand in
    /// for it when it takes exactly the stored properties as labels, in order,
    /// and can be called as `Self(...)` with nothing more: it is not failable,
    /// not `throws`, and not `async`. Every configuration in ``layout`` needs
    /// such an `init`. Otherwise the first `init` is returned, so the
    /// diagnostic can point at it.
    var initializerBlockingMemberwise: InitializerDeclSyntax? {
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

    // MARK: - Rendering

    /// The `fake()` source, with one method per configuration in ``layout``,
    /// each inside the `#if` clause that selects it.
    func fakeMethod() -> String {
        condition.guarding(render(layout))
    }

    private func render(_ layout: StoredPropertyLayout) -> String {
        switch layout {
        case .unconditional(let properties):
            return fakeMethod(for: properties)
        case .conditional(let clauses):
            let branches = clauses.map { clause in
                let directive = clause.condition.map { "\(clause.keyword) \($0)" } ?? clause.keyword
                return "\(directive)\n\(render(clause.layout))"
            }
            return (branches + ["#endif"]).joined(separator: "\n")
        }
    }

    private func fakeMethod(for properties: [StoredProperty]) -> String {
        // A configuration may have no stored properties at all, and then the
        // memberwise initializer takes no arguments.
        guard !properties.isEmpty else {
            return """
                \(accessLevel.prefixing("static func fake"))() -> Self {
                    Self()
                }
                """
        }

        var parameters: [String] = []
        var assignments: [String] = []

        for property in properties {
            let escaping = property.isEscaping ? "@escaping " : ""
            // A property with no value the macro can write becomes a required
            // parameter rather than a defaulted one.
            let defaultValue = property.defaultValue.map { " = \($0.trimmedDescription)" } ?? ""

            parameters.append(
                "    \(property.name): \(escaping)\(property.type.trimmedDescription)\(defaultValue)"
            )
            assignments.append("        \(property.name): \(property.name)")
        }

        return """
            \(accessLevel.prefixing("static func fake"))(
            \(parameters.joined(separator: ",\n"))
            ) -> Self {
                Self(
            \(assignments.joined(separator: ",\n"))
                )
            }
            """
    }
}

/// Reads a struct's members into the layout `fake()` is built from.
///
/// Its own type, so the names and the access level the reading depends on are
/// state rather than arguments passed down every level of the recursion.
private struct StoredPropertyReader {
    /// The names the struct's generic parameter clause introduces. A property
    /// built from one of them has no value the macro could write.
    let genericParameterNames: Set<String>

    /// The access level of the generated method, which decides whether a
    /// declared value can be used as a default argument.
    let accessLevel: AccessLevel

    /// The stored properties the struct declares, in declaration order.
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
    /// holds, ahead of anything else. A `var` that declares its own value
    /// defaults to that value, the way the memberwise initializer does, so a
    /// fake starts from the state the model itself describes.
    func layout(of structDecl: StructDeclSyntax) -> StoredPropertyLayout {
        layout(of: Array(structDecl.memberBlock.members), after: [])
    }

    /// The layout of `members`, with `prefix` already declared ahead of them.
    ///
    /// A `#if` block splits the layout: each clause continues with its own
    /// members followed by everything after the block, since the memberwise
    /// initializer of that configuration takes both. A block without `#else`
    /// gains one, because the configuration where no clause holds has an
    /// initializer too. A block whose clauses all end up with the same
    /// properties, such as one holding only methods, is not split at all.
    private func layout(
        of members: [MemberBlockItemSyntax],
        after prefix: [StoredProperty]
    ) -> StoredPropertyLayout {
        var properties = prefix

        for (index, member) in members.enumerated() {
            guard let ifConfig = member.decl.as(IfConfigDeclSyntax.self) else {
                properties += storedProperties(in: member)
                continue
            }

            let remainder = Array(members[(index + 1)...])
            func clauseLayout(_ clauseMembers: [MemberBlockItemSyntax]) -> StoredPropertyLayout {
                layout(of: clauseMembers + remainder, after: properties)
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
    private func storedProperties(in member: MemberBlockItemSyntax) -> [StoredProperty] {
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
                type: type,
                isEscaping: type.isFunction,
                defaultValue: variable.fakeValue
                    ?? declaredDefault(of: binding)
                    ?? type.fakeDefaultValue(genericParameterNames: genericParameterNames)
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
    private func declaredDefault(of binding: PatternBindingSyntax) -> ExprSyntax? {
        guard let value = binding.initializer?.value,
            accessLevel != .public || value.isLiteral
        else {
            return nil
        }
        return value
    }
}
