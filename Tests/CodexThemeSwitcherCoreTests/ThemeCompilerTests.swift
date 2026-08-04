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

    func testVoiceStyleCompilesFullOverlayAndSafeEmbeddedOrbCSS() throws {
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.orbScale = 1.25
        voice.light.overlayMascotWidth = 339
        voice.light.orbLocksToOverlayCenter = false
        voice.dark.hueRotation = -45
        voice.dark.orbLocksToOverlayCenter = false
        voice.rawCSS = ".voice-extra { border-radius: 50%; }"
        var theme = TestFixtures.theme()
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(compiled.css.contains("--cts-voice-scale: 1.25;"))
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-overlay-mascot-width: 339px;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-overlay-mascot-height: 368px;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-overlay-anchor-width: min(113px, 339px);"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-overlay-anchor-height: min(122px, 368px);"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-lock-center: 0;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "data-codex-voice-activity-shelf"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "data-codex-voice-activity-backdrop"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "data-avatar-overlay-hit-region=\"notification-tray\""
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "height: var(--cts-voice-activity-tray-height) !important;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "top: var(--cts-voice-activity-tray-top) !important;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "var(--cts-voice-activity-visual-clip-top, 0px)"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "var(--cts-voice-activity-visual-clip-bottom, 0px)"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "pointer-events: auto !important;"
            )
        )
        XCTAssertFalse(compiled.avatarOverlayCSS.contains("top: 8px !important;"))
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "calc(100vh - var(--cts-voice-activity-shelf-height) - 8px)"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-activity-presentation-left"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-activity-presentation-scale"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-avatar-overlay-size=\"mascot\"]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "height: var(--cts-voice-overlay-anchor-height) !important;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-avatar-overlay-hit-region=\"mascot\"]"
            )
        )
        XCTAssertTrue(compiled.css.contains(".codex-avatar-root"))
        XCTAssertTrue(
            compiled.css.contains("/* Codex Theme Voice Embedded Orb */")
        )
        XCTAssertFalse(compiled.css.contains(".voice-extra"))
        XCTAssertFalse(compiled.css.contains("body::before"))
        XCTAssertFalse(
            compiled.css.contains(
                "[data-avatar-overlay-hit-region=\"mascot\"]"
            )
        )
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
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "scale(var(--cts-voice-scale));"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-layout-shift-x"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-layout-shift-y"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "left: 50vw !important;"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "top: 50vh !important;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-avatar-overlay-hit-region=\"mascot\"]"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-scale-shift-x"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                """
                [class*="voiceorb" i]
                ) {
                  scale: var(--cts-voice-scale) !important;
                """
            )
        )
    }

    func testCustomVoiceAvatarControlsDockToVisualBottom() throws {
        let portrait = TestFixtures.imageAsset(
            name: "portrait.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.avatarMode = .image
        voice.light.orbBackgroundAssetID = portrait.id
        voice.dark.avatarMode = .native
        voice.dark.orbBackgroundAssetID = nil
        var theme = TestFixtures.theme(assets: [portrait])
        theme.voiceStyle = voice

        let css = try ThemeCompiler().compile(theme).avatarOverlayCSS

        XCTAssertTrue(
            css.contains(
                ":has(> [data-avatar-overlay-native-surface-id=\"voice-microphone\"]),"
            )
        )
        XCTAssertTrue(
            css.contains(
                ":has(> [data-avatar-overlay-native-surface-id=\"voice-output\"])"
            )
        )
        XCTAssertTrue(css.contains("top: calc(100% - 41px) !important;"))
        XCTAssertTrue(
            css.contains(
                ":has(> [data-avatar-overlay-native-surface-id=\"voice-controls\"])"
            )
        )
        XCTAssertTrue(css.contains("top: calc(100% - 26px) !important;"))
        XCTAssertEqual(
            css.components(separatedBy: "top: calc(100% - 41px) !important;")
                .count - 1,
            2
        )
        XCTAssertEqual(
            css.components(separatedBy: "top: calc(100% - 26px) !important;")
                .count - 1,
            2
        )
    }

    func testCustomVoiceAvatarReportsVisualSizeToNativeOverlayLayout() throws {
        let portrait = TestFixtures.imageAsset(
            name: "portrait.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.avatarMode = .image
        voice.light.orbBackgroundAssetID = portrait.id
        voice.light.overlayMascotWidth = 339
        voice.dark.avatarMode = .native
        voice.dark.orbBackgroundAssetID = nil
        var theme = TestFixtures.theme(assets: [portrait])
        theme.voiceStyle = voice

        let css = try ThemeCompiler().compile(theme).avatarOverlayCSS

        // The node ChatGPT measures must match the custom visual. This is
        // what makes the native overlay window reserve space for its task
        // cards instead of placing them over the avatar.
        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-width: 339px;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-height: 368px;")
        )
        XCTAssertTrue(
            css.contains(
                "height: var(--cts-voice-overlay-anchor-height) !important;"
            )
        )
        XCTAssertFalse(
            css.contains("--cts-voice-overlay-anchor-width: min(113px, 339px);")
        )
    }

    func testCustomVoiceAvatarMeasurementIncludesVisualScale() throws {
        let portrait = TestFixtures.imageAsset(
            name: "portrait-scaled.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.avatarMode = .image
        voice.light.orbBackgroundAssetID = portrait.id
        voice.light.overlayMascotWidth = 113
        voice.light.orbScale = 2
        voice.dark.avatarMode = .native
        voice.dark.orbBackgroundAssetID = nil
        var theme = TestFixtures.theme(assets: [portrait])
        theme.voiceStyle = voice

        let css = try ThemeCompiler().compile(theme).avatarOverlayCSS

        // The custom image is transformed inside the mascot node. The size
        // node reported to ChatGPT must include that transform, otherwise
        // the host window clips the image back to the stock orb size.
        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-width: 226px;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-height: 246px;")
        )
    }

    func testCustomVoiceAvatarSupportsIndependentHeightScale() throws {
        let portrait = TestFixtures.imageAsset(
            name: "portrait-tall.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.avatarMode = .image
        voice.light.orbBackgroundAssetID = portrait.id
        voice.light.overlayMascotWidth = 113
        voice.light.overlayMascotHeightScale = 1.5
        voice.dark.avatarMode = .native
        voice.dark.orbBackgroundAssetID = nil
        var theme = TestFixtures.theme(assets: [portrait])
        theme.voiceStyle = voice

        let css = try ThemeCompiler().compile(theme).avatarOverlayCSS

        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-width: 113px;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-overlay-anchor-height: 185px;")
        )
    }

    func testVoiceOverlayCenteringFollowsExplicitAppearanceSetting() throws {
        let background = TestFixtures.imageAsset(
            name: "voice-background.png",
            bytes: [1, 2, 3]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.backgroundAssetID = nil
        voice.light.orbLocksToOverlayCenter = true
        voice.dark.backgroundAssetID = background.id
        voice.dark.orbLocksToOverlayCenter = false
        var theme = TestFixtures.theme(assets: [background])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)
        let centeringRule = "left: 50vw !important;"

        XCTAssertEqual(
            compiled.avatarOverlayCSS.components(
                separatedBy: centeringRule
            ).count - 1,
            2
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "@media (prefers-color-scheme: light)"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ":root:where(.electron-light)[data-codex-theme-switcher-theme]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "position: fixed !important;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ":has(> [data-avatar-overlay-hit-region=\"mascot\"]")
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                ":root:where(.electron-dark:not(.electron-light))[data-codex-theme-switcher-theme]\n        :has(> [data-avatar-overlay-hit-region=\"mascot\"]"
            )
        )
        XCTAssertFalse(compiled.css.contains(centeringRule))
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
        let outerURL =
            "codex-theme-asset://\(outer.id.uuidString.lowercased())"
        let orbURL =
            "codex-theme-asset://\(orb.id.uuidString.lowercased())"

        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(".codex-avatar-root")
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "data-codex-voice-session-active=\"false\""
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ".codex-avatar-root[data-codex-pet-id]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-testid=\"avatar-mascot-button\"]:has("
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-avatar-overlay-hit-region=\"mascot-badge\"]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                ".codex-avatar-root[data-realtime-voice-orb],"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "\n          .codex-avatar-root,"
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
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-position-x"
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-position-y"
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
                "--cts-voice-orb-image-enabled: 1;"
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
                """
                html:root[data-codex-theme-switcher-theme] :is(
                  .codex-avatar-root[data-realtime-voice-orb],
                  [data-voice-orb],
                  [data-codex-voice-orb],
                  [class*="voice-orb" i],
                  [class*="voiceorb" i]
                ) canvas {
                  opacity: var(--cts-voice-opacity) !important;
                  scale: var(--cts-voice-scale) !important;
                """
            )
        )
        XCTAssertFalse(
            compiled.avatarOverlayCSS.contains(
                """
                [class*="voiceorb" i]
                ) {
                  opacity: var(--cts-voice-opacity) !important;
                """
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "var(--cts-voice-orb-live-left, 15.625%)"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "var(--cts-voice-orb-live-height, 68.2692%)"
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
        XCTAssertFalse(compiled.css.contains(outerURL))
        XCTAssertTrue(compiled.css.contains(orbURL))
        XCTAssertFalse(compiled.css.contains("--cts-voice-background-image"))
        XCTAssertEqual(Set(compiled.runtimeAssets.map(\.id)), [outer.id, orb.id])
    }

    func testVoiceMouthFramesCompileAsPortableOrderedAssets() throws {
        let closed = TestFixtures.imageAsset(
            name: "mouth-closed.png",
            bytes: [1, 2, 3]
        )
        let medium = TestFixtures.imageAsset(
            name: "mouth-medium.png",
            bytes: [4, 5, 6]
        )
        let open = TestFixtures.imageAsset(
            name: "mouth-open.png",
            bytes: [7, 8, 9]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.orbBackgroundAssetID = closed.id
        voice.light.orbMouthFrameAssetIDs = [medium.id, open.id]
        voice.light.orbMouthSensitivity = 1.4
        voice.light.orbMouthAttackMilliseconds = 24
        voice.light.orbMouthReleaseMilliseconds = 110
        voice.light.orbMouthNoiseGate = 0.045
        voice.light.orbMouthResponseCurve = 0.65
        voice.light.orbMouthSmoothing = 0.6
        voice.light.orbMouthFrameHoldMilliseconds = 120
        var theme = TestFixtures.theme(assets: [open, closed, medium])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)
        let css = compiled.avatarOverlayCSS

        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-frame-count: 3;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-sensitivity: 1.4;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-attack-ms: 24;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-release-ms: 110;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-noise-gate: 0.045;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-response-curve: 0.65;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-smoothing: 0.6;")
        )
        XCTAssertTrue(
            css.contains("--cts-voice-orb-mouth-hold-ms: 120;")
        )
        XCTAssertTrue(
            css.contains(
                "--cts-voice-orb-active-image,"
            )
        )
        XCTAssertTrue(css.contains(")::before {"))
        XCTAssertTrue(
            css.contains("--cts-voice-orb-blink-opacity")
        )
        XCTAssertEqual(
            Set(compiled.runtimeAssets.map(\.id)),
            [closed.id, medium.id, open.id]
        )
    }

    func testVoiceIdleMotionAndBlinkCompileAsPortableSettings() throws {
        let portrait = TestFixtures.imageAsset(
            name: "portrait.png",
            bytes: [1, 2, 3]
        )
        let blink = TestFixtures.imageAsset(
            name: "portrait-closed-eyes.png",
            bytes: [4, 5, 6]
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.orbBackgroundAssetID = portrait.id
        voice.light.orbIdleMotionEnabled = true
        voice.light.orbIdleMotionStrength = 0.45
        voice.light.orbIdleMotionPeriodSeconds = 5.2
        voice.light.orbBlinkAssetID = blink.id
        voice.light.orbBlinkIntervalSeconds = 3.8
        voice.light.orbBlinkDurationMilliseconds = 160
        var theme = TestFixtures.theme(assets: [blink, portrait])
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)
        let css = compiled.avatarOverlayCSS

        XCTAssertTrue(css.contains("--cts-voice-orb-idle-enabled: 1;"))
        XCTAssertTrue(css.contains("--cts-voice-orb-idle-strength: 0.45;"))
        XCTAssertTrue(css.contains("--cts-voice-orb-idle-period-ms: 5200;"))
        XCTAssertTrue(css.contains("--cts-voice-orb-blink-enabled: 1;"))
        XCTAssertTrue(css.contains("--cts-voice-orb-blink-interval-ms: 3800;"))
        XCTAssertTrue(css.contains("--cts-voice-orb-blink-duration-ms: 160;"))
        XCTAssertTrue(css.contains("var(--cts-voice-orb-idle-x, 0px)"))
        XCTAssertTrue(css.contains("--cts-voice-orb-blink-image"))
        XCTAssertEqual(
            Set(compiled.runtimeAssets.map(\.id)),
            [portrait.id, blink.id]
        )
    }

    func testEscaperHandlesIdentifiersStringsAndComments() {
        XCTAssertEqual(CSSEscaper.escapeIdentifier("9 lives"), "\\39 \\20 lives")
        XCTAssertEqual(CSSEscaper.escapeString("a\"b\\c\n"), "a\\\"b\\\\c\\a ")
        XCTAssertFalse(CSSEscaper.escapeComment("name */ body").contains("*/"))
    }

    func testLive2DVoiceCompilesModelResourcesAndKeepsFlatRendererData() throws {
        let settings = ThemeAsset(
            name: "avatar.model3.json",
            mediaType: "application/json",
            data: Data("{}".utf8)
        )
        let moc = ThemeAsset(
            name: "avatar.moc3",
            mediaType: "application/octet-stream",
            data: Data([0x4D, 0x4F, 0x43, 0x33])
        )
        let texture = TestFixtures.imageAsset(
            name: "textures/texture_00.png"
        )
        let flat = TestFixtures.imageAsset(name: "flat.png")
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.avatarMode = .live2D
        voice.light.live2DModel = ThemeLive2DModel(
            modelSettingsPath: settings.name,
            resources: [
                .init(path: settings.name, assetID: settings.id),
                .init(path: moc.name, assetID: moc.id),
                .init(path: texture.name, assetID: texture.id)
            ]
        )
        voice.light.orbBackgroundAssetID = flat.id
        voice.dark.avatarMode = .image
        voice.dark.orbBackgroundAssetID = flat.id
        var theme = TestFixtures.theme(
            assets: [settings, moc, texture, flat]
        )
        theme.voiceStyle = voice

        let compiled = try ThemeCompiler().compile(theme)

        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-avatar-mode: live2D;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-avatar-mode: image;"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-live2d-manifest:"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-codex-live2d-avatar]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "[data-codex-live2d-loading=\"true\"]"
            )
        )
        XCTAssertTrue(
            compiled.avatarOverlayCSS.contains(
                "--cts-voice-orb-background-image:"
            )
        )
        XCTAssertEqual(
            Set(compiled.runtimeAssets.map(\.id)),
            Set([settings.id, moc.id, texture.id, flat.id])
        )
    }
}
