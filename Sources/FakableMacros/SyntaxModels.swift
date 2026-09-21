/// A stored property of a struct that `fake()` needs a parameter for.
struct StoredProperty {
    let name: String
    let type: String

    /// The value the parameter defaults to, or `nil` when the parameter has to
    /// be required because no value can be written for its type.
    let defaultValue: String?
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
