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
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("0.12.0")),
        .package(url: "https://github.com/VeldsparCrypto/Ed25519.git", .exact("0.0.1")),
        .package(url: "https://github.com/VeldsparCrypto/SWSQLite.git", .exact("1.0.20")),
        .package(url: "https://github.com/VeldsparCrypto/swifter.git", .exact("1.4.8")),
        .package(url: "https://github.com/VeldsparCrypto/SwiftClient.git", .exact("3.0.5")),
        ],
    targets: [
        .target(
            name: "veldspard",
            dependencies: ["CryptoSwift","Swifter","Swifter","SwiftClient","VeldsparCore","Ed25519","SWSQLite"],
            path: "./Sources/daemon"),
        .target(
            name: "miner",
            dependencies: ["CryptoSwift","Swifter","SWSQLite","VeldsparCore","Ed25519","SwiftClient","Swifter"],
            path: "./Sources/miner"),
        .target(
            name: "simplewallet",
            dependencies: ["CryptoSwift","Swifter","SWSQLite","VeldsparCore","Swifter","SwiftClient","Ed25519"],
            path: "./Sources/simplewallet"),
        .target(
            name: "VeldsparCore",
            dependencies: ["CryptoSwift","Ed25519"],
            path: "./Sources/core"),
        ]
)
