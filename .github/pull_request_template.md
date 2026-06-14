## Summary

<!-- What does this PR change and why? -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactor / maintenance

## Test plan

<!-- How did you verify this? e.g. `swift test`, Xcode scheme, sample decode -->

- [ ] `swift build`
- [ ] `swift test`
- [ ] Tested macro expansion in a client target (if applicable)
- [ ] Cross-platform build (if platform support changed): `xcodebuild build -scheme CodableDefault-Package -destination 'generic/platform=tvOS Simulator' -skipMacroValidation`
- [ ] Demo app builds (if demo or docs changed): `xcodebuild build -project Examples/CodableDefaultDemo/CodableDefaultDemo.xcodeproj -scheme CodableDefaultDemo -destination 'generic/platform=iOS Simulator'`

## Checklist

- [ ] Changes are limited to the scope of this PR
- [ ] README updated (if user-facing behavior changed)
- [ ] Release notes updated in `docs/releases/` (if shipping a release)
- [ ] CI passes locally or is expected to pass on macOS with Swift 6.2+
