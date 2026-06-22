// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ds-fathom",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ds-fathom",
            dependencies: [],
            path: "Sources/DSFathom"
        )
    ]
)
