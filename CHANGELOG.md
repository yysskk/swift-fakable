# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `@Fakable` macro that generates a `static func fake(...)` for structs and a
  `static func fake()` for enums, wrapped in `#if DEBUG`.
- Type-driven default values for struct properties and enum associated values:
  `""`, `0`, `0.0`, `false`, `[]`, `[:]`, `nil`, and a `.fake()` fallback that
  lets nested `@Fakable` models compose.
- Access-level-aware generation, so a `public` type gets a `public fake()`.
- Enum case selection that prefers a case without associated values, and falls
  back to the first case with defaulted values when every case has them.

[Unreleased]: https://github.com/yysskk/swift-fakable/commits/main
