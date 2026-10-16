import SwiftSyntax

/// Resolves the value `fake()` uses for a parameter of a given type.
///
/// The same rules apply to a struct's stored properties and to an enum case's
/// associated values, so both paths go through here.
enum DefaultValue {
    /// The value to use for `type`, or `nil` when none can be written for it.
    ///
    /// The table covers the stdlib types that have an obvious empty value, the
    /// Foundation value types that stand in for one, and the collections. Every
    /// value is deterministic, so two fakes of the same type compare equal.
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
        case "Double", "Float", "CGFloat", "TimeInterval":
            return "0.0"
        case "Bool":
            return "false"
        case "Decimal":
            // Decimal is ExpressibleByIntegerLiteral, so the literal is enough.
            return "0"
        case "Date":
            // The epoch rather than Date(), so the value does not depend on when
            // the fixture is built.
            return "Date(timeIntervalSince1970: 0)"
        case "UUID":
            // The nil UUID, so the value does not change between two fakes.
            return "UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))"
        case "URL":
            // The only non-failable initializer that needs no import beyond the
            // one the property's own type already requires.
            return "URL(fileURLWithPath: \"/\")"
        case "Data":
            return "Data()"
        default:
            // Dictionary check must come before Array check
            if spelling.hasPrefix("[") && spelling.contains(":") && spelling.hasSuffix("]") {
                return "[:]"
            }
            if spelling.hasPrefix("[") && spelling.hasSuffix("]") {
                return "[]"
            }
            // Ahead of the generic check, so Set<T> is empty for the same reason
            // [T] is: the element type never has to be written.
            if type.isSet {
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
    /// Whether the type is a `Set`, however its element type is spelled.
    ///
    /// Read from the syntax node rather than from the spelling, so a type whose
    /// name merely starts with `Set` does not count as one.
    var isSet: Bool {
        self.as(IdentifierTypeSyntax.self)?.name.text == "Set"
    }

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
