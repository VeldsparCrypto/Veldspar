// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "node",
    products: [
        .executable(name: "SharkChainD", targets: ["node"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.8.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Session.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Session-SQLite.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-RequestLogger.git", from: "3.0.0"),
        ],
    targets: [
        .target(
            name: "node",
            dependencies: ["CryptoSwift","PerfectHTTPServer","PerfectSession","PerfectSessionSQLite","PerfectRequestLogger"]),
        ]
)
