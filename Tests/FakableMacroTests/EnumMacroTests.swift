import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Enum Macro Tests")
struct EnumMacroTests {
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
}
