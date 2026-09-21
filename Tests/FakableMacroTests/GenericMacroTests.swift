import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Generic Macro Tests")
struct GenericMacroTests {
    @Test("Generic property becomes a required parameter")
    func fakableWithGenericProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Box<T> {
                let value: T
                let label: String
            }
            """,
            expandedSource: """
                struct Box<T> {
                    let value: T
                    let label: String

                    #if DEBUG
                    static func fake(
                        value: T,
                        label: String = ""
                    ) -> Self {
                        Self(
                            value: value,
                            label: label
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Collections and optionals of a generic parameter keep their default")
    func fakableWithGenericCollections() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Bag<Element> {
                let items: [Element]
                let first: Element?
            }
            """,
            expandedSource: """
                struct Bag<Element> {
                    let items: [Element]
                    let first: Element?

                    #if DEBUG
                    static func fake(
                        items: [Element] = [],
                        first: Element? = nil
                    ) -> Self {
                        Self(
                            items: items,
                            first: first
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Type merely sharing a prefix with a generic parameter keeps its default")
    func fakableWithSimilarlyNamedType() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Holder<T> {
                let total: Total
                let value: T
            }
            """,
            expandedSource: """
                struct Holder<T> {
                    let total: Total
                    let value: T

                    #if DEBUG
                    static func fake(
                        total: Total = .fake(),
                        value: T
                    ) -> Self {
                        Self(
                            total: total,
                            value: value
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Generic enum uses a case without associated values")
    func fakableWithGenericEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Either<T> {
                case some(T)
                case none
            }
            """,
            expandedSource: """
                enum Either<T> {
                    case some(T)
                    case none

                    #if DEBUG
                    static func fake() -> Self {
                        .none
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Generic enum uses the first case whose values can be written")
    func fakableWithPartlyWritableGenericEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Wrapped<T> {
                case value(T)
                case count(Int)
            }
            """,
            expandedSource: """
                enum Wrapped<T> {
                    case value(T)
                    case count(Int)

                    #if DEBUG
                    static func fake() -> Self {
                        .count(0)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
