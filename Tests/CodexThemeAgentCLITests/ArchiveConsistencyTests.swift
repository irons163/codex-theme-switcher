import CodexThemeSwitcherCore
import Foundation
import XCTest
@testable import CodexThemeAgentCLI

@MainActor
final class ArchiveConsistencyTests: XCTestCase {
    func testSampleResponseAndWrittenArchiveUseSameEnvelope() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("sample.codextheme")

        let execution = await CodexThemeAgentCLI().run(
            arguments: [
                "sample",
                "--archive",
                "--output", output.path
            ]
        )

        XCTAssertEqual(execution.exitCode, 0)
        let response = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: execution.standardOutput
            ) as? [String: Any]
        )
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let responseArchive = try XCTUnwrap(
            data["archive"] as? [String: Any]
        )
        let responseArchiveData = try JSONSerialization.data(
            withJSONObject: responseArchive,
            options: [.sortedKeys]
        )
        let responseEnvelope = try ThemeJSONCoding.decoder().decode(
            ThemeArchiveEnvelope.self,
            from: responseArchiveData
        )
        let fileEnvelope = try ThemeJSONCoding.decoder().decode(
            ThemeArchiveEnvelope.self,
            from: Data(contentsOf: output)
        )

        XCTAssertEqual(responseEnvelope, fileEnvelope)
    }

    func testNormalizePreservesArchiveMetadataAndIsIdempotent() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("input.codextheme")
        let first = directory.appendingPathComponent("first.codextheme")
        let second = directory.appendingPathComponent("second.codextheme")
        let envelope = ThemeArchiveEnvelope(
            format: ThemeArchiveService.formatIdentifier,
            archiveVersion: ThemeArchiveService.currentArchiveVersion,
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000.25),
            theme: BuiltInThemes.paper
        )
        try ThemeJSONCoding.encoder().encode(envelope).write(to: input)

        let firstExecution = await CodexThemeAgentCLI().run(
            arguments: [
                "normalize",
                "--archive",
                "--input", input.path,
                "--output", first.path
            ]
        )
        let secondExecution = await CodexThemeAgentCLI().run(
            arguments: [
                "normalize",
                "--archive",
                "--input", first.path,
                "--output", second.path
            ]
        )

        XCTAssertEqual(firstExecution.exitCode, 0)
        XCTAssertEqual(secondExecution.exitCode, 0)
        XCTAssertEqual(
            try Data(contentsOf: first),
            try Data(contentsOf: second)
        )
        let normalized = try ThemeJSONCoding.decoder().decode(
            ThemeArchiveEnvelope.self,
            from: Data(contentsOf: second)
        )
        XCTAssertEqual(normalized.exportedAt, envelope.exportedAt)
        XCTAssertEqual(normalized.archiveVersion, envelope.archiveVersion)
        XCTAssertEqual(normalized.format, envelope.format)
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
}
