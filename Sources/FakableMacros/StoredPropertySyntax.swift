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
