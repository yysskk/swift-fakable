/// A stored property of a struct that `fake()` needs a parameter for.
struct StoredProperty: Equatable {
    let name: String

    /// The parameter type, as the property declares it, marked `@escaping`
    /// when it is a function type.
    let type: String

    /// The value the parameter defaults to, or `nil` when the parameter has to
    /// be required because no value can be written for its type.
    let defaultValue: String?
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
    let type: String

    /// The value the parameter defaults to, or `nil` when none can be written
    /// for its type.
    let value: String?
}
