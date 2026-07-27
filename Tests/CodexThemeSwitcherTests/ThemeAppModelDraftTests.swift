import CodexThemeSwitcherCore
import Foundation
import XCTest
@testable import CodexThemeSwitcher

final class ThemeAppModelDraftTests: XCTestCase {
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
        model.mutateDraft { $0.metadata.name = "First — edited" }

        model.selectTheme(second.id)
        XCTAssertEqual(model.draft?.metadata.name, "Second")
        XCTAssertFalse(model.isDraftDirty)

        await model.reloadThemes(selecting: second.id)
        model.selectTheme(first.id)

        XCTAssertEqual(model.draft?.metadata.name, "First — edited")
        XCTAssertTrue(model.isDraftDirty)
        XCTAssertTrue(model.hasUnsavedChanges(for: first.id))
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
}
