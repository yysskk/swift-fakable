import FakableMacros
import SwiftSyntaxMacros

/// The macros every expansion suite in this target expands.
let testMacros: [String: Macro.Type] = [
    "Fakable": FakableMacro.self
]
