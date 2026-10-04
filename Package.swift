// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacMail",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "MacMail",
            targets: ["MacMail"]
        ),
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
        .executableTarget(
            name: "MacMail",
            dependencies: ["MacMailCore"]
        ),
        .testTarget(
            name: "MacMailCoreTests",
            dependencies: ["MacMailCore"]
        )
    ]
)
