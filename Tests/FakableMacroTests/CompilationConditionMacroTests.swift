import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Compilation Condition Macro Tests")
struct CompilationConditionMacroTests {
    @Test("Explicit .debug wraps fake() in #if DEBUG")
    func fakableWithDebugCondition() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: .debug)
            struct Item {
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
            macros: testMacros
        )
    }

    @Test("Custom condition wraps fake() in that condition")
    func fakableWithCustomCondition() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: .custom("DEBUG || UITESTS"))
            struct Item {
                let name: String
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String

                    #if DEBUG || UITESTS
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
            macros: testMacros
        )
    }

    @Test("Always emits fake() with no guard")
    func fakableWithAlwaysCondition() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: .always)
            struct Item {
                let name: String
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String

                    static func fake(
                        name: String = ""
                    ) -> Self {
                        Self(
                            name: name
                        )
                    }
                }
                """,
            macros: testMacros
        )
    }

    @Test("Condition applies to enums too")
    func fakableWithConditionOnEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable(condition: .always)
            enum Status {
                case active
            }
            """,
            expandedSource: """
                enum Status {
                    case active

                    static func fake() -> Self {
                        .active
                    }
                }
                """,
            macros: testMacros
        )
    }
}
