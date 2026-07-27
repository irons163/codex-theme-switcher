import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class FileThemeRepositoryTests: XCTestCase {
    func testSaveLoadListActiveAndDeleteLifecycle() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = FileThemeRepository(rootDirectory: root)
        let theme = TestFixtures.theme()

        let saved = try await repository.save(theme, collisionPolicy: .fail)
        XCTAssertEqual(saved, theme)
        let containsSavedTheme = await repository.contains(id: theme.id)
        let loadedTheme = try await repository.load(id: theme.id)
        XCTAssertTrue(containsSavedTheme)
        XCTAssertEqual(loadedTheme, theme)

        let userSummaries = try await repository.list(includeBuiltIns: false)
        XCTAssertEqual(userSummaries.map(\.id), [theme.id])
        XCTAssertFalse(userSummaries[0].isBuiltIn)

        try await repository.setActiveThemeID(theme.id)
        let activeBeforeDelete = try await repository.activeThemeID()
        XCTAssertEqual(activeBeforeDelete, theme.id)

        try await repository.delete(id: theme.id)
        let containsDeletedTheme = await repository.contains(id: theme.id)
        let activeAfterDelete = try await repository.activeThemeID()
        XCTAssertFalse(containsDeletedTheme)
        XCTAssertNil(activeAfterDelete)
    }

    func testListIncludesBuiltInsByDefault() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = FileThemeRepository(rootDirectory: root)

        let summaries = try await repository.list()
        let builtInIDs = Set(summaries.filter(\.isBuiltIn).map(\.id))
        let loadedMidnight = try await repository.load(
            id: BuiltInThemes.midnight.id
        )

        XCTAssertEqual(builtInIDs, Set(BuiltInThemes.all.map(\.id)))
        XCTAssertEqual(loadedMidnight, BuiltInThemes.midnight)
    }

    func testCollisionPoliciesFailReplaceAndClone() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = FileThemeRepository(rootDirectory: root)
        let original = TestFixtures.theme()
        _ = try await repository.save(original, collisionPolicy: .fail)

        do {
            _ = try await repository.save(original, collisionPolicy: .fail)
            XCTFail("Expected collision")
        } catch let error as ThemeRepositoryError {
            XCTAssertEqual(error, .themeAlreadyExists(original.id))
        }

        var replacement = original
        replacement.metadata.name = "Replacement"
        let replaced = try await repository.save(replacement, collisionPolicy: .replace)
        let loadedReplacement = try await repository.load(id: original.id)
        XCTAssertEqual(replaced.metadata.name, "Replacement")
        XCTAssertEqual(loadedReplacement, replacement)

        let clone = try await repository.save(replacement, collisionPolicy: .clone)
        let loadedClone = try await repository.load(id: clone.id)
        XCTAssertNotEqual(clone.id, replacement.id)
        XCTAssertEqual(clone.metadata.name, "Replacement Copy")
        XCTAssertEqual(loadedClone, clone)
    }

    func testSeparateRepositoryInstancesSerializeFailCollisions() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let firstRepository = FileThemeRepository(rootDirectory: root)
        let secondRepository = FileThemeRepository(rootDirectory: root)
        let theme = TestFixtures.theme()

        let outcomes = await withTaskGroup(of: Bool.self) { group in
            for repository in [firstRepository, secondRepository] {
                group.addTask {
                    do {
                        _ = try await repository.save(
                            theme,
                            collisionPolicy: .fail
                        )
                        return true
                    } catch ThemeRepositoryError.themeAlreadyExists(theme.id) {
                        return false
                    } catch {
                        XCTFail("Unexpected repository error: \(error)")
                        return false
                    }
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        XCTAssertEqual(outcomes.filter { $0 }.count, 1)
        XCTAssertEqual(outcomes.filter { !$0 }.count, 1)
        let loaded = try await firstRepository.load(id: theme.id)
        XCTAssertEqual(loaded, theme)
    }

    func testBuiltInsCanBeActiveButCannotBeReplacedOrDeleted() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = FileThemeRepository(rootDirectory: root)
        let builtIn = BuiltInThemes.paper

        try await repository.setActiveThemeID(builtIn.id)
        let activeID = try await repository.activeThemeID()
        XCTAssertEqual(activeID, builtIn.id)

        do {
            _ = try await repository.save(builtIn, collisionPolicy: .replace)
            XCTFail("Expected built-in replacement to fail")
        } catch let error as ThemeRepositoryError {
            XCTAssertEqual(error, .cannotReplaceBuiltIn(builtIn.id))
        }

        do {
            try await repository.delete(id: builtIn.id)
            XCTFail("Expected built-in deletion to fail")
        } catch let error as ThemeRepositoryError {
            XCTAssertEqual(error, .cannotDeleteBuiltIn(builtIn.id))
        }
    }

    func testInvalidActiveThemeIsRejected() async throws {
        let root = TestFixtures.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = FileThemeRepository(rootDirectory: root)
        let missing = UUID()

        do {
            try await repository.setActiveThemeID(missing)
            XCTFail("Expected invalid active theme")
        } catch let error as ThemeRepositoryError {
            XCTAssertEqual(error, .invalidActiveTheme(missing))
        }
    }
}
