// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Valdi",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Valdi",
            targets: ["Valdi"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Valdi",
            dependencies: [],
            path: "Sources/Valdi",
            resources: [
                .process("Resources"),
                .process("Shaders")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "ValdiTests",
            dependencies: ["Valdi"],
            path: "Tests/ValdiTests"
        )
    ]
)
