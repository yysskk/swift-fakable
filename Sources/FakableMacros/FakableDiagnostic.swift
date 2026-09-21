import SwiftDiagnostics

/// The diagnostics `@Fakable` emits.
///
/// Every case carries a stable ``MessageID``, so a diagnostic can be recognised
/// by tooling rather than only by its text.
enum FakableDiagnostic: String, DiagnosticMessage {
    /// The macro was attached to something other than a struct or an enum.
    case unsupportedDeclaration

    /// A struct has nothing the memberwise initializer would take.
    case noStoredProperties

    /// An enum has no case to return.
    case noCases

    /// The case `fake()` would return carries a value the macro cannot write.
    case unwritableAssociatedValue

    var message: String {
        switch self {
        case .unsupportedDeclaration:
            "'@Fakable' can only be applied to a struct or an enum"
        case .noStoredProperties:
            "'@Fakable' generates nothing for a struct with no stored properties"
        case .noCases:
            "'@Fakable' generates nothing for an enum with no cases"
        case .unwritableAssociatedValue:
            """
            '@Fakable' cannot write a value for a generic associated value; \
            add a case without associated values
            """
        }
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .unsupportedDeclaration, .unwritableAssociatedValue:
            .error
        case .noStoredProperties, .noCases:
            .warning
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "FakableMacros", id: rawValue)
    }
}
