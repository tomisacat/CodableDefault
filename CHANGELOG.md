# Changelog

> All notable changes to this project are documented in this file.
>
> The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
> and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



## [1.1.0] - 2026-06-11

### Added

- `@Default(_:transform:)` and `@Default(_:codingKey:transform:)` for optional post-decode `(T) throws -> T` transforms.
- Macro expansion and runtime tests for transform behavior.
- README documentation and demo client scenario for `transform:`.

### Changed

- Migrated `CodableDefaultTests` and `CodableDefaultMacroTests` from XCTest to Swift Testing.

[1.1.0]: https://github.com/tomisacat/CodableDefault/releases/tag/1.1.0

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
