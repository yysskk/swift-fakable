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
struct EnumCaseInfo {
    let name: String
    let parameters: [EnumCaseParameter]
}

/// A single associated value of an enum case.
struct EnumCaseParameter {
    let label: String?

    /// The value `fake()` passes, or `nil` when none can be written for its type.
    let value: String?
}
