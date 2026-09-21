import SwiftDiagnostics

/// The diagnostics `@Fakable` emits.
///
/// Every case carries a stable ``MessageID``, so a diagnostic can be recognised
/// by tooling rather than only by its text.
enum FakableDiagnostic: DiagnosticMessage, Error {
    /// The macro was attached to something other than a struct or an enum.
    case unsupportedDeclaration

    /// A struct has nothing the memberwise initializer would take.
    case noStoredProperties

    /// An enum has no case to return.
    case noCases

    /// The case `fake()` would return carries a value the macro cannot write.
    case unwritableAssociatedValue

    /// The `condition:` argument was not written in a form the macro can read.
    case unreadableCondition

    /// The custom condition is not something `#if` accepts.
    case invalidCondition(String)

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
            '@Fakable' cannot write a value for any case of this enum; \
            every case carries a generic associated value
            """
        case .unreadableCondition:
            """
            '@Fakable' needs 'condition:' written literally as '.debug', \
            '.always', or '.custom("FLAG")'
            """
        case .invalidCondition(let condition):
            // Spelled as a literal, so a condition containing a newline is
            // still reported on one line.
            "\(String(reflecting: condition)) is not a compilation condition '#if' accepts"
        }
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .noStoredProperties, .noCases:
            .warning
        case .unsupportedDeclaration, .unwritableAssociatedValue, .unreadableCondition,
            .invalidCondition:
            .error
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "FakableMacros", id: identifier)
    }

    private var identifier: String {
        switch self {
        case .unsupportedDeclaration: "unsupportedDeclaration"
        case .noStoredProperties: "noStoredProperties"
        case .noCases: "noCases"
        case .unwritableAssociatedValue: "unwritableAssociatedValue"
        case .unreadableCondition: "unreadableCondition"
        case .invalidCondition: "invalidCondition"
        }
    }
}
