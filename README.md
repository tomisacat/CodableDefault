# CodableDefault

Swift macros that make `Codable` decoding tolerant of missing or `null` JSON fields by applying compile-time default values, while leaving required properties strict. Use `@Default(_:transform:)` to clamp, normalize, or validate resolved values after decode. Custom JSON key names are supported via `@Default(_:codingKey:)` or a hand-written `CodingKeys` enum.

## Motivation

API responses often omit keys or send `null` for optional configuration fields. With plain `Codable`, you typically need manual `init(from:)`, property wrappers, or post-decode merging. **CodableDefault** keeps models declarative: mark fields with `@Default`, attach `@CodableDefault` to the type, and the macro generates decoding logic for you — including optional post-decode transforms when you need to shape or validate the final value.

## Requirements

| Component | Version |
|-----------|---------|
| Swift | 6.2+ |
| Xcode | 16+ (recommended) |
| iOS | 13+ |
| macOS | 10.15+ (required to build and run macro tooling) |

Dependencies are pinned via [Package.resolved](Package.resolved) (`swift-syntax` 602.x, up to next minor).

## Installation

### Swift Package Manager (`Package.swift`)

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tomisacat/CodableDefault.git", from: "1.0.0"),
],
targets: [
    .target(
        name: "<YourTarget>",
        dependencies: [
            .product(name: "CodableDefault", package: "CodableDefault"),
        ]
    ),
]
```

### Xcode

1. Open your app or workspace in Xcode.
2. Choose **File → Add Package Dependencies…**
3. Paste the repository URL:
   ```
   https://github.com/tomisacat/CodableDefault.git
   ```
4. Set the dependency rule (for example **Up to Next Major** from `1.0.0`), then click **Add Package**.
5. When prompted, add the **CodableDefault** library product to the target that contains your `Codable` models (your app target or a framework target).
6. In Swift files that use the macros, add:

   ```swift
   import CodableDefault
   ```

### Local package (Xcode)

1. **File → Add Package Dependencies… → Add Local…**
2. Select the **folder that contains `Package.swift`** (the repo root), not `Sources/`.
3. Add the **CodableDefault** library product to your app or framework target — not `CodableDefaultClient`.
4. Build once (**⌘B**). The module appears in the index only after a successful build.
5. `import CodableDefault` in files that use `@CodableDefault` / `@Default`.

Equivalent `Package.swift` dependency:

```swift
dependencies: [
    .package(path: "../CodableDefault"),  // path to this repo
],
targets: [
    .target(
        name: "<YourTarget>",
        dependencies: [
            .product(name: "CodableDefault", package: "CodableDefault"),
        ]
    ),
]
```

## Troubleshooting

### `No such module 'CodableDefault'`

This usually means Xcode has not built or linked the library yet — not that the import name is wrong.

1. **Link the product** — In your app target → **General** → **Frameworks, Libraries, and Embedded Content**, confirm **CodableDefault** is listed. If you only added the package to the project without assigning it to a target, the module will not be available.
2. **Pick the library product** — Add **CodableDefault**, not `CodableDefaultMacros` or `CodableDefaultClient`.
3. **Build first** — Run **Product → Clean Build Folder**, then **⌘B**. Macro packages must compile the plugin on the Mac host before client code indexes correctly.
4. **Resolve packages** — **File → Packages → Reset Package Caches**, then **Resolve Package Versions**.
5. **Local path** — The dependency must point at the directory containing `Package.swift`.
6. **Toolchain** — CodableDefault requires **Swift 6.2+** (Xcode 16.3+ or a Swift 6.2 toolchain). Older Xcode versions cannot build the package.
7. **Check the Report navigator** — If the package failed to build (e.g. macro / `swift-syntax` errors), Xcode often still shows `No such module` instead of the real error.

## Quick start

```swift
import CodableDefault

@CodableDefault
struct Settings: Codable {
    var name: String

    @Default(false)
    var isEnabled: Bool

    @Default("guest", codingKey: "user_name")
    var username: String

    @Default(10, codingKey: "retry", transform: { min($0, 100) })
    var retryCount: Int
}

let json = #"{"name":"App","retry":150}"#.data(using: .utf8)!
let settings = try JSONDecoder().decode(Settings.self, from: json)
// settings.name == "App"
// settings.isEnabled == false      (default — key omitted)
// settings.username == "guest"     (default — key omitted)
// settings.retryCount == 100       (transform clamped 150 → 100)
```

## Macros

### `@CodableDefault`

**Role:** Attached to a `struct` or `class` that conforms to `Codable` (or `Decodable`).

**Generates:**

- `enum CodingKeys` — unless you already define one (see [Custom `CodingKeys`](#custom-codingkeys))
- `init(from decoder: Decoder) throws` — `required` for classes

**Usage:**

```swift
@CodableDefault
struct Model: Codable { ... }
```

### `@Default(_:)`

**Role:** Peer macro on a stored property. Marks a default value used when the key is **missing** or the value decodes as **`null`** (via `decodeIfPresent`).

```swift
@Default(false)
var isEnabled: Bool

@Default(10)
var retryCount: Int

@Default("guest")
var username: String
```

The default expression is copied into generated code as-is (literals, `.empty`, `[]`, etc.).

### `@Default(_:codingKey:)`

**Role:** Same as `@Default`, plus a custom JSON key (string raw value for `CodingKeys`).

```swift
@Default(false, codingKey: "is_enabled")
var isEnabled: Bool

@Default("guest", codingKey: "user_name")
var username: String
```

### `@Default(_:transform:)` and `@Default(_:codingKey:transform:)`

**Role:** Same as `@Default`, plus an optional post-decode `(T) throws -> T` transform applied to the resolved value — whether that value came from JSON or from the default fallback.

```swift
@Default(10, transform: { min($0, 100) })
var retryCount: Int

@Default("guest", transform: { $0.trimmingCharacters(in: .whitespaces) })
var username: String

@Default(0, codingKey: "limit", transform: { min($0, 100) })
var limit: Int
```

Throwing transforms propagate out of `init(from:)`. Use this for validation, clamping, or normalization after the default-or-decode step.

Defaulted properties with a transform expand to:

```swift
self.retryCount = try {
    let __codableDefault_retryCount =
        (try? container.decodeIfPresent(Int.self, forKey: .retryCount))
        ?? 10
    return try { min($0, 100) }(__codableDefault_retryCount)
}()
```

## How properties are decoded

| Annotation | JSON key | When key absent | When value is `null` |
|--------------|----------|-----------------|----------------------|
| *(none)* | Property name | **Throws** | **Throws** (for non-optional types) |
| `@Default(value)` | Property name | Uses `value` | Uses `value` |
| `@Default(value, codingKey: "key")` | `"key"` | Uses `value` | Uses `value` |
| `@Default(value, transform: { … })` | Property name | Uses `transform(value)` | Uses `transform(value)` |
| `@Default(value, codingKey: "key", transform: { … })` | `"key"` | Uses `transform(value)` | Uses `transform(value)` |

Required properties use:

```swift
self.name = try container.decode(String.self, forKey: .name)
```

Defaulted properties use:

```swift
self.isEnabled =
    (try? container.decodeIfPresent(Bool.self, forKey: .isEnabled))
    ?? false
```

When the key is present but the value has the **wrong type**, decoding fails and the default is used (same as missing/`null`). If you need strict type checking on present keys, do not use `@Default` for that property.

## Custom `CodingKeys`

Define your own enum when you need full control (e.g. several required fields with snake_case keys). The macro **does not** emit `CodingKeys` in that case; it only emits `init(from:)`.

**Rules:**

- Enum must be named `CodingKeys` and conform to `String, CodingKey`.
- Every stored instance property on the type needs a matching case name (same spelling as the property).
- Use `case propertyName = "json_key"` for custom wire names.

```swift
@CodableDefault
struct Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case name = "display_name"
        case isEnabled = "is_enabled"
    }

    var name: String

    @Default(false)
    var isEnabled: Bool
}
```

If a property has no matching case, expansion fails with a clear compile-time error.

Combine with `@Default(_:codingKey:)` only when the macro generates `CodingKeys`; if you provide the enum, put raw values on the enum cases instead.

## Generated code (example)

Input:

```swift
@CodableDefault
struct Config: Codable {
    var apiVersion: String
    @Default(true)
    var enabled: Bool
    @Default(10, codingKey: "retry")
    var retryCount: Int
}
```

Expanded members (conceptually):

```swift
enum CodingKeys: String, CodingKey {
    case apiVersion
    case enabled
    case retryCount = "retry"
}

init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.apiVersion = try container.decode(String.self, forKey: .apiVersion)

    self.enabled =
        (try? container.decodeIfPresent(Bool.self, forKey: .enabled))
        ?? true

    self.retryCount =
        (try? container.decodeIfPresent(Int.self, forKey: .retryCount))
        ?? 10
}
```

## Encoding

The macros customize **decoding** only (`init(from:)`). For `struct` types that declare `Codable`, Swift can still **synthesize** `encode(to:)` as long as you do not implement it yourself. Generated `CodingKeys` are used for both directions when synthesis applies.

Run `swift run CodableDefaultClient` for a round-trip encode/decode sample.

## Project layout

```
CodableDefault/
├── Package.swift                 # Swift 6.2 package manifest
├── Package.resolved              # Locked dependency versions
├── README.md
├── Sources/
│   ├── CodableDefault/           # Public macro declarations
│   │   └── CodableDefault.swift
│   ├── CodableDefaultMacros/     # Macro implementations (compiler plugin)
│   │   └── CodableDefaultMacro.swift
│   └── CodableDefaultClient/     # Example executable
│       └── main.swift
└── Tests/
    └── CodableDefaultTests/      # End-to-end decode tests
```

| Target | Kind | Purpose |
|--------|------|---------|
| `CodableDefault` | Library | `@CodableDefault`, `@Default` API |
| `CodableDefaultMacros` | Macro / plugin | SwiftSyntax expansion |
| `CodableDefaultClient` | Executable | Usage demo |
| `CodableDefaultTests` | Tests | Runtime decode/encode tests (Swift Testing) |
| `CodableDefaultMacroTests` | Tests | Macro expansion tests (Swift Testing) |

## Development

### Build

```bash
swift build
```

### Test

```bash
swift test
```

Macro implementations compile for the **host** (macOS). In Xcode, run tests with destination **My Mac** and scheme **CodableDefault-Package**. Testing against the **iOS Simulator** can fail because Xcode may try to build `swift-syntax` macro support for iOS.

### Example client

```bash
swift run CodableDefaultClient
```

## Limitations

- **Stored properties only** — must have an explicit type annotation (`var count: Int`).
- **Static properties** are ignored.
- **Computed properties** are ignored.
- **Enums, actors, protocols** are not supported as `@CodableDefault` targets (only `struct` and `class`).
- **No custom `encode(to:)`** generation — decoding-only customization.
- **Default expressions** are pasted literally; they must be valid at the use site (e.g. capture surrounding generics correctly).
- **User `CodingKeys`** must list every decodable stored property; partial enums are not merged automatically.
- **Wrong JSON types** on `@Default` fields fall back to the default value instead of throwing.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release history is in [CHANGELOG.md](CHANGELOG.md).

## License

CodableDefault is released under the [MIT License](LICENSE).
