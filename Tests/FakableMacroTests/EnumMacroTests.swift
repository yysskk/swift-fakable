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
            enum Status {
                case active
                case inactive
            }
            """,
            expandedSource: """
                enum Status {
                    case active
                    case inactive

                    #if DEBUG
                    static func fake() -> Self {
                        .active
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
                    static func fake(
                        id: String = ""
                    ) -> Self {
                        .user(id: id)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("Unlabeled associated values become positional parameters")
    func fakableWithUnlabeledAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Measurement {
                case point(Int, String)
                case distance(Double)
            }
            """,
            expandedSource: """
                enum Measurement {
                    case point(Int, String)
                    case distance(Double)

                    #if DEBUG
                    static func fake(
                        _ value0: Int = 0,
                        _ value1: String = ""
                    ) -> Self {
                        .point(value0, value1)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("A case can label some of its values and not others")
    func fakableWithPartlyLabeledAssociatedValues() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Reading {
                case sample(Int, unit: String)
            }
            """,
            expandedSource: """
                enum Reading {
                    case sample(Int, unit: String)

                    #if DEBUG
                    static func fake(
                        _ value0: Int = 0,
                        unit: String = ""
                    ) -> Self {
                        .sample(value0, unit: unit)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("A value named after a _ takes that name, with no label")
    func fakableWithNamedUnlabeledAssociatedValue() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Event {
                case tapped(_ title: String, at: Int)
            }
            """,
            expandedSource: """
                enum Event {
                    case tapped(_ title: String, at: Int)

                    #if DEBUG
                    static func fake(
                        _ title: String = "",
                        at: Int = 0
                    ) -> Self {
                        .tapped(title, at: at)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("A label that is a keyword keeps its backticks")
    func fakableWithKeywordAssociatedValueLabel() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Command {
                case run(`default`: Int)
            }
            """,
            expandedSource: """
                enum Command {
                    case run(`default`: Int)

                    #if DEBUG
                    static func fake(
                        `default`: Int = 0
                    ) -> Self {
                        .run(`default`: `default`)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }

    @Test("A label that collides with a positional name keeps both parameters")
    func fakableWithCollidingAssociatedValueLabel() {
        assertMacroExpansionForTesting(
            """
            @Fakable
            enum Sample {
                case taken(value1: Int, String)
            }
            """,
            expandedSource: """
                enum Sample {
                    case taken(value1: Int, String)

                    #if DEBUG
                    static func fake(
                        value1: Int = 0,
                        _ value1_: String = ""
                    ) -> Self {
                        .taken(value1: value1, value1_)
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
                    static func fake(
                        value: Int = 0,
                        message: String = ""
                    ) -> Self {
                        .success(value: value, message: message)
                    }
                    #endif
                }
                """,
            macros: testMacros
        )
    }
}
