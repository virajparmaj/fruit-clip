// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FruitClip",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "FruitClip",
            path: "Sources/FruitClip",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "FruitClipTests",
            dependencies: ["FruitClip"],
            path: "Tests/FruitClipTests"
        ),
    ]
)
