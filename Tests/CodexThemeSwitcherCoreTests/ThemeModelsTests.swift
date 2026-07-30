import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeModelsTests: XCTestCase {
    func testLegacySchemaOneDocumentWithoutImageSkinDecodes() throws {
        let legacyJSON = """
        {
          "schemaVersion": 1,
          "id": "00000000-0000-0000-0000-000000000101",
          "metadata": {
            "name": "Legacy Theme",
            "author": "Legacy Author",
            "description": "Created before image skins.",
            "version": "1.0.0",
            "tags": ["legacy"],
            "createdAt": 0,
            "updatedAt": 0
          },
          "layers": [],
          "assets": []
        }
        """

        let decoded = try JSONDecoder().decode(
            ThemeDocument.self,
            from: Data(legacyJSON.utf8)
        )

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.metadata.name, "Legacy Theme")
        XCTAssertNil(decoded.imageSkin)
    }

    func testNilImageSkinIsOmittedFromEncodedDocument() throws {
        let data = try JSONEncoder().encode(TestFixtures.theme())
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertNil(object["imageSkin"])
    }

    func testDocumentRoundTripsWithInlineAsset() throws {
        let bytes = Data([0x00, 0x10, 0x20, 0xFF])
        let asset = ThemeAsset(
            name: "texture.png",
            mediaType: "image/png",
            data: bytes
        )
        let original = TestFixtures.theme(assets: [asset])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeDocument.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.assets.first?.decodedData, bytes)
    }

    func testDocumentRoundTripsCompleteImageSkinAndBothAssets() throws {
        let light = TestFixtures.imageAsset(
            name: "light.webp",
            mediaType: "image/webp",
            bytes: [0x10, 0x20, 0x30]
        )
        let dark = TestFixtures.imageAsset(
            name: "dark.jpg",
            mediaType: "image/jpeg",
            bytes: [0x40, 0x50, 0x60]
        )
        var imageSkin = TestFixtures.imageSkin(
            lightAssetID: light.id,
            darkAssetID: dark.id
        )
        imageSkin.wallpaperScope = .mainContent
        let original = TestFixtures.theme(
            assets: [light, dark],
            imageSkin: imageSkin
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeDocument.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.imageSkin?.wallpaperScope, .mainContent)
        XCTAssertEqual(decoded.imageSkin?.light.backgroundAssetID, light.id)
        XCTAssertEqual(decoded.imageSkin?.dark.backgroundAssetID, dark.id)
        XCTAssertEqual(decoded.assets.map(\.decodedData), [
            Data([0x10, 0x20, 0x30]),
            Data([0x40, 0x50, 0x60])
        ])
    }

    func testImageSkinNestedObjectsDecodeMissingFieldsWithDefaults() throws {
        let skin = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data(#"""
            {
              "isEnabled": false,
              "light": { "backgroundColor": "#123456" },
              "glass": { "blurRadius": 7 },
              "targets": { "cards": false }
            }
            """#.utf8)
        )

        var expectedLight = ThemeSkinVariant.lightDefault
        expectedLight.backgroundColor = "#123456"
        var expectedGlass = ThemeSkinGlass()
        expectedGlass.blurRadius = 7
        var expectedTargets = ThemeSkinTargets()
        expectedTargets.cards = false

        XCTAssertFalse(skin.isEnabled)
        XCTAssertEqual(skin.wallpaperScope, .fullWindow)
        XCTAssertEqual(skin.light, expectedLight)
        XCTAssertEqual(skin.dark, .darkDefault)
        XCTAssertEqual(skin.centerPanel, ThemeSkinCenterPanel())
        XCTAssertEqual(skin.glass, expectedGlass)
        XCTAssertEqual(skin.targets, expectedTargets)

        let allDefaults = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data("{}".utf8)
        )
        XCTAssertEqual(allDefaults, ThemeImageSkin())
    }

    func testCenterPanelPartialSettingsUseAppearanceSpecificDefaults() throws {
        let skin = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data(#"""
            {
              "light": {
                "centerPanelOpacity": 0.71,
                "centerPanelBorderColor": "#F0E0D0"
              },
              "dark": {
                "centerPanelTint": "#020304",
                "centerPanelShadowOpacity": 0.44
              },
              "centerPanel": {
                "isEnabled": true,
                "cornerRadius": 31,
                "maximumWidth": 920
              }
            }
            """#.utf8)
        )

        XCTAssertTrue(skin.centerPanel.isEnabled)
        XCTAssertEqual(skin.centerPanel.cornerRadius, 31)
        XCTAssertEqual(skin.centerPanel.maximumWidth, 920)
        XCTAssertEqual(
            skin.centerPanel.backdropBlur,
            ThemeSkinCenterPanel().backdropBlur
        )
        XCTAssertEqual(skin.light.centerPanelOpacity, 0.71)
        XCTAssertEqual(skin.light.centerPanelBorderColor, "#F0E0D0")
        XCTAssertEqual(
            skin.light.centerPanelTint,
            ThemeSkinVariant.lightDefault.centerPanelTint
        )
        XCTAssertEqual(skin.dark.centerPanelTint, "#020304")
        XCTAssertEqual(skin.dark.centerPanelShadowOpacity, 0.44)
        XCTAssertEqual(
            skin.dark.centerPanelBorderColor,
            ThemeSkinVariant.darkDefault.centerPanelBorderColor
        )
    }

    func testComposerActionColorsRoundTripAndLegacyValuesRemainAutomatic() throws {
        var skin = ThemeImageSkin()
        skin.light.composerActionBackgroundColor = "#123456"
        skin.light.composerActionIconColor = "#ABCDEF80"
        skin.dark.composerActionBackgroundColor = "#654321"
        skin.dark.composerActionIconColor = "#FEDCBA"

        let data = try JSONEncoder().encode(skin)
        let decoded = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: data
        )

        XCTAssertEqual(decoded, skin)
        XCTAssertEqual(
            decoded.light.composerActionBackgroundColor,
            "#123456"
        )
        XCTAssertEqual(decoded.light.composerActionIconColor, "#ABCDEF80")
        XCTAssertEqual(
            decoded.dark.composerActionBackgroundColor,
            "#654321"
        )
        XCTAssertEqual(decoded.dark.composerActionIconColor, "#FEDCBA")

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let light = try XCTUnwrap(object["light"] as? [String: Any])
        let dark = try XCTUnwrap(object["dark"] as? [String: Any])
        XCTAssertEqual(
            light["composerActionBackgroundColor"] as? String,
            "#123456"
        )
        XCTAssertEqual(
            light["composerActionIconColor"] as? String,
            "#ABCDEF80"
        )
        XCTAssertEqual(
            dark["composerActionBackgroundColor"] as? String,
            "#654321"
        )
        XCTAssertEqual(
            dark["composerActionIconColor"] as? String,
            "#FEDCBA"
        )

        let legacy = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data(#"""
            {
              "light": {
                "primaryTextColor": "#102030",
                "cardTint": "#405060",
                "cardOpacity": 0.37
              },
              "dark": {
                "primaryTextColor": "#E0D0C0",
                "cardTint": "#302010",
                "cardOpacity": 0.63
              }
            }
            """#.utf8)
        )

        XCTAssertNil(legacy.light.composerActionBackgroundColor)
        XCTAssertNil(legacy.light.composerActionIconColor)
        XCTAssertNil(legacy.dark.composerActionBackgroundColor)
        XCTAssertNil(legacy.dark.composerActionIconColor)
    }

    func testWallpaperScopeUsesStableValuesAndFutureSafeFallback() throws {
        let cases: [
            (
                scope: ThemeSkinWallpaperScope,
                rawValue: String
            )
        ] = [
            (.fullWindow, "fullWindow"),
            (.mainContent, "mainContent")
        ]

        XCTAssertEqual(ThemeSkinWallpaperScope.allCases.count, cases.count)
        for item in cases {
            var skin = ThemeImageSkin()
            skin.wallpaperScope = item.scope
            let data = try JSONEncoder().encode(skin)
            let object = try XCTUnwrap(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            XCTAssertEqual(object["wallpaperScope"] as? String, item.rawValue)
            XCTAssertEqual(
                try JSONDecoder()
                    .decode(ThemeImageSkin.self, from: data)
                    .wallpaperScope,
                item.scope
            )
        }

        for value in ["null", #""futureFloatingPane""#] {
            let skin = try JSONDecoder().decode(
                ThemeImageSkin.self,
                from: Data(
                    #"{"wallpaperScope":\#(value)}"#.utf8
                )
            )
            XCTAssertEqual(skin.wallpaperScope, .fullWindow)
        }
    }

    func testEveryImageFitCaseRoundTripsItsStableRawValue() throws {
        let cases: [(fit: ThemeSkinImageFit, rawValue: String)] = [
            (.cover, "cover"),
            (.contain, "contain"),
            (.fill, "fill"),
            (.fitWidth, "fitWidth"),
            (.fitHeight, "fitHeight"),
            (.original, "original"),
            (.tile, "tile")
        ]

        XCTAssertEqual(ThemeSkinImageFit.allCases.count, cases.count)
        for item in cases {
            let data = try JSONEncoder().encode(item.fit)
            XCTAssertEqual(
                String(decoding: data, as: UTF8.self),
                "\"\(item.rawValue)\""
            )
            XCTAssertEqual(
                try JSONDecoder().decode(
                    ThemeSkinImageFit.self,
                    from: data
                ),
                item.fit
            )
        }
    }

    func testLegacyImageFitRawValuesRemainDecodable() throws {
        let legacyCases: [(rawValue: String, fit: ThemeSkinImageFit)] = [
            ("cover", .cover),
            ("contain", .contain),
            ("fill", .fill),
            ("tile", .tile)
        ]

        for item in legacyCases {
            XCTAssertEqual(
                try JSONDecoder().decode(
                    ThemeSkinImageFit.self,
                    from: Data("\"\(item.rawValue)\"".utf8)
                ),
                item.fit
            )
        }
    }

    func testUnknownImageFitFallsBackToAppearanceSpecificDefault() throws {
        let skin = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data(#"""
            {
              "light": {
                "imageFit": "futurePanoramaFit",
                "backgroundColor": "#FEFDFC"
              },
              "dark": {
                "imageFit": "futurePortraitFit",
                "backgroundColor": "#010203"
              }
            }
            """#.utf8)
        )

        XCTAssertEqual(
            skin.light.imageFit,
            ThemeSkinVariant.lightDefault.imageFit
        )
        XCTAssertEqual(
            skin.dark.imageFit,
            ThemeSkinVariant.darkDefault.imageFit
        )
        XCTAssertEqual(skin.light.backgroundColor, "#FEFDFC")
        XCTAssertEqual(skin.dark.backgroundColor, "#010203")
    }

    func testVoiceStyleRoundTripsAndPartialVariantsUseAppearanceDefaults() throws {
        let decoded = try JSONDecoder().decode(
            ThemeVoiceStyle.self,
            from: Data(#"""
            {
              "isEnabled": true,
              "light": {
                "backgroundAssetID": "72df1136-dbab-482a-8e52-f8bd743102c4",
                "backgroundImageFit": "contain",
                "backgroundPositionX": 0.2,
                "backgroundPositionY": 0.8,
                "backgroundZoom": 1.4,
                "backgroundImageOpacity": 0.75,
                "backgroundImageBlur": 3,
                "orbBackgroundAssetID": "48f4ae9a-d231-4c56-9a76-e43d61ec7929",
                "orbBackgroundImageFit": "fitWidth",
                "orbBackgroundPositionX": 0.3,
                "orbBackgroundPositionY": 0.7,
                "orbBackgroundImageOpacity": 0.65,
                "orbBackgroundImageBlur": 2,
                "orbBackgroundInset": 6,
                "orbBackgroundFollowsVoicePulse": false,
                "orbBackgroundPulseStrength": 1.35,
                "orbMouthFrameAssetIDs": [
                  "adcb6bb4-d138-41a5-86d6-ae583c66d9db",
                  "041873a8-4c44-4928-bc55-f737580aca70"
                ],
                "orbMouthSensitivity": 1.5,
                "orbMouthAttackMilliseconds": 22,
                "orbMouthReleaseMilliseconds": 115,
                "orbMouthNoiseGate": 0.04,
                "orbMouthResponseCurve": 0.68,
                "orbMouthSmoothing": 0.61,
                "orbMouthFrameHoldMilliseconds": 130,
                "orbIdleMotionEnabled": true,
                "orbIdleMotionStrength": 0.45,
                "orbIdleMotionPeriodSeconds": 5.2,
                "orbBlinkAssetID": "21eca502-1bda-4eb4-a1ad-aa7ba09f9be2",
                "orbBlinkIntervalSeconds": 3.8,
                "orbBlinkDurationMilliseconds": 160,
                "orbScale": 1.25
              },
              "dark": { "glowOpacity": 0.8 },
              "rawCSS": ".custom-voice { opacity: .9; }"
            }
            """#.utf8)
        )

        XCTAssertTrue(decoded.isEnabled)
        XCTAssertEqual(
            decoded.light.backgroundAssetID?.uuidString.lowercased(),
            "72df1136-dbab-482a-8e52-f8bd743102c4"
        )
        XCTAssertEqual(decoded.light.backgroundImageFit, .contain)
        XCTAssertEqual(decoded.light.backgroundPositionX, 0.2)
        XCTAssertEqual(decoded.light.backgroundPositionY, 0.8)
        XCTAssertEqual(decoded.light.backgroundZoom, 1.4)
        XCTAssertEqual(decoded.light.backgroundImageOpacity, 0.75)
        XCTAssertEqual(decoded.light.backgroundImageBlur, 3)
        XCTAssertEqual(
            decoded.light.orbBackgroundAssetID?.uuidString.lowercased(),
            "48f4ae9a-d231-4c56-9a76-e43d61ec7929"
        )
        XCTAssertEqual(decoded.light.orbBackgroundImageFit, .fitWidth)
        XCTAssertEqual(decoded.light.orbBackgroundPositionX, 0.3)
        XCTAssertEqual(decoded.light.orbBackgroundPositionY, 0.7)
        XCTAssertEqual(decoded.light.orbBackgroundImageOpacity, 0.65)
        XCTAssertEqual(decoded.light.orbBackgroundImageBlur, 2)
        XCTAssertEqual(decoded.light.orbBackgroundInset, 6)
        XCTAssertFalse(decoded.light.orbBackgroundFollowsVoicePulse)
        XCTAssertEqual(decoded.light.orbBackgroundPulseStrength, 1.35)
        XCTAssertEqual(
            decoded.light.orbMouthFrameAssetIDs.map {
                $0.uuidString.lowercased()
            },
            [
                "adcb6bb4-d138-41a5-86d6-ae583c66d9db",
                "041873a8-4c44-4928-bc55-f737580aca70"
            ]
        )
        XCTAssertEqual(decoded.light.orbMouthSensitivity, 1.5)
        XCTAssertEqual(decoded.light.orbMouthAttackMilliseconds, 22)
        XCTAssertEqual(decoded.light.orbMouthReleaseMilliseconds, 115)
        XCTAssertEqual(decoded.light.orbMouthNoiseGate, 0.04)
        XCTAssertEqual(decoded.light.orbMouthResponseCurve, 0.68)
        XCTAssertEqual(decoded.light.orbMouthSmoothing, 0.61)
        XCTAssertEqual(decoded.light.orbMouthFrameHoldMilliseconds, 130)
        XCTAssertTrue(decoded.light.orbIdleMotionEnabled)
        XCTAssertEqual(decoded.light.orbIdleMotionStrength, 0.45)
        XCTAssertEqual(decoded.light.orbIdleMotionPeriodSeconds, 5.2)
        XCTAssertEqual(
            decoded.light.orbBlinkAssetID?.uuidString.lowercased(),
            "21eca502-1bda-4eb4-a1ad-aa7ba09f9be2"
        )
        XCTAssertEqual(decoded.light.orbBlinkIntervalSeconds, 3.8)
        XCTAssertEqual(decoded.light.orbBlinkDurationMilliseconds, 160)
        XCTAssertEqual(decoded.light.orbScale, 1.25)
        XCTAssertEqual(
            decoded.light.glowColor,
            ThemeVoiceVariant.lightDefault.glowColor
        )
        XCTAssertEqual(decoded.dark.glowOpacity, 0.8)
        XCTAssertEqual(
            decoded.dark.glowColor,
            ThemeVoiceVariant.darkDefault.glowColor
        )
        XCTAssertNil(decoded.dark.backgroundAssetID)
        XCTAssertNil(decoded.dark.orbBackgroundAssetID)
        XCTAssertEqual(decoded.dark.backgroundImageFit, .cover)
        XCTAssertEqual(decoded.dark.orbBackgroundImageFit, .cover)
        XCTAssertEqual(decoded.dark.orbBackgroundInset, 4)
        XCTAssertTrue(decoded.dark.orbBackgroundFollowsVoicePulse)
        XCTAssertEqual(decoded.dark.orbBackgroundPulseStrength, 1)
        XCTAssertTrue(decoded.dark.orbMouthFrameAssetIDs.isEmpty)
        XCTAssertEqual(decoded.dark.orbMouthSensitivity, 1)
        XCTAssertEqual(decoded.dark.orbMouthAttackMilliseconds, 18)
        XCTAssertEqual(decoded.dark.orbMouthReleaseMilliseconds, 72)
        XCTAssertEqual(decoded.dark.orbMouthNoiseGate, 0.05)
        XCTAssertEqual(decoded.dark.orbMouthResponseCurve, 0.9)
        XCTAssertEqual(decoded.dark.orbMouthSmoothing, 0.72)
        XCTAssertEqual(decoded.dark.orbMouthFrameHoldMilliseconds, 80)
        XCTAssertFalse(decoded.dark.orbIdleMotionEnabled)
        XCTAssertEqual(decoded.dark.orbIdleMotionStrength, 0.35)
        XCTAssertEqual(decoded.dark.orbIdleMotionPeriodSeconds, 4.8)
        XCTAssertNil(decoded.dark.orbBlinkAssetID)
        XCTAssertEqual(decoded.dark.orbBlinkIntervalSeconds, 4.2)
        XCTAssertEqual(decoded.dark.orbBlinkDurationMilliseconds, 140)

        var theme = TestFixtures.theme()
        theme.voiceStyle = decoded
        let data = try JSONEncoder().encode(theme)
        XCTAssertEqual(
            try JSONDecoder().decode(ThemeDocument.self, from: data),
            theme
        )
    }

    func testNilVoiceStyleIsOmittedFromEncodedDocument() throws {
        let data = try JSONEncoder().encode(TestFixtures.theme())
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertNil(object["voiceStyle"])
    }

    func testSemanticRoleOverridesManualVariableName() {
        let variable = ThemeVariable(
            name: "--ignored",
            value: "#fff",
            semanticRole: .textPrimary
        )

        XCTAssertEqual(
            variable.resolvedName,
            "--codex-theme-text-primary"
        )
    }

    func testBuiltInThemesHaveStableUniqueIDsAndValidate() {
        XCTAssertEqual(BuiltInThemes.all.count, 3)
        XCTAssertEqual(Set(BuiltInThemes.all.map(\.id)).count, 3)

        let validator = ThemeValidator()
        for theme in BuiltInThemes.all {
            XCTAssertTrue(
                validator.validate(theme).isValid,
                "\(theme.metadata.name) should be valid: \(validator.validate(theme).issues)"
            )
            XCTAssertEqual(BuiltInThemes.theme(id: theme.id), theme)
        }
    }

    func testSummaryReflectsDocumentMetadata() {
        let theme = TestFixtures.theme()
        let summary = ThemeSummary(document: theme, isBuiltIn: false)

        XCTAssertEqual(summary.id, theme.id)
        XCTAssertEqual(summary.name, "Test Theme")
        XCTAssertEqual(summary.author, "Theme Tester")
        XCTAssertEqual(summary.updatedAt, TestFixtures.date)
        XCTAssertFalse(summary.isBuiltIn)
    }
}
