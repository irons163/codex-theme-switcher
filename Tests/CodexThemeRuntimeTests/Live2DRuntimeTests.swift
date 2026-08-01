import Foundation
import XCTest

final class Live2DRuntimeTests: XCTestCase {
    func testRuntimeKeepsFlatRendererAndAddsLive2DLifecycle() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("const VERSION = 46;"))
        XCTAssertTrue(
            source.contains(
                ".codex-avatar-root:not([data-codex-pet-id])"
            )
        )
        XCTAssertTrue(source.contains("function prepareVoiceImages("))
        XCTAssertTrue(source.contains("function mountVoiceLive2D("))
        XCTAssertTrue(source.contains("function destroyVoiceLive2D("))
        XCTAssertTrue(source.contains("pulse.canvasLastError = null"))
        XCTAssertTrue(source.contains("finally {"))
        XCTAssertTrue(source.contains("function ensureLive2DBlobLoader("))
        XCTAssertTrue(source.contains("async function live2DSettings("))
        XCTAssertTrue(source.contains("function ensureLive2DDrawOrderCompatibility("))
        XCTAssertTrue(source.contains("drawables.drawOrders"))
        XCTAssertTrue(source.contains("const normalizedOrders = new Int32Array("))
        XCTAssertTrue(source.contains("|| right - left"))
        XCTAssertTrue(source.contains("hides blinking"))
        XCTAssertTrue(source.contains("const asset = live2DAsset("))
        XCTAssertTrue(source.contains("await asset.blob.arrayBuffer()"))
        XCTAssertTrue(source.contains("new Settings(settingsJSON)"))
        XCTAssertTrue(source.contains("[data-codex-live2d-avatar]"))
        XCTAssertFalse(source.contains("const response = await fetch(url);"))
        XCTAssertTrue(source.contains("refreshVoicePulseSync,"))
        XCTAssertTrue(source.contains("live2D: {"))
        XCTAssertTrue(source.contains("const eyeBlinkIDs = internal.eyeBlink"))
        XCTAssertTrue(source.contains("state.eyeBlinkAmount = blinkAmount"))
        XCTAssertTrue(source.contains("coreModel.setParameterValueById(handles.eyeLeft"))
        XCTAssertTrue(source.contains("modelUpdateWrapper"))
        XCTAssertTrue(source.contains("immediately before Pixi draws the model"))
        XCTAssertTrue(source.contains("coreModel.update?.()"))
        XCTAssertTrue(source.contains("set(handles.mouth, mouth, 1)"))
        XCTAssertTrue(source.contains("silence always returns ParamMouthOpenY"))
        XCTAssertTrue(source.contains("function steppedVoiceMouthLevel("))
        XCTAssertTrue(source.contains("const maximumIndex = frameCount - 1"))
        XCTAssertTrue(source.contains("the exact mouth-frame steps"))
        XCTAssertTrue(source.contains("function setVoiceSessionActive("))
        XCTAssertTrue(source.contains("sessionPhase === \"active\""))
        XCTAssertTrue(source.contains("setVoiceSessionActive(false)"))
        XCTAssertTrue(source.contains("VOICE_SESSION_STYLE_ID"))
        XCTAssertTrue(source.contains("data-codex-pet-id"))
        XCTAssertTrue(source.contains("avatar-mascot-button"))
        XCTAssertTrue(source.contains("mascot-badge"))
        XCTAssertTrue(source.contains("VOICE_SESSION_ACTIVE_ATTRIBUTE"))
    }

    func testBundledLive2DLibrariesIncludeTheirLicenses() {
        let vendor = runtimeDirectory.appendingPathComponent(
            "vendor",
            isDirectory: true
        )
        for filename in [
            "pixi.min.js",
            "pixi-unsafe-eval.min.js",
            "pixi-live2d-display-cubism4.min.js",
            "LICENSE-pixi.txt",
            "LICENSE-pixi-unsafe-eval.txt",
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
        let injectionSource = try String(
            contentsOf: injection,
            encoding: .utf8
        )
        XCTAssertTrue(injectionSource.contains("previousDocumentMarker"))
        XCTAssertTrue(
            injectionSource.contains(
                "require the old global marker to disappear"
            )
        )
        XCTAssertFalse(injectionSource.contains("await delay(150);"))

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

        XCTAssertEqual(object["version"] as? Int, 46)

        let nativeCompositionTest = """
        const runtime = require(\(javascriptString(injection.path)));
        class Storage {
          constructor(values) { this.values = values; }
          getItem(key) { return this.values[key] ?? null; }
        }
        global.Storage = Storage;
        const gate = {
          name: "620613358",
          value: true,
          rule_id: "enabled"
        };
        const inner = { feature_gates: { "620613358": gate } };
        const stored = JSON.stringify({ data: JSON.stringify(inner) });
        const storage = new Storage({
          "statsig.cached.evaluations.test": stored,
          "unrelated": "unchanged"
        });
        eval(runtime.live2DNativeCompositionOverrideSource());
        const returned = storage.getItem(
          "statsig.cached.evaluations.test"
        );
        const parsed = JSON.parse(JSON.parse(returned).data);
        const original = JSON.parse(JSON.parse(stored).data);
        process.stdout.write(JSON.stringify({
          gate: parsed.feature_gates["620613358"].value,
          original: original.feature_gates["620613358"].value,
          unrelated: storage.getItem("unrelated"),
          overlay: runtime.isAvatarOverlayIndexURL(
            "app://-/index.html?initialRoute=%2Favatar-overlay"
          ),
          composition: runtime.isAvatarOverlayIndexURL(
            "app://-/avatar-overlay-composition-surface.html?surfaceId=voice-output"
          )
        }));
        """
        let nativeCompositionData = try runNode(nativeCompositionTest)
        let nativeComposition = try XCTUnwrap(
            JSONSerialization.jsonObject(with: nativeCompositionData)
                as? [String: Any]
        )
        XCTAssertEqual(nativeComposition["gate"] as? Bool, false)
        XCTAssertEqual(nativeComposition["original"] as? Bool, true)
        XCTAssertEqual(nativeComposition["unrelated"] as? String, "unchanged")
        XCTAssertEqual(nativeComposition["overlay"] as? Bool, true)
        XCTAssertEqual(nativeComposition["composition"] as? Bool, false)

        let cdp = runtimeDirectory.appendingPathComponent("lib/cdp.js")
        let targetTest = """
        const { codexAvatarOverlayTargets } = require(\(javascriptString(cdp.path)));
        const targets = [
          { type: "page", webSocketDebuggerUrl: "ws://main", url: "app://-/index.html?initialRoute=%2Favatar-overlay" },
          { type: "page", webSocketDebuggerUrl: "ws://voice", url: "app://-/avatar-overlay-composition-surface.html?surfaceId=voice-output" },
          { type: "page", webSocketDebuggerUrl: "ws://activity", url: "app://-/avatar-overlay-composition-surface.html?surfaceId=activity-slot-0" }
        ];
        process.stdout.write(JSON.stringify(codexAvatarOverlayTargets(targets).map((target) => target.url)));
        """
        let targetData = try runNode(targetTest)
        let overlayURLs = try XCTUnwrap(
            JSONSerialization.jsonObject(with: targetData) as? [String]
        )
        XCTAssertEqual(overlayURLs.count, 2)
        XCTAssertTrue(overlayURLs.contains { $0.contains("surfaceId=voice-output") })
        XCTAssertFalse(overlayURLs.contains { $0.contains("activity-slot-0") })
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
