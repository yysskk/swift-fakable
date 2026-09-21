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
        structDecl.memberBlock.members.flatMap { member -> [StoredProperty] in
            guard let variable = member.decl.as(VariableDeclSyntax.self), !variable.isStatic else {
                return []
            }

            return variable.bindingsWithResolvedTypes.compactMap { binding, type in
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
                    isOptional: type.is(OptionalTypeSyntax.self)
                        || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
                )
            }
        }
    }

    /// The case `fake()` returns.
    ///
    /// A case without associated values is preferred, wherever it appears, since
    /// it needs no values invented for it. Only when every case carries
    /// associated values does the first case win, with defaults filled in.
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

        // If no case without associated values, use the first case with default values
        for member in members {
            if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
                let element = caseDecl.elements.first,
                let parameterClause = element.parameterClause
            {
                let parameters = enumCaseParameters(of: parameterClause)
                return EnumCaseInfo(name: element.name.text, parameters: parameters)
            }
        }

        // Empty enum
        return nil
    }

    private static func enumCaseParameters(
        of parameterClause: EnumCaseParameterClauseSyntax
    ) -> [EnumCaseParameter] {
        parameterClause.parameters.map { param in
            let type = param.type.trimmedDescription
            let label = param.firstName?.text
            let isOptional =
                param.type.is(OptionalTypeSyntax.self) || param.type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)

            return EnumCaseParameter(
                label: label,
                type: type,
                isOptional: isOptional
            )
        }
    }

    // MARK: - Rendering

    static func fakeMethod(for properties: [StoredProperty], accessLevel: String) -> String {
        var parameters: [String] = []
        var assignments: [String] = []

        for property in properties {
            let defaultValue = DefaultValue.resolve(for: property)
            parameters.append("    \(property.name): \(property.type) = \(defaultValue)")
            assignments.append("        \(property.name): \(property.name)")
        }

        let parametersString = parameters.joined(separator: ",\n")
        let assignmentsString = assignments.joined(separator: ",\n")

        return """
            #if DEBUG
            \(accessLevel)static func fake(
            \(parametersString)
            ) -> Self {
                Self(
            \(assignmentsString)
                )
            }
            #endif
            """
    }

    static func enumFakeMethod(firstCase: EnumCaseInfo, accessLevel: String) -> String {
        if firstCase.parameters.isEmpty {
            // Case without associated values
            return """
                #if DEBUG
                \(accessLevel)static func fake() -> Self {
                    .\(firstCase.name)
                }
                #endif
                """
        } else {
            // Case with associated values - generate with default parameters
            let parameterValues = firstCase.parameters
                .map { param in
                    let defaultValue = DefaultValue.resolve(for: param)
                    if let label = param.label {
                        return "\(label): \(defaultValue)"
                    } else {
                        return defaultValue
                    }
                }
                .joined(separator: ", ")

            return """
                #if DEBUG
                \(accessLevel)static func fake() -> Self {
                    .\(firstCase.name)(\(parameterValues))
                }
                #endif
                """
        }
    }
}
