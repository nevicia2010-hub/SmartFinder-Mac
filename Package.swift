// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartFinder",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SmartFinder", targets: ["SmartFinder"]),
        .executable(name: "SmartFinderCoreTests", targets: ["SmartFinderCoreTests"])
    ],
    targets: [
        .target(name: "SmartFinderCore"),
        .executableTarget(
            name: "SmartFinder",
            dependencies: ["SmartFinderCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(name: "SmartFinderCoreTests", dependencies: ["SmartFinderCore"])
    ]
)
