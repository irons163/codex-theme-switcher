import Foundation
@testable import CodexThemeSwitcherCore

enum TestFixtures {
    static let date = Date(timeIntervalSince1970: 1_700_000_000)

    static func theme(
        id: UUID = UUID(),
        name: String = "Test Theme",
        rawCSS: String = "",
        assets: [ThemeAsset] = [],
        imageSkin: ThemeImageSkin? = nil
    ) -> ThemeDocument {
        ThemeDocument(
            id: id,
            metadata: ThemeMetadata(
                name: name,
                author: "Theme Tester",
                description: "A theme used by unit tests.",
                version: "2.1.0",
                tags: ["test", "fixture"],
                homepage: URL(string: "https://example.invalid/theme"),
                license: "MIT",
                createdAt: date,
                updatedAt: date
            ),
            layers: [
                ThemeLayer(
                    name: "Base",
                    variables: [
                        ThemeVariable(
                            value: "#22aaff",
                            semanticRole: .accent
                        ),
                        ThemeVariable(
                            name: "--custom-radius",
                            value: "14px"
                        )
                    ],
                    components: [
                        ThemeComponentOverride(
                            componentID: "composer",
                            declarations: [
                                ThemeCSSDeclaration(
                                    property: "border-radius",
                                    value: "var(--custom-radius)"
                                )
                            ]
                        )
                    ],
                    rules: [
                        ThemeCSSRule(
                            name: "Links",
                            selector: "a",
                            declarations: [
                                ThemeCSSDeclaration(
                                    property: "color",
                                    value: "var(--codex-theme-accent)",
                                    isImportant: true
                                )
                            ]
                        )
                    ],
                    rawCSS: rawCSS
                )
            ],
            assets: assets,
            imageSkin: imageSkin
        )
    }

    static func imageAsset(
        id: UUID = UUID(),
        name: String = "background.png",
        mediaType: String = "image/png",
        bytes: [UInt8] = [1, 2, 3]
    ) -> ThemeAsset {
        ThemeAsset(
            id: id,
            name: name,
            mediaType: mediaType,
            data: Data(bytes)
        )
    }

    static func imageSkin(
        lightAssetID: UUID?,
        darkAssetID: UUID?
    ) -> ThemeImageSkin {
        ThemeImageSkin(
            light: ThemeSkinVariant(
                backgroundAssetID: lightAssetID,
                backgroundColor: "#FFF4ED",
                imageFit: .contain,
                positionX: 0.25,
                positionY: 0.75,
                zoom: 1.1,
                imageOpacity: 0.92,
                imageBlur: 2,
                brightness: 1.12,
                contrast: 0.94,
                saturation: 0.86,
                blendMode: .softLight,
                overlayColor: "#FFE7DB",
                overlayOpacity: 0.14,
                scrimDirection: .right,
                scrimOpacity: 0.18,
                vignetteOpacity: 0.06,
                primaryTextColor: "#241C18",
                secondaryTextColor: "#685A52",
                accentColor: "#B85E38",
                sidebarTint: "#FFF9F4",
                sidebarOpacity: 0.48,
                contentTint: "#FFF7F1",
                contentOpacity: 0.12,
                composerTint: "#FFFCF9",
                composerOpacity: 0.8,
                cardTint: "#FFF8F2",
                cardOpacity: 0.62,
                borderColor: "#FFFFFF",
                borderOpacity: 0.52
            ),
            dark: ThemeSkinVariant(
                backgroundAssetID: darkAssetID,
                backgroundColor: "#08090C",
                imageFit: .cover,
                positionX: 0.68,
                positionY: 0.42,
                zoom: 1.06,
                imageOpacity: 0.88,
                imageBlur: 4,
                brightness: 0.7,
                contrast: 1.18,
                saturation: 0.76,
                blendMode: .multiply,
                overlayColor: "#050609",
                overlayOpacity: 0.32,
                scrimDirection: .left,
                scrimOpacity: 0.54,
                vignetteOpacity: 0.28,
                primaryTextColor: "#F5EFE7",
                secondaryTextColor: "#C4B7A8",
                accentColor: "#D8AD64",
                sidebarTint: "#08090C",
                sidebarOpacity: 0.46,
                contentTint: "#08090C",
                contentOpacity: 0.1,
                composerTint: "#14120F",
                composerOpacity: 0.82,
                cardTint: "#15130F",
                cardOpacity: 0.66,
                borderColor: "#D8AD64",
                borderOpacity: 0.3
            ),
            glass: ThemeSkinGlass(
                blurRadius: 24,
                saturation: 1.24,
                borderWidth: 1.5,
                cornerRadius: 20,
                shadowOpacity: 0.32,
                shadowBlur: 44,
                textShadowOpacity: 0.2
            ),
            targets: ThemeSkinTargets(
                sidebar: true,
                content: true,
                titlebar: false,
                composer: true,
                cards: true,
                popovers: false,
                codeBlocks: true
            )
        )
    }

    static func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CodexThemeSwitcherCoreTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
