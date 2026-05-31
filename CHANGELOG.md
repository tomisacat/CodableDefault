# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Macro expansion tests (`CodableDefaultMacroTests`) using `assertMacroExpansion`.
- Runtime tests for `null` values, class decoding, encode/decode round-trip, and wrong-type fallback.
- Dependabot configuration for GitHub Actions and Swift dependencies.
- `CONTRIBUTING.md`, `CHANGELOG.md`, and `SECURITY.md`.
- CI matrix across Xcode 26.0 and latest stable, with SwiftPM caching.

### Changed

- Pin `swift-syntax` with `.upToNextMinor(from: "602.0.0")`.
- Document wrong-type fallback behavior in README.

## [1.0.0] - 2026-05-31

### Added

- `@CodableDefault` member macro for `struct` and `class` types.
- `@Default(_:)` peer macro for missing or `null` JSON values.
- `@Default(_:codingKey:)` for custom JSON key names.
- Support for user-defined `CodingKeys` enums.
- `CodableDefaultClient` demo executable.
- XCTest coverage for decoding behavior.
- GitHub Actions CI, issue templates, and pull request template.

[1.0.0]: https://github.com/tomisacat/CodableDefault/releases/tag/1.0.0
