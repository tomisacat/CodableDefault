# Contributing to CodableDefault

Thanks for your interest in contributing. This guide covers local development and pull request expectations.

## Requirements

| Component | Version |
|-----------|---------|
| Swift | 6.2+ |
| Xcode | 26.0+ (recommended) |
| iOS | 13+ |
| macOS | 10.15+ (required for macro plugin builds) |
| watchOS | 6+ |
| tvOS | 13+ |
| visionOS | 1+ |

Dependencies are pinned via [Package.resolved](Package.resolved) (`swift-syntax` 603.x, up to next minor).

## Getting started

```bash
git clone https://github.com/tomisacat/CodableDefault.git
cd CodableDefault
swift build
swift test
```

Run the command-line demo executable:

```bash
swift run CodableDefaultClient
```

Run the SwiftUI demo app:

```bash
cd Examples/CodableDefaultDemo
open CodableDefaultDemo.xcodeproj
```

## Project layout

| Path | Purpose |
|------|---------|
| `Sources/CodableDefault/` | Public macro declarations |
| `Sources/CodableDefaultMacros/` | Macro implementations (compiler plugin) |
| `Sources/CodableDefaultClient/` | Command-line usage demo (not for app targets) |
| `Examples/CodableDefaultDemo/` | SwiftUI iOS demo app (local package dependency) |
| `Tests/CodableDefaultTests/` | Runtime decode/encode tests (Swift Testing) |
| `Tests/CodableDefaultMacroTests/` | Macro expansion tests (Swift Testing) |
| `docs/releases/` | Version release notes |

## Running tests

```bash
swift test
```

In Xcode, use scheme **CodableDefault-Package** with destination **My Mac**. Testing against the **iOS Simulator** can fail because macro tooling builds for the macOS host.

To verify cross-platform builds locally:

```bash
xcodebuild build \
  -scheme CodableDefault-Package \
  -destination 'generic/platform=tvOS Simulator' \
  -skipMacroValidation
```

Replace the destination with `iOS Simulator`, `watchOS Simulator`, or `visionOS Simulator` as needed.

### Test types

- **Runtime tests** (`CodableDefaultTests`) — verify JSON decoding and encoding behavior through the public API (`@Test`, `#expect`).
- **Macro expansion tests** (`CodableDefaultMacroTests`) — verify generated `CodingKeys` and `init(from:)` source via `assertMacroExpansion`.

Add or update both when changing macro output or decode semantics.

## Pull requests

1. Open an issue or comment on an existing one before large changes.
2. Keep PRs focused on a single concern.
3. Include tests for behavior changes.
4. Update `README.md` and `docs/releases/` when user-facing behavior changes.
5. Ensure CI passes (`swift build`, `swift test`, platform matrix, and demo app build on macOS).

Use the pull request template when opening a PR.

## Reporting bugs

Use the [bug report issue template](https://github.com/tomisacat/CodableDefault/issues/new?template=bug_report.yml). Include a minimal model, JSON payload, and your Swift/Xcode/platform versions.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
