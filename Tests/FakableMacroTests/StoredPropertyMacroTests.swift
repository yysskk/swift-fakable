import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Stored Property Macro Tests")
struct StoredPropertyMacroTests {
    @Test("Property observer stays a stored property")
    func fakableWithPropertyObserver() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Counter {
                let id: String
                var count: Int {
                    didSet {
                        print(count)
                    }
                }
            }
            """,
            expandedSource: """
                struct Counter {
                    let id: String
                    var count: Int {
                        didSet {
                            print(count)
                        }
                    }

                    #if DEBUG
                    static func fake(
                        id: String = "",
                        count: Int = 0
                    ) -> Self {
                        Self(
                            id: id,
                            count: count
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Static property is not a memberwise parameter")
    func fakableWithStaticProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Config {
                static let shared: String = "x"
                let id: String
            }
            """,
            expandedSource: """
                struct Config {
                    static let shared: String = "x"
                    let id: String

                    #if DEBUG
                    static func fake(
                        id: String = ""
                    ) -> Self {
                        Self(
                            id: id
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Every binding of a declaration becomes a parameter")
    func fakableWithSeveralBindingsPerDeclaration() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Point {
                let x: Int, y: Int
            }
            """,
            expandedSource: """
                struct Point {
                    let x: Int, y: Int

                    #if DEBUG
                    static func fake(
                        x: Int = 0,
                        y: Int = 0
                    ) -> Self {
                        Self(
                            x: x,
                            y: y
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Bindings sharing one type annotation each get a parameter")
    func fakableWithSharedTypeAnnotation() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Point {
                let x, y: Int
            }
            """,
            expandedSource: """
                struct Point {
                    let x, y: Int

                    #if DEBUG
                    static func fake(
                        x: Int = 0,
                        y: Int = 0
                    ) -> Self {
                        Self(
                            x: x,
                            y: y
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Constant with a value is not a memberwise parameter")
    func fakableWithInitializedConstant() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                let version: Int = 5
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    let version: Int = 5

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

    @Test("Variable with a value stays a parameter")
    func fakableWithInitializedVariable() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                var version: Int = 5
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    var version: Int = 5

                    #if DEBUG
                    static func fake(
                        name: String = "",
                        version: Int = 0
                    ) -> Self {
                        Self(
                            name: name,
                            version: version
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Computed property is skipped")
    func fakableWithComputedProperty() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                let name: String
                var label: String {
                    name
                }
            }
            """,
            expandedSource: """
                struct Item {
                    let name: String
                    var label: String {
                        name
                    }

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
}
