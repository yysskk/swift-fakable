import SwiftSyntax
import SwiftSyntaxMacros

extension AttributeListSyntax {
    /// The attribute called `name`, or `nil` when there is none.
    ///
    /// Matched by name, bare or qualified with the module, since a macro
    /// cannot resolve which declaration an attribute refers to.
    func attribute(named name: String) -> AttributeSyntax? {
        for element in self {
            if case .attribute(let attribute) = element,
                attribute.attributeName.unqualifiedName == name
            {
                return attribute
            }
        }
        return nil
    }
}

extension TypeSyntax {
    /// The last component of the name, so `Fakable.FakeValue` gives `FakeValue`.
    fileprivate var unqualifiedName: String {
        if let member = self.as(MemberTypeSyntax.self) {
            return member.name.text
        }
        return trimmedDescription
    }
}

extension MacroExpansionContext {
    /// Whether the innermost enclosing type is marked `@Fakable`.
    var isInsideFakableType: Bool {
        guard let type = lexicalContext.first?.asProtocol((any WithAttributesSyntax).self) else {
            return false
        }
        return type.attributes.attribute(named: "Fakable") != nil
    }
}
