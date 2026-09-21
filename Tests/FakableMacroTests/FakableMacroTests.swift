import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

private var testMacros: [String: Macro.Type] {
    [
        "Fakable": FakableMacro.self
    ]
}

@Suite("FakableMacro Tests")
struct FakableMacroTests {
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

    @Test("Enum generates fake() returning first case")
    func fakableWithEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Sex {
                case man
                case woman
            }
            """,
            expandedSource: """
                enum Sex {
                    case man
                    case woman

                    #if DEBUG
                    static func fake() -> Self {
                        .man
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

    @Test("Public enum generates public fake()")
    func fakableWithPublicEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            public enum ServerCartItemCategory {
                case sideDishes
                case vegetablesAndFruits
                case dairyFood
                case other
            }
            """,
            expandedSource: """
                public enum ServerCartItemCategory {
                    case sideDishes
                    case vegetablesAndFruits
                    case dairyFood
                    case other

                    #if DEBUG
                    public static func fake() -> Self {
                        .sideDishes
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Public struct generates public fake()")
    func fakableWithPublicStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            public struct User {
                let id: String
                let name: String
            }
            """,
            expandedSource: """
                public struct User {
                    let id: String
                    let name: String

                    #if DEBUG
                    public static func fake(
                        id: String = "",
                        name: String = ""
                    ) -> Self {
                        Self(
                            id: id,
                            name: name
                        )
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Enum with associated values generates fake() returning first case without parameters")
    func fakableWithEnumAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum UserType {
                case guest
                case user(id: String)
                case admin(id: String, level: Int)
            }
            """,
            expandedSource: """
                enum UserType {
                    case guest
                    case user(id: String)
                    case admin(id: String, level: Int)

                    #if DEBUG
                    static func fake() -> Self {
                        .guest
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Enum with associated values first skips to parameter-less case")
    func fakableWithEnumAssociatedValuesFirst() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum UserRole {
                case user(id: String)
                case guest
                case admin(id: String, level: Int)
            }
            """,
            expandedSource: """
                enum UserRole {
                    case user(id: String)
                    case guest
                    case admin(id: String, level: Int)

                    #if DEBUG
                    static func fake() -> Self {
                        .guest
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Enum with only associated values generates fake() with default parameters")
    func fakableWithOnlyAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum ComplexEnum {
                case user(id: String)
                case admin(id: String, level: Int)
            }
            """,
            expandedSource: """
                enum ComplexEnum {
                    case user(id: String)
                    case admin(id: String, level: Int)

                    #if DEBUG
                    static func fake() -> Self {
                        .user(id: "")
                    }
                    #endif
                }
                """,
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

    @Test("Enum with single case generates fake()")
    func fakableWithSingleCase() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum SingleCase {
                case only
            }
            """,
            expandedSource: """
                enum SingleCase {
                    case only

                    #if DEBUG
                    static func fake() -> Self {
                        .only
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Enum with only associated values (multiple parameters) generates fake() with defaults")
    func fakableWithMultipleAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Result {
                case success(value: Int, message: String)
                case failure(error: String, code: Int)
            }
            """,
            expandedSource: """
                enum Result {
                    case success(value: Int, message: String)
                    case failure(error: String, code: Int)

                    #if DEBUG
                    static func fake() -> Self {
                        .success(value: 0, message: "")
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

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
    @Test("Package struct generates package fake()")
    func fakableWithPackageStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            package struct Item {
                let name: String
            }
            """,
            expandedSource: """
                package struct Item {
                    let name: String

                    #if DEBUG
                    package static func fake(
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

    @Test("Fileprivate struct generates fileprivate fake()")
    func fakableWithFileprivateStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            fileprivate struct Item {
                let name: String
            }
            """,
            expandedSource: """
                fileprivate struct Item {
                    let name: String

                    #if DEBUG
                    fileprivate static func fake(
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

    @Test("Private struct generates private fake()")
    func fakableWithPrivateStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            private struct Item {
                let name: String
            }
            """,
            expandedSource: """
                private struct Item {
                    let name: String

                    #if DEBUG
                    private static func fake(
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

    @Test("Explicit internal struct generates unqualified fake()")
    func fakableWithExplicitInternalStruct() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            internal struct Item {
                let name: String
            }
            """,
            expandedSource: """
                internal struct Item {
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
    @Test("Package enum generates package fake()")
    func fakableWithPackageEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            package enum Status {
                case active
                case inactive
            }
            """,
            expandedSource: """
                package enum Status {
                    case active
                    case inactive

                    #if DEBUG
                    package static func fake() -> Self {
                        .active
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Fileprivate enum generates fileprivate fake()")
    func fakableWithFileprivateEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            fileprivate enum Status {
                case active
                case inactive
            }
            """,
            expandedSource: """
                fileprivate enum Status {
                    case active
                    case inactive

                    #if DEBUG
                    fileprivate static func fake() -> Self {
                        .active
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Private enum generates private fake()")
    func fakableWithPrivateEnum() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            private enum Status {
                case active
                case inactive
            }
            """,
            expandedSource: """
                private enum Status {
                    case active
                    case inactive

                    #if DEBUG
                    private static func fake() -> Self {
                        .active
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
