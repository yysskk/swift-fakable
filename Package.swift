// swift-tools-version: 6.0

import CompilerPluginSupport
import Foundation
import PackageDescription

/// Upcoming language features every target opts into, so the package is
/// already written the way later language modes require.
let upcomingFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "swift-fakable",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Fakable",
            targets: ["Fakable"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"605.0.0"),
    ],
    targets: [
        .macro(
            name: "FakableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            swiftSettings: upcomingFeatures
        ),
        .target(
            name: "Fakable",
            dependencies: ["FakableMacros"],
            swiftSettings: upcomingFeatures
        ),
        .testTarget(
            name: "FakableTests",
            dependencies: ["Fakable"],
            swiftSettings: upcomingFeatures + [
                // Exercises @Fakable(condition: .custom(...)) end to end; the
                // runtime tests reference a fake that only exists when this
                // flag is defined.
                .define("FAKABLE_RUNTIME_TEST_CONDITION")
            ]
        ),
        .testTarget(
            name: "FakableMacroTests",
            dependencies: [
                "FakableMacros",
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: upcomingFeatures
        ),
    ]
)

// swift-docc-plugin builds the documentation and takes no part in the library,
// but a dependency declared here is one every client resolves as well. It is
// added only where the documentation is actually built: the docs workflow sets
// FAKABLE_BUILD_DOCUMENTATION, and so does anyone generating them by hand.
if ProcessInfo.processInfo.environment["FAKABLE_BUILD_DOCUMENTATION"] != nil {
    package.dependencies.append(
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.4.3")
    )
}
