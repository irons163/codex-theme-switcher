import Foundation
import XCTest
@testable import CodexThemeRuntime

final class RuntimeHelperRunnerTests: XCTestCase {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeRunnerTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    private func makeHelper(in directory: URL) throws -> URL {
        let helper = directory.appendingPathComponent("fake-helper.js")
        let source = #"""
        "use strict";
        const fs = require("node:fs");
        const args = process.argv.slice(2);
        const command = args[0];
        if (command === "invalid-output") {
          process.stdout.write("not-json");
          process.exit(0);
        }
        if (command === "nonzero") {
          process.stdout.write(JSON.stringify({
            ok: true,
            status: { mode: "fake" },
            error: null
          }));
          process.exit(7);
        }
        const stdin = command === "apply" ? fs.readFileSync(0) : Buffer.alloc(0);
        const input = stdin.length ? JSON.parse(stdin.toString("utf8")) : null;
        const valueAfter = (flag) => {
          const index = args.indexOf(flag);
          return index < 0 ? null : args[index + 1];
        };
        process.stdout.write(JSON.stringify({
          ok: true,
          status: {
            codexPath: valueAfter("--codex-app"),
            mode: "fake",
            activeThemeID: input && input.themeID,
            activeThemeName: input && input.themeName
          },
          error: null,
          rawOutput: JSON.stringify({ args, input })
        }));
        """#
        try Data(source.utf8).write(to: helper)
        return helper
    }

    private func makeRunner() throws -> (
        runner: RuntimeHelperRunner,
        codexApp: URL,
        userRoot: URL
    ) {
        let root = try makeTemporaryDirectory()
        let helper = try makeHelper(in: root)
        let codexApp = root.appendingPathComponent(
            "Codex Test.app",
            isDirectory: true
        )
        let userRoot = root.appendingPathComponent(
            "User Root",
            isDirectory: true
        )
        let node = try XCTUnwrap(
            RuntimeLocator.defaultNodeExecutable(
                codexApp: codexApp,
                environment: ProcessInfo.processInfo.environment
            ),
            "Tests require the same Node runtime as the production helper."
        )
        return (
            RuntimeHelperRunner(
                helperScript: helper,
                codexApp: codexApp,
                userRoot: userRoot,
                nodeExecutable: node
            ),
            codexApp,
            userRoot
        )
    }

    func testApplyEncodesPayloadAndPassesExactRuntimeArguments() async throws {
        let fixture = try makeRunner()

        let result = try await fixture.runner.apply(
            css: ":root { color: 🟣; }",
            themeID: "purple",
            themeName: "Purple"
        )

        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.status?.codexPath, fixture.codexApp.path)
        XCTAssertEqual(result.status?.activeThemeID, "purple")
        XCTAssertEqual(result.status?.activeThemeName, "Purple")

        let rawOutput = try XCTUnwrap(result.rawOutput)
        let rawData = try XCTUnwrap(rawOutput.data(using: .utf8))
        let wire = try XCTUnwrap(
            JSONSerialization.jsonObject(with: rawData)
                as? [String: Any]
        )
        let args = try XCTUnwrap(wire["args"] as? [String])
        XCTAssertEqual(
            args,
            [
                "apply",
                "--codex-app", fixture.codexApp.path,
                "--user-root", fixture.userRoot.path,
                "--json"
            ]
        )
        let input = try XCTUnwrap(wire["input"] as? [String: String])
        XCTAssertEqual(input["themeID"], "purple")
        XCTAssertEqual(input["themeName"], "Purple")
        XCTAssertEqual(input["css"], ":root { color: 🟣; }")
    }

    func testConvenienceCommandsForwardTheirCommandNames() async throws {
        let fixture = try makeRunner()
        let commands: [(String, () async throws -> ThemeRuntimeResult)] = [
            ("status", { try await fixture.runner.status() }),
            ("launch", { try await fixture.runner.launch() }),
            ("inject", { try await fixture.runner.inject() }),
            ("clear", { try await fixture.runner.clear() }),
            ("stop", { try await fixture.runner.stop() })
        ]

        for (expected, invoke) in commands {
            let result = try await invoke()
            let rawOutput = try XCTUnwrap(result.rawOutput)
            let data = try XCTUnwrap(rawOutput.data(using: .utf8))
            let wire = try XCTUnwrap(
                JSONSerialization.jsonObject(with: data)
                    as? [String: Any]
            )
            let args = try XCTUnwrap(wire["args"] as? [String])
            XCTAssertEqual(args.first, expected)
        }
    }

    func testNonzeroExitCannotReportSuccess() async throws {
        let fixture = try makeRunner()

        let result = try await fixture.runner.run(command: "nonzero")

        XCTAssertFalse(result.ok)
        XCTAssertEqual(result.status?.mode, "fake")
        XCTAssertEqual(result.error?.code, "process-exit")
        XCTAssertEqual(
            result.error?.message,
            "Runtime helper exited with status 7."
        )
    }

    func testInvalidOutputProducesStructuredFailureWithRawOutput() async throws {
        let fixture = try makeRunner()

        let result = try await fixture.runner.run(command: "invalid-output")

        XCTAssertFalse(result.ok)
        XCTAssertNil(result.status)
        XCTAssertEqual(result.error?.code, "invalid-output")
        XCTAssertEqual(result.error?.message, "not-json")
        XCTAssertEqual(result.rawOutput, "not-json")
    }

    func testActorControllerForwardsApply() async throws {
        let fixture = try makeRunner()
        let controller = ThemeRuntimeController(runner: fixture.runner)

        let result = try await controller.apply(
            css: ":root{}",
            themeID: "actor",
            themeName: "Actor"
        )

        XCTAssertEqual(result.status?.activeThemeID, "actor")
        XCTAssertEqual(result.status?.activeThemeName, "Actor")
    }
}
