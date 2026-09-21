# Contributing

Thanks for your interest in improving swift-fakable! This guide covers the
project layout, how to build and test, and the conventions we follow.

## Project layout

- `Sources/Fakable/` — the runtime module clients depend on. It declares the
  `@Fakable` macro and nothing else; there is no runtime code.
- `Sources/FakableMacros/` — the macro implementation (built on
  [swift-syntax](https://github.com/swiftlang/swift-syntax)). `FakableMacro` is
  the entry point, `FakeGenerator` reads the declaration and renders the method
  source, and `DefaultValue` decides the default for each parameter type.
- `Tests/FakableMacroTests/` — macro-expansion tests that pin the exact
  generated source.
- `Tests/FakableTests/` — runtime tests that exercise the behavior of the
  generated `fake()` methods.

## Building and testing

```sh
swift build
swift test
```

Tests use [swift-testing](https://github.com/swiftlang/swift-testing) (`@Test` /
`#expect`), which ships with every supported toolchain.

### Code coverage

```sh
scripts/export-coverage.sh
```

The script runs the test suite with coverage enabled, prints a per-file summary,
and writes `coverage.lcov` to the repository root. Coverage is measured over
`Sources/` only — test code and dependency sources are excluded — and the paths
in the report are relative to the repository root. It works with both the macOS
and Linux toolchains, so it produces the same report locally as it does in CI.

CI runs the same script and uploads the macOS report to
[Codecov](https://codecov.io/gh/yysskk/swift-fakable), which comments on pull
requests with the resulting change. `codecov.yml` holds the thresholds: the
project total may drift by 1%, while new and changed lines are expected to reach
80%. Pull requests from forks skip the upload, because they cannot read the
repository's Codecov token; run the script locally to check coverage on those.

### Swift version compatibility

The package supports Swift 6.0+ through a single `Package.swift` at
swift-tools-version 6.0, and accepts swift-syntax `600.0.0..<605.0.0` so
dependency resolution can agree with whatever swift-syntax major the other
packages in a consuming project pin.

The tools version is a **hard floor for consumers**: raising it to 6.4 would
stop everyone on Swift 6.0–6.3 from resolving the package at all. Leave it at
6.0 unless the manifest actually needs a newer feature, and if it ever does, add
a `Package@swift-6.0.swift` fallback rather than dropping those toolchains.

CI builds the package against the latest patch of every swift-syntax major in
the range plus the floor on the oldest supported toolchain, while tests always
run against the version resolution picks. When a new swift-syntax major is
released, bump the upper bound and add the new major to the
`swift-syntax-compat` CI matrix.

## Writing tests

Most changes should include both:

- A **macro-expansion test** in `Tests/FakableMacroTests/`, using the
  `assertMacroExpansionForTesting(_:expandedSource:diagnostics:macros:)` helper.
  It wraps swift-syntax's `assertMacroExpansion` and reports mismatches through
  swift-testing. Paste the input declaration and the exact expected expansion; if
  the whitespace is hard to predict, run the test once and copy the "Actual
  expanded source" from the failure.
- A **runtime test** in `Tests/FakableTests/`, adding the model to the test
  fixtures at the top of `FakableTests.swift` and asserting that the generated
  `fake()` behaves as expected.

Diagnostics are tested by passing a `diagnostics:` array to
`assertMacroExpansionForTesting`.

## Keeping documentation in sync

When a change affects generated output or user-facing behavior, update all of
these together so they don't drift:

- `README.md`
- `docs/advanced-usage.md`
- `llms.txt` and `llms-full.txt`
- the DocC catalog under `Sources/Fakable/Fakable.docc/`

## Commit and PR conventions

- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit
  and PR titles (`feat:`, `fix:`, `refactor:`, `chore:`, `ci:`, `docs:`).
- Keep pull requests focused and reviewable.
- Fill in the pull request template, including the testing and docs checklist.
