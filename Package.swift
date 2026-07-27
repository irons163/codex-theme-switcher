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
        ),
        .executable(
            name: "codex-theme",
            targets: ["CodexThemeAgentCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.1"
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
                "CodexThemeRuntime",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "CodexThemeAgentCLI",
            dependencies: [
                "CodexThemeSwitcherCore",
                "CodexThemeRuntime"
            ],
            exclude: ["Resources"]
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
        ),
        .testTarget(
            name: "CodexThemeAgentCLITests",
            dependencies: [
                "CodexThemeAgentCLI",
                "CodexThemeSwitcherCore",
                "CodexThemeRuntime"
            ]
        )
    ]
)
