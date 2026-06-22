// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepSeekBalance",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DeepSeekBalance",
            dependencies: [],
            path: "Sources/DeepSeekBalance"
        )
    ]
)
