import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler-plugin entry point that registers the macros provided by this module.
@main
struct FakablePlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        FakableMacro.self,
        FakeValueMacro.self,
        FakeCaseMacro.self,
    ]
}
