import AppKit
import CodexThemeSwitcherCore
import Foundation
import XCTest
@testable import CodexThemeAgentCLI

@MainActor
final class CodexThemeAgentCLITests: XCTestCase {
    func testCapabilitiesAdvertiseSafeAgentWorkflow() async throws {
        let execution = await CodexThemeAgentCLI().run(
            arguments: ["capabilities"]
        )

        XCTAssertEqual(execution.exitCode, 0)
        XCTAssertTrue(execution.standardError.isEmpty)
        let response = try object(execution.standardOutput)
        XCTAssertEqual(response["ok"] as? Bool, true)
        XCTAssertEqual(response["protocolVersion"] as? Int, 1)
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let security = try XCTUnwrap(data["security"] as? [String: Any])
        XCTAssertEqual(
            security["applyAcceptsRawCompiledCSS"] as? Bool,
            false
        )
        XCTAssertEqual(security["coreValidationRequired"] as? Bool, true)
        let runtime = try XCTUnwrap(data["runtime"] as? [String: Any])
        XCTAssertEqual(
            runtime["codexAppOption"] as? String,
            "--codex-app <path>"
        )
        XCTAssertEqual(
            runtime["voiceStyleIsolation"] as? Bool,
            true
        )
        XCTAssertEqual(
            runtime["rendererTargets"] as? [String],
            ["main", "avatar-overlay"]
        )
    }

    func testValidateAcceptsDocumentFromStandardInput() async throws {
        let document = BuiltInThemes.paper
        let input = try ThemeJSONCoding.encoder().encode(document)

        let execution = await CodexThemeAgentCLI().run(
            arguments: ["validate", "--input", "-"],
            standardInput: input
        )

        XCTAssertEqual(execution.exitCode, 0)
        let response = try object(execution.standardOutput)
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        XCTAssertEqual(data["valid"] as? Bool, true)
        XCTAssertEqual(data["inputFormat"] as? String, "document")
    }

    func testValidateReturnsStructuredFailureForInvalidTheme() async throws {
        var document = BuiltInThemes.paper
        document.id = UUID()
        document.metadata.name = " "
        let input = try ThemeJSONCoding.encoder().encode(document)

        let execution = await CodexThemeAgentCLI().run(
            arguments: ["validate", "--input", "-"],
            standardInput: input
        )

        XCTAssertEqual(execution.exitCode, 4)
        XCTAssertTrue(execution.standardOutput.isEmpty)
        let response = try object(execution.standardError)
        XCTAssertEqual(response["ok"] as? Bool, false)
        let error = try XCTUnwrap(response["error"] as? [String: Any])
        XCTAssertEqual(error["code"] as? String, "validation_failed")
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        XCTAssertEqual(data["valid"] as? Bool, false)
    }

    func testSampleInstallListGetCompileAndExport() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let sampleURL = root.appendingPathComponent("sample.codextheme")

        let sample = await CodexThemeAgentCLI().run(
            arguments: [
                "sample",
                "--archive",
                "--output", sampleURL.path
            ]
        )
        XCTAssertEqual(sample.exitCode, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sampleURL.path))
        let sampleResponse = try object(sample.standardOutput)
        let sampleData = try XCTUnwrap(
            sampleResponse["data"] as? [String: Any]
        )
        let sampleArchive = try XCTUnwrap(
            sampleData["archive"] as? [String: Any]
        )
        XCTAssertEqual(
            sampleArchive["format"] as? String,
            ThemeArchiveService.formatIdentifier
        )

        let install = await CodexThemeAgentCLI().run(
            arguments: [
                "install",
                "--input", sampleURL.path,
                "--root", root.path
            ]
        )
        XCTAssertEqual(
            install.exitCode,
            0,
            String(data: install.standardError, encoding: .utf8) ?? ""
        )
        let installResponse = try object(install.standardOutput)
        let installData = try XCTUnwrap(
            installResponse["data"] as? [String: Any]
        )
        let document = try XCTUnwrap(
            installData["document"] as? [String: Any]
        )
        let id = try XCTUnwrap(document["id"] as? String)

        let list = await CodexThemeAgentCLI().run(
            arguments: ["list", "--user-only", "--root", root.path]
        )
        XCTAssertEqual(list.exitCode, 0)
        let listResponse = try object(list.standardOutput)
        let listData = try XCTUnwrap(listResponse["data"] as? [String: Any])
        let themes = try XCTUnwrap(listData["themes"] as? [[String: Any]])
        XCTAssertEqual(themes.count, 1)
        XCTAssertEqual(themes[0]["id"] as? String, id)

        let get = await CodexThemeAgentCLI().run(
            arguments: ["get", "--id", id, "--root", root.path]
        )
        XCTAssertEqual(get.exitCode, 0)

        let compile = await CodexThemeAgentCLI().run(
            arguments: ["compile", "--id", id, "--root", root.path]
        )
        XCTAssertEqual(compile.exitCode, 0)
        let compileResponse = try object(compile.standardOutput)
        let compileData = try XCTUnwrap(
            compileResponse["data"] as? [String: Any]
        )
        XCTAssertGreaterThan(compileData["cssCharacterCount"] as? Int ?? 0, 0)

        let archiveURL = root.appendingPathComponent("exported.codextheme")
        let export = await CodexThemeAgentCLI().run(
            arguments: [
                "export",
                "--id", id,
                "--output", archiveURL.path,
                "--root", root.path
            ]
        )
        XCTAssertEqual(export.exitCode, 0)
        let inspection = try ThemeArchiveService().inspect(archiveURL)
        XCTAssertEqual(inspection.theme.id, UUID(uuidString: id))
    }

    func testPreviewWritesPNGAndReportsApproximation() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("paper.png")
        let input = try ThemeJSONCoding.encoder().encode(BuiltInThemes.paper)

        let execution = await CodexThemeAgentCLI().run(
            arguments: [
                "preview",
                "--input", "-",
                "--appearance", "light",
                "--surface", "home",
                "--width", "480",
                "--height", "300",
                "--output", output.path
            ],
            standardInput: input
        )

        XCTAssertEqual(
            execution.exitCode,
            0,
            String(data: execution.standardError, encoding: .utf8) ?? ""
        )
        let png = try Data(contentsOf: output)
        XCTAssertEqual(Array(png.prefix(8)), [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        ])
        let response = try object(execution.standardOutput)
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let renders = try XCTUnwrap(data["renders"] as? [[String: Any]])
        XCTAssertEqual(renders.count, 1)
        XCTAssertEqual(renders[0]["isApproximation"] as? Bool, true)
        XCTAssertEqual(renders[0]["outputPath"] as? String, output.path)
    }

    func testChatPreviewRendersMessageContentRegion() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("paper-chat.png")
        let input = try ThemeJSONCoding.encoder().encode(
            BuiltInThemes.paper
        )

        let execution = await CodexThemeAgentCLI().run(
            arguments: [
                "preview",
                "--input", "-",
                "--appearance", "light",
                "--surface", "chat",
                "--width", "640",
                "--height", "420",
                "--output", output.path
            ],
            standardInput: input
        )

        XCTAssertEqual(
            execution.exitCode,
            0,
            String(data: execution.standardError, encoding: .utf8) ?? ""
        )
        let bitmap = try XCTUnwrap(
            NSBitmapImageRep(data: Data(contentsOf: output))
        )
        XCTAssertEqual(bitmap.pixelsWide, 640)
        XCTAssertEqual(bitmap.pixelsHigh, 420)

        // This rectangle excludes the sidebar, titlebar, and composer. A
        // functioning chat preview fills it with message text and the code card;
        // a collapsed offscreen ScrollView leaves it as one flat background.
        var histogram: [UInt32: Int] = [:]
        for y in 150..<340 {
            for x in 170..<600 {
                guard let color = bitmap.colorAt(x: x, y: y),
                      let key = rgbaKey(color) else {
                    continue
                }
                histogram[key, default: 0] += 1
            }
        }

        let sampledPixels = histogram.values.reduce(0, +)
        let dominantPixels = histogram.values.max() ?? 0
        XCTAssertGreaterThan(sampledPixels, 0)
        XCTAssertGreaterThan(
            sampledPixels - dominantPixels,
            500,
            "The chat message region is visually empty."
        )
    }

    func testPreviewWarnsWhenAssetMIMEIsDisguisedPDF() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("disguised.png")
        let asset = ThemeAsset(
            name: "disguised.png",
            mediaType: "image/png",
            data: makePDFData()
        )
        var skin = ThemeImageSkin()
        skin.light.backgroundAssetID = asset.id
        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.assets = [asset]
        theme.imageSkin = skin

        let execution = await CodexThemeAgentCLI().run(
            arguments: [
                "preview",
                "--input", "-",
                "--appearance", "light",
                "--surface", "home",
                "--width", "480",
                "--height", "300",
                "--output", output.path
            ],
            standardInput: try ThemeJSONCoding.encoder().encode(theme)
        )

        XCTAssertEqual(
            execution.exitCode,
            0,
            String(data: execution.standardError, encoding: .utf8) ?? ""
        )
        let response = try object(execution.standardOutput)
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let renders = try XCTUnwrap(data["renders"] as? [[String: Any]])
        let render = try XCTUnwrap(renders.first)
        let warnings = try XCTUnwrap(
            render["warnings"] as? [[String: Any]]
        )
        XCTAssertTrue(
            warnings.contains {
                $0["code"] as? String == "wallpaper_asset_invalid"
            },
            "A PDF declared as image/png must not enter the wallpaper decoder."
        )
    }

    func testInvalidPreviewSizeReturnsStableErrorCode() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("invalid.png")
        let input = try ThemeJSONCoding.encoder().encode(
            BuiltInThemes.paper
        )

        let execution = await CodexThemeAgentCLI().run(
            arguments: [
                "preview",
                "--input", "-",
                "--appearance", "light",
                "--surface", "home",
                "--width", "239",
                "--height", "300",
                "--output", output.path
            ],
            standardInput: input
        )

        XCTAssertNotEqual(execution.exitCode, 0)
        XCTAssertTrue(execution.standardOutput.isEmpty)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: output.path)
        )
        let response = try object(execution.standardError)
        let error = try XCTUnwrap(response["error"] as? [String: Any])
        XCTAssertEqual(
            error["code"] as? String,
            "invalid_preview_size"
        )
    }

    func testSchemaCommandReturnsTrackedSchema() async throws {
        let execution = await CodexThemeAgentCLI().run(
            arguments: ["schema"]
        )

        XCTAssertEqual(
            execution.exitCode,
            0,
            String(data: execution.standardError, encoding: .utf8) ?? ""
        )
        let response = try object(execution.standardOutput)
        let data = try XCTUnwrap(response["data"] as? [String: Any])
        let schema = try XCTUnwrap(data["schema"] as? [String: Any])
        XCTAssertEqual(
            schema["$schema"] as? String,
            "https://json-schema.org/draft/2020-12/schema"
        )
    }

    private func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }

    private func makePDFData() -> Data {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 16, height: 16))
        return view.dataWithPDF(inside: view.bounds)
    }

    private func rgbaKey(_ color: NSColor) -> UInt32? {
        guard let color = color.usingColorSpace(.sRGB) else {
            return nil
        }
        func byte(_ value: CGFloat) -> UInt32 {
            UInt32(max(0, min(255, Int((value * 255).rounded()))))
        }
        return byte(color.redComponent) << 24
            | byte(color.greenComponent) << 16
            | byte(color.blueComponent) << 8
            | byte(color.alphaComponent)
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
