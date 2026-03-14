// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LivePhotoPairer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "LivePhotoPairerCore", targets: ["LivePhotoPairerCore"]),
        .executable(name: "LivePhotoPairer", targets: ["LivePhotoPairerApp"])
    ],
    targets: [
        .target(
            name: "LivePhotoPairerCore",
            path: "Sources/LivePhotoPairerCore"
        ),
        .executableTarget(
            name: "LivePhotoPairerApp",
            dependencies: ["LivePhotoPairerCore"],
            path: "Sources/LivePhotoPairerApp"
        ),
        .testTarget(
            name: "LivePhotoPairerTests",
            dependencies: ["LivePhotoPairerCore"],
            path: "Tests/LivePhotoPairerTests"
        )
    ]
)
