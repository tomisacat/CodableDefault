# Contributing to CodableDefault

Thanks for your interest in contributing. This guide covers local development and pull request expectations.

## Requirements

| Component | Version |
|-----------|---------|
| Swift | 6.2+ |
| Xcode | 26.0+ (recommended) |
| macOS | 10.15+ (required for macro plugin builds) |

## Getting started

```bash
git clone https://github.com/tomisacat/CodableDefault.git
cd CodableDefault
swift build
swift test
```

Run the demo executable:

```bash
swift run CodableDefaultClient
```

## Project layout

| Path | Purpose |
|------|---------|
| `Sources/CodableDefault/` | Public macro declarations |
| `Sources/CodableDefaultMacros/` | Macro implementations (compiler plugin) |
| `Sources/CodableDefaultClient/` | Usage demo (not for app targets) |
| `Tests/CodableDefaultTests/` | Runtime decode/encode tests (Swift Testing) |
| `Tests/CodableDefaultMacroTests/` | Macro expansion tests (Swift Testing) |

## Running tests

```bash
swift test
```

In Xcode, use scheme **CodableDefault-Package** with destination **My Mac**. Testing against the **iOS Simulator** can fail because macro tooling builds for the macOS host.

### Test types

- **Runtime tests** (`CodableDefaultTests`) — verify JSON decoding and encoding behavior through the public API (`@Test`, `#expect`).
- **Macro expansion tests** (`CodableDefaultMacroTests`) — verify generated `CodingKeys` and `init(from:)` source via `assertMacroExpansion`.

Add or update both when changing macro output or decode semantics.

## Pull requests

1. Open an issue or comment on an existing one before large changes.
2. Keep PRs focused on a single concern.
3. Include tests for behavior changes.
4. Update `README.md` and `CHANGELOG.md` when user-facing behavior changes.
5. Ensure CI passes (`swift build` and `swift test` on macOS).

Use the pull request template when opening a PR.

## Reporting bugs

Use the [bug report issue template](https://github.com/tomisacat/CodableDefault/issues/new?template=bug_report.yml). Include a minimal model, JSON payload, and your Swift/Xcode versions.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
