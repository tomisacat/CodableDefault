// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CodableDefault",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CodableDefault",
            targets: ["CodableDefault"]
        ),
        .executable(
            name: "CodableDefaultClient",
            targets: ["CodableDefaultClient"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            .upToNextMinor(from: "602.0.0")
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "CodableDefaultMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "CodableDefault", dependencies: ["CodableDefaultMacros"]),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "CodableDefaultClient", dependencies: ["CodableDefault"]),

        .testTarget(
            name: "CodableDefaultTests",
            dependencies: ["CodableDefault"]
        ),

        .testTarget(
            name: "CodableDefaultMacroTests",
            dependencies: [
                "CodableDefaultMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
