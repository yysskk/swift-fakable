import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The implementation of the `@Fakable` macro.
///
/// It adds a `static func fake(...)` member, wrapped in `#if DEBUG`, to the
/// struct or enum it is attached to.
public struct FakableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract access level (public, internal, etc.)
        let accessLevel = extractAccessLevel(from: declaration)

        // Handle struct declarations
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let storedProperties = FakeGenerator.storedProperties(of: structDecl)

            guard !storedProperties.isEmpty else {
                return []
            }

            let fakeMethod = FakeGenerator.fakeMethod(for: storedProperties, accessLevel: accessLevel)
            return [DeclSyntax(stringLiteral: fakeMethod)]
        }

        // Handle enum declarations
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let firstCase = FakeGenerator.firstCase(of: enumDecl)

            guard let firstCase else {
                return []
            }

            let fakeMethod = FakeGenerator.enumFakeMethod(firstCase: firstCase, accessLevel: accessLevel)
            return [DeclSyntax(stringLiteral: fakeMethod)]
        }

        throw FakableError.onlyApplicableToStructOrEnum
    }
}
