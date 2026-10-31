import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// What the fix-its actually write, rather than only what they are called.
///
/// A fix-it that leaves the source broken is worse than no fix-it, and the
/// trivia around a removed attribute is where that goes wrong.
@Suite("Fix-It Tests")
struct FixItMacroTests {
    @Test("Removing a marker on a line of its own leaves the case where it was")
    func removeFakeCaseOnItsOwnLine() {
        assertMacroExpansionForTesting(
            """
            enum Status {
                @FakeCase
                case active
            }
            """,
            expandedSource: """
                enum Status {
                    case active
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' has no effect in an enum that is not '@Fakable'",
                    line: 2,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros,
            fixedSource: """
                enum Status {
                    case active
                }
                """
        )
    }

    @Test("Removing a marker written inline leaves the declaration on its line")
    func removeFakeCaseWrittenInline() {
        assertMacroExpansionForTesting(
            """
            enum Status {
                @FakeCase case active
            }
            """,
            expandedSource: """
                enum Status {
                    case active
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' has no effect in an enum that is not '@Fakable'",
                    line: 2,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros,
            fixedSource: """
                enum Status {
                    case active
                }
                """
        )
    }

    @Test("Removing a marker keeps the other attributes on the property")
    func removeFakeValueBesideAnotherAttribute() {
        assertMacroExpansionForTesting(
            """
            struct Item {
                @available(macOS 15.0, *)
                @FakeValue(1)
                var count: Int { 0 }
            }
            """,
            expandedSource: """
                struct Item {
                    @available(macOS 15.0, *)
                    var count: Int { 0 }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                        '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                        property, or its type is not '@Fakable'
                        """,
                    line: 3,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                )
            ],
            macros: testMacros,
            fixedSource: """
                struct Item {
                    @available(macOS 15.0, *)
                    var count: Int { 0 }
                }
                """
        )
    }

    @Test("An unreadable condition is replaced with .debug")
    func replaceUnreadableConditionWithDebug() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: someCondition)
            struct Item {
                let name: String
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                        '@Fakable' needs 'condition:' written literally as '.debug', \
                        '.always', '.custom("FLAG")', or "FLAG"
                        """,
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [FixItSpec(message: "Replace with '.debug'")]
                )
            ],
            macros: testMacros,
            fixedSource: """
                @Fakable(condition: .debug)
                struct Item {
                    let name: String
                }
                """
        )
    }
}
