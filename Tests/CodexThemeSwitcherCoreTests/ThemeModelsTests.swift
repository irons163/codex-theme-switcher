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
        XCTAssertEqual(skin.glass, expectedGlass)
        XCTAssertEqual(skin.targets, expectedTargets)

        let allDefaults = try JSONDecoder().decode(
            ThemeImageSkin.self,
            from: Data("{}".utf8)
        )
        XCTAssertEqual(allDefaults, ThemeImageSkin())
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
