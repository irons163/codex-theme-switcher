import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeValidatorTests: XCTestCase {
    private let validator = ThemeValidator()

    func testAllowsDataRelativeAndLocalFontSources() {
        let theme = TestFixtures.theme(
            rawCSS: """
            .photo { background-image: url(data:image/png;base64,AA==); }
            .texture { background-image: url("./texture.png"); }
            @font-face {
              font-family: "Local Test";
              src: local("Inter"), url(/fonts/test.woff2);
            }
            """
        )

        let result = validator.validate(theme)

        XCTAssertTrue(result.isValid, "\(result.issues)")
        XCTAssertFalse(result.issues.contains { $0.code == .unsafeURL })
    }

    func testRejectsImportRulesIncludingEscapedImport() {
        let direct = validator.validate(
            TestFixtures.theme(rawCSS: #"@import "theme.css";"#)
        )
        let escaped = validator.validate(
            TestFixtures.theme(rawCSS: #"@\69mport "theme.css";"#)
        )

        XCTAssertTrue(direct.issues.contains { $0.code == .unsafeImport })
        XCTAssertTrue(escaped.issues.contains { $0.code == .unsafeImport })
    }

    func testRejectsExternalFileAndProtocolRelativeURLs() {
        let samples = [
            #"body { background: url("https://example.com/a.png"); }"#,
            #"body { background: url(http://example.com/a.png); }"#,
            #"body { background: url(file:///tmp/a.png); }"#,
            #"body { background: url(//example.com/a.png); }"#,
            #"body { background: url(ftp://example.com/a.png); }"#
        ]

        for css in samples {
            let result = validator.validate(TestFixtures.theme(rawCSS: css))
            XCTAssertTrue(
                result.issues.contains { $0.code == .unsafeURL },
                "Expected unsafe URL for \(css)"
            )
        }
    }

    func testRejectsCommentAndEscapeObfuscatedExternalURL() {
        let theme = TestFixtures.theme(
            rawCSS: #".x { background: u/**/rl("\68ttps://example.com/a.png"); }"#
        )

        let result = validator.validate(theme)

        XCTAssertTrue(result.issues.contains { $0.code == .unsafeURL })
    }

    func testRejectsEscapedImportAndExternalURLInjectedThroughSelectors() {
        let maliciousSelector =
            #"@\69mport u/**/rl("\68ttps://tracker.invalid/theme.css"); :root"#
        var theme = TestFixtures.theme()
        theme.layers[0].components[0].selectors = [maliciousSelector]
        theme.layers[0].rules[0].selector = maliciousSelector

        let result = validator.validate(theme)

        XCTAssertTrue(
            result.issues.contains {
                $0.path.contains(".selectors[0]")
                    && $0.code == .unsafeImport
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.path.contains(".selectors[0]")
                    && $0.code == .unsafeURL
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.path.hasSuffix(".selector")
                    && $0.code == .unsafeImport
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.path.hasSuffix(".selector")
                    && $0.code == .unsafeURL
            }
        )
    }

    func testValidatesVariablesDeclarationsAndAssets() {
        let duplicate = UUID()
        let invalidAsset = ThemeAsset(
            id: duplicate,
            name: "",
            mediaType: "not a type",
            dataBase64: "%%%not-base64%%%"
        )
        let theme = ThemeDocument(
            metadata: ThemeMetadata(name: ""),
            layers: [
                ThemeLayer(
                    id: duplicate,
                    name: "",
                    condition: .custom,
                    mediaQuery: "{bad}",
                    variables: [
                        ThemeVariable(name: "accent", value: "")
                    ],
                    rules: [
                        ThemeCSSRule(
                            name: "Broken",
                            selector: "{body}",
                            declarations: [
                                ThemeCSSDeclaration(
                                    property: "bad property",
                                    value: ""
                                )
                            ]
                        )
                    ]
                )
            ],
            assets: [invalidAsset]
        )

        let codes = Set(validator.validate(theme).issues.map(\.code))

        XCTAssertTrue(codes.contains(.emptyThemeName))
        XCTAssertTrue(codes.contains(.emptyLayerName))
        XCTAssertTrue(codes.contains(.duplicateIdentifier))
        XCTAssertTrue(codes.contains(.invalidVariableName))
        XCTAssertTrue(codes.contains(.emptyVariableValue))
        XCTAssertTrue(codes.contains(.invalidMediaQuery))
        XCTAssertTrue(codes.contains(.invalidSelector))
        XCTAssertTrue(codes.contains(.invalidDeclarationProperty))
        XCTAssertTrue(codes.contains(.emptyDeclarationValue))
        XCTAssertTrue(codes.contains(.invalidAssetName))
        XCTAssertTrue(codes.contains(.invalidAssetMediaType))
        XCTAssertTrue(codes.contains(.invalidAssetData))
    }

    func testAssetLimitsAreConfigurable() {
        let validator = ThemeValidator(
            configuration: .init(
                maximumAssetBytes: 2,
                maximumTotalAssetBytes: 3,
                maximumCSSCharacters: 10_000
            )
        )
        let assets = [
            ThemeAsset(name: "one.bin", mediaType: "application/octet-stream", data: Data([1, 2, 3])),
            ThemeAsset(name: "two.bin", mediaType: "application/octet-stream", data: Data([4, 5]))
        ]

        let result = validator.validate(TestFixtures.theme(assets: assets))
        let codes = Set(result.issues.map(\.code))

        XCTAssertTrue(codes.contains(.assetTooLarge))
        XCTAssertTrue(codes.contains(.totalAssetsTooLarge))
    }

    func testImageSkinRejectsMissingAndNonImageAssetReferences() {
        let missing = UUID()
        let font = ThemeAsset(
            name: "display.woff2",
            mediaType: "font/woff2",
            data: Data([1, 2, 3])
        )
        let theme = TestFixtures.theme(
            assets: [font],
            imageSkin: TestFixtures.imageSkin(
                lightAssetID: missing,
                darkAssetID: font.id
            )
        )

        let result = validator.validate(theme)

        XCTAssertTrue(
            result.issues.contains {
                $0.code == .missingSkinAsset
                    && $0.path == "imageSkin.light.backgroundAssetID"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinAssetType
                    && $0.path == "imageSkin.dark.backgroundAssetID"
            }
        )
    }

    func testImageSkinRejectsUnsafeAndStructurallyInvalidColorValues() {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.light.overlayColor =
            #"red; background: u/**/rl("\68ttps://tracker.invalid/pixel")"#
        skin.dark.accentColor = #"@\69mport "tracker.css""#
        skin.light.centerPanelBorderColor = "red; border: 8px"
        skin.dark.centerPanelShadowColor =
            #"u\72l("https://tracker.invalid/shadow")"#
        let result = validator.validate(
            TestFixtures.theme(imageSkin: skin)
        )

        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinCSSValue
                    && $0.path == "imageSkin.light.overlayColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .unsafeURL
                    && $0.path == "imageSkin.light.overlayColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .unsafeImport
                    && $0.path == "imageSkin.dark.accentColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinCSSValue
                    && $0.path
                        == "imageSkin.light.centerPanelBorderColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .unsafeURL
                    && $0.path
                        == "imageSkin.dark.centerPanelShadowColor"
            }
        )
    }

    func testImageSkinValidatesOptionalComposerActionColors() {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.light.composerActionBackgroundColor =
            "red; outline: 10px solid blue"
        skin.dark.composerActionIconColor =
            #"u\72l("https://tracker.invalid/action-icon")"#

        let result = validator.validate(
            TestFixtures.theme(imageSkin: skin)
        )

        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinCSSValue
                    && $0.path
                        == "imageSkin.light.composerActionBackgroundColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .unsafeURL
                    && $0.path
                        == "imageSkin.dark.composerActionIconColor"
            }
        )
    }

    func testImageSkinRejectsImportantCommentsAndUnsupportedHEIC() {
        let heic = ThemeAsset(
            name: "wallpaper.heic",
            mediaType: "image/heic",
            data: Data([1, 2, 3])
        )
        var skin = TestFixtures.imageSkin(
            lightAssetID: heic.id,
            darkAssetID: nil
        )
        skin.light.overlayColor = "red !important"
        skin.dark.accentColor = "/* hidden */ #fff"

        let result = ThemeValidator().validate(
            TestFixtures.theme(
                assets: [heic],
                imageSkin: skin
            )
        )

        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinAssetType
                    && $0.path == "imageSkin.light.backgroundAssetID"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinCSSValue
                    && $0.path == "imageSkin.light.overlayColor"
            }
        )
        XCTAssertTrue(
            result.issues.contains {
                $0.code == .invalidSkinCSSValue
                    && $0.path == "imageSkin.dark.accentColor"
            }
        )
    }

    func testImageSkinRejectsNonFiniteAndOutOfRangeNumbers() {
        var skin = TestFixtures.imageSkin(
            lightAssetID: nil,
            darkAssetID: nil
        )
        skin.light.positionX = -0.01
        skin.light.imageOpacity = .infinity
        skin.dark.zoom = 3.01
        skin.dark.imageBlur = -0.01
        skin.light.centerPanelOpacity = 1.01
        skin.dark.centerPanelShadowOpacity = .nan
        skin.glass.blurRadius = 80.01
        skin.glass.shadowOpacity = -0.01
        skin.centerPanel.maximumWidth = 319.99
        skin.centerPanel.horizontalPadding = 120.01
        skin.centerPanel.shadowOffsetX = -.infinity

        let result = validator.validate(
            TestFixtures.theme(imageSkin: skin)
        )
        let paths = Set(
            result.issues
                .filter { $0.code == .invalidSkinNumber }
                .map(\.path)
        )

        XCTAssertTrue(paths.contains("imageSkin.light.positionX"))
        XCTAssertTrue(paths.contains("imageSkin.light.imageOpacity"))
        XCTAssertTrue(paths.contains("imageSkin.dark.zoom"))
        XCTAssertTrue(paths.contains("imageSkin.dark.imageBlur"))
        XCTAssertTrue(paths.contains("imageSkin.light.centerPanelOpacity"))
        XCTAssertTrue(
            paths.contains("imageSkin.dark.centerPanelShadowOpacity")
        )
        XCTAssertTrue(paths.contains("imageSkin.glass.blurRadius"))
        XCTAssertTrue(paths.contains("imageSkin.glass.shadowOpacity"))
        XCTAssertTrue(paths.contains("imageSkin.centerPanel.maximumWidth"))
        XCTAssertTrue(
            paths.contains("imageSkin.centerPanel.horizontalPadding")
        )
        XCTAssertTrue(paths.contains("imageSkin.centerPanel.shadowOffsetX"))
    }
}
