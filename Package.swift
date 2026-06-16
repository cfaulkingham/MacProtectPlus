// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacProtectPlus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacProtectPlus", targets: ["MacProtectPlus"]),
        .executable(name: "MacProtectPlusInstaller", targets: ["MacProtectPlusInstaller"])
    ],
    targets: [
        .executableTarget(
            name: "MacProtectPlus",
            path: "Sources/MacProtectPlus"
        ),
        .executableTarget(
            name: "MacProtectPlusInstaller",
            path: "Sources/MacProtectPlusInstaller"
        )
    ]
)
