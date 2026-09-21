import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler-plugin entry point that registers the macros provided by this module.
@main
struct FakablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FakableMacro.self
    ]
}
