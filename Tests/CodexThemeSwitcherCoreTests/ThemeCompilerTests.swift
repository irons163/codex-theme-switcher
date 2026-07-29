import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeCompilerTests: XCTestCase {
    func testCompilesVariablesComponentsRulesAndRawCSSInOrder() throws {
        var theme = TestFixtures.theme(rawCSS: ".raw { opacity: .75; }")
        theme.layers[0].condition = .dark
        theme.layers[0].components.append(
            ThemeComponentOverride(
                componentID: "future-component",
                selectors: [".future"],
                declarations: [
                    ThemeCSSDeclaration(property: "padding", value: "8px")
                ]
            )
        )

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(compiled.css.contains("@media (prefers-color-scheme: dark)"))
        XCTAssertTrue(compiled.css.contains("--codex-theme-accent: #22aaff;"))
        XCTAssertTrue(compiled.css.contains("--custom-radius: 14px;"))
        XCTAssertTrue(
            compiled.css.contains(
                "[data-codex-composer-root] .composer-surface-chrome"
            )
        )
        XCTAssertTrue(compiled.css.contains("border-radius: var(--custom-radius);"))
        XCTAssertTrue(compiled.css.contains(".future {"))
        XCTAssertTrue(compiled.css.contains("color: var(--codex-theme-accent) !important;"))

        let variableRange = try XCTUnwrap(compiled.css.range(of: "--codex-theme-accent"))
        let componentRange = try XCTUnwrap(
            compiled.css.range(
                of: "[data-codex-composer-root] .composer-surface-chrome"
            )
        )
        let ruleRange = try XCTUnwrap(compiled.css.range(of: "\n  a {"))
        let rawRange = try XCTUnwrap(compiled.css.range(of: ".raw {"))
        XCTAssertLessThan(variableRange.lowerBound, componentRange.lowerBound)
        XCTAssertLessThan(componentRange.lowerBound, ruleRange.lowerBound)
        XCTAssertLessThan(ruleRange.lowerBound, rawRange.lowerBound)
    }

    func testUnknownComponentProducesWarningWithoutInvalidCSS() throws {
        var theme = TestFixtures.theme()
        theme.layers[0].components = [
            ThemeComponentOverride(
                componentID: "not-in-catalog",
                declarations: [
                    ThemeCSSDeclaration(property: "color", value: "red")
                ]
            )
        ]

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertEqual(compiled.warnings.count, 1)
        XCTAssertEqual(compiled.warnings.first?.code, .unknownComponent)
        XCTAssertFalse(compiled.css.contains("not-in-catalog"))
    }

    func testExternalizesEmbeddedAssetForRuntime() throws {
        let assetID = UUID()
        let asset = ThemeAsset(
            id: assetID,
            name: "pixel.png",
            mediaType: "image/png",
            data: Data([0, 1, 2, 3])
        )
        let theme = TestFixtures.theme(
            rawCSS: #".hero { background-image: theme-asset("\#(assetID.uuidString)"); }"#,
            assets: [asset]
        )

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(
            compiled.css.contains(
                #"url("codex-theme-asset://\#(assetID.uuidString.lowercased())")"#
            )
        )
        XCTAssertEqual(compiled.runtimeAssets, [asset])
        XCTAssertEqual(compiled.referencedAssetIDs, [assetID])
        XCTAssertFalse(compiled.css.contains("theme-asset("))
        XCTAssertFalse(compiled.css.contains("base64"))
        XCTAssertFalse(compiled.css.contains("data:"))
    }

    func testImageSkinCompilesBetweenStructuredAndAdvancedCSS() throws {
        let light = TestFixtures.imageAsset(
            name: "light.png",
            bytes: [1, 2, 3]
        )
        let dark = TestFixtures.imageAsset(
            name: "dark.webp",
            mediaType: "image/webp",
            bytes: [4, 5, 6]
        )
        let theme = TestFixtures.theme(
            rawCSS: ":root { --cts-skin-accent: hotpink; }",
            assets: [light, dark],
            imageSkin: TestFixtures.imageSkin(
                lightAssetID: light.id,
                darkAssetID: dark.id
            )
        )

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(compiled.css.contains("/* Codex Theme Image Skin */"))
        XCTAssertTrue(
            compiled.css.contains("@media (prefers-color-scheme: dark)")
        )
        XCTAssertTrue(
            compiled.css.contains(
                ":root:where(.electron-light)"
            )
        )
        XCTAssertTrue(
            compiled.css.contains(
                ":root:where(.electron-dark:not(.electron-light))"
            )
        )
        XCTAssertTrue(
            compiled.css.contains(
                #"url("codex-theme-asset://\#(light.id.uuidString.lowercased())")"#
            )
        )
        XCTAssertTrue(
            compiled.css.contains(
                #"url("codex-theme-asset://\#(dark.id.uuidString.lowercased())")"#
            )
        )
        XCTAssertEqual(
            compiled.runtimeAssets.map(\.id),
            [light.id, dark.id].sorted {
                $0.uuidString.lowercased() < $1.uuidString.lowercased()
            }
        )
        XCTAssertEqual(compiled.referencedAssetIDs, [light.id, dark.id])
        XCTAssertFalse(compiled.css.contains("theme-asset("))
        XCTAssertFalse(compiled.css.contains("base64"))

        let skinRange = try XCTUnwrap(
            compiled.css.range(of: "/* Codex Theme Image Skin */")
        )
        let layerRange = try XCTUnwrap(
            compiled.css.range(of: "/* Layer: Base */")
        )
        let rawRange = try XCTUnwrap(
            compiled.css.range(of: "--cts-skin-accent: hotpink")
        )
        XCTAssertLessThan(layerRange.lowerBound, skinRange.lowerBound)
        XCTAssertLessThan(skinRange.lowerBound, rawRange.lowerBound)
    }

    func testImageSkinExternalizesSharedLightAndDarkAssetOnlyOnce() throws {
        let shared = TestFixtures.imageAsset(
            name: "shared.jpg",
            mediaType: "image/jpeg",
            bytes: [0xFF, 0xD8, 0xFF]
        )
        let theme = TestFixtures.theme(
            assets: [shared],
            imageSkin: TestFixtures.imageSkin(
                lightAssetID: shared.id,
                darkAssetID: shared.id
            )
        )

        let compiled = try ThemeCompiler().compile(theme)
        let assetURL =
            #"url("codex-theme-asset://\#(shared.id.uuidString.lowercased())")"#

        XCTAssertEqual(
            compiled.css.components(separatedBy: assetURL).count - 1,
            1
        )
        XCTAssertEqual(compiled.runtimeAssets, [shared])
        XCTAssertEqual(compiled.referencedAssetIDs, [shared.id])
        XCTAssertFalse(compiled.css.contains("theme-asset("))
        XCTAssertFalse(compiled.css.contains("base64"))
    }

    func testRuntimeAssetsAreReferencedDeduplicatedAndUUIDSorted() throws {
        let first = ThemeAsset(
            id: try XCTUnwrap(UUID(
                uuidString: "00000000-0000-4000-8000-000000000001"
            )),
            name: "first.png",
            mediaType: "image/png",
            data: Data([1])
        )
        let second = ThemeAsset(
            id: try XCTUnwrap(UUID(
                uuidString: "FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFFF"
            )),
            name: "second.png",
            mediaType: "image/png",
            data: Data([2])
        )
        let unused = ThemeAsset(
            id: try XCTUnwrap(UUID(
                uuidString: "77777777-7777-4777-B777-777777777777"
            )),
            name: "unused.png",
            mediaType: "image/png",
            data: Data([3])
        )
        let theme = TestFixtures.theme(
            rawCSS: """
            .second {
              background: theme-asset('\(second.id.uuidString.uppercased())');
            }
            .first {
              background: theme-asset(\(first.id.uuidString));
              mask-image: theme-asset("\(first.id.uuidString)");
            }
            """,
            assets: [second, unused, first]
        )

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertEqual(compiled.runtimeAssets, [first, second])
        XCTAssertEqual(compiled.referencedAssetIDs, [first.id, second.id])
        XCTAssertFalse(compiled.runtimeAssets.contains(unused))
        XCTAssertEqual(
            compiled.css.components(
                separatedBy: "codex-theme-asset://\(first.id.uuidString.lowercased())"
            ).count - 1,
            2
        )
        XCTAssertTrue(
            compiled.css.contains(
                "codex-theme-asset://\(second.id.uuidString.lowercased())"
            )
        )
    }

    func testLargeRuntimeAssetDoesNotGrowCompiledCSS() throws {
        let largeData = Data(repeating: 0xA5, count: 4 * 1_024 * 1_024)
        let asset = ThemeAsset(
            id: UUID(),
            name: "large.png",
            mediaType: "image/png",
            data: largeData
        )
        let theme = TestFixtures.theme(
            rawCSS: """
            .hero {
              background-image: theme-asset(\(asset.id.uuidString));
            }
            """,
            assets: [asset]
        )

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertEqual(compiled.runtimeAssets, [asset])
        XCTAssertLessThan(compiled.css.utf8.count, 10_000)
        XCTAssertFalse(compiled.css.contains(asset.dataBase64))
        XCTAssertFalse(compiled.css.contains("base64"))
        XCTAssertFalse(compiled.css.contains("data:"))
    }

    func testEveryImageFitCompilesExpectedBackgroundSizingAndRepeat() throws {
        let cases: [
            (
                fit: ThemeSkinImageFit,
                backgroundSize: String,
                backgroundRepeat: String
            )
        ] = [
            (.cover, "cover", "no-repeat"),
            (.contain, "contain", "no-repeat"),
            (.fill, "100% 100%", "no-repeat"),
            (.fitWidth, "100% auto", "no-repeat"),
            (.fitHeight, "auto 100%", "no-repeat"),
            (.original, "auto", "no-repeat"),
            (.tile, "auto", "repeat")
        ]

        XCTAssertEqual(ThemeSkinImageFit.allCases.count, cases.count)
        for item in cases {
            var skin = ThemeImageSkin()
            skin.light.imageFit = item.fit
            skin.dark.imageFit = item.fit

            let css = try ThemeCompiler()
                .compile(TestFixtures.theme(imageSkin: skin))
                .css

            XCTAssertTrue(
                css.contains(
                    "--cts-skin-background-size: "
                        + item.backgroundSize
                        + ";"
                ),
                "Missing background-size for \(item.fit)"
            )
            XCTAssertTrue(
                css.contains(
                    "--cts-skin-background-repeat: "
                        + item.backgroundRepeat
                        + ";"
                ),
                "Missing background-repeat for \(item.fit)"
            )
        }
    }

    func testFitModesAvoidOverscanWhileBlurredCoverKeepsEdgeProtection() throws {
        var fitSkin = ThemeImageSkin()
        fitSkin.light.imageFit = .contain
        fitSkin.light.imageBlur = 18
        fitSkin.dark.imageFit = .original
        fitSkin.dark.imageBlur = 18

        let fitCSS = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: fitSkin))
            .css
        XCTAssertTrue(fitCSS.contains("--cts-skin-image-inset: 0px;"))
        XCTAssertFalse(fitCSS.contains("--cts-skin-image-inset: -40px;"))

        var coverSkin = ThemeImageSkin()
        coverSkin.light.imageFit = .cover
        coverSkin.light.imageBlur = 18
        coverSkin.dark = coverSkin.light

        let coverCSS = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: coverSkin))
            .css
        XCTAssertTrue(
            coverCSS.contains("--cts-skin-image-inset: -40px;")
        )
    }

    func testFullWindowWallpaperKeepsViewportPseudoElements() throws {
        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: ThemeImageSkin()))
            .css

        XCTAssertTrue(
            css.contains(
                "html:root[data-codex-theme-switcher-theme]::before {"
            )
        )
        XCTAssertTrue(css.contains("position: fixed;"))
        XCTAssertFalse(css.contains("main.main-surface::before"))
        XCTAssertTrue(
            css.contains(
                "background-color: var(--cts-skin-content) !important;"
            )
        )
    }

    func testMainContentWallpaperReflowsInsideResizableContentPane() throws {
        var skin = ThemeImageSkin()
        skin.wallpaperScope = .mainContent

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        XCTAssertFalse(
            css.contains(
                "html:root[data-codex-theme-switcher-theme]::before {"
            )
        )
        XCTAssertTrue(css.contains("main.main-surface::before {"))
        XCTAssertTrue(css.contains("main.main-surface::after {"))
        XCTAssertTrue(css.contains("position: absolute;"))
        XCTAssertTrue(css.contains("z-index: -2;"))
        XCTAssertTrue(css.contains("z-index: -1;"))
        XCTAssertTrue(
            css.contains(
                "background-size: var(--cts-skin-background-size);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "linear-gradient(var(--cts-skin-content), var(--cts-skin-content))"
            )
        )
        XCTAssertTrue(
            css.contains(
                "[data-app-shell-main-content-layout]"
            )
        )
        XCTAssertFalse(
            css.contains(
                "main.main-surface {\n"
                    + "  background-color: var(--cts-skin-content) !important;"
            )
        )
    }

    func testMainContentWallpaperDoesNotDependOnContentGlassTarget() throws {
        var skin = ThemeImageSkin()
        skin.wallpaperScope = .mainContent
        skin.targets.content = false

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        XCTAssertTrue(css.contains("main.main-surface::before {"))
        XCTAssertTrue(
            css.contains(
                "[data-app-shell-main-content-layout]"
            )
        )
        XCTAssertFalse(
            css.contains(
                "linear-gradient(var(--cts-skin-content), var(--cts-skin-content))"
            )
        )
    }

    func testDisabledCenterPanelEmitsNoPanelVariablesOrSelectors() throws {
        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: ThemeImageSkin()))
            .css

        XCTAssertFalse(css.contains("--cts-skin-center-panel-"))
        XCTAssertFalse(
            css.contains(
                "[data-thread-find-target=\"conversation\"]"
            )
        )
        XCTAssertFalse(css.contains("[data-feature=\"game-source\"]"))
    }

    func testCenterPanelCompilesIndependentPaletteAndMaterialRules() throws {
        var skin = ThemeImageSkin()
        skin.targets.content = false
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 27,
            backdropSaturation: 1.35,
            borderWidth: 2.25,
            cornerRadius: 29,
            shadowBlur: 51,
            shadowOffsetX: -4,
            shadowOffsetY: 13,
            maximumWidth: 940,
            horizontalPadding: 38,
            verticalPadding: 31
        )
        skin.light.centerPanelTint = "#F1E2D3"
        skin.light.centerPanelOpacity = 0.63
        skin.light.centerPanelBorderColor = "#ABCDEF"
        skin.light.centerPanelBorderOpacity = 0.42
        skin.light.centerPanelShadowColor = "#654321"
        skin.light.centerPanelShadowOpacity = 0.19

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-background: "
                    + "color-mix(in srgb, #F1E2D3 63%, transparent);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-border: "
                    + "color-mix(in srgb, #ABCDEF 42%, transparent);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-shadow: "
                    + "color-mix(in srgb, #654321 19%, transparent);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-backdrop-blur: 27px;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-backdrop-saturation: 1.35;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-center-panel-maximum-width: 940px;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "[data-mcp-app-portal-target=\"true\"]:has("
                    + "> [data-thread-find-target=\"conversation\"])"
            )
        )
        XCTAssertTrue(
            css.contains(
                "main.main-surface [role=\"main\"] div:has("
                    + "> [data-feature=\"game-source\"])"
            )
        )
        XCTAssertTrue(
            css.contains(
                "padding: var(--cts-skin-center-panel-padding-y) "
                    + "var(--cts-skin-center-panel-padding-x) !important;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "border: var(--cts-skin-center-panel-border-width) "
                    + "solid var(--cts-skin-center-panel-border) !important;"
            )
        )
        XCTAssertFalse(
            css.contains(
                "opacity: var(--cts-skin-center-panel"
            )
        )
        XCTAssertFalse(
            css.contains(
                "--color-token-main-surface-primary: "
                    + "var(--cts-skin-content);"
            )
        )
    }

    func testImageSkinUsesCodexTextTokensAndNarrowSurfaceSelectors() throws {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.targets = ThemeSkinTargets(
            sidebar: false,
            content: false,
            titlebar: false,
            composer: true,
            cards: true,
            popovers: true,
            codeBlocks: true
        )

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        XCTAssertTrue(
            css.contains(
                "--color-token-foreground: var(--cts-skin-text-primary);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--color-token-primary: var(--cts-skin-accent);"
            )
        )
        XCTAssertFalse(
            css.contains(
                "--color-token-primary: var(--cts-skin-accent) !important;"
            )
        )
        XCTAssertFalse(css.contains("[data-app-action-sidebar-project-row]"))
        XCTAssertFalse(css.contains("[role=\"dialog\"]"))
        XCTAssertTrue(
            css.contains("[role=\"menu\"][data-state=\"open\"]")
        )
        XCTAssertTrue(css.contains("[data-message-author-role] pre"))
        XCTAssertFalse(
            css.contains(
                "--color-token-side-bar-background: var(--cts-skin-sidebar)"
            )
        )
    }

    func testHomeCardSelectorsCoverCurrentAndLegacyCodexMarkup() throws {
        let expectedSelectors = [
            "section[class~=\"group/home-suggestions\"] button[aria-labelledby]",
            "[data-home-ambient-suggestions] button[aria-labelledby]"
        ]

        XCTAssertEqual(
            ThemeComponentCatalog.default.selectors(for: "homeCard"),
            expectedSelectors
        )

        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.targets = ThemeSkinTargets(
            sidebar: false,
            content: false,
            titlebar: false,
            composer: false,
            cards: true,
            popovers: false,
            codeBlocks: false
        )
        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        for selector in expectedSelectors {
            XCTAssertTrue(
                css.contains(selector),
                "Missing Home card selector: \(selector)"
            )
        }
    }

    func testComposerActionButtonUsesIndependentColorsAndStableSelector() throws {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.light.composerActionBackgroundColor = "#123456"
        skin.light.composerActionIconColor = "#ABCDEF80"
        skin.dark.composerActionBackgroundColor = "#654321"
        skin.dark.composerActionIconColor = "#FEDCBA"
        skin.targets = ThemeSkinTargets(
            sidebar: false,
            content: false,
            titlebar: false,
            composer: true,
            cards: false,
            popovers: false,
            codeBlocks: false
        )

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css
        let selector =
            "[data-codex-composer-root] .composer-surface-chrome "
            + "button.size-token-button-composer.bg-token-foreground"

        XCTAssertTrue(css.contains(selector))
        XCTAssertTrue(
            css.contains(
                "--cts-skin-composer-action-background: #123456;"
            )
        )
        XCTAssertTrue(
            css.contains("--cts-skin-composer-action-icon: #ABCDEF80;")
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-composer-action-background: #654321;"
            )
        )
        XCTAssertTrue(
            css.contains("--cts-skin-composer-action-icon: #FEDCBA;")
        )
        XCTAssertTrue(
            css.contains(
                "background-color: "
                    + "var(--cts-skin-composer-action-background) "
                    + "!important;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--color-token-foreground: "
                    + "var(--cts-skin-composer-action-background) "
                    + "!important;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--color-token-dropdown-background: "
                    + "var(--cts-skin-composer-action-icon) "
                    + "!important;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "color: var(--cts-skin-composer-action-icon) !important;"
            )
        )
    }

    func testLegacyComposerActionColorsFollowTextAndCompleteCardSurface() throws {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.light.primaryTextColor = "#102030"
        skin.light.cardTint = "#405060"
        skin.light.cardOpacity = 0.37
        skin.light.composerActionBackgroundColor = nil
        skin.light.composerActionIconColor = nil

        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css

        XCTAssertTrue(
            css.contains(
                "--cts-skin-text-primary: #102030;"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-card: "
                    + "color-mix(in srgb, #405060 37%, transparent);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-composer-action-background: "
                    + "var(--cts-skin-text-primary);"
            )
        )
        XCTAssertTrue(
            css.contains(
                "--cts-skin-composer-action-icon: var(--cts-skin-card);"
            )
        )
    }

    func testMissingAssetThrowsPreciseError() {
        let missing = UUID()
        let theme = TestFixtures.theme(
            rawCSS: #".hero { background: theme-asset(\#(missing.uuidString)); }"#
        )

        XCTAssertThrowsError(try ThemeCompiler().compile(theme)) { error in
            XCTAssertEqual(error as? ThemeCompilationError, .missingAsset(missing))
        }
    }

    func testUnsafeCSSFailsBeforeCompilation() {
        let theme = TestFixtures.theme(
            rawCSS: #".x { background: url(https://example.com/tracker.png); }"#
        )

        XCTAssertThrowsError(try ThemeCompiler().compile(theme)) { error in
            guard case let ThemeCompilationError.validationFailed(validation) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertTrue(validation.issues.contains { $0.code == .unsafeURL })
        }
    }

    func testVoiceStyleCompilesIntoIsolatedAvatarOverlayCSS() throws {
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.orbScale = 1.25
        voice.dark.hueRotation = -45
        voice.rawCSS = ".voice-extra { border-radius: 50%; }"
        var theme = TestFixtures.theme()
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertFalse(compiled.css.contains("--cts-voice-scale"))
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-scale: 1.25;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-hue: -45deg;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ".voice-extra { border-radius: 50%; }"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "html:root[data-codex-theme-switcher-theme]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "scale: var(--cts-voice-scale) !important;"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains("transform: scale(")
        )
    }

    func testDisabledVoiceStyleProducesNoAvatarOverlayCSS() throws {
        var theme = TestFixtures.theme()
        theme.voiceStyle = ThemeVoiceStyle(isEnabled: false)

        XCTAssertEqual(
            try ThemeCompiler().compile(theme).avatarOverlayCSS,
            ""
        )
    }

    func testVoiceAdvancedCSSCanReferencePortableAssets() throws {
        let asset = TestFixtures.imageAsset(
            name: "voice.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.rawCSS = #"""
        .voice-extra {
          background-image: theme-asset("\#(asset.id.uuidString)");
        }
        """#
        var theme = TestFixtures.theme(assets: [asset])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "codex-theme-asset://\(asset.id.uuidString.lowercased())"
            )
        )
        XCTAssertEqual(compiled.runtimeAssets, [asset])
    }

    func testVoiceBackgroundCompilesAsPortableOverlayOnlyAsset() throws {
        let asset = TestFixtures.imageAsset(
            name: "voice-background.png",
            bytes: [4, 5, 6]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.backgroundAssetID = asset.id
        voice.light.backgroundImageFit = .contain
        voice.light.backgroundPositionX = 0.2
        voice.light.backgroundPositionY = 0.8
        voice.light.backgroundZoom = 1.25
        voice.light.backgroundImageOpacity = 0.7
        voice.light.backgroundImageBlur = 4
        var theme = TestFixtures.theme(assets: [asset])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)
        let assetURL =
            "codex-theme-asset://\(asset.id.uuidString.lowercased())"

        XCTAssertFalse(compiled.css.contains(assetURL))
        XCTAssertTrue(compiled.avatarOverlayCSS.contains(assetURL))
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-background-size: contain;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-background-position: 20% 80%;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-background-scale: 1.25;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-background-opacity: 0.7;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-background-blur: 4px;"
            )
        )
        XCTAssertEqual(compiled.runtimeAssets, [asset])
    }

    func testVoiceOrbImageTargetsRealAvatarRootWithoutGenericSVG() throws {
        let outer = TestFixtures.imageAsset(
            name: "voice-background.png",
            bytes: [4, 5, 6]
        )
        let orb = TestFixtures.imageAsset(
            name: "voice-orb.png",
            bytes: [7, 8, 9]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.backgroundAssetID = outer.id
        voice.light.orbBackgroundAssetID = orb.id
        voice.light.orbBackgroundImageFit = .contain
        voice.light.orbBackgroundPositionX = 0.25
        voice.light.orbBackgroundPositionY = 0.75
        voice.light.orbBackgroundImageOpacity = 0.6
        voice.light.orbBackgroundImageBlur = 3
        voice.light.orbBackgroundInset = 8
        voice.light.orbBackgroundFollowsVoicePulse = true
        voice.light.orbBackgroundPulseStrength = 1.25
        var theme = TestFixtures.theme(assets: [outer, orb])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(".codex-avatar-root")
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ".codex-avatar-root,"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-size: contain;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-position: 25% 75%;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-opacity: 0.6;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-blur: 3px;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-inset: 8px;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-pulse-enabled: 1;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-pulse-strength: 1.25;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "scale: var(--cts-voice-orb-live-pulse, 1);"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(")::after {")
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                """
                  canvas,
                  svg,
                """
            )
        )
        XCTAssertFalse(compiled.css.contains("voice-orb.png"))
        XCTAssertEqual(Set(compiled.runtimeAssets.map(\.id)), [outer.id, orb.id])
    }

    func testEscaperHandlesIdentifiersStringsAndComments() {
        XCTAssertEqual(CSSEscaper.escapeIdentifier("9 lives"), "\\39 \\20 lives")
        XCTAssertEqual(CSSEscaper.escapeString("a\"b\\c\n"), "a\\\"b\\\\c\\a ")
        XCTAssertFalse(CSSEscaper.escapeComment("name */ body").contains("*/"))
    }
}
