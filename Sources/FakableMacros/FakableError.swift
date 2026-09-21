/// Diagnostics emitted by ``FakableMacro``.
enum FakableError: Error, CustomStringConvertible {
    case onlyApplicableToStructOrEnum

    var description: String {
        switch self {
        case .onlyApplicableToStructOrEnum:
            return "@Fakable can only be applied to a struct or enum"
        }
    }
}
