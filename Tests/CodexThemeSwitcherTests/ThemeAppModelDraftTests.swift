import CodexThemeSwitcherCore
import Foundation
import ImageIO
import XCTest
@testable import CodexThemeSwitcher

final class ThemeAppModelDraftTests: XCTestCase {
    private var voiceDefaultsDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples")
            .appendingPathComponent("voice-mouth-sprites")
    }

    @MainActor
    func testLive2DImportCollectsReferencedCubismFilesWithRelativePaths()
        throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherLive2DImport-\(UUID().uuidString)",
                isDirectory: true
            )
        let textures = root.appendingPathComponent(
            "textures",
            isDirectory: true
        )
        let motions = root.appendingPathComponent(
            "motions",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: textures,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: motions,
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        let settingsURL = root.appendingPathComponent(
            "avatar.model3.json"
        )
        let settings = """
        {
          "Version": 3,
          "FileReferences": {
            "Moc": "avatar.moc3",
            "Textures": ["textures/texture_00.png"],
            "Physics": "avatar.physics3.json",
            "Motions": {
              "Idle": [{"File": "motions/idle.motion3.json"}],
              "Tap": [{
                "File": "motions/missing.motion3.json",
                "Sound": "../shared/missing.mp3"
              }]
            }
          }
        }
        """
        try Data(settings.utf8).write(to: settingsURL)
        try Data([0x4D, 0x4F, 0x43, 0x33]).write(
            to: root.appendingPathComponent("avatar.moc3")
        )
        try Data([0x89, 0x50, 0x4E, 0x47]).write(
            to: textures.appendingPathComponent("texture_00.png")
        )
        try Data("{}".utf8).write(
            to: root.appendingPathComponent("avatar.physics3.json")
        )
        try Data("{}".utf8).write(
            to: motions.appendingPathComponent("idle.motion3.json")
        )
        let model = ThemeAppModel(
            repository: FileThemeRepository(
                rootDirectory: root.appendingPathComponent("repository")
            ),
            runtime: nil
        )

        let imported = try model.makeLive2DModel(from: settingsURL)

        XCTAssertEqual(
            Set(imported.model.resources.map(\.path)),
            Set([
                "avatar.model3.json",
                "avatar.moc3",
                "avatar.physics3.json",
                "motions/idle.motion3.json",
                "textures/texture_00.png"
            ])
        )
        XCTAssertEqual(imported.assets.count, 5)
        XCTAssertEqual(
            imported.assets.first {
                $0.name == "avatar.model3.json"
            }?.mediaType,
            "application/json"
        )
        XCTAssertEqual(
            Set(imported.model.resources.map(\.assetID)),
            Set(imported.assets.map(\.id))
        )
    }

    func testVoiceDefaultsPreferPackagedAppResources() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherPackagedVoiceDefaults-\(UUID().uuidString)",
                isDirectory: true
            )
        let resources = root.appendingPathComponent(
            "Contents/Resources",
            isDirectory: true
        )
        let voiceDefaults = resources.appendingPathComponent(
            "VoiceDefaults",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: voiceDefaults,
            withIntermediateDirectories: true
        )
        for filename in [
            VoiceDefaultPresetResources.mouthSpriteFilename,
            VoiceDefaultPresetResources.blinkFilename
        ] {
            XCTAssertTrue(
                FileManager.default.createFile(
                    atPath: voiceDefaults
                        .appendingPathComponent(filename)
                        .path,
                    contents: Data([0])
                )
            )
        }
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let resolved = VoiceDefaultPresetResources.directoryURL(
            mainResourceURL: resources,
            sourceFileURL: root
                .appendingPathComponent("Missing")
                .appendingPathComponent("VoiceDefaultPresetResources.swift")
        )

        XCTAssertEqual(
            resolved?.standardizedFileURL,
            voiceDefaults.standardizedFileURL
        )
    }

    @MainActor
    func testMouthSpriteSheetSplitsIntoFourOrderedSquareAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherMouthSheetTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let repository = FileThemeRepository(rootDirectory: root)
        let model = ThemeAppModel(repository: repository, runtime: nil)
        let sample = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples")
            .appendingPathComponent("voice-mouth-sprites")
            .appendingPathComponent("anime-girl-mouth-2x2.png")

        let frames = try model.makeMouthSpriteFrameAssets(
            from: sample,
            gridSize: 2
        )

        XCTAssertEqual(frames.count, 4)
        XCTAssertEqual(
            frames.map(\.mediaType),
            Array(repeating: "image/png", count: 4)
        )
        XCTAssertTrue(frames[0].name.contains("1-"))
        XCTAssertTrue(frames[1].name.contains("2-"))
        XCTAssertTrue(frames[2].name.contains("3-"))
        XCTAssertTrue(frames[3].name.contains("4-"))
        for frame in frames {
            let data = try XCTUnwrap(frame.decodedData)
            let source = try XCTUnwrap(
                CGImageSourceCreateWithData(data as CFData, nil)
            )
            let properties = try XCTUnwrap(
                CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                    as? [CFString: Any]
            )
            XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 627)
            XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 627)
        }
    }

    @MainActor
    func testMouthSpriteSheetSupportsNineOrderedAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherMouthSheet3x3Tests-\(UUID().uuidString)",
                isDirectory: true
            )
        let repository = FileThemeRepository(rootDirectory: root)
        let model = ThemeAppModel(repository: repository, runtime: nil)
        let sample = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples")
            .appendingPathComponent("voice-mouth-sprites")
            .appendingPathComponent("anime-girl-mouth-3x3.png")

        let frames = try model.makeMouthSpriteFrameAssets(
            from: sample,
            gridSize: 3
        )

        XCTAssertEqual(frames.count, 9)
        XCTAssertEqual(
            frames.map(\.mediaType),
            Array(repeating: "image/png", count: 9)
        )
        for (index, frame) in frames.enumerated() {
            XCTAssertTrue(frame.name.contains("\(index + 1)-"))
            let data = try XCTUnwrap(frame.decodedData)
            let source = try XCTUnwrap(
                CGImageSourceCreateWithData(data as CFData, nil)
            )
            let properties = try XCTUnwrap(
                CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                    as? [CFString: Any]
            )
            XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 418)
            XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 418)
        }
    }

    @MainActor
    func testDefaultVoicePresetIncludesTunedImagesForBothAppearances() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherVoicePresetTests-\(UUID().uuidString)",
                isDirectory: true
            )
        let model = ThemeAppModel(
            repository: FileThemeRepository(rootDirectory: root),
            voiceDefaultResourceDirectory: voiceDefaultsDirectory,
            runtime: nil
        )

        let preset = try model.makeDefaultVoicePreset()
        let light = preset.style.light

        XCTAssertTrue(preset.style.isEnabled)
        XCTAssertEqual(preset.assets.count, 5)
        XCTAssertEqual(preset.style.light, preset.style.dark)
        XCTAssertEqual(light.orbScale, 3)
        XCTAssertEqual(light.orbOpacity, 0)
        XCTAssertEqual(light.orbMouthFrameAssetIDs.count, 3)
        XCTAssertNotNil(light.orbBackgroundAssetID)
        XCTAssertNotNil(light.orbBlinkAssetID)
        XCTAssertEqual(
            Set(
                [light.orbBackgroundAssetID, light.orbBlinkAssetID]
                    .compactMap { $0 }
                    + light.orbMouthFrameAssetIDs
            ),
            Set(preset.assets.map(\.id))
        )
        XCTAssertTrue(preset.assets.allSatisfy {
            $0.mediaType == "image/png" && $0.decodedData != nil
        })
    }

    @MainActor
    func testFirstVoiceEnableSeedsDefaultPresetWithoutOverwritingLater() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherVoiceEnableTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.metadata.name = "Voice defaults"
        theme.voiceStyle = nil
        let repository = FileThemeRepository(rootDirectory: root)
        _ = try await repository.save(theme, collisionPolicy: .fail)
        let model = ThemeAppModel(
            repository: repository,
            voiceDefaultResourceDirectory: voiceDefaultsDirectory,
            runtime: nil
        )
        await model.reloadThemes(selecting: theme.id)

        model.setVoiceStyleEnabled(true)

        let seeded = try XCTUnwrap(model.draft)
        XCTAssertEqual(seeded.assets.count, 5)
        XCTAssertEqual(
            seeded.voiceStyle?.light,
            seeded.voiceStyle?.dark
        )
        XCTAssertEqual(seeded.voiceStyle?.light.orbScale, 3)
        let seededAssetIDs = seeded.assets.map(\.id)

        model.setVoiceStyleEnabled(false)
        model.setVoiceStyleEnabled(true)

        XCTAssertEqual(model.draft?.assets.map(\.id), seededAssetIDs)
        XCTAssertTrue(model.draft?.voiceStyle?.isEnabled == true)
    }

    @MainActor
    func testSwitchingAndReloadingPreservesEachUnsavedDraft() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherAppTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let repository = FileThemeRepository(rootDirectory: root)
        var first = BuiltInThemes.midnight
        first.id = UUID()
        first.metadata.name = "First"
        var second = BuiltInThemes.paper
        second.id = UUID()
        second.metadata.name = "Second"
        _ = try await repository.save(first, collisionPolicy: .fail)
        _ = try await repository.save(second, collisionPolicy: .fail)

        let model = ThemeAppModel(
            repository: repository,
            runtime: nil
        )
        await model.reloadThemes(selecting: first.id)
        model.previewAppearance = .light
        model.previewSurface = .chat
        model.mutateDraft { $0.metadata.name = "First — edited" }

        model.selectTheme(second.id)
        XCTAssertEqual(model.draft?.metadata.name, "Second")
        XCTAssertFalse(model.isDraftDirty)

        await model.reloadThemes(selecting: second.id)
        model.selectTheme(first.id)

        XCTAssertEqual(model.draft?.metadata.name, "First — edited")
        XCTAssertTrue(model.isDraftDirty)
        XCTAssertTrue(model.hasUnsavedChanges(for: first.id))
        XCTAssertEqual(model.previewAppearance, .light)
        XCTAssertEqual(model.previewSurface, .chat)
    }

    @MainActor
    func testReplacingAndClearingSkinBackgroundPrunesOrphanAssets() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherSkinTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let firstAsset = ThemeAsset(
            name: "first.png",
            mediaType: "image/png",
            data: Data([1, 2, 3])
        )
        let secondAsset = ThemeAsset(
            name: "second.png",
            mediaType: "image/png",
            data: Data([4, 5, 6])
        )
        var skin = ThemeImageSkin()
        skin.dark.backgroundAssetID = firstAsset.id

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.metadata.name = "Skin"
        theme.assets = [firstAsset, secondAsset]
        theme.imageSkin = skin

        let repository = FileThemeRepository(rootDirectory: root)
        _ = try await repository.save(theme, collisionPolicy: .fail)
        let model = ThemeAppModel(repository: repository, runtime: nil)
        await model.reloadThemes(selecting: theme.id)

        model.setSkinBackground(secondAsset.id, for: .dark)

        XCTAssertEqual(
            model.draft?.imageSkin?.dark.backgroundAssetID,
            secondAsset.id
        )
        XCTAssertEqual(model.draft?.assets.map(\.id), [secondAsset.id])

        model.clearSkinBackground(for: .dark)

        XCTAssertNil(model.draft?.imageSkin?.dark.backgroundAssetID)
        XCTAssertTrue(model.draft?.assets.isEmpty == true)
    }

    @MainActor
    func testReplacingClearingAndRemovingVoiceBackgroundPrunesAssets() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherVoiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let firstAsset = ThemeAsset(
            name: "first.png",
            mediaType: "image/png",
            data: Data([1, 2, 3])
        )
        let secondAsset = ThemeAsset(
            name: "second.png",
            mediaType: "image/png",
            data: Data([4, 5, 6])
        )
        let mouthAsset = ThemeAsset(
            name: "mouth-open.png",
            mediaType: "image/png",
            data: Data([7, 8, 9])
        )
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.dark.backgroundAssetID = firstAsset.id
        voice.dark.orbBackgroundAssetID = firstAsset.id

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.metadata.name = "Voice"
        theme.assets = [firstAsset, secondAsset, mouthAsset]
        theme.voiceStyle = voice

        let repository = FileThemeRepository(rootDirectory: root)
        _ = try await repository.save(theme, collisionPolicy: .fail)
        let model = ThemeAppModel(repository: repository, runtime: nil)
        await model.reloadThemes(selecting: theme.id)

        model.setVoiceBackground(secondAsset.id, for: .dark)

        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.backgroundAssetID,
            secondAsset.id
        )
        XCTAssertEqual(
            Set(model.draft?.assets.map(\.id) ?? []),
            [firstAsset.id, secondAsset.id, mouthAsset.id]
        )

        model.setVoiceOrbBackground(secondAsset.id, for: .dark)

        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.orbBackgroundAssetID,
            secondAsset.id
        )
        XCTAssertEqual(
            Set(model.draft?.assets.map(\.id) ?? []),
            [secondAsset.id, mouthAsset.id]
        )

        model.addVoiceMouthFrame(mouthAsset.id, for: .dark)

        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.orbMouthFrameAssetIDs,
            [mouthAsset.id]
        )

        model.setVoiceBlinkImage(mouthAsset.id, for: .dark)

        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.orbBlinkAssetID,
            mouthAsset.id
        )

        model.clearVoiceBackground(for: .dark)

        XCTAssertNil(model.draft?.voiceStyle?.dark.backgroundAssetID)
        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.orbBackgroundAssetID,
            secondAsset.id
        )
        XCTAssertEqual(
            Set(model.draft?.assets.map(\.id) ?? []),
            [secondAsset.id, mouthAsset.id]
        )

        model.clearVoiceOrbBackground(for: .dark)

        XCTAssertNil(model.draft?.voiceStyle?.dark.orbBackgroundAssetID)
        XCTAssertTrue(
            model.draft?.voiceStyle?.dark.orbMouthFrameAssetIDs.isEmpty
                == true
        )
        XCTAssertEqual(
            model.draft?.voiceStyle?.dark.orbBlinkAssetID,
            mouthAsset.id
        )
        XCTAssertEqual(
            Set(model.draft?.assets.map(\.id) ?? []),
            [mouthAsset.id]
        )

        model.clearVoiceBlinkImage(for: .dark)

        XCTAssertNil(model.draft?.voiceStyle?.dark.orbBlinkAssetID)
        XCTAssertTrue(model.draft?.assets.isEmpty == true)
    }
}
