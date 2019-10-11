// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftyPoeditor",
    platforms: [
        .macOS(.v10_14)
    ],
    dependencies: [
        .package(url: "https://github.com/yanagiba/swift-ast.git",
                 from: "0.19.9"),
        .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.0.0-alpha.2"),
    ],
    targets: [
        .target(
            name: "SwiftyPoeditor",
            dependencies: ["SwiftAST+Tooling", "SwiftyRequest", "ConsoleKit"]),
        .testTarget(
            name: "SwiftyPoeditorTests",
            dependencies: ["SwiftyPoeditor"]),
    ],
    swiftLanguageVersions: [.v5]
)
