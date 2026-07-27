// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexThemeSwitcher",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CodexThemeSwitcherCore",
            targets: ["CodexThemeSwitcherCore"]
        ),
        .library(
            name: "CodexThemeRuntime",
            targets: ["CodexThemeRuntime"]
        ),
        .executable(
            name: "CodexThemeSwitcher",
            targets: ["CodexThemeSwitcher"]
        )
    ],
    targets: [
        .target(
            name: "CodexThemeSwitcherCore"
        ),
        .target(
            name: "CodexThemeRuntime",
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "CodexThemeSwitcher",
            dependencies: [
                "CodexThemeSwitcherCore",
                "CodexThemeRuntime"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CodexThemeSwitcherCoreTests",
            dependencies: ["CodexThemeSwitcherCore"]
        ),
        .testTarget(
            name: "CodexThemeRuntimeTests",
            dependencies: ["CodexThemeRuntime"]
        ),
        .testTarget(
            name: "CodexThemeSwitcherTests",
            dependencies: [
                "CodexThemeSwitcher",
                "CodexThemeSwitcherCore",
                "CodexThemeRuntime"
            ]
        )
    ]
)
