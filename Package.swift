// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LivePhotoPairer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LivePhotoPairer", targets: ["LivePhotoPairerApp"])
    ],
    targets: [
        .executableTarget(
            name: "LivePhotoPairerApp",
            path: "Sources/LivePhotoPairerApp"
        ),
        .testTarget(
            name: "LivePhotoPairerTests",
            dependencies: ["LivePhotoPairerApp"],
            path: "Tests/LivePhotoPairerTests"
        )
    ]
)
