import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Basic Macro Tests")
struct BasicMacroTests {
    @Test("Simple struct generates fake()")
    func fakableWithSimpleStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Person {
                let name: String
                let age: Int
            }
            """,
            expandedSource: """
                struct Person {
                    let name: String
                    let age: Int

                    #if DEBUG
                    static func fake(
                        name: String = "",
                        age: Int = 0
                    ) -> Self {
                        Self(
                            name: name,
                            age: age
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Optional property uses nil as default in fake()")
    func fakableWithOptionalProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let itemId: String
                let name: String?
            }
            """,
            expandedSource: """
                struct Item {
                    let itemId: String
                    let name: String?

                    #if DEBUG
                    static func fake(
                        itemId: String = "",
                        name: String? = nil
                    ) -> Self {
                        Self(
                            itemId: itemId,
                            name: name
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Array uses [] and Dictionary uses [:] as default")
    func fakableWithArrayAndDictionary() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Container {
                let items: [String]
                let mapping: [String: Int]
            }
            """,
            expandedSource: """
                struct Container {
                    let items: [String]
                    let mapping: [String: Int]

                    #if DEBUG
                    static func fake(
                        items: [String] = [],
                        mapping: [String: Int] = [:]
                    ) -> Self {
                        Self(
                            items: items,
                            mapping: mapping
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Custom type uses .fake() as default")
    func fakableWithCustomType() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Order {
                let id: String
                let item: Item
            }
            """,
            expandedSource: """
                struct Order {
                    let id: String
                    let item: Item

                    #if DEBUG
                    static func fake(
                        id: String = "",
                        item: Item = .fake()
                    ) -> Self {
                        Self(
                            id: id,
                            item: item
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Struct with enum property uses .fake() for enum")
    func fakableStructWithEnumProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Person {
                let name: String
                let sex: Sex
            }
            """,
            expandedSource: """
                struct Person {
                    let name: String
                    let sex: Sex

                    #if DEBUG
                    static func fake(
                        name: String = "",
                        sex: Sex = .fake()
                    ) -> Self {
                        Self(
                            name: name,
                            sex: sex
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
