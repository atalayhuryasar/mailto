// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacMail",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "MacMailCore",
            targets: ["MacMailCore"]
        )
    ],
    targets: [
        .target(
            name: "MacMailCore",
            dependencies: []
        ),
        .testTarget(
            name: "MacMailCoreTests",
            dependencies: ["MacMailCore"]
        )
    ]
)
