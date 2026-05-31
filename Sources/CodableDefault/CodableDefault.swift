// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(CodingKeys), named(init(from:)))
public macro CodableDefault() =
    #externalMacro(
        module: "CodableDefaultMacros",
        type: "CodableDefaultMacro"
    )

@attached(peer)
public macro Default<T>(_ value: T) =
    #externalMacro(
        module: "CodableDefaultMacros",
        type: "DefaultMacro"
    )

@attached(peer)
public macro Default<T>(_ value: T, codingKey: String) =
    #externalMacro(
        module: "CodableDefaultMacros",
        type: "DefaultMacro"
    )
