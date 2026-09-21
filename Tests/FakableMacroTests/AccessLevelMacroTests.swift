import FakableMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite("Access Level Macro Tests")
struct AccessLevelMacroTests {
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
