// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DMGForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "DMGForgeCore", targets: ["DMGForgeCore"]),
        .executable(name: "dmgforge", targets: ["DMGForge"])
    ],
    targets: [
        .target(name: "DMGForgeCore"),
        .executableTarget(
            name: "DMGForge",
            dependencies: ["DMGForgeCore"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "DMGForgeTests",
            dependencies: ["DMGForge", "DMGForgeCore"]
        )
    ]
)
