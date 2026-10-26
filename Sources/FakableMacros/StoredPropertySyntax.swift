import SwiftSyntax

extension VariableDeclSyntax {
    /// Whether this is a type-level property, which the memberwise initializer
    /// does not take.
    var isStatic: Bool {
        modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.static) || modifier.name.tokenKind == .keyword(.class)
        }
    }

    /// Whether this declares constants (`let`) rather than variables (`var`).
    var isConstant: Bool {
        bindingSpecifier.tokenKind == .keyword(.let)
    }

    /// Each binding paired with the type it resolves to.
    ///
    /// One declaration can introduce several properties, and in `let a, b: Int`
    /// only the last binding carries the annotation while the earlier ones share
    /// it. Resolving from the back gives every binding its type.
    var bindingsWithResolvedTypes: [(binding: PatternBindingSyntax, type: TypeSyntax?)] {
        var resolved: [(binding: PatternBindingSyntax, type: TypeSyntax?)] = []
        var sharedType: TypeSyntax?

        for binding in bindings.reversed() {
            if let annotatedType = binding.typeAnnotation?.type {
                sharedType = annotatedType
            }
            resolved.append((binding: binding, type: sharedType))
        }

        return resolved.reversed()
    }
}

extension PatternBindingSyntax {
    /// Whether the property is stored, and so part of the memberwise initializer.
    ///
    /// A `willSet` or `didSet` observer leaves a property stored; a getter, in
    /// any of its spellings, makes it computed.
    var isStored: Bool {
        guard let accessorBlock else {
            return true
        }

        switch accessorBlock.accessors {
        case .getter:
            return false
        case .accessors(let accessors):
            return accessors.allSatisfy { accessor in
                let specifier = accessor.accessorSpecifier.tokenKind
                return specifier == .keyword(.willSet) || specifier == .keyword(.didSet)
            }
        }
    }
}

extension ExprSyntax {
    /// Whether the expression is a literal, built only from other literals.
    ///
    /// A literal references no declaration, so it is valid as a default
    /// argument at any access level. Covers numbers (with a leading `-`),
    /// strings without interpolation, `true` / `false`, `nil`, and array and
    /// dictionary literals of those.
    var isLiteral: Bool {
        if self.is(IntegerLiteralExprSyntax.self)
            || self.is(FloatLiteralExprSyntax.self)
            || self.is(BooleanLiteralExprSyntax.self)
            || self.is(NilLiteralExprSyntax.self)
        {
            return true
        }

        if let string = self.as(StringLiteralExprSyntax.self) {
            return string.segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
        }

        if let prefix = self.as(PrefixOperatorExprSyntax.self) {
            return prefix.operator.text == "-"
                && (prefix.expression.is(IntegerLiteralExprSyntax.self)
                    || prefix.expression.is(FloatLiteralExprSyntax.self))
        }

        if let array = self.as(ArrayExprSyntax.self) {
            return array.elements.allSatisfy(\.expression.isLiteral)
        }

        if let dictionary = self.as(DictionaryExprSyntax.self) {
            switch dictionary.content {
            case .colon:
                return true
            case .elements(let elements):
                return elements.allSatisfy { $0.key.isLiteral && $0.value.isLiteral }
            }
        }

        return false
    }
}
