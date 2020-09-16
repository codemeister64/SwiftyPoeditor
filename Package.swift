// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftyPoeditor",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "swifty-poeditor", targets: ["swifty-poeditor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yanagiba/swift-ast.git", .exact("0.19.9")),
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "swifty-poeditor",
            dependencies: ["SwiftAST+Tooling", "AsyncHTTPClient", "ConsoleKit"])
    ],
    swiftLanguageVersions: [.v5]
)
