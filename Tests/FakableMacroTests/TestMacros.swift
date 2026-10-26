import FakableMacros
import SwiftSyntaxMacros

/// The macros every expansion suite in this target expands.
let testMacros: [String: any Macro.Type] = [
    "Fakable": FakableMacro.self,
    "FakeValue": FakeValueMacro.self,
    "FakeCase": FakeCaseMacro.self,
]
