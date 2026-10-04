// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mailto",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "mailto",
            targets: ["Mailto"]
        ),
        .library(
            name: "MailtoCore",
            targets: ["MailtoCore"]
        )
    ],
    targets: [
        .target(
            name: "MailtoCore",
            dependencies: []
        ),
        .executableTarget(
            name: "Mailto",
            dependencies: ["MailtoCore"]
        ),
        .testTarget(
            name: "MailtoCoreTests",
            dependencies: ["MailtoCore"]
        )
    ]
)
