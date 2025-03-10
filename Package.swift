// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PantawCoin",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "PantawCoin", targets: ["PantawCoin"])
    ],
    dependencies: [
        // Dependencies go here
    ],
    targets: [
        .executableTarget(
            name: "PantawCoin",
            dependencies: [],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "PantawCoinTests",
            dependencies: ["PantawCoin"]),
    ]
)
