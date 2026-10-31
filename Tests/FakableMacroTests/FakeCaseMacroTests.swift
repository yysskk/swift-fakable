import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("FakeCase Macro Tests")
struct FakeCaseMacroTests {
    @Test("Case marked @FakeCase is what fake() returns")
    func fakeCaseSelectsCase() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Status {
                case unknown
                @FakeCase
                case active
            }
            """,
            expandedSource: """
                enum Status {
                    case unknown
                    case active

                    #if DEBUG
                    static func fake() -> Self {
                        .active
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Marked case with associated values has them filled in")
    func fakeCaseWithAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Result {
                case idle
                @FakeCase
                case loaded(items: [String], page: Int)
            }
            """,
            expandedSource: """
                enum Result {
                    case idle
                    case loaded(items: [String], page: Int)

                    #if DEBUG
                    static func fake(
                        items: [String] = [],
                        page: Int = 0
                    ) -> Self {
                        .loaded(items: items, page: page)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Marked case with a value the macro cannot write is an error")
    func fakeCaseWithUnwritableValue() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Event<T> {
                case idle
                @FakeCase
                case value(T)
            }
            """,
            expandedSource: """
                enum Event<T> {
                    case idle
                    case value(T)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                        '@FakeCase' marks a case with an associated value that has no default, \
                        such as a generic or a closure
                        """,
                    line: 4,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Marking two cases is an error on the second")
    func fakeCaseMarkedTwice() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Status {
                @FakeCase
                case active
                @FakeCase
                case inactive
            }
            """,
            expandedSource: """
                enum Status {
                    case active
                    case inactive
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' can mark only one case of an enum",
                    line: 5,
                    column: 5,
                    severity: .error,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros
        )
    }

    @Test("@FakeCase on a declaration of several cases is an error")
    func fakeCaseOnSeveralCases() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Status {
                @FakeCase
                case active, inactive
            }
            """,
            expandedSource: """
                enum Status {
                    case active, inactive

                    #if DEBUG
                    static func fake() -> Self {
                        .active
                    }
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' marks a single case; declare this case on its own",
                    line: 3,
                    column: 5,
                    severity: .error,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros
        )
    }

    @Test("@FakeCase on something other than a case is an error")
    func fakeCaseOnProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                @FakeCase
                let name: String
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String

                    #if DEBUG
                    static func fake(
                        name: String = ""
                    ) -> Self {
                        Self(
                            name: name
                        )
                    }
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' can only be applied to an enum case",
                    line: 3,
                    column: 5,
                    severity: .error,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros
        )
    }

    @Test("@FakeCase in an enum without @Fakable is a warning")
    func fakeCaseOutsideFakableEnum() {
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
            macros: testMacros
        )
    }

    @Test("@FakeCase on a case inside #if is a warning")
    func fakeCaseInsideConditional() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Status {
                case unknown
                #if DEBUG
                @FakeCase
                case debugging
                #endif
            }
            """,
            expandedSource: """
                enum Status {
                    case unknown
                    #if DEBUG
                    case debugging
                    #endif

                    #if DEBUG
                    static func fake() -> Self {
                        .unknown
                    }
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'@FakeCase' has no effect on a case declared inside '#if'",
                    line: 5,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeCase'")]
                )
            ],
            macros: testMacros
        )
    }
}
