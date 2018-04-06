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
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Session.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Session-SQLite.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-RequestLogger.git", from: "3.0.0"),
        ],
    targets: [
        .target(
            name: "sharkd",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","PerfectSessionSQLite","PerfectRequestLogger","SharkCore"],
            path: "./Sources/sharkd"),
        .target(
            name: "miner",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","PerfectSessionSQLite","PerfectRequestLogger","SharkCore"],
            path: "./Sources/miner"),
        .target(
            name: "simplewallet",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","PerfectSessionSQLite","PerfectRequestLogger","SharkCore"],
            path: "./Sources/simplewallet"),
        .target(
            name: "SharkCore",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","PerfectSessionSQLite","PerfectRequestLogger"],
            path: "./Sources/core"),
        ]
)
