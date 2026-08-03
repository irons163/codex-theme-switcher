import Foundation
import XCTest

final class Live2DRuntimeTests: XCTestCase {
    func testRuntimeKeepsFlatRendererAndAddsLive2DLifecycle() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("const VERSION = 67;"))
        XCTAssertTrue(
            source.contains(
                "VOICE_SESSION_INACTIVE_GRACE_MILLISECONDS = 500"
            )
        )
        XCTAssertTrue(
            source.contains(
                ".codex-avatar-root[data-realtime-voice-orb]"
            )
        )
        XCTAssertTrue(source.contains("function prepareVoiceImages("))
        XCTAssertTrue(source.contains("function mountVoiceLive2D("))
        XCTAssertTrue(source.contains("function destroyVoiceLive2D("))
        XCTAssertTrue(source.contains("preserveLive2D = false"))
        XCTAssertTrue(source.contains("root.appendChild(state.container)"))
        XCTAssertTrue(source.contains("data-codex-live2d-loading"))
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
        XCTAssertTrue(source.contains("VOICE_PRESENTATION_ATTRIBUTE"))
        XCTAssertTrue(source.contains("function markVoicePresentationAncestors("))
        XCTAssertTrue(source.contains("function clearVoicePresentationAncestors("))
        XCTAssertTrue(
            source.contains("voiceRendererRole() === \"foreground\"")
        )
        XCTAssertTrue(source.contains("pulse.sessionPhase = \"starting\""))
        XCTAssertTrue(source.contains("function rendererVoiceSessionActive("))
        XCTAssertTrue(source.contains("function instrumentVoiceRenderer("))
        XCTAssertTrue(source.contains("function releaseVoiceRendererInstrumentation("))
        XCTAssertTrue(source.contains("function synchronizeRendererVoiceFrame("))
        XCTAssertTrue(source.contains("function renderVoiceLive2DFrame("))
        XCTAssertTrue(source.contains("Prime Pixi immediately"))
        XCTAssertTrue(source.contains("renderVoiceLive2DFrame();"))
        XCTAssertTrue(source.contains("preserveDrawingBuffer: true"))
        XCTAssertTrue(source.contains("cleared back buffer"))
        XCTAssertTrue(
            source.contains("function copyLive2DPresentationFrame(")
        )
        XCTAssertTrue(
            source.contains("function initializeLive2DPresentation(")
        )
        XCTAssertTrue(source.contains("getContext(\"2d\""))
        XCTAssertFalse(source.contains("getContext(\"bitmaprenderer\""))
        XCTAssertFalse(source.contains("transferFromImageBitmap(bitmap)"))
        XCTAssertTrue(
            source.contains("waitForLive2DPresentationFrame(")
        )
        XCTAssertTrue(
            source.contains("function installLive2DPresentationMirror(")
        )
        XCTAssertTrue(source.contains("view: renderCanvas"))
        XCTAssertTrue(source.contains("context.globalCompositeOperation = \"copy\""))
        XCTAssertTrue(source.contains("gl.finish()"))
        XCTAssertTrue(source.contains("copyLive2DPresentationFrame(state)"))
        XCTAssertTrue(source.contains("renderer.setInputs = wrappedSetInputs"))
        XCTAssertTrue(
            source.contains(
                "renderer.setPublishedAudioLevels = wrappedSetPublishedAudioLevels"
            )
        )
        XCTAssertTrue(source.contains("renderer.setInputs = pulse.originalSetInputs"))
        XCTAssertTrue(
            source.contains(
                "pulse.originalSetPublishedAudioLevels"
            )
        )
        XCTAssertTrue(
            source.contains(
                "phase === \"starting\" || phase === \"active\""
            )
        )
        XCTAssertFalse(source.contains("sessionPhase === \"active\""))
        XCTAssertTrue(source.contains("const rendererHasActivity"))
        XCTAssertTrue(source.contains("it is the authoritative"))
        XCTAssertTrue(source.contains("setVoiceSessionActive(false)"))
        XCTAssertTrue(source.contains("function deferVoiceSessionDeactivation("))
        XCTAssertTrue(source.contains("sessionDeactivationTimer"))
        XCTAssertTrue(source.contains("VOICE_SESSION_STYLE_ID"))
        XCTAssertTrue(
            source.contains("canvas[data-codex-live2d-canvas]")
        )
        XCTAssertTrue(source.contains("will-change: auto !important;"))
        XCTAssertTrue(source.contains("data-codex-pet-id"))
        XCTAssertTrue(source.contains("avatar-mascot-button"))
        XCTAssertTrue(source.contains("mascot-badge"))
        XCTAssertTrue(source.contains("VOICE_SESSION_ACTIVE_ATTRIBUTE"))
        XCTAssertTrue(source.contains("VOICE_ACTIVITY_SHELF_ATTRIBUTE"))
        XCTAssertFalse(source.contains("VOICE_ACTIVITY_BACKDROP_ATTRIBUTE"))
        XCTAssertTrue(source.contains("VOICE_ACTIVITY_TRAY_HEIGHT"))
        XCTAssertTrue(source.contains("VOICE_ACTIVITY_TRAY_TOP"))
        XCTAssertTrue(source.contains("VOICE_ACTIVITY_PLACEMENT_ATTRIBUTE"))
        XCTAssertTrue(source.contains("function voiceActivityVisibleSlots("))
        XCTAssertTrue(source.contains("function voiceActivityTrayVisualHeight("))
        XCTAssertFalse(source.contains("function voiceActivityReservedRowHeight("))
        XCTAssertFalse(source.contains("const reservedRowHeight"))
        XCTAssertTrue(source.contains("const trayVisualHeight"))
        XCTAssertTrue(source.contains("function voiceActivityTrayLayout("))
        XCTAssertTrue(source.contains("const nativePlacement"))
        XCTAssertTrue(source.contains("activityShelfPresentationObserver"))
        XCTAssertTrue(source.contains("function synchronizeVoiceActivityShelf("))
        XCTAssertTrue(source.contains("function startVoiceActivityShelfSync("))
        XCTAssertTrue(source.contains("function stopVoiceActivityShelfSync("))
        XCTAssertFalse(
            source.contains("VOICE_ACTIVITY_PRESENTATION_LEFT")
        )
        XCTAssertFalse(
            source.contains("VOICE_ACTIVITY_PRESENTATION_SCALE")
        )
        XCTAssertTrue(source.contains("activityShelfTrayPositionObserver"))
        XCTAssertTrue(
            source.contains(
                "const rootLayout = layoutRectWithin(root, layoutTarget)"
            )
        )
        XCTAssertTrue(
            source.contains("visible horizontal feedback loop")
        )
        XCTAssertTrue(
            source.contains(
                "data-avatar-overlay-native-surface-id^=\"activity-slot-\""
            )
        )
        XCTAssertTrue(source.contains("const rootWidth = Number(root.offsetWidth)"))
        XCTAssertTrue(source.contains("untransformed CSS layout box"))
        XCTAssertTrue(source.contains("voiceSessionActive:"))
        XCTAssertTrue(source.contains("voiceSessionPhase:"))
        XCTAssertTrue(source.contains("voiceRendererFound:"))
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

    func testLive2DPresentationCopiesIntoOneStable2DSurface() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(
            source.range(
                of: "  function synchronizeLive2DPresentationCanvas("
            )
        )
        let end = try XCTUnwrap(
            source.range(
                of: "\n  function ensureLive2DDrawOrderCompatibility(",
                range: start.upperBound..<source.endIndex
            )
        )
        let functions = String(source[start.lowerBound..<end.lowerBound])
        let script = """
        \(functions)
        (async () => {
          const copies = [];
          const context = {
            save() {},
            restore() {},
            setTransform() {},
            drawImage(source) { copies.push(source.frame); },
            globalCompositeOperation: "source-over"
          };
          const presentation = {
            width: 300,
            height: 150,
            isConnected: true,
            getContext(type) {
              return type === "2d" ? context : null;
            }
          };
          const renderCanvas = { width: 64, height: 64, frame: 0 };
          let renders = 0;
          let finishes = 0;
          const renderer = {
            gl: { finish() { finishes += 1; } },
            render() {
              renders += 1;
              renderCanvas.frame = renders;
              return renders;
            }
          };
          const state = {
            generation: 1,
            canvas: presentation,
            renderCanvas,
            app: { renderer },
            presentationContext: null,
            presentationMode: "",
            presentationCopyPending: false,
            presentationLatestRequested: 0,
            presentationCommittedSequence: 0,
            presentationFrameReady: false,
            presentationError: null
          };
          initializeLive2DPresentation(state);
          installLive2DPresentationMirror(state);
          renderer.render();
          renderer.render();
          renderer.render();
          process.stdout.write(JSON.stringify({
            mode: state.presentationMode,
            copies,
            finishes,
            committed: state.presentationCommittedSequence,
            ready: state.presentationFrameReady,
            pending: state.presentationCopyPending,
            width: presentation.width,
            height: presentation.height
          }));
        })().catch((error) => {
          console.error(error);
          process.exitCode = 1;
        });
        """
        let data = try runNode(script)
        let result = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(result["mode"] as? String, "2d")
        XCTAssertEqual(result["copies"] as? [Int], [1, 2, 3])
        XCTAssertEqual(result["finishes"] as? Int, 3)
        XCTAssertEqual(result["committed"] as? Int, 3)
        XCTAssertEqual(result["ready"] as? Bool, true)
        XCTAssertEqual(result["pending"] as? Bool, false)
        XCTAssertEqual(result["width"] as? Int, 64)
        XCTAssertEqual(result["height"] as? Int, 64)
    }

    func testVoiceSessionVisibilityCoversUpdatedChatGPTPhases() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(
            source.range(of: "  function rendererVoiceSessionActive(")
        )
        let end = try XCTUnwrap(
            source.range(
                of: "\n  function isVoiceRendererInstance(",
                range: start.upperBound..<source.endIndex
            )
        )
        let functionSource = String(source[start.lowerBound..<end.lowerBound])
        let script = """
        \(functionSource)
        const runtime = {
          voicePulse: {
            root: {},
            canvasLastError: null,
            sessionActive: false,
            sessionPhase: "inactive",
            instrumentedAudioRenderer: null,
            instrumentedSetInputs: null,
            originalSetInputs: null,
            instrumentedSetPublishedAudioLevels: null,
            originalSetPublishedAudioLevels: null
          }
        };
        const transitions = [];
        let deactivationPending = false;
        let synchronizedFrames = 0;
        function synchronizeVoiceCanvas() { return true; }
        function renderVoiceLive2DFrame() { synchronizedFrames += 1; }
        function rendererVoiceLevel() { return 0; }
        function speakingFallbackEnergy() { return 0.5; }
        function synchronizeVoiceMouth() {}
        function synchronizeVoiceIdle() {}
        function setVoiceSessionActive(active) {
          if (active) deactivationPending = false;
          runtime.voicePulse.sessionActive = Boolean(active);
          transitions.push(Boolean(active));
        }
        function deferVoiceSessionDeactivation() {
          deactivationPending = true;
        }
        function flushVoiceSessionDeactivation() {
          if (!deactivationPending) return;
          deactivationPending = false;
          setVoiceSessionActive(false);
        }
        const phase = (value) => rendererVoiceSessionActive({
          inputs: { phase: value, voiceActivity: "idle" },
          publishedAudioLevels: null
        });
        const originalSetInputs = function (inputs) {
          this.inputs = inputs;
        };
        const originalSetPublishedAudioLevels = function (levels) {
          this.publishedAudioLevels = levels;
        };
        const renderer = {
          inputs: { phase: "inactive", voiceActivity: "idle" },
          publishedAudioLevels: null,
          setInputs: originalSetInputs,
          setPublishedAudioLevels: originalSetPublishedAudioLevels
        };
        instrumentVoiceRenderer(renderer);
        renderer.setInputs({ phase: "starting", voiceActivity: "idle" });
        const instrumentedStarting = {
          active: runtime.voicePulse.sessionActive,
          phase: runtime.voicePulse.sessionPhase
        };
        renderer.setInputs({ phase: "stopping", voiceActivity: "idle" });
        const instrumentedStopping = {
          active: runtime.voicePulse.sessionActive,
          phase: runtime.voicePulse.sessionPhase,
          pending: deactivationPending
        };
        renderer.setInputs({ phase: "inactive", voiceActivity: "idle" });
        const instrumentedInactive = {
          active: runtime.voicePulse.sessionActive,
          phase: runtime.voicePulse.sessionPhase,
          pending: deactivationPending
        };
        flushVoiceSessionDeactivation();
        const afterGrace = runtime.voicePulse.sessionActive;
        renderer.setPublishedAudioLevels({ overall: 0.42 });
        releaseVoiceRendererInstrumentation();
        process.stdout.write(JSON.stringify({
          inactive: phase("inactive"),
          starting: phase("starting"),
          active: phase("active"),
          stopping: phase("stopping"),
          speakingFallback: rendererVoiceSessionActive({
            inputs: { voiceActivity: "speaking" },
            publishedAudioLevels: null
          }),
          audioFallback: rendererVoiceSessionActive({
            inputs: { voiceActivity: "idle" },
            publishedAudioLevels: { overall: 0 }
          }),
          unknown: rendererVoiceSessionActive(null),
          instrumentedStarting,
          instrumentedStopping,
          instrumentedInactive,
          afterGrace,
          restoredInputs: renderer.setInputs === originalSetInputs,
          restoredLevels: renderer.setPublishedAudioLevels
            === originalSetPublishedAudioLevels,
          synchronizedFrames,
          transitions
        }));
        """
        let data = try runNode(script)
        let result = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(result["inactive"] as? Bool, false)
        XCTAssertEqual(result["starting"] as? Bool, true)
        XCTAssertEqual(result["active"] as? Bool, true)
        XCTAssertEqual(result["stopping"] as? Bool, false)
        XCTAssertEqual(result["speakingFallback"] as? Bool, true)
        XCTAssertEqual(result["audioFallback"] as? Bool, true)
        XCTAssertTrue(result["unknown"] is NSNull)
        let instrumentedStarting = result["instrumentedStarting"]
            as? [String: Any]
        XCTAssertEqual(instrumentedStarting?["active"] as? Bool, true)
        XCTAssertEqual(instrumentedStarting?["phase"] as? String, "starting")
        let instrumentedStopping = result["instrumentedStopping"]
            as? [String: Any]
        XCTAssertEqual(instrumentedStopping?["active"] as? Bool, true)
        XCTAssertEqual(instrumentedStopping?["phase"] as? String, "stopping")
        XCTAssertEqual(instrumentedStopping?["pending"] as? Bool, true)
        let instrumentedInactive = result["instrumentedInactive"]
            as? [String: Any]
        XCTAssertEqual(instrumentedInactive?["active"] as? Bool, true)
        XCTAssertEqual(instrumentedInactive?["phase"] as? String, "inactive")
        XCTAssertEqual(instrumentedInactive?["pending"] as? Bool, true)
        XCTAssertEqual(result["afterGrace"] as? Bool, false)
        XCTAssertEqual(result["restoredInputs"] as? Bool, true)
        XCTAssertEqual(result["restoredLevels"] as? Bool, true)
        XCTAssertGreaterThanOrEqual(result["synchronizedFrames"] as? Int ?? 0, 4)
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

        XCTAssertEqual(object["version"] as? Int, 67)

        let nativeCompositionTest = """
        const runtime = require(\(javascriptString(injection.path)));
        const events = [];
        global.MessageEvent = class MessageEvent {
          constructor(type, init) {
            this.type = type;
            Object.assign(this, init);
          }
        };
        global.window = {
          location: { origin: "app://-" },
          dispatchEvent(event) {
            events.push(event);
            return true;
          },
          setTimeout(callback) {
            callback();
            return events.length;
          },
          clearTimeout() {}
        };
        const enabled = eval(
          runtime.live2DNativeCompositionOverrideSource(true)
        );
        const enabledMessage = events.at(-1).data;
        const disabled = eval(
          runtime.live2DNativeCompositionOverrideSource(false)
        );
        const disabledMessage = events.at(-1).data;
        process.stdout.write(JSON.stringify({
          enabled: enabled.forceNonNative,
          enabledMessage,
          disabled: disabled.forceNonNative,
          disabledMessage,
          overlay: runtime.isAvatarOverlayIndexURL(
            "app://-/index.html?initialRoute=%2Favatar-overlay"
          ),
          composition: runtime.isAvatarOverlayIndexURL(
            "app://-/avatar-overlay-composition-surface.html?surfaceId=voice-output"
          ),
          mainIndex: runtime.isCodexIndexURL(
            "app://-/index.html"
          ),
          voiceComposition: runtime.isVoiceCompositionURL(
            "app://-/avatar-overlay-composition-surface.html?surfaceId=voice-output"
          )
        }));
        """
        let nativeCompositionData = try runNode(nativeCompositionTest)
        let nativeComposition = try XCTUnwrap(
            JSONSerialization.jsonObject(with: nativeCompositionData)
            as? [String: Any]
        )
        XCTAssertEqual(nativeComposition["enabled"] as? Bool, true)
        XCTAssertEqual(nativeComposition["disabled"] as? Bool, false)
        let enabledMessage = try XCTUnwrap(
            nativeComposition["enabledMessage"] as? [String: Any]
        )
        XCTAssertEqual(
            enabledMessage["type"] as? String,
            "persisted-atom-updated"
        )
        XCTAssertEqual(
            enabledMessage["key"] as? String,
            "avatar-overlay-force-non-native-rendering"
        )
        XCTAssertEqual(enabledMessage["value"] as? Bool, true)
        XCTAssertEqual(enabledMessage["deleted"] as? Bool, false)
        let disabledMessage = try XCTUnwrap(
            nativeComposition["disabledMessage"] as? [String: Any]
        )
        XCTAssertEqual(disabledMessage["deleted"] as? Bool, true)
        XCTAssertEqual(nativeComposition["overlay"] as? Bool, true)
        XCTAssertEqual(nativeComposition["composition"] as? Bool, false)
        XCTAssertEqual(nativeComposition["mainIndex"] as? Bool, true)
        XCTAssertEqual(nativeComposition["voiceComposition"] as? Bool, true)

        let cdp = runtimeDirectory.appendingPathComponent("lib/cdp.js")
        let targetTest = """
        const { codexAvatarOverlayTargets } = require(\(javascriptString(cdp.path)));
        const injection = require(\(javascriptString(injection.path)));
        const targets = [
          { id: "legacy", type: "page", webSocketDebuggerUrl: "ws://main", url: "app://-/index.html?initialRoute=%2Favatar-overlay" },
          { id: "voice", type: "page", webSocketDebuggerUrl: "ws://voice", url: "app://-/avatar-overlay-composition-surface.html?surfaceId=voice-output" },
          { type: "page", webSocketDebuggerUrl: "ws://activity", url: "app://-/avatar-overlay-composition-surface.html?surfaceId=activity-slot-0" }
        ];
        const live2DTheme = {
          css: ":root { --cts-voice-avatar-mode: live2D; }",
          live2D: { assetID: "model" }
        };
        const allOverlayTargets = codexAvatarOverlayTargets(targets);
        process.stdout.write(JSON.stringify({
          all: allOverlayTargets.map((target) => target.id),
          live2D: injection.preferredAvatarOverlayTargets(
            allOverlayTargets,
            live2DTheme
          ).map((target) => target.id),
          flat: injection.preferredAvatarOverlayTargets(
            allOverlayTargets,
            { css: ".flat { display: block; }" }
          ).map((target) => target.id),
          legacyRole: injection.avatarOverlayTargetRole(
            allOverlayTargets[0],
            allOverlayTargets,
            live2DTheme
          ),
          voiceRole: injection.avatarOverlayTargetRole(
            allOverlayTargets[1],
            allOverlayTargets,
            live2DTheme
          ),
          soloLegacyRole: injection.avatarOverlayTargetRole(
            allOverlayTargets[0],
            [allOverlayTargets[0]],
            live2DTheme
          )
        }));
        """
        let targetData = try runNode(targetTest)
        let overlayTargets = try XCTUnwrap(
            JSONSerialization.jsonObject(with: targetData) as? [String: Any]
        )
        XCTAssertEqual(overlayTargets["all"] as? [String], ["legacy", "voice"])
        XCTAssertEqual(
            overlayTargets["live2D"] as? [String],
            ["legacy"]
        )
        XCTAssertEqual(overlayTargets["flat"] as? [String], ["legacy"])
        XCTAssertEqual(overlayTargets["legacyRole"] as? String, "full")
        XCTAssertEqual(overlayTargets["voiceRole"] as? String, "full")
        XCTAssertEqual(overlayTargets["soloLegacyRole"] as? String, "full")
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
