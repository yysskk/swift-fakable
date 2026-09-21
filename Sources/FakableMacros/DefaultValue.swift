import SwiftSyntax

/// Resolves the value `fake()` uses for a parameter of a given type.
///
/// The same rules apply to a struct's stored properties and to an enum case's
/// associated values, so both paths go through here.
enum DefaultValue {
    /// The value to use for `type`, or `nil` when none can be written for it.
    ///
    /// - Parameters:
    ///   - type: The type as it was written. Matching is on that spelling, since
    ///     the macro reads syntax and never resolves types.
    ///   - genericParameterNames: The names the enclosing declaration introduces.
    ///     A type built from one of these has no value the macro could write, so
    ///     it resolves to `nil` rather than to `.fake()`.
    static func resolve(for type: TypeSyntax, genericParameterNames: Set<String>) -> String? {
        if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return "nil"
        }

        let spelling = type.trimmedDescription
        switch spelling {
        case "String":
            return "\"\""
        case "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return "0"
        case "Double", "Float", "CGFloat":
            return "0.0"
        case "Bool":
            return "false"
        default:
            // Dictionary check must come before Array check
            if spelling.hasPrefix("[") && spelling.contains(":") && spelling.hasSuffix("]") {
                return "[:]"
            }
            if spelling.hasPrefix("[") && spelling.hasSuffix("]") {
                return "[]"
            }
            if type.references(anyOf: genericParameterNames) {
                return nil
            }
            // For other types (structs, enums, etc.), try to use .fake()
            // If the type doesn't have .fake(), users can provide explicit default values
            return ".fake()"
        }
    }
}

extension TypeSyntax {
    /// Whether the type is written in terms of any of `names`.
    ///
    /// Compared token by token, so a type called `Total` does not count as a
    /// reference to a generic parameter named `T`.
    func references(anyOf names: Set<String>) -> Bool {
        guard !names.isEmpty else {
            return false
        }

        return tokens(viewMode: .sourceAccurate).contains { token in
            if case .identifier(let text) = token.tokenKind {
                return names.contains(text)
            }
            return false
        }
    }
}

extension GenericParameterClauseSyntax? {
    /// The names the clause introduces, or an empty set when there is no clause.
    var parameterNames: Set<String> {
        guard let self else {
            return []
        }
        return Set(self.parameters.map(\.name.text))
    }
}
