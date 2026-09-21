import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Diagnostic Macro Tests")
struct DiagnosticMacroTests {
    @Test("Applying @Fakable to a class is an error")
    func fakableOnClassShouldFail() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            class Person {
                let name: String
            }
            """,
            expandedSource: """
                class Person {
                    let name: String
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@Fakable' can only be applied to a struct or an enum",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Applying @Fakable to a protocol is an error")
    func fakableOnProtocolShouldFail() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            protocol Person {
                var name: String { get }
            }
            """,
            expandedSource: """
                protocol Person {
                    var name: String { get }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@Fakable' can only be applied to a struct or an enum",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Struct with no stored properties warns")
    func fakableWithoutStoredProperties() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Marker {
                var label: String {
                    "marker"
                }
            }
            """,
            expandedSource: """
                struct Marker {
                    var label: String {
                        "marker"
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@Fakable' generates nothing for a struct with no stored properties",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Enum with no cases warns")
    func fakableWithEmptyEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum EmptyEnum {
            }
            """,
            expandedSource: """
                enum EmptyEnum {
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@Fakable' generates nothing for an enum with no cases",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
    }

    @Test("Generic enum with only generic associated values is an error")
    func fakableWithUnwritableAssociatedValue() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Wrapped<T> {
                case value(T)
            }
            """,
            expandedSource: """
                enum Wrapped<T> {
                    case value(T)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                        '@Fakable' cannot write a value for any case of this enum; \
                        every case carries a generic associated value
                        """,
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Condition that is not written literally is an error")
    func fakableWithUnreadableCondition() {
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
                        '.always', or '.custom("FLAG")'
                        """,
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Condition that #if would reject is an error")
    func fakableWithInvalidCondition() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: .custom("not a condition!"))
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
                    message: #""not a condition!" is not a compilation condition '#if' accepts"#,
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Condition that closes the #if is an error")
    func fakableWithEscapingCondition() {
        assertMacroExpansionForTesting(
            #"""
            @Fakable(condition: .custom("DEBUG\n#endif\nstruct Injected {}\n#if DEBUG"))
            struct Item {
                let name: String
            }
            """#,
            expandedSource: #"""
                struct Item {
                    let name: String
                }
                """#,
            diagnostics: [
                DiagnosticSpec(
                    message: #""DEBUG\n#endif\nstruct Injected {}\n#if DEBUG" is not a compilation condition '#if' accepts"#,
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }
}
