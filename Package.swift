// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftyPoeditor",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(name: "swifty-poeditor", targets: ["swifty-poeditor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yanagiba/swift-ast.git", .exact("0.4.2")),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", .exact("3.1.0")),
        .package(url: "https://github.com/vapor/console-kit.git", .exact("4.0.0-beta.2"))
    ],
    targets: [
        .target(
            name: "swifty-poeditor",
            dependencies: ["SwiftAST+Tooling", "SwiftyRequest", "ConsoleKit"]),
    ],
    swiftLanguageVersions: [.v5]
)
