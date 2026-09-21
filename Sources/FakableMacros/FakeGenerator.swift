import SwiftSyntax

/// Reads the members `fake()` has to cover, and renders the method source.
enum FakeGenerator {

    // MARK: - Extraction

    /// The stored properties `fake()` takes a parameter for, in declaration order.
    ///
    /// These are exactly the properties the memberwise initializer takes, since
    /// that is what the generated method calls. Type-level properties, computed
    /// properties, and constants that already have a value are all left out for
    /// that reason.
    ///
    /// A property whose type is inferred is also left out: the macro reads
    /// syntax, not types, so there is nothing to write a parameter type from.
    static func storedProperties(of structDecl: StructDeclSyntax) -> [StoredProperty] {
        let genericParameterNames = structDecl.genericParameterClause.parameterNames

        return structDecl.memberBlock.members.flatMap { member -> [StoredProperty] in
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
                    type: type.trimmedDescription,
                    defaultValue: DefaultValue.resolve(
                        for: type,
                        genericParameterNames: genericParameterNames
                    )
                )
            }
        }
    }

    /// The case `fake()` returns.
    ///
    /// A case without associated values is preferred, wherever it appears, since
    /// it needs no values invented for it. Only when every case carries
    /// associated values does the first case win, with values filled in.
    static func firstCase(of enumDecl: EnumDeclSyntax) -> EnumCaseInfo? {
        let members = enumDecl.memberBlock.members

        // First, try to find a case without associated values
        for member in members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
                // Check if the case has no associated values
                for element in caseDecl.elements where element.parameterClause == nil {
                    return EnumCaseInfo(name: element.name.text, parameters: [])
                }
            }
        }

        // Otherwise take the first case whose values can all be written. When
        // none can be, hand back the first candidate anyway so the caller has
        // something to report the failure against.
        let genericParameterNames = enumDecl.genericParameterClause.parameterNames
        var firstCandidate: EnumCaseInfo?

        for member in members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            for element in caseDecl.elements {
                guard let parameterClause = element.parameterClause else {
                    continue
                }

                let candidate = EnumCaseInfo(
                    name: element.name.text,
                    parameters: enumCaseParameters(
                        of: parameterClause,
                        genericParameterNames: genericParameterNames
                    )
                )

                if candidate.parameters.allSatisfy({ $0.value != nil }) {
                    return candidate
                }

                firstCandidate = firstCandidate ?? candidate
            }
        }

        // Empty enum
        return firstCandidate
    }

    private static func enumCaseParameters(
        of parameterClause: EnumCaseParameterClauseSyntax,
        genericParameterNames: Set<String>
    ) -> [EnumCaseParameter] {
        parameterClause.parameters.map { parameter in
            EnumCaseParameter(
                label: parameter.firstName?.text,
                value: DefaultValue.resolve(
                    for: parameter.type,
                    genericParameterNames: genericParameterNames
                )
            )
        }
    }

    // MARK: - Rendering

    static func fakeMethod(for properties: [StoredProperty], accessLevel: AccessLevel) -> String {
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
            #if DEBUG
            \(accessLevel.modifier)static func fake(
            \(parametersString)
            ) -> Self {
                Self(
            \(assignmentsString)
                )
            }
            #endif
            """
    }

    /// The enum `fake()` source, or `nil` when no value can be written for one
    /// of the case's associated values.
    static func enumFakeMethod(firstCase: EnumCaseInfo, accessLevel: AccessLevel) -> String? {
        if firstCase.parameters.isEmpty {
            // Case without associated values
            return """
                #if DEBUG
                \(accessLevel.modifier)static func fake() -> Self {
                    .\(firstCase.name)
                }
                #endif
                """
        }

        // Case with associated values - fill each one in from its type
        var renderedValues: [String] = []
        for parameter in firstCase.parameters {
            guard let value = parameter.value else {
                return nil
            }
            renderedValues.append(parameter.label.map { "\($0): \(value)" } ?? value)
        }

        return """
            #if DEBUG
            \(accessLevel.modifier)static func fake() -> Self {
                .\(firstCase.name)(\(renderedValues.joined(separator: ", ")))
            }
            #endif
            """
    }
}
