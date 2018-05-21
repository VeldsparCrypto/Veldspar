// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharkChain",
    products: [
        .library        (name: "SharkCore",     targets: ["SharkCore"]),
        .executable     (name: "sharkd",        targets: ["sharkd"]),
        .executable     (name: "miner",         targets: ["miner"]),
        .executable     (name: "simplewallet",  targets: ["simplewallet"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("0.8.3")),
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", .exact("3.0.10")),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Session.git", .exact("3.1.1")),
        .package(url: "https://gitlab.com/katalysis/Ed25519.git", .exact("0.2.1")),
        .package(url: "https://github.com/sharksync/SWSQLite.git", .exact("1.0.11")),
        ],
    targets: [
        .target(
            name: "sharkd",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","SWSQLite","SharkCore","Ed25519"],
            path: "./Sources/sharkd"),
        .target(
            name: "miner",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","SWSQLite","SharkCore","Ed25519"],
            path: "./Sources/miner"),
        .target(
            name: "simplewallet",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","SWSQLite","SharkCore","Ed25519"],
            path: "./Sources/simplewallet"),
        .target(
            name: "SharkCore",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","SWSQLite","Ed25519"],
            path: "./Sources/core"),
        ]
)
