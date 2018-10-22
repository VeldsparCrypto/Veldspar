// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Veldspar",
    products: [
        .library        (name: "VeldsparCore",     targets: ["VeldsparCore"]),
        .library        (name: "VeldsparDatabase", targets: ["VeldsparDatabase"]),
        .library        (name: "VeldsparNetwork",  targets: ["VeldsparNetwork"]),
        .executable     (name: "veldspard",        targets: ["veldspard"]),
        .executable     (name: "miner",            targets: ["miner"]),
        .executable     (name: "simplewallet",     targets: ["simplewallet"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("0.12.0")),
        .package(url: "https://github.com/VeldsparCrypto/Ed25519.git", .exact("0.0.1")),
        .package(url: "https://github.com/sharksync/SWSQLite.git", .exact("1.0.11")),
        .package(url: "https://github.com/VeldsparCrypto/swifter.git", .exact("1.4.7")),
        .package(url: "https://editfmah@github.com/VeldsparCrypto/SwiftClient.git", .exact("3.0.5")),
        ],
    targets: [
        .target(
            name: "veldspard",
            dependencies: ["CryptoSwift","Swifter","VeldsparDatabase","VeldsparNetwork","VeldsparCore","Ed25519","SwiftClient"],
            path: "./Sources/daemon"),
        .target(
            name: "VeldsparNetwork",
            dependencies: ["CryptoSwift","Swifter","SwiftClient"],
            path: "./Sources/network"),
        .target(
            name: "VeldsparDatabase",
            dependencies: ["SWSQLite","VeldsparCore"],
            path: "./Sources/database"),
        .target(
            name: "miner",
            dependencies: ["CryptoSwift","Swifter","SWSQLite","VeldsparCore","Ed25519","SwiftClient"],
            path: "./Sources/miner"),
        .target(
            name: "simplewallet",
            dependencies: ["CryptoSwift","Swifter","SWSQLite","VeldsparCore","Ed25519","SwiftClient"],
            path: "./Sources/simplewallet"),
        .target(
            name: "VeldsparCore",
            dependencies: ["CryptoSwift","Ed25519"],
            path: "./Sources/core"),
        ]
)
