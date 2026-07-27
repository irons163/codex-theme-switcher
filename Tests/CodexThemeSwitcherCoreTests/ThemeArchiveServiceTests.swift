import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeArchiveServiceTests: XCTestCase {
    func testExportAndInspectSingleJSONArchive() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("shared.codextheme")
        let exportedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let asset = ThemeAsset(
            name: "texture.png",
            mediaType: "image/png",
            data: Data([1, 2, 3])
        )
        let theme = TestFixtures.theme(assets: [asset])
        let service = ThemeArchiveService(now: { exportedAt })

        try service.export(theme, to: url)
        let inspection = try service.inspect(url)

        XCTAssertEqual(inspection.format, ThemeArchiveService.formatIdentifier)
        XCTAssertEqual(
            inspection.archiveVersion,
            ThemeArchiveService.currentArchiveVersion
        )
        XCTAssertEqual(inspection.exportedAt, exportedAt)
        XCTAssertEqual(inspection.theme, theme)
        XCTAssertEqual(inspection.theme.assets.first?.decodedData, Data([1, 2, 3]))
        XCTAssertGreaterThan(inspection.encodedByteCount, 0)

        let topLevel = try JSONSerialization.jsonObject(
            with: Data(contentsOf: url)
        ) as? [String: Any]
        XCTAssertNotNil(topLevel?["theme"])
        XCTAssertNotNil(topLevel?["format"])
    }

    func testInspectLegacyArchiveWithoutImageSkin() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.codextheme")
        let legacyArchive = """
        {
          "format": "com.codex-theme-switcher.theme",
          "archiveVersion": 1,
          "exportedAt": 0,
          "theme": {
            "schemaVersion": 1,
            "id": "00000000-0000-0000-0000-000000000201",
            "metadata": {
              "name": "Legacy Archive",
              "author": "",
              "description": "",
              "version": "1.0.0",
              "tags": [],
              "createdAt": 0,
              "updatedAt": 0
            },
            "layers": [],
            "assets": []
          }
        }
        """
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(legacyArchive.utf8).write(to: url)

        let inspection = try ThemeArchiveService().inspect(url)

        XCTAssertEqual(inspection.archiveVersion, 1)
        XCTAssertEqual(inspection.theme.metadata.name, "Legacy Archive")
        XCTAssertNil(inspection.theme.imageSkin)
    }

    func testImageSkinArchiveRoundTripPreservesBothVariantsAndAssets() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("image-skin.codextheme")
        let light = TestFixtures.imageAsset(
            name: "light.png",
            bytes: [1, 2, 3]
        )
        let dark = TestFixtures.imageAsset(
            name: "dark.jpg",
            mediaType: "image/jpeg",
            bytes: [4, 5, 6]
        )
        var imageSkin = TestFixtures.imageSkin(
            lightAssetID: light.id,
            darkAssetID: dark.id
        )
        imageSkin.wallpaperScope = .mainContent
        let theme = TestFixtures.theme(
            assets: [light, dark],
            imageSkin: imageSkin
        )

        try ThemeArchiveService().export(theme, to: url)
        let inspection = try ThemeArchiveService().inspect(url)

        XCTAssertEqual(inspection.archiveVersion, 1)
        XCTAssertEqual(inspection.theme, theme)
        XCTAssertEqual(
            inspection.theme.imageSkin?.wallpaperScope,
            .mainContent
        )
        XCTAssertEqual(
            inspection.theme.imageSkin?.light.backgroundAssetID,
            light.id
        )
        XCTAssertEqual(
            inspection.theme.imageSkin?.dark.backgroundAssetID,
            dark.id
        )
        XCTAssertEqual(
            inspection.theme.assets.map(\.decodedData),
            [Data([1, 2, 3]), Data([4, 5, 6])]
        )
    }

    func testImportCollisionClonesThemeAndPreservesAssets() async throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = FileThemeRepository(
            rootDirectory: directory.appendingPathComponent("Repository")
        )
        let archiveURL = directory.appendingPathComponent("theme.codextheme")
        let light = ThemeAsset(
            name: "light.webp",
            mediaType: "image/webp",
            data: Data([4, 5, 6])
        )
        let dark = ThemeAsset(
            name: "dark.jpg",
            mediaType: "image/jpeg",
            data: Data([7, 8, 9])
        )
        let theme = TestFixtures.theme(
            assets: [light, dark],
            imageSkin: TestFixtures.imageSkin(
                lightAssetID: light.id,
                darkAssetID: dark.id
            )
        )
        let service = ThemeArchiveService()

        _ = try await repository.save(theme, collisionPolicy: .fail)
        try service.export(theme, to: archiveURL)
        let imported = try await service.importTheme(
            from: archiveURL,
            into: repository
        )
        let loadedImportedTheme = try await repository.load(id: imported.id)

        XCTAssertNotEqual(imported.id, theme.id)
        XCTAssertEqual(imported.metadata.name, "Test Theme Copy")
        XCTAssertEqual(imported.assets, theme.assets)
        XCTAssertEqual(
            imported.imageSkin?.light.backgroundAssetID,
            light.id
        )
        XCTAssertEqual(
            imported.imageSkin?.dark.backgroundAssetID,
            dark.id
        )
        XCTAssertEqual(loadedImportedTheme, imported)
    }

    func testInspectRejectsUnsupportedFormatAndVersion() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = ThemeArchiveService()

        let wrongFormatURL = directory.appendingPathComponent("wrong-format.codextheme")
        try write(
            ThemeArchiveEnvelope(
                format: "another.format",
                archiveVersion: ThemeArchiveService.currentArchiveVersion,
                exportedAt: TestFixtures.date,
                theme: TestFixtures.theme()
            ),
            to: wrongFormatURL
        )
        XCTAssertThrowsError(try service.inspect(wrongFormatURL)) { error in
            XCTAssertEqual(
                error as? ThemeArchiveError,
                .unsupportedFormat("another.format")
            )
        }

        let wrongVersionURL = directory.appendingPathComponent("wrong-version.codextheme")
        try write(
            ThemeArchiveEnvelope(
                format: ThemeArchiveService.formatIdentifier,
                archiveVersion: 999,
                exportedAt: TestFixtures.date,
                theme: TestFixtures.theme()
            ),
            to: wrongVersionURL
        )
        XCTAssertThrowsError(try service.inspect(wrongVersionURL)) { error in
            XCTAssertEqual(
                error as? ThemeArchiveError,
                .unsupportedArchiveVersion(999)
            )
        }
    }

    func testArchiveSizeLimitIsEnforcedForExportAndImport() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("large.codextheme")
        let service = ThemeArchiveService(maximumArchiveBytes: 32)

        XCTAssertThrowsError(try service.export(TestFixtures.theme(), to: url)) { error in
            guard case ThemeArchiveError.archiveTooLarge = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data(repeating: 0x41, count: 64).write(to: url)
        XCTAssertThrowsError(try service.inspect(url)) { error in
            guard case ThemeArchiveError.archiveTooLarge = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testUnsafeImportedThemeIsRejected() throws {
        let directory = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("unsafe.codextheme")
        var unsafe = TestFixtures.theme()
        unsafe.layers[0].rules[0].selector =
            #"@\69mport u/**/rl("\68ttps://tracker.invalid/theme.css"); :root"#
        try write(
            ThemeArchiveEnvelope(
                format: ThemeArchiveService.formatIdentifier,
                archiveVersion: ThemeArchiveService.currentArchiveVersion,
                exportedAt: TestFixtures.date,
                theme: unsafe
            ),
            to: url
        )

        XCTAssertThrowsError(try ThemeArchiveService().inspect(url)) { error in
            guard let validation = error as? ThemeValidationError else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertTrue(validation.issues.contains { $0.code == .unsafeImport })
            XCTAssertTrue(validation.issues.contains { $0.code == .unsafeURL })
        }
    }

    private func write(_ envelope: ThemeArchiveEnvelope, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(envelope).write(to: url)
    }
}
