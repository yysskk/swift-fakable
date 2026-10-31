import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("FakeValue Macro Tests")
struct FakeValueMacroTests {
    @Test("Value from @FakeValue becomes the parameter default")
    func fakeValueOnConstant() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct User {
                @FakeValue("user@example.com")
                let email: String
                @FakeValue(Role.member)
                let role: Role
            }
            """,
            expandedSource: """
                struct User {
                    let email: String
                    let role: Role

                    #if DEBUG
                    static func fake(
                        email: String = "user@example.com",
                        role: Role = Role.member
                    ) -> Self {
                        Self(
                            email: email,
                            role: role
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("@FakeValue wins over a declared value and over the optional default")
    func fakeValuePrecedence() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Query {
                @FakeValue(3)
                var page: Int = 1
                @FakeValue("draft")
                var note: String?
            }
            """,
            expandedSource: """
                struct Query {
                    var page: Int = 1
                    var note: String?

                    #if DEBUG
                    static func fake(
                        page: Int = 3,
                        note: String? = "draft"
                    ) -> Self {
                        Self(
                            page: page,
                            note: note
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("@FakeValue on a declaration of several properties is rejected")
    func fakeValueOnSeveralBindings() {
        // The compiler, not the macro, refuses a peer macro here; the test pins
        // that so the documentation's advice stays true.
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Size {
                @FakeValue(10)
                let width, height: Int
            }
            """,
            expandedSource: """
                struct Size {
                    let width, height: Int

                    #if DEBUG
                    static func fake(
                        width: Int = 10,
                        height: Int = 10
                    ) -> Self {
                        Self(
                            width: width,
                            height: height
                        )
                    }
                    #endif
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "peer macro can only be applied to a single variable",
                    line: 3,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("@FakeValue on something other than a property is an error")
    func fakeValueOnFunction() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                @FakeValue(1)
                func count() -> Int { 0 }
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    func count() -> Int { 0 }

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
                    message: "'@FakeValue' can only be applied to a stored property",
                    line: 4,
                    column: 5,
                    severity: .error,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                )
            ],
            macros: testMacros
        )
    }

    @Test("@FakeValue on a property fake() does not take is a warning")
    func fakeValueOnSkippedProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                @FakeValue(1)
                static var count: Int = 0
                @FakeValue(2)
                let version: Int = 5
                @FakeValue(3)
                var revision = 1
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    static var count: Int = 0
                    let version: Int = 5
                    var revision = 1

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
                    message: """
                        '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                        property, or its type is not '@Fakable'
                        """,
                    line: 4,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                ),
                DiagnosticSpec(
                    message: """
                        '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                        property, or its type is not '@Fakable'
                        """,
                    line: 6,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                ),
                DiagnosticSpec(
                    message: """
                        '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                        property, or its type is not '@Fakable'
                        """,
                    line: 8,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                ),
            ],
            macros: testMacros
        )
    }

    @Test("@FakeValue in a type without @Fakable is a warning")
    func fakeValueOutsideFakableType() {
        assertMacroExpansionForTesting(
            """
            struct Item {
                @FakeValue("a")
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
                        '@FakeValue' has no effect here; 'fake()' takes no parameter for this \
                        property, or its type is not '@Fakable'
                        """,
                    line: 2,
                    column: 5,
                    severity: .warning,
                    fixIts: [FixItSpec(message: "Remove '@FakeValue'")]
                )
            ],
            macros: testMacros
        )
    }
}
