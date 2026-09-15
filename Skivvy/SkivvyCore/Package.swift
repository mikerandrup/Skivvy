// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SkivvyCore",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "SkivvyCore", targets: ["SkivvyCore"]),
    ],
    targets: [
        .target(name: "SkivvyCore"),
        .testTarget(
            name: "SkivvyCoreTests",
            dependencies: ["SkivvyCore"]
        ),
    ]
)
