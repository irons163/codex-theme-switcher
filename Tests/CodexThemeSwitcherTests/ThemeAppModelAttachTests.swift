import CodexThemeRuntime
import CodexThemeSwitcherCore
import Foundation
import XCTest
@testable import CodexThemeSwitcher

final class ThemeAppModelAttachTests: XCTestCase {
    private struct ApplyPayload: Codable, Equatable {
        let themeID: String
        let themeName: String
        let css: String
    }

    private struct CommandRecord: Decodable {
        let command: String
        let input: ApplyPayload?
    }

    @MainActor
    func testFirstAttachWithoutActiveThemeOnlyConnects() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let model = ThemeAppModel(
            repository: fixture.repository,
            runtime: fixture.runtime
        )
        await model.reloadThemes()
        await model.refreshRuntime()

        XCTAssertNil(model.activeThemeID)
        XCTAssertNotNil(
            model.selectedThemeID,
            "The editor may preview a theme without making it active."
        )
        XCTAssertTrue(
            model.launchAndAttachHelp.contains("不會自動套用")
                || model.launchAndAttachHelp.contains(
                    "No theme will be applied automatically"
                )
        )

        model.launchAndAttach()

        let commands = try await waitForCommands(
            2,
            in: fixture.commandLog,
            model: model
        )
        XCTAssertEqual(commands.map(\.command), ["status", "launch"])
        XCTAssertNil(model.activeThemeID)
        XCTAssertNil(model.activeThemeName)
        XCTAssertTrue(model.isAttached)
        XCTAssertTrue(
            model.runtimeSummary.contains("尚未套用主題")
                || model.runtimeSummary.contains("No theme applied")
        )
        let noticeText = model.notice?.text ?? ""
        XCTAssertTrue(
            noticeText.contains("選好主題")
                || noticeText.contains("Choose a theme")
        )
    }

    @MainActor
    func testAttachRestoresRuntimeSnapshotInsteadOfLaterEdits() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let themeID = UUID()
        let appliedSnapshot = ApplyPayload(
            themeID: themeID.uuidString,
            themeName: "Last Applied Theme",
            css: ":root { --attach-test: applied-marker; }"
        )
        try JSONEncoder().encode(appliedSnapshot).write(
            to: fixture.runtimeSnapshot
        )

        var persisted = BuiltInThemes.midnight
        persisted.id = themeID
        persisted.metadata.name = "Saved But Not Applied"
        persisted.layers[0].rawCSS = """
        :root { --attach-test: saved-marker; }
        """
        _ = try await fixture.repository.save(
            persisted,
            collisionPolicy: .fail
        )
        try await fixture.repository.setActiveThemeID(persisted.id)

        let model = ThemeAppModel(
            repository: fixture.repository,
            runtime: fixture.runtime
        )
        await model.reloadThemes(selecting: persisted.id)
        await model.refreshRuntime()
        model.mutateDraft(
            actionName: "Unsaved edit",
            coalesces: false
        ) {
            $0.metadata.name = "Unsaved Theme"
            $0.layers[0].rawCSS = """
            :root { --attach-test: unsaved-marker; }
            """
        }

        XCTAssertTrue(model.isDraftDirty)
        XCTAssertTrue(model.launchAndAttachHelp.contains("Last Applied Theme"))
        XCTAssertFalse(
            model.launchAndAttachHelp.contains("Saved But Not Applied")
        )
        XCTAssertFalse(model.launchAndAttachHelp.contains("Unsaved Theme"))

        model.launchAndAttach()

        let commands = try await waitForCommands(
            2,
            in: fixture.commandLog,
            model: model
        )
        XCTAssertEqual(commands.map(\.command), ["status", "launch"])
        XCTAssertTrue(commands.allSatisfy { $0.input == nil })
        XCTAssertEqual(
            try JSONDecoder().decode(
                ApplyPayload.self,
                from: Data(contentsOf: fixture.runtimeSnapshot)
            ),
            appliedSnapshot
        )

        XCTAssertEqual(model.draft?.metadata.name, "Unsaved Theme")
        XCTAssertTrue(model.isDraftDirty)
        XCTAssertEqual(model.activeThemeName, "Last Applied Theme")
        XCTAssertTrue(model.runtimeSummary.contains("Last Applied Theme"))
        XCTAssertFalse(model.runtimeSummary.contains("Saved But Not Applied"))
        XCTAssertFalse(model.runtimeSummary.contains("Unsaved Theme"))
        XCTAssertTrue(
            model.notice?.text.contains("Last Applied Theme") == true
        )
    }

    @MainActor
    func testDeletingAppliedThemeClearsRuntimeStatusImmediately() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.metadata.name = "Delete Me"
        _ = try await fixture.repository.save(
            theme,
            collisionPolicy: .fail
        )
        try await fixture.repository.setActiveThemeID(theme.id)
        try JSONEncoder().encode(
            ApplyPayload(
                themeID: theme.id.uuidString,
                themeName: theme.metadata.name,
                css: ":root {}"
            )
        ).write(to: fixture.runtimeSnapshot)

        let model = ThemeAppModel(
            repository: fixture.repository,
            runtime: fixture.runtime
        )
        await model.reloadThemes(selecting: theme.id)
        await model.refreshRuntime()
        XCTAssertEqual(model.appliedThemeID, theme.id)

        model.deleteSelected()

        let commands = try await waitForCommands(
            2,
            in: fixture.commandLog,
            model: model
        )
        XCTAssertEqual(commands.map(\.command), ["status", "clear"])
        XCTAssertNil(model.appliedThemeID)
        XCTAssertNil(model.activeThemeName)
        XCTAssertNil(model.activeThemeID)
        let themeStillExists = await fixture.repository.contains(id: theme.id)
        XCTAssertFalse(themeStillExists)
        XCTAssertTrue(
            model.runtimeSummary.contains("尚未套用主題")
                || model.runtimeSummary.contains("No theme applied")
        )
    }

    @MainActor
    func testStaleStatusCannotOverwriteCompletedAttach() async throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let model = ThemeAppModel(
            repository: fixture.repository,
            runtime: fixture.runtime
        )
        await model.reloadThemes()
        try Data("500".utf8).write(to: fixture.statusDelay)

        let refreshTask = Task { @MainActor in
            await model.refreshRuntime()
        }
        _ = try await waitForLoggedCommands(
            1,
            in: fixture.commandLog
        )
        try JSONEncoder().encode(
            ApplyPayload(
                themeID: UUID().uuidString,
                themeName: "Restored After Stale Status",
                css: ":root {}"
            )
        ).write(to: fixture.runtimeSnapshot)

        model.launchAndAttach()
        let commands = try await waitForCommands(
            2,
            in: fixture.commandLog,
            model: model
        )
        XCTAssertEqual(commands.map(\.command), ["status", "launch"])
        await refreshTask.value

        XCTAssertTrue(model.isAttached)
        XCTAssertEqual(
            model.activeThemeName,
            "Restored After Stale Status"
        )
        XCTAssertTrue(
            model.runtimeSummary.contains("Restored After Stale Status")
        )
    }

    private func makeFixture() throws -> (
        root: URL,
        repository: FileThemeRepository,
        runtime: ThemeRuntimeController,
        commandLog: URL,
        runtimeSnapshot: URL,
        statusDelay: URL
    ) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeSwitcherAttachTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        do {
            let helper = root.appendingPathComponent("fake-helper.js")
            let helperSource = #"""
            "use strict";
            const fs = require("node:fs");
            const path = require("node:path");
            const args = process.argv.slice(2);
            const command = args[0];
            const valueAfter = (flag) => {
              const index = args.indexOf(flag);
              return index < 0 ? null : args[index + 1];
            };
            const userRoot = valueAfter("--user-root");
            fs.mkdirSync(userRoot, { recursive: true });
            const stdin = command === "apply"
              ? fs.readFileSync(0)
              : Buffer.alloc(0);
            const input = stdin.length
              ? JSON.parse(stdin.toString("utf8"))
              : null;
            const snapshotPath = path.join(
              userRoot,
              "fake-active-theme.json"
            );
            let activeTheme = null;
            try {
              activeTheme = JSON.parse(
                fs.readFileSync(snapshotPath, "utf8")
              );
            } catch {}
            if (command === "apply") {
              activeTheme = input;
              fs.writeFileSync(snapshotPath, JSON.stringify(activeTheme));
            } else if (command === "clear") {
              activeTheme = null;
              try {
                fs.unlinkSync(snapshotPath);
              } catch {}
            }
            fs.appendFileSync(
              path.join(userRoot, "commands.ndjson"),
              `${JSON.stringify({ command, input })}\n`
            );
            if (command === "status") {
              let delay = 0;
              try {
                delay = Number(
                  fs.readFileSync(
                    path.join(userRoot, "status-delay-ms"),
                    "utf8"
                  )
                );
              } catch {}
              if (delay > 0) {
                Atomics.wait(
                  new Int32Array(new SharedArrayBuffer(4)),
                  0,
                  0,
                  delay
                );
              }
            }
            const attached = command !== "status";
            process.stdout.write(JSON.stringify({
              ok: true,
              status: {
                codexVersion: "test",
                mode: "fake",
                isInjected: attached,
                bridgeRunning: attached,
                isRunning: true,
                isDebugPortReady: true,
                hasCodexTarget: attached,
                activeThemeID: activeTheme && activeTheme.themeID,
                activeThemeName: activeTheme && activeTheme.themeName,
                injectedRendererCount: attached ? 1 : 0
              },
              error: null
            }));
            """#
            try Data(helperSource.utf8).write(to: helper)

            let runtimeRoot = root.appendingPathComponent(
                "runtime",
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: runtimeRoot,
                withIntermediateDirectories: true
            )
            let codexApp = root.appendingPathComponent(
                "Codex Test.app",
                isDirectory: true
            )
            let node = try XCTUnwrap(
                RuntimeLocator.defaultNodeExecutable(
                    codexApp: codexApp,
                    environment: ProcessInfo.processInfo.environment
                ),
                "Tests require the same Node runtime as the production helper."
            )
            let runtime = ThemeRuntimeController(
                runner: RuntimeHelperRunner(
                    helperScript: helper,
                    codexApp: codexApp,
                    userRoot: runtimeRoot,
                    nodeExecutable: node
                )
            )
            let repository = FileThemeRepository(
                rootDirectory: root.appendingPathComponent(
                    "themes",
                    isDirectory: true
                )
            )
            return (
                root,
                repository,
                runtime,
                runtimeRoot.appendingPathComponent("commands.ndjson"),
                runtimeRoot.appendingPathComponent("fake-active-theme.json"),
                runtimeRoot.appendingPathComponent("status-delay-ms")
            )
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }

    @MainActor
    private func waitForLoggedCommands(
        _ expectedCount: Int,
        in url: URL
    ) async throws -> [CommandRecord] {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            let commands = try readCommands(from: url)
            if commands.count >= expectedCount {
                return commands
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        let commands = try readCommands(from: url)
        XCTFail(
            "Timed out waiting for \(expectedCount) logged commands; "
                + "received \(commands.map(\.command))."
        )
        return commands
    }

    @MainActor
    private func waitForCommands(
        _ expectedCount: Int,
        in url: URL,
        model: ThemeAppModel
    ) async throws -> [CommandRecord] {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            let commands = try readCommands(from: url)
            if commands.count >= expectedCount, !model.isBusy {
                return commands
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        let commands = try readCommands(from: url)
        XCTFail(
            "Timed out waiting for \(expectedCount) runtime commands; "
                + "received \(commands.map(\.command))."
        )
        return commands
    }

    private func readCommands(from url: URL) throws -> [CommandRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        return try String(contentsOf: url, encoding: .utf8)
            .split(whereSeparator: \.isNewline)
            .map {
                try JSONDecoder().decode(
                    CommandRecord.self,
                    from: Data($0.utf8)
                )
            }
    }
}
