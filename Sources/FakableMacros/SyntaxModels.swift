/// A stored property of a struct that `fake()` needs a parameter for.
struct StoredProperty {
    let name: String
    let type: String
    let isOptional: Bool
}

/// The enum case that `fake()` returns, and the associated values it needs.
struct EnumCaseInfo {
    let name: String
    let parameters: [EnumCaseParameter]
}

/// A single associated value of an enum case.
struct EnumCaseParameter {
    let label: String?
    let type: String
    let isOptional: Bool
}
