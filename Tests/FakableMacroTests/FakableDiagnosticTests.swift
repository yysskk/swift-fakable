@testable import FakableMacros
import SwiftDiagnostics
import Testing

@Suite("Diagnostic Tests")
struct FakableDiagnosticTests {
    /// Every diagnostic the macros emit.
    ///
    /// Written out rather than derived, since one case carries a value: a new
    /// diagnostic has to be listed here before the checks below cover it.
    private static let all: [FakableDiagnostic] = [
        .unsupportedDeclaration,
        .noStoredProperties,
        .memberwiseInitializerUnavailable,
        .noCases,
        .unwritableAssociatedValue,
        .unreadableCondition,
        .invalidCondition("not a condition!"),
        .unwritableFakeCase,
        .duplicateFakeCase,
        .misplacedFakeCase,
        .ambiguousFakeCase,
        .unusedFakeCase,
        .conditionalFakeCase,
        .misplacedFakeValue,
        .unusedFakeValue,
    ]

    @Test("Each diagnostic is identified by its own case name, in one domain")
    func identifierMatchesCaseName() {
        for diagnostic in Self.all {
            #expect(
                diagnostic.diagnosticID
                    == MessageID(domain: "FakableMacros", id: caseName(of: diagnostic))
            )
        }
    }

    @Test("No two diagnostics share an identifier")
    func identifiersAreUnique() {
        let identifiers = Self.all.map(\.diagnosticID)

        #expect(Set(identifiers).count == identifiers.count)
    }

    @Test("Every diagnostic says something")
    func messagesAreWritten() {
        for diagnostic in Self.all {
            #expect(!diagnostic.message.isEmpty)
        }
    }
}

/// The name of the case `diagnostic` is, whether or not it carries a value.
///
/// A case with an associated value describes itself as `name(value)`, and
/// reflection is what separates the two.
private func caseName(of diagnostic: FakableDiagnostic) -> String {
    Mirror(reflecting: diagnostic).children.first?.label ?? String(describing: diagnostic)
}
