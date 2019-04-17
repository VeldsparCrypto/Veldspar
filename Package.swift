// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Veldspar",
    products: [
        .library        (name: "VeldsparCore",     targets: ["VeldsparCore"]),
        .executable     (name: "veldspard",        targets: ["veldspard"]),
        .executable     (name: "miner",            targets: ["miner"]),
        .executable     (name: "simplewallet",     targets: ["simplewallet"]),
        .executable     (name: "paperwallet",      targets: ["paperwallet"]),
        .executable     (name: "onlinewallet",     targets: ["onlinewallet"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        
        .package(url: "https://github.com/VeldsparCrypto/CSQlite.git", .exact("1.0.8")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("0.15.0")),
        .package(url: "https://github.com/VeldsparCrypto/Ed25519.git", .exact("0.0.2")),
        .package(url: "https://github.com/VeldsparCrypto/SWSQLite.git", .exact("1.0.28")),
        .package(url: "https://github.com/VeldsparCrypto/swifter.git", .exact("1.4.8")),
        .package(url: "https://github.com/onevcat/Rainbow.git", .exact("3.1.5")),
        ],
    targets: [
        .target(
            name: "veldspard",
            dependencies: ["CryptoSwift","Swifter","VeldsparCore","Ed25519","SWSQLite","Rainbow"],
            path: "./Sources/daemon"),
        .target(
            name: "paperwallet",
            dependencies: ["CryptoSwift","VeldsparCore","Ed25519","SWSQLite","Rainbow"],
            path: "./Sources/paperwallet"),
        .target(
            name: "onlinewallet",
            dependencies: ["CryptoSwift","VeldsparCore","Ed25519","SWSQLite","Rainbow"],
            path: "./Sources/onlinewallet"),
        .target(
            name: "miner",
            dependencies: ["CryptoSwift","SWSQLite","VeldsparCore","Ed25519"],
            path: "./Sources/miner"),
        .target(
            name: "simplewallet",
            dependencies: ["Rainbow","CryptoSwift","SWSQLite","VeldsparCore","Ed25519"],
            path: "./Sources/simplewallet"),
        .target(
            name: "VeldsparCore",
            dependencies: ["CryptoSwift","Ed25519"],
            path: "./Sources/core"),
        ],
            swiftLanguageVersions: [4]
)
