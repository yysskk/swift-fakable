import SwiftSyntax

/// The modules whose types the default table knows by name.
///
/// A qualified spelling such as `Swift.String` or `Foundation.Date` names the
/// same type as the bare one, so it takes the same default. A type nested in
/// one of your own, such as `Models.Date`, keeps its base and does not.
private let qualifyingModuleNames: Set<String> = ["CoreGraphics", "Foundation", "Swift"]

/// The collections an empty array literal builds that are written as a name,
/// rather than with the `[T]` sugar.
private let arrayLiteralTypeNames: Set<String> = [
    "Array", "ArraySlice", "ContiguousArray", "Set",
]

extension TypeSyntax {
    /// The value `fake()` uses for a parameter of this type, or `nil` when none
    /// can be written for it.
    ///
    /// The same rules apply to a struct's stored properties and to an enum
    /// case's associated values, so both paths go through here. The table
    /// covers the stdlib types that have an obvious empty value, the Foundation
    /// and CoreGraphics value types that stand in for one, and the collections.
    /// Every value is deterministic, so two fakes of the same type compare
    /// equal.
    ///
    /// Matching is on the type as it was written, since the macro reads syntax
    /// and never resolves types. Sugar and longhand are read from the syntax
    /// tree rather than from the text, so `Optional<String>` is the same type
    /// to the table as `String?`, `Array<String>` as `[String]`, and
    /// `Dictionary<String, Int>` as `[String: Int]`.
    ///
    /// - Parameter genericParameterNames: The names the enclosing declaration
    ///   introduces. A type built from one of these has no value the macro
    ///   could write, so it resolves to `nil` rather than to `.fake()`.
    func fakeDefaultValue(genericParameterNames: Set<String>) -> String? {
        // Ahead of the type name, so an optional of any type is nil.
        if isOptional {
            return "nil"
        }

        switch unqualifiedSpelling {
        case "String", "Substring":
            return "\"\""
        case "Character":
            // A Character holds exactly one, so a space stands in for the empty
            // string the other text types get.
            return "\" \""
        case "Int", "Int8", "Int16", "Int32", "Int64", "Int128",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "UInt128":
            return "0"
        case "Double", "Float", "Float16", "CGFloat", "TimeInterval":
            return "0.0"
        case "Bool":
            return "false"
        case "Decimal":
            // Decimal is ExpressibleByIntegerLiteral, so the literal is enough.
            return "0"
        case "Date":
            // The epoch rather than Date(), so the value does not depend on when
            // the fixture is built.
            return "Date(timeIntervalSince1970: 0)"
        case "UUID":
            // The nil UUID, so the value does not change between two fakes.
            return "UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))"
        case "URL":
            // The only non-failable initializer that needs no import beyond the
            // one the property's own type already requires.
            return "URL(fileURLWithPath: \"/\")"
        case "Data":
            return "Data()"
        case "Duration":
            return ".zero"
        case "CGPoint", "CGSize", "CGRect", "CGVector":
            // The zero value, written as the no-argument initializer rather
            // than `.zero`: the geometry types are named by Foundation, while
            // `.zero` is declared in CoreGraphics, which the property's own
            // type does not require.
            return "\(unqualifiedSpelling)()"
        default:
            // Ahead of the generic check, so a collection is empty for the same
            // reason whatever it holds: the element type is never written out.
            if isDictionary {
                return "[:]"
            }
            if isArrayLiteralCollection {
                return "[]"
            }
            if references(anyOf: genericParameterNames) {
                return nil
            }
            // Only a type written as a name can have a `fake()` of its own. A
            // closure, tuple, existential or metatype has no member to call,
            // so it becomes a required parameter instead.
            return isNominal ? ".fake()" : nil
        }
    }
}

extension TypeSyntax {
    /// Whether the type is an optional, however it is written.
    ///
    /// Covers the `String?` and `String!` sugar as well as the longhand
    /// `Optional<String>`.
    var isOptional: Bool {
        self.is(OptionalTypeSyntax.self)
            || self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
            || nominalName == "Optional"
    }

    /// Whether an empty array literal builds a value of the type, however it is
    /// written.
    ///
    /// Covers the `[String]` sugar as well as the longhand `Array<String>`, and
    /// the collections that have no sugar of their own: `Set<String>`,
    /// `ArraySlice<String>`, and `ContiguousArray<String>`. Every one of them is
    /// `ExpressibleByArrayLiteral`, so `[]` is its empty value whatever it
    /// holds.
    var isArrayLiteralCollection: Bool {
        guard !self.is(ArrayTypeSyntax.self) else {
            return true
        }
        guard let nominalName else {
            return false
        }
        return arrayLiteralTypeNames.contains(nominalName)
    }

    /// Whether the type is a dictionary, however it is written.
    ///
    /// Covers the `[String: Int]` sugar as well as the longhand
    /// `Dictionary<String, Int>`. A nested spelling such as `[String: [Int]]`
    /// is a dictionary and not an array, because the node says which it is.
    var isDictionary: Bool {
        self.is(DictionaryTypeSyntax.self) || nominalName == "Dictionary"
    }

    /// Whether the type is written as a name, such as `Item` or
    /// `Models.Item`, and so could declare a `fake()` of its own.
    ///
    /// A function type, a tuple, `any P`, `P & Q`, a metatype, and an
    /// `InlineArray` written as `[3 of Int]` are not.
    var isNominal: Bool {
        self.is(IdentifierTypeSyntax.self) || self.is(MemberTypeSyntax.self)
    }

    /// Whether the type is a function type, looking through attributes such
    /// as `@Sendable` and through parentheses.
    ///
    /// A parameter of function type does not escape unless it is marked
    /// `@escaping`, and `fake()` stores every parameter it takes, so such a
    /// parameter needs the attribute. An optional function type is already
    /// escaping and does not count.
    var isFunction: Bool {
        if self.is(FunctionTypeSyntax.self) {
            return true
        }
        if let attributed = self.as(AttributedTypeSyntax.self) {
            return attributed.baseType.isFunction
        }
        if let tuple = self.as(TupleTypeSyntax.self), tuple.elements.count == 1,
            let element = tuple.elements.first, element.firstName == nil
        {
            return element.type.isFunction
        }
        return false
    }

    /// The type's spelling with any module qualification dropped.
    ///
    /// `Swift.String` gives `String`, so a qualified spelling takes the same
    /// default as the bare one. Generic arguments are kept, so a type of your
    /// own named `Date<Wrapped>` is not mistaken for `Foundation.Date`.
    var unqualifiedSpelling: String {
        unqualified.trimmedDescription
    }

    /// Whether the type is written in terms of any of `names`.
    ///
    /// Compared token by token, so a type called `Total` does not count as a
    /// reference to a generic parameter named `T`.
    func references(anyOf names: Set<String>) -> Bool {
        guard !names.isEmpty else {
            return false
        }

        return tokens(viewMode: .sourceAccurate).contains { token in
            if case .identifier(let text) = token.tokenKind {
                return names.contains(text)
            }
            return false
        }
    }

    /// The name the nominal type is written with, module qualification dropped,
    /// or `nil` for a type that is not written as a name.
    ///
    /// Read from the syntax node rather than from the spelling, so a type whose
    /// name merely starts with `Set` does not count as one. The sugar `[Int]`
    /// names nothing and gives `nil`, which is why each collection test takes
    /// the sugared node into account as well.
    private var nominalName: String? {
        unqualified.as(IdentifierTypeSyntax.self)?.name.text
    }

    /// The type with a qualifying module name dropped from the front.
    ///
    /// Only the modules the default table draws from are dropped. `Outer.Inner`
    /// keeps its base, since `Inner` on its own could name anything.
    private var unqualified: TypeSyntax {
        guard let member = self.as(MemberTypeSyntax.self),
            let moduleName = member.baseType.as(IdentifierTypeSyntax.self)?.name.text,
            qualifyingModuleNames.contains(moduleName)
        else {
            return self
        }

        return TypeSyntax(
            IdentifierTypeSyntax(
                name: member.name,
                genericArgumentClause: member.genericArgumentClause
            )
        )
    }
}

extension GenericParameterClauseSyntax? {
    /// The names the clause introduces, or an empty set when there is no clause.
    var parameterNames: Set<String> {
        guard let self else {
            return []
        }
        return Set(self.parameters.map(\.name.text))
    }
}
