import CodexThemeSwitcherCore
import Foundation
import XCTest
@testable import CodexThemeSwitcher

final class ThemeAppModelHistoryTests: XCTestCase {
    @MainActor
    func testDraftMutationUndoRedoRestoresDirtyState() async throws {
        let theme = makeTheme(name: "Original")
        let fixture = try await makeModel(
            documents: [theme],
            selecting: theme.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let original = try XCTUnwrap(fixture.model.draft)
        fixture.model.mutateDraft(
            actionName: "Rename",
            coalesces: false
        ) {
            $0.metadata.name = "Edited"
        }
        let edited = try XCTUnwrap(fixture.model.draft)

        XCTAssertEqual(edited.metadata.name, "Edited")
        XCTAssertTrue(fixture.model.isDraftDirty)
        XCTAssertTrue(fixture.model.hasUnsavedChanges(for: theme.id))
        XCTAssertTrue(fixture.model.canUndoDraft)
        XCTAssertFalse(fixture.model.canRedoDraft)

        fixture.model.undoDraftChange()

        XCTAssertEqual(fixture.model.draft, original)
        XCTAssertEqual(
            fixture.model.themes.first(where: { $0.id == theme.id }),
            original
        )
        XCTAssertFalse(fixture.model.isDraftDirty)
        XCTAssertFalse(fixture.model.hasUnsavedChanges(for: theme.id))
        XCTAssertFalse(fixture.model.canUndoDraft)
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.redoDraftChange()

        XCTAssertEqual(fixture.model.draft, edited)
        XCTAssertTrue(fixture.model.isDraftDirty)
        XCTAssertTrue(fixture.model.hasUnsavedChanges(for: theme.id))
        XCTAssertTrue(fixture.model.canUndoDraft)
        XCTAssertFalse(fixture.model.canRedoDraft)
    }

    @MainActor
    func testContinuousMutationsWithSameKeyCoalesceIntoOneStep() async throws {
        var skin = ThemeImageSkin()
        skin.dark.imageOpacity = 0.45
        let theme = makeTheme(name: "Coalescing", imageSkin: skin)
        let fixture = try await makeModel(
            documents: [theme],
            selecting: theme.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let original = try XCTUnwrap(fixture.model.draft)
        for opacity in [0.55, 0.7, 0.85] {
            fixture.model.mutateDraft(
                actionName: "Adjust image opacity",
                coalescingKey: "skin.dark.imageOpacity"
            ) { document in
                document.imageSkin?.dark.imageOpacity = opacity
            }
        }
        let final = try XCTUnwrap(fixture.model.draft)

        XCTAssertEqual(final.imageSkin?.dark.imageOpacity, 0.85)
        XCTAssertTrue(fixture.model.canUndoDraft)

        fixture.model.undoDraftChange()

        XCTAssertEqual(fixture.model.draft, original)
        XCTAssertFalse(fixture.model.canUndoDraft)
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.redoDraftChange()

        XCTAssertEqual(fixture.model.draft, final)
        XCTAssertEqual(fixture.model.draft?.imageSkin?.dark.imageOpacity, 0.85)
    }

    @MainActor
    func testNewMutationAfterUndoClearsRedoHistory() async throws {
        let theme = makeTheme(name: "Original")
        let fixture = try await makeModel(
            documents: [theme],
            selecting: theme.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        fixture.model.mutateDraft(
            actionName: "Rename",
            coalesces: false
        ) {
            $0.metadata.name = "Discarded branch"
        }
        fixture.model.undoDraftChange()
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.mutateDraft(
            actionName: "Change author",
            coalesces: false
        ) {
            $0.metadata.author = "New branch"
        }

        XCTAssertEqual(fixture.model.draft?.metadata.name, "Original")
        XCTAssertEqual(fixture.model.draft?.metadata.author, "New branch")
        XCTAssertFalse(fixture.model.canRedoDraft)

        let newBranch = fixture.model.draft
        fixture.model.redoDraftChange()
        XCTAssertEqual(fixture.model.draft, newBranch)
    }

    @MainActor
    func testCopySkinVariantIsOneAtomicUndoableChange() async throws {
        var skin = ThemeImageSkin()
        skin.light.backgroundColor = "#FAEEE4"
        skin.light.positionX = 0.2
        skin.light.imageOpacity = 0.72
        skin.light.centerPanelTint = "#FFF8F2"
        skin.dark.backgroundColor = "#07090D"
        skin.dark.positionX = 0.8
        skin.dark.imageOpacity = 0.94
        skin.dark.centerPanelTint = "#111318"
        skin.wallpaperScope = .mainContent
        skin.glass.blurRadius = 37
        skin.centerPanel.maximumWidth = 1_120
        skin.targets.cards = false

        let theme = makeTheme(name: "Copy", imageSkin: skin)
        let fixture = try await makeModel(
            documents: [theme],
            selecting: theme.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let original = try XCTUnwrap(fixture.model.draft)
        let originalSkin = try XCTUnwrap(original.imageSkin)
        fixture.model.copySkinVariant(from: .light, to: .dark)
        let copied = try XCTUnwrap(fixture.model.draft)
        let copiedSkin = try XCTUnwrap(copied.imageSkin)

        XCTAssertEqual(copiedSkin.dark, originalSkin.light)
        XCTAssertEqual(copiedSkin.light, originalSkin.light)
        XCTAssertEqual(copiedSkin.wallpaperScope, originalSkin.wallpaperScope)
        XCTAssertEqual(copiedSkin.glass, originalSkin.glass)
        XCTAssertEqual(copiedSkin.centerPanel, originalSkin.centerPanel)
        XCTAssertEqual(copiedSkin.targets, originalSkin.targets)

        fixture.model.undoDraftChange()

        XCTAssertEqual(fixture.model.draft, original)
        XCTAssertFalse(fixture.model.canUndoDraft)
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.redoDraftChange()

        XCTAssertEqual(fixture.model.draft, copied)
    }

    @MainActor
    func testUndoRedoRestoresPrunedSkinAssetAndReference() async throws {
        let firstAsset = ThemeAsset(
            name: "first.png",
            mediaType: "image/png",
            data: Data([1, 2, 3, 4])
        )
        let secondAsset = ThemeAsset(
            name: "second.png",
            mediaType: "image/png",
            data: Data([5, 6, 7, 8])
        )
        var skin = ThemeImageSkin()
        skin.dark.backgroundAssetID = firstAsset.id
        let theme = makeTheme(
            name: "Assets",
            assets: [firstAsset, secondAsset],
            imageSkin: skin
        )
        let fixture = try await makeModel(
            documents: [theme],
            selecting: theme.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let original = try XCTUnwrap(fixture.model.draft)
        fixture.model.setSkinBackground(secondAsset.id, for: .dark)
        let replaced = try XCTUnwrap(fixture.model.draft)

        XCTAssertEqual(
            replaced.imageSkin?.dark.backgroundAssetID,
            secondAsset.id
        )
        XCTAssertEqual(replaced.assets.map(\.id), [secondAsset.id])

        fixture.model.undoDraftChange()

        XCTAssertEqual(fixture.model.draft, original)
        XCTAssertEqual(
            fixture.model.draft?.imageSkin?.dark.backgroundAssetID,
            firstAsset.id
        )
        XCTAssertEqual(fixture.model.draft?.assets.map(\.id), [
            firstAsset.id,
            secondAsset.id
        ])
        XCTAssertEqual(
            fixture.model.draft?.assets.first {
                $0.id == firstAsset.id
            }?.decodedData,
            Data([1, 2, 3, 4])
        )

        fixture.model.redoDraftChange()

        XCTAssertEqual(fixture.model.draft, replaced)
        XCTAssertEqual(
            fixture.model.draft?.assets.first?.decodedData,
            Data([5, 6, 7, 8])
        )
    }

    @MainActor
    func testHistoryIsIsolatedPerThemeAndNoOpCreatesNoEntry() async throws {
        let first = makeTheme(name: "First")
        let second = makeTheme(name: "Second")
        let fixture = try await makeModel(
            documents: [first, second],
            selecting: first.id
        )
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        fixture.model.mutateDraft(
            actionName: "No-op",
            coalesces: false
        ) {
            $0.metadata.name = "First"
        }
        XCTAssertFalse(fixture.model.canUndoDraft)
        XCTAssertFalse(fixture.model.isDraftDirty)

        fixture.model.mutateDraft(
            actionName: "Edit first",
            coalesces: false
        ) {
            $0.metadata.name = "First edited"
        }
        XCTAssertTrue(fixture.model.canUndoDraft)

        fixture.model.selectTheme(second.id)
        XCTAssertEqual(fixture.model.draft?.metadata.name, "Second")
        XCTAssertFalse(fixture.model.canUndoDraft)
        XCTAssertFalse(fixture.model.canRedoDraft)

        fixture.model.mutateDraft(
            actionName: "Edit second",
            coalesces: false
        ) {
            $0.metadata.name = "Second edited"
        }
        fixture.model.undoDraftChange()
        XCTAssertEqual(fixture.model.draft?.metadata.name, "Second")
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.selectTheme(first.id)
        XCTAssertEqual(fixture.model.draft?.metadata.name, "First edited")
        XCTAssertTrue(fixture.model.canUndoDraft)
        XCTAssertFalse(fixture.model.canRedoDraft)

        fixture.model.undoDraftChange()
        XCTAssertEqual(fixture.model.draft?.metadata.name, "First")
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.selectTheme(second.id)
        XCTAssertEqual(fixture.model.draft?.metadata.name, "Second")
        XCTAssertTrue(fixture.model.canRedoDraft)

        fixture.model.redoDraftChange()
        XCTAssertEqual(fixture.model.draft?.metadata.name, "Second edited")
    }

    private func makeTheme(
        name: String,
        assets: [ThemeAsset] = [],
        imageSkin: ThemeImageSkin? = nil
    ) -> ThemeDocument {
        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.metadata.name = name
        theme.metadata.author = "History Tests"
        theme.metadata.createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        theme.metadata.updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        theme.assets = assets
        theme.imageSkin = imageSkin
        return theme
    }

    @MainActor
    private func makeModel(
        documents: [ThemeDocument],
        selecting selectedID: UUID
    ) async throws -> (
        model: ThemeAppModel,
        root: URL
    ) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherHistoryTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        let repository = FileThemeRepository(rootDirectory: root)
        do {
            for document in documents {
                _ = try await repository.save(
                    document,
                    collisionPolicy: .fail
                )
            }
            let model = ThemeAppModel(repository: repository, runtime: nil)
            await model.reloadThemes(selecting: selectedID)
            return (model, root)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }
}
