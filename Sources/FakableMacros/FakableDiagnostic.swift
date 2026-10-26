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
        switch self {
        case .unsupportedDeclaration:
            "'@Fakable' can only be applied to a struct or an enum"
        case .noStoredProperties:
            "'@Fakable' generates nothing for a struct with no stored properties"
        case .memberwiseInitializerUnavailable:
            """
            '@Fakable' calls the memberwise initializer, which a struct that \
            declares an 'init' in its body does not get; move this 'init' to an extension
            """
        case .noCases:
            "'@Fakable' generates nothing for an enum with no cases"
        case .unwritableAssociatedValue:
            """
            '@Fakable' cannot write a value for any case of this enum; \
            every case carries an associated value with no default, such as a generic or a closure
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
        case .unwritableFakeCase:
            """
            '@FakeCase' marks a case with an associated value that has no default, \
            such as a generic or a closure
            """
        case .duplicateFakeCase:
            "'@FakeCase' can mark only one case of an enum"
        case .misplacedFakeCase:
            "'@FakeCase' can only be applied to an enum case"
        case .ambiguousFakeCase:
            "'@FakeCase' marks a single case; declare this case on its own"
        case .unusedFakeCase:
            "'@FakeCase' has no effect in an enum that is not '@Fakable'"
        case .conditionalFakeCase:
            "'@FakeCase' has no effect on a case declared inside '#if'"
        case .misplacedFakeValue:
            "'@FakeValue' can only be applied to a stored property"
        case .unusedFakeValue:
            """
            '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
            property, or its type is not '@Fakable'
            """
        }
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .noStoredProperties, .noCases, .unusedFakeValue, .unusedFakeCase,
            .conditionalFakeCase:
            .warning
        case .unsupportedDeclaration, .memberwiseInitializerUnavailable,
            .unwritableAssociatedValue, .unreadableCondition, .invalidCondition,
            .unwritableFakeCase, .duplicateFakeCase, .misplacedFakeCase, .ambiguousFakeCase,
            .misplacedFakeValue:
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
        case .memberwiseInitializerUnavailable: "memberwiseInitializerUnavailable"
        case .noCases: "noCases"
        case .unwritableAssociatedValue: "unwritableAssociatedValue"
        case .unreadableCondition: "unreadableCondition"
        case .invalidCondition: "invalidCondition"
        case .unwritableFakeCase: "unwritableFakeCase"
        case .duplicateFakeCase: "duplicateFakeCase"
        case .misplacedFakeCase: "misplacedFakeCase"
        case .ambiguousFakeCase: "ambiguousFakeCase"
        case .unusedFakeCase: "unusedFakeCase"
        case .conditionalFakeCase: "conditionalFakeCase"
        case .misplacedFakeValue: "misplacedFakeValue"
        case .unusedFakeValue: "unusedFakeValue"
        }
    }
}
