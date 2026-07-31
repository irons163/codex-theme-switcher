import Foundation
import XCTest

final class Live2DRuntimeTests: XCTestCase {
    func testRuntimeKeepsFlatRendererAndAddsLive2DLifecycle() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("const VERSION = 25;"))
        XCTAssertTrue(source.contains("function prepareVoiceImages("))
        XCTAssertTrue(source.contains("function mountVoiceLive2D("))
        XCTAssertTrue(source.contains("function destroyVoiceLive2D("))
        XCTAssertTrue(source.contains("refreshVoicePulseSync,"))
        XCTAssertTrue(source.contains("live2D: {"))
    }

    func testBundledLive2DLibrariesIncludeTheirLicenses() {
        let vendor = runtimeDirectory.appendingPathComponent(
            "vendor",
            isDirectory: true
        )
        for filename in [
            "pixi.min.js",
            "pixi-live2d-display-cubism4.min.js",
            "LICENSE-pixi.txt",
            "LICENSE-pixi-live2d-display.txt"
        ] {
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: vendor.appendingPathComponent(filename).path
                ),
                "\(filename) should be bundled"
            )
        }
    }

    func testInjectionRecognizesOnlyLive2DThemes() throws {
        let injection = runtimeDirectory
            .appendingPathComponent("lib/injection.js")
        let script = """
        const runtime = require(\(javascriptString(injection.path)));
        const result = {
          version: runtime.RENDERER_RUNTIME_VERSION,
          live: runtime.themeUsesLive2D({
            css: ':root{--cts-voice-avatar-mode: live2D;}'
          }),
          flat: runtime.themeUsesLive2D({
            css: ':root{--cts-voice-avatar-mode: image;}'
          })
        };
        process.stdout.write(JSON.stringify(result));
        """
        let result = try runNode(script)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: result) as? [String: Any]
        )

        XCTAssertEqual(object["version"] as? Int, 25)
        XCTAssertEqual(object["live"] as? Bool, true)
        XCTAssertEqual(object["flat"] as? Bool, false)
    }

    private var runtimeDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/CodexThemeRuntime/Resources/runtime")
    }

    private func runNode(_ source: String) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", "-e", source]
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        XCTAssertEqual(
            process.terminationStatus,
            0,
            String(data: errorData, encoding: .utf8) ?? ""
        )
        return output.fileHandleForReading.readDataToEndOfFile()
    }

    private func javascriptString(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value])
        let array = data.flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "[]"
        return String(array.dropFirst().dropLast())
    }
}
