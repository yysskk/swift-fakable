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
    @Test("Bracket sugar resolves whatever it nests")
    func fakableWithNestedBracketSugar() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Catalog {
                let grouped: [String: [Int]]
                let matrix: [[String]]
                let name: String!
            }
            """,
            expandedSource: """
                struct Catalog {
                    let grouped: [String: [Int]]
                    let matrix: [[String]]
                    let name: String!

                    #if DEBUG
                    static func fake(
                        grouped: [String: [Int]] = [:],
                        matrix: [[String]] = [],
                        name: String! = nil
                    ) -> Self {
                        Self(
                            grouped: grouped,
                            matrix: matrix,
                            name: name
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Longhand generic spelling resolves like its sugar")
    func fakableWithLonghandGenericSpelling() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Inventory {
                let name: Optional<String>
                let items: Array<String>
                let mapping: Dictionary<String, Int>
                let tags: Set<String>
            }
            """,
            expandedSource: """
                struct Inventory {
                    let name: Optional<String>
                    let items: Array<String>
                    let mapping: Dictionary<String, Int>
                    let tags: Set<String>

                    #if DEBUG
                    static func fake(
                        name: Optional<String> = nil,
                        items: Array<String> = [],
                        mapping: Dictionary<String, Int> = [:],
                        tags: Set<String> = []
                    ) -> Self {
                        Self(
                            name: name,
                            items: items,
                            mapping: mapping,
                            tags: tags
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Module-qualified spelling resolves like its bare name")
    func fakableWithModuleQualifiedSpelling() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Entry {
                let name: Swift.String
                let count: Swift.Int
                let createdAt: Foundation.Date
                let payload: Foundation.Data
                let items: Swift.Array<Swift.String>
            }
            """,
            expandedSource: """
                struct Entry {
                    let name: Swift.String
                    let count: Swift.Int
                    let createdAt: Foundation.Date
                    let payload: Foundation.Data
                    let items: Swift.Array<Swift.String>

                    #if DEBUG
                    static func fake(
                        name: Swift.String = "",
                        count: Swift.Int = 0,
                        createdAt: Foundation.Date = Date(timeIntervalSince1970: 0),
                        payload: Foundation.Data = Data(),
                        items: Swift.Array<Swift.String> = []
                    ) -> Self {
                        Self(
                            name: name,
                            count: count,
                            createdAt: createdAt,
                            payload: payload,
                            items: items
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Type nested in a type of your own keeps the .fake() fallback")
    func fakableWithNestedTypeSpelling() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Booking {
                let slot: Models.Date
            }
            """,
            expandedSource: """
                struct Booking {
                    let slot: Models.Date

                    #if DEBUG
                    static func fake(
                        slot: Models.Date = .fake()
                    ) -> Self {
                        Self(
                            slot: slot
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Foundation value types use their empty defaults")
    func fakableWithFoundationValueTypes() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Receipt {
                let id: UUID
                let issuedAt: Date
                let endpoint: URL
                let payload: Data
                let amount: Decimal
                let duration: TimeInterval
            }
            """,
            expandedSource: """
                struct Receipt {
                    let id: UUID
                    let issuedAt: Date
                    let endpoint: URL
                    let payload: Data
                    let amount: Decimal
                    let duration: TimeInterval

                    #if DEBUG
                    static func fake(
                        id: UUID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                        issuedAt: Date = Date(timeIntervalSince1970: 0),
                        endpoint: URL = URL(fileURLWithPath: "/"),
                        payload: Data = Data(),
                        amount: Decimal = 0,
                        duration: TimeInterval = 0.0
                    ) -> Self {
                        Self(
                            id: id,
                            issuedAt: issuedAt,
                            endpoint: endpoint,
                            payload: payload,
                            amount: amount,
                            duration: duration
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Set uses [] as default, including a set of a generic parameter")
    func fakableWithSet() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Catalog<Element> {
                let tags: Set<String>
                let entries: Set<Element>
            }
            """,
            expandedSource: """
                struct Catalog<Element> {
                    let tags: Set<String>
                    let entries: Set<Element>

                    #if DEBUG
                    static func fake(
                        tags: Set<String> = [],
                        entries: Set<Element> = []
                    ) -> Self {
                        Self(
                            tags: tags,
                            entries: entries
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
