import SwiftSyntax

/// A stored property of a struct that `fake()` needs a parameter for.
struct StoredProperty {
    let name: String

    /// The parameter type, as the property declares it.
    let type: TypeSyntax

    /// Whether the parameter needs `@escaping`.
    ///
    /// A parameter of function type does not escape unless it says so, and
    /// `fake()` stores every parameter it takes. Kept apart from ``type``, so
    /// the model says what is true of the property and the rendering decides
    /// how to write it.
    let isEscaping: Bool

    /// The value the parameter defaults to, or `nil` when the parameter has to
    /// be required because no value can be written for its type.
    let defaultValue: ExprSyntax?
}

extension StoredProperty: Equatable {
    /// Compared by what the parameter is written as.
    ///
    /// Two `#if` clauses that end up with the same properties collapse into one
    /// method, and "the same" there is a question about the source they render
    /// to. A syntax node compares by identity, so the same type written in two
    /// clauses would otherwise count as two different ones.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
            && lhs.isEscaping == rhs.isEscaping
            && lhs.type.trimmedDescription == rhs.type.trimmedDescription
            && lhs.defaultValue?.trimmedDescription == rhs.defaultValue?.trimmedDescription
    }
}

/// The stored properties of a struct, across the build configurations its
/// `#if` blocks select between.
indirect enum StoredPropertyLayout: Equatable {
    /// The same properties in every configuration this layout covers.
    case unconditional([StoredProperty])

    /// A `#if` block whose clauses select different properties.
    case conditional([Clause])

    /// One clause of a `#if` block.
    struct Clause: Equatable {
        /// `#if`, `#elseif`, or `#else`.
        let keyword: String

        /// The condition written after the keyword, or `nil` for `#else`.
        let condition: String?

        /// The properties of the configurations this clause selects.
        let layout: StoredPropertyLayout
    }

    /// The properties of every configuration, one list each.
    var configurations: [[StoredProperty]] {
        switch self {
        case .unconditional(let properties):
            [properties]
        case .conditional(let clauses):
            clauses.flatMap(\.layout.configurations)
        }
    }
}

/// The enum case that `fake()` returns, and the associated values it needs.
struct EnumCase {
    let name: String
    let associatedValues: [AssociatedValue]

    /// Whether every associated value has a value the macro can write.
    ///
    /// Only such a case can be what `fake()` returns: `fake()` has to be
    /// callable with no arguments, since `.fake()` is how a nested model
    /// reaches it. A case carrying a generic parameter or a closure is not one,
    /// and is reported rather than generated.
    var isWritable: Bool {
        associatedValues.allSatisfy { $0.value != nil }
    }
}

/// A case marked `@FakeCase`, with the attribute that marks it.
///
/// The attribute is kept so a diagnostic about the choice is reported where the
/// choice was made, rather than on `@Fakable`.
struct MarkedCase {
    let fakeCase: EnumCase
    let attribute: AttributeSyntax
}

/// A single associated value of an enum case.
struct AssociatedValue {
    /// The label the case declares for it, or `nil` when it declares none.
    ///
    /// It is the argument label of the parameter `fake()` takes for the value,
    /// so a value without one is passed positionally.
    let label: String?

    /// The name the case gives the value after a `_`, as in
    /// `case tapped(_ title: String)`, or `nil` when it gives none.
    ///
    /// The value is unlabeled either way. This only names the parameter inside
    /// `fake()`, in place of one made up from its position.
    let declaredName: String?

    /// The parameter type, as the case declares it.
    let type: TypeSyntax

    /// The value the parameter defaults to, or `nil` when none can be written
    /// for its type.
    let value: ExprSyntax?
}
