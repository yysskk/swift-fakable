import SwiftDiagnostics

/// The diagnostics `@Fakable`, `@FakeValue`, and `@FakeCase` emit.
///
/// Every case carries a stable ``MessageID``, so a diagnostic can be recognised
/// by tooling rather than only by its text.
enum FakableDiagnostic: DiagnosticMessage, Error {
    /// The macro was attached to something other than a struct or an enum.
    case unsupportedDeclaration

    /// A struct has nothing the memberwise initializer would take.
    case noStoredProperties

    /// A struct declares an `init` in its body, so Swift does not synthesize
    /// the memberwise initializer `fake()` calls, and no declared `init`
    /// takes its place.
    case memberwiseInitializerUnavailable

    /// An enum has no case to return.
    case noCases

    /// Every case carries an associated value the macro cannot write.
    case unwritableAssociatedValue

    /// The `condition:` argument was not written in a form the macro can read.
    case unreadableCondition

    /// The custom condition is not something `#if` accepts.
    case invalidCondition(String)

    /// The case marked `@FakeCase` carries a value the macro cannot write.
    case unwritableFakeCase

    /// More than one case is marked `@FakeCase`.
    case duplicateFakeCase

    /// `@FakeCase` was attached to something other than an enum case.
    case misplacedFakeCase

    /// `@FakeCase` was attached to a declaration of several cases.
    case ambiguousFakeCase

    /// `@FakeCase` was attached to a case of an enum without `@Fakable`.
    case unusedFakeCase

    /// `@FakeCase` was attached to a case declared inside `#if`.
    case conditionalFakeCase

    /// `@FakeValue` was attached to something other than a property.
    case misplacedFakeValue

    /// `@FakeValue` was attached to a property `fake()` takes no parameter
    /// for, or to a property of a type without `@Fakable`.
    case unusedFakeValue

    var message: String {
        descriptor.message
    }

    var severity: DiagnosticSeverity {
        descriptor.severity
    }

    var diagnosticID: MessageID {
        MessageID(domain: "FakableMacros", id: descriptor.id)
    }

    /// Everything that tells one diagnostic from another, so a case is
    /// described in one place rather than once per property.
    private var descriptor: Descriptor {
        switch self {
        case .unsupportedDeclaration:
            Descriptor(
                id: "unsupportedDeclaration",
                severity: .error,
                message: "'@Fakable' can only be applied to a struct or an enum"
            )
        case .noStoredProperties:
            Descriptor(
                id: "noStoredProperties",
                severity: .warning,
                message: "'@Fakable' generates nothing for a struct with no stored properties"
            )
        case .memberwiseInitializerUnavailable:
            Descriptor(
                id: "memberwiseInitializerUnavailable",
                severity: .error,
                message: """
                    '@Fakable' calls the memberwise initializer, which a struct that \
                    declares an 'init' in its body does not get; move this 'init' to an extension
                    """
            )
        case .noCases:
            Descriptor(
                id: "noCases",
                severity: .warning,
                message: "'@Fakable' generates nothing for an enum with no cases"
            )
        case .unwritableAssociatedValue:
            Descriptor(
                id: "unwritableAssociatedValue",
                severity: .error,
                message: """
                    '@Fakable' cannot write a value for any case of this enum; \
                    every case carries an associated value with no default, such as a generic or a closure
                    """
            )
        case .unreadableCondition:
            Descriptor(
                id: "unreadableCondition",
                severity: .error,
                message: """
                    '@Fakable' needs 'condition:' written literally as '.debug', \
                    '.always', '.custom("FLAG")', or "FLAG"
                    """
            )
        case .invalidCondition(let condition):
            Descriptor(
                id: "invalidCondition",
                severity: .error,
                // Spelled as a literal, so a condition containing a newline is
                // still reported on one line.
                message: "\(String(reflecting: condition)) is not a compilation condition '#if' accepts"
            )
        case .unwritableFakeCase:
            Descriptor(
                id: "unwritableFakeCase",
                severity: .error,
                message: """
                    '@FakeCase' marks a case with an associated value that has no default, \
                    such as a generic or a closure
                    """
            )
        case .duplicateFakeCase:
            Descriptor(
                id: "duplicateFakeCase",
                severity: .error,
                message: "'@FakeCase' can mark only one case of an enum"
            )
        case .misplacedFakeCase:
            Descriptor(
                id: "misplacedFakeCase",
                severity: .error,
                message: "'@FakeCase' can only be applied to an enum case"
            )
        case .ambiguousFakeCase:
            Descriptor(
                id: "ambiguousFakeCase",
                severity: .error,
                message: "'@FakeCase' marks a single case; declare this case on its own"
            )
        case .unusedFakeCase:
            Descriptor(
                id: "unusedFakeCase",
                severity: .warning,
                message: "'@FakeCase' has no effect in an enum that is not '@Fakable'"
            )
        case .conditionalFakeCase:
            Descriptor(
                id: "conditionalFakeCase",
                severity: .warning,
                message: "'@FakeCase' has no effect on a case declared inside '#if'"
            )
        case .misplacedFakeValue:
            Descriptor(
                id: "misplacedFakeValue",
                severity: .error,
                message: "'@FakeValue' can only be applied to a stored property"
            )
        case .unusedFakeValue:
            Descriptor(
                id: "unusedFakeValue",
                severity: .warning,
                message: """
                    '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                    property, or its type is not '@Fakable'
                    """
            )
        }
    }
}

extension FakableDiagnostic {
    /// What one diagnostic is: the id tooling recognises it by, how loudly it
    /// is reported, and what it says.
    private struct Descriptor {
        /// The ``MessageID`` id, which is the case's own name.
        let id: String

        let severity: DiagnosticSeverity

        let message: String
    }
}
