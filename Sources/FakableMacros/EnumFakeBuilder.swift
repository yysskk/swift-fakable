import SwiftSyntax

/// Chooses the case an enum's `fake()` returns and renders the method.
///
/// The generic parameter names, the access level, and the compilation
/// condition are the same for every step, so they are state here rather than
/// arguments threaded through each of them.
struct EnumFakeBuilder {
    private let enumDecl: EnumDeclSyntax
    private let accessLevel: AccessLevel
    private let condition: CompilationCondition
    private let genericParameterNames: Set<String>

    init(
        of enumDecl: EnumDeclSyntax,
        accessLevel: AccessLevel,
        condition: CompilationCondition
    ) {
        self.enumDecl = enumDecl
        self.accessLevel = accessLevel
        self.condition = condition
        self.genericParameterNames = enumDecl.genericParameterClause.parameterNames
    }

    // MARK: - Selection

    /// The cases marked `@FakeCase`, in declaration order.
    ///
    /// More than one is an error, which is why they are all returned rather
    /// than just the first.
    var markedCases: [MarkedCase] {
        enumDecl.memberBlock.members.compactMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
                let attribute = caseDecl.attributes.attribute(named: "FakeCase"),
                let element = caseDecl.elements.first
            else {
                return nil
            }

            return MarkedCase(fakeCase: fakeCase(for: element), attribute: attribute)
        }
    }

    /// The `@FakeCase` attributes on cases declared inside `#if`, at any depth.
    ///
    /// Cases inside `#if` are not considered when choosing what `fake()`
    /// returns, so a marker there would otherwise be ignored without a word.
    var conditionalFakeCaseAttributes: [AttributeSyntax] {
        func attributes(
            in members: MemberBlockItemListSyntax,
            isConditional: Bool
        ) -> [AttributeSyntax] {
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

    /// The case `fake()` returns when none is marked `@FakeCase`, or `nil` when
    /// the enum has no cases at all.
    ///
    /// A case without associated values is preferred, wherever it appears,
    /// since it needs no values invented for it. Only when every case carries
    /// associated values does the first ``EnumCase/isWritable`` one win. When
    /// none of them is, the first case is returned anyway, so the caller has a
    /// case to report the failure about rather than a second kind of `nil`.
    var fakeCase: EnumCase? {
        let elements = enumDecl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap(\.elements)

        if let withoutValues = elements.first(where: { $0.parameterClause == nil }) {
            return fakeCase(for: withoutValues)
        }

        let candidates = elements.map { fakeCase(for: $0) }
        return candidates.first(where: \.isWritable) ?? candidates.first
    }

    /// The case one element of a `case` declaration describes.
    private func fakeCase(for element: EnumCaseElementSyntax) -> EnumCase {
        EnumCase(
            name: element.name.text,
            associatedValues: element.parameterClause.map(associatedValues(of:)) ?? []
        )
    }

    private func associatedValues(
        of parameterClause: EnumCaseParameterClauseSyntax
    ) -> [AssociatedValue] {
        parameterClause.parameters.map { parameter in
            // `case tapped(_ title: String)` declares the value unlabeled and
            // names it for the case's own body, so the first name is the `_`
            // and the name the macro can use follows it.
            let isUnlabeled = parameter.firstName?.tokenKind == .wildcard

            return AssociatedValue(
                label: isUnlabeled ? nil : parameter.firstName?.text,
                declaredName: isUnlabeled ? parameter.secondName?.text : nil,
                type: parameter.type.trimmedDescription,
                value: parameter.type.fakeDefaultValue(
                    genericParameterNames: genericParameterNames
                )
            )
        }
    }

    // MARK: - Rendering

    /// The `fake()` source returning `fakeCase`.
    ///
    /// The case's associated values become parameters, the way a struct's
    /// stored properties do, each defaulted by its type. `fake()` still returns
    /// the same value as before when it is called with no arguments, and a test
    /// that wants one value of the case different no longer has to write the
    /// case out by hand.
    ///
    /// Callers render only an ``EnumCase/isWritable`` case, since `fake()` has
    /// to be callable with no arguments for `.fake()` to reach it. A value with
    /// no default would become a required parameter here, the way a struct's
    /// does.
    func fakeMethod(for fakeCase: EnumCase) -> String {
        guard !fakeCase.associatedValues.isEmpty else {
            return condition.guarding(
                """
                \(accessLevel.prefixing("static func fake"))() -> Self {
                    .\(fakeCase.name)
                }
                """
            )
        }

        var parameters: [String] = []
        var arguments: [String] = []

        for (associatedValue, name) in zip(
            fakeCase.associatedValues,
            parameterNames(for: fakeCase.associatedValues)
        ) {
            // A value the case declares no label for is passed positionally, so
            // its parameter takes none either.
            let declaration =
                switch associatedValue.label {
                case nil: "_ \(name)"
                case name: name
                case let label?: "\(label) \(name)"
                }
            let defaultValue = associatedValue.value.map { " = \($0)" } ?? ""

            parameters.append("    \(declaration): \(associatedValue.type)\(defaultValue)")
            arguments.append(associatedValue.label.map { "\($0): \(name)" } ?? name)
        }

        return condition.guarding(
            """
            \(accessLevel.prefixing("static func fake"))(
            \(parameters.joined(separator: ",\n"))
            ) -> Self {
                .\(fakeCase.name)(\(arguments.joined(separator: ", ")))
            }
            """
        )
    }

    /// The parameter name each associated value is referred to by inside
    /// `fake()`, in order.
    ///
    /// A labeled value is named after its label, an unlabeled one after the
    /// name the case gives it, and a value with neither after its position,
    /// since there is nothing else to call it. The names are then made unique:
    /// one a previous value already took gains an underscore, so a case can
    /// label a value `value0` without colliding with the name an unlabeled one
    /// is given. Only the name inside the method changes; the labels the caller
    /// writes are the ones the case declares.
    private func parameterNames(for associatedValues: [AssociatedValue]) -> [String] {
        var taken: Set<String> = []

        return associatedValues.enumerated().map { index, associatedValue in
            var name =
                associatedValue.label
                ?? associatedValue.declaredName
                ?? "value\(index)"
            while !taken.insert(name).inserted {
                name += "_"
            }
            return name
        }
    }
}
