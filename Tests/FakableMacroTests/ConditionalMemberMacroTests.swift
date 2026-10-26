import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Conditional Member Macro Tests")
struct ConditionalMemberMacroTests {
    @Test("Each #if clause gets a fake() of its own, plus the missing #else")
    func fakableWithConditionalProperties() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                #if os(iOS)
                let badge: Int
                #elseif os(macOS)
                let menu: String
                #endif
                let count: Int
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    #if os(iOS)
                    let badge: Int
                    #elseif os(macOS)
                    let menu: String
                    #endif
                    let count: Int

                    #if DEBUG
                    #if os(iOS)
                    static func fake(
                        name: String = "",
                        badge: Int = 0,
                        count: Int = 0
                    ) -> Self {
                        Self(
                            name: name,
                            badge: badge,
                            count: count
                        )
                    }
                    #elseif os(macOS)
                    static func fake(
                        name: String = "",
                        menu: String = "",
                        count: Int = 0
                    ) -> Self {
                        Self(
                            name: name,
                            menu: menu,
                            count: count
                        )
                    }
                    #else
                    static func fake(
                        name: String = "",
                        count: Int = 0
                    ) -> Self {
                        Self(
                            name: name,
                            count: count
                        )
                    }
                    #endif
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Nested #if blocks split within their clause")
    func fakableWithNestedConditionalProperties() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                #if DEBUG
                let note: String
                #if os(iOS)
                let badge: Int
                #endif
                #else
                let id: Int
                #endif
            }
            """,
            expandedSource: """
                struct Item {
                    #if DEBUG
                    let note: String
                    #if os(iOS)
                    let badge: Int
                    #endif
                    #else
                    let id: Int
                    #endif

                    #if DEBUG
                    #if DEBUG
                    #if os(iOS)
                    static func fake(
                        note: String = "",
                        badge: Int = 0
                    ) -> Self {
                        Self(
                            note: note,
                            badge: badge
                        )
                    }
                    #else
                    static func fake(
                        note: String = ""
                    ) -> Self {
                        Self(
                            note: note
                        )
                    }
                    #endif
                    #else
                    static func fake(
                        id: Int = 0
                    ) -> Self {
                        Self(
                            id: id
                        )
                    }
                    #endif
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("#if block without stored properties does not split fake()")
    func fakableWithConditionalMethodsOnly() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                #if DEBUG
                func debugDescription() -> String {
                    name
                }
                #endif
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    #if DEBUG
                    func debugDescription() -> String {
                        name
                    }
                    #endif

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

    @Test("Configuration with no stored properties calls Self()")
    func fakableWithEmptyConfiguration() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                #if os(iOS)
                let badge: Int
                #endif
            }
            """,
            expandedSource: """
                struct Item {
                    #if os(iOS)
                    let badge: Int
                    #endif

                    #if DEBUG
                    #if os(iOS)
                    static func fake(
                        badge: Int = 0
                    ) -> Self {
                        Self(
                            badge: badge
                        )
                    }
                    #else
                    static func fake() -> Self {
                        Self()
                    }
                    #endif
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Init must stand in for every configuration's memberwise initializer")
    func fakableWithInitializerCoveringOneConfiguration() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                #if os(iOS)
                let badge: Int
                #endif

                init(name: String) {
                    self.name = name
                }
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    #if os(iOS)
                    let badge: Int
                    #endif

                    init(name: String) {
                        self.name = name
                    }
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: """
                        '@Fakable' calls the memberwise initializer, which a struct that \
                        declares an 'init' in its body does not get; move this 'init' to an extension
                        """,
                    line: 8,
                    column: 5,
                    severity: .error
                )
            ],
            macros: testMacros
        )
    }

    @Test("Sequential #if blocks give one fake() per combination")
    func fakableWithSequentialConditionalBlocks() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                #if os(iOS)
                let badge: Int
                #endif
                #if DEBUG
                let note: String
                #endif
            }
            """,
            expandedSource: """
                struct Item {
                    #if os(iOS)
                    let badge: Int
                    #endif
                    #if DEBUG
                    let note: String
                    #endif

                    #if DEBUG
                    #if os(iOS)
                    #if DEBUG
                    static func fake(
                        badge: Int = 0,
                        note: String = ""
                    ) -> Self {
                        Self(
                            badge: badge,
                            note: note
                        )
                    }
                    #else
                    static func fake(
                        badge: Int = 0
                    ) -> Self {
                        Self(
                            badge: badge
                        )
                    }
                    #endif
                    #else
                    #if DEBUG
                    static func fake(
                        note: String = ""
                    ) -> Self {
                        Self(
                            note: note
                        )
                    }
                    #else
                    static func fake() -> Self {
                        Self()
                    }
                    #endif
                    #endif
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
