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

    @Test("Variable with a value stays a parameter, defaulted to that value")
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
                        version: Int = 5
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

    @Test("Declared value that references a declaration is used as written")
    func fakableWithInitializerReferencingDeclaration() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Page {
                static let first = 1
                var number: Int = Self.first
                var label: String = "page \\(Self.first)"
            }
            """,
            expandedSource: """
                struct Page {
                    static let first = 1
                    var number: Int = Self.first
                    var label: String = "page \\(Self.first)"

                    #if DEBUG
                    static func fake(
                        number: Int = Self.first,
                        label: String = "page \\(Self.first)"
                    ) -> Self {
                        Self(
                            number: number,
                            label: label
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Declared value overrides the optional default")
    func fakableWithInitializedOptional() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            struct Item {
                var note: String? = "draft"
            }
            """,
            expandedSource: """
                struct Item {
                    var note: String? = "draft"

                    #if DEBUG
                    static func fake(
                        note: String? = "draft"
                    ) -> Self {
                        Self(
                            note: note
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Public fake() uses a declared literal")
    func fakableWithPublicLiteralInitializers() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            public struct Settings {
                var count: Int = 5
                var offset: Int = -1
                var ratio: Double = -0.5
                var title: String = "untitled"
                var isOn: Bool = true
                var tags: [String] = ["a", "b"]
                var limits: [String: Int] = ["a": 1]
                var empty: [String: Int] = [:]
                var note: String? = nil
            }
            """,
            expandedSource: """
                public struct Settings {
                    var count: Int = 5
                    var offset: Int = -1
                    var ratio: Double = -0.5
                    var title: String = "untitled"
                    var isOn: Bool = true
                    var tags: [String] = ["a", "b"]
                    var limits: [String: Int] = ["a": 1]
                    var empty: [String: Int] = [:]
                    var note: String? = nil

                    #if DEBUG
                    public static func fake(
                        count: Int = 5,
                        offset: Int = -1,
                        ratio: Double = -0.5,
                        title: String = "untitled",
                        isOn: Bool = true,
                        tags: [String] = ["a", "b"],
                        limits: [String: Int] = ["a": 1],
                        empty: [String: Int] = [:],
                        note: String? = nil
                    ) -> Self {
                        Self(
                            count: count,
                            offset: offset,
                            ratio: ratio,
                            title: title,
                            isOn: isOn,
                            tags: tags,
                            limits: limits,
                            empty: empty,
                            note: note
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Public fake() falls back to the type default for a non-literal value")
    func fakableWithPublicNonLiteralInitializers() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            public struct Settings {
                static let first = 1
                var number: Int = Self.first
                var label: String = "page \\(1)"
                var pages: [Int] = [Self.first]
            }
            """,
            expandedSource: """
                public struct Settings {
                    static let first = 1
                    var number: Int = Self.first
                    var label: String = "page \\(1)"
                    var pages: [Int] = [Self.first]

                    #if DEBUG
                    public static func fake(
                        number: Int = 0,
                        label: String = "",
                        pages: [Int] = []
                    ) -> Self {
                        Self(
                            number: number,
                            label: label,
                            pages: pages
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Package fake() uses a non-literal value as written")
    func fakableWithPackageNonLiteralInitializer() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            package struct Settings {
                static let first = 1
                var number: Int = Self.first
            }
            """,
            expandedSource: """
                package struct Settings {
                    static let first = 1
                    var number: Int = Self.first

                    #if DEBUG
                    package static func fake(
                        number: Int = Self.first
                    ) -> Self {
                        Self(
                            number: number
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
