import Foundation
import XCTest

final class Live2DRuntimeTests: XCTestCase {
    func testNativeInputShapeIncludesPhoneWithoutDroppingExistingControls() throws {
        let source = try String(contentsOf: runtimeDirectory.appendingPathComponent("theme-inject.js"), encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "  function voiceNativeInputRegions("))
        let end = try XCTUnwrap(source.range(of: "  function synchronizeVoicePresentationDrag(", range: start.upperBound..<source.endIndex))
        let script = """
        const assert = require('node:assert/strict');
        const window = { innerWidth: 1920, innerHeight: 1080 };
        const node = (left, top, width, height, extra = {}) => ({
          getBoundingClientRect: () => ({ left, top, right: left + width, bottom: top + height, width, height }),
          closest: () => extra.inert ? {} : null,
          css: { display: 'block', visibility: 'visible', pointerEvents: 'auto', ...extra.css },
          parentElement: extra.parentElement || null,
          offsetWidth: width, offsetHeight: height, clientWidth: width, clientHeight: height, clientLeft: 0, clientTop: 0
        });
        const phone = node(805.7, 270, 308.6, 540);
        const button = node(898, 822, 124, 40);
        const clippingParent = node(100, 100, 40, 40, { css: { overflow: 'hidden' } });
        const clippedCard = node(90, 90, 100, 100, { parentElement: clippingParent });
        let nodes = [phone, button, clippedCard, node(0, 0, 1920, 1080, { inert: true }),
          node(0, 0, 500, 500, { css: { pointerEvents: 'none' } })];
        const document = { querySelectorAll: () => nodes };
        const computedStyle = node => node.css;
        const runtime = { voiceDragDiagnostics: {} };
        const published = [];
        const drag = { nativeRegionHost: { setPointerRegions: async (regions, proximity) => published.push({ regions, proximity }) } };
        \(source[start.lowerBound..<end.lowerBound])
        (async () => {
          await publishVoiceNativeInputRegions(drag, true);
          assert.deepEqual(published[0].regions, [
            { left: 805, top: 270, width: 310, height: 540 },
            { left: 898, top: 822, width: 124, height: 40 },
            { left: 100, top: 100, width: 40, height: 40 }
          ]);
          assert.equal(runtime.voiceDragDiagnostics.nativeRegionsPublished, true);
          await publishVoiceNativeInputRegions(drag, true);
          assert.equal(published.length, 1, 'unchanged regions must not reset native mouse capture');
          drag.pointerID = 7;
          await publishVoiceNativeInputRegions(drag, true);
          assert.deepEqual(published[1].regions, [{ left: 0, top: 0, width: 1920, height: 1080 }],
            'a fast drag must remain interactive beyond the previous phone position');
          drag.pointerID = null;
          nodes = nodes.filter(node => node !== phone);
          await publishVoiceNativeInputRegions(drag, true);
          assert.equal(published[2].regions.length, 2);
          assert.deepEqual(published[2].regions[0], published[0].regions[1], 'native buttons must remain clickable after removing Voice');
          process.stdout.write(JSON.stringify({ passed: true }));
        })().catch(error => { console.error(error); process.exitCode = 1; });
        """
        let result = try JSONSerialization.jsonObject(with: runNode(script)) as? [String: Bool]
        XCTAssertEqual(result?["passed"], true)
    }

    func testVoiceDragCapturesPointerKeepsControlsOnscreenAndRemembersPosition() throws {
        let source = try String(contentsOf: runtimeDirectory.appendingPathComponent("theme-inject.js"), encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "  function synchronizeLive2DPresentationRoot("))
        let end = try XCTUnwrap(source.range(of: "  function mountLive2DPresentationContainer(", range: start.upperBound..<source.endIndex))
        let script = """
        const assert = require('node:assert/strict');
        class Node {
          constructor() {
            this.children = []; this.handlers = {}; this.vars = new Map(); this.attributes = new Map();
            this.style = { getPropertyValue: key => this.vars.get(key) || '',
              setProperty: (key, value) => this.vars.set(key, value), removeProperty: key => this.vars.delete(key) };
          }
          appendChild(child) { this.children.push(child); child.parent = this; }
          remove() { if(this.parent) this.parent.children = this.parent.children.filter(child => child !== this); }
          setAttribute(key, value) { this.attributes.set(key, value); }
          addEventListener(type, handler) { this.handlers[type] = handler; }
          setPointerCapture(id) { this.captured = id; }
          releasePointerCapture(id) { if(this.captured === id) this.captured = null; }
          getBoundingClientRect() { return { left: 0, top: 0, right: 1920, bottom: 1080 }; }
          emit(type, values) { const event = { type, button: 0, pointerId: 7, clientX: 960, clientY: 540,
            preventDefault() {}, stopPropagation() {}, ...values };
            listeners.get(type)?.(event); this.handlers[type]?.(event); }
        }
        const stored = new Map();
        const nativeMessages = [];
        const listeners = new Map(), timers = new Map();
        const frames = new Map();
        let timerSequence = 0;
        function setTimeout(callback) { timers.set(++timerSequence, callback); return timerSequence; }
        function clearTimeout(id) { timers.delete(id); }
        function requestAnimationFrame(callback) { frames.set(++timerSequence, callback); return timerSequence; }
        function cancelAnimationFrame(id) { frames.delete(id); }
        const window = { innerWidth: 1920, innerHeight: 1080, sessionStorage: {
          getItem: key => stored.get(key), setItem: (key, value) => stored.set(key, value) },
          electronBridge: { sendMessageFromView: message => { nativeMessages.push(message); return Promise.resolve(); } },
          addEventListener: (type, listener) => listeners.set(type, listener), removeEventListener: type => listeners.delete(type) };
        const document = { body: new Node(), documentElement: new Node(), createElement: () => new Node() };
        const customProperty = (_, name) => ({ '--cts-voice-background-size': 'contain', '--cts-voice-background-scale': '0.5' })[name] || '';
        const extractCSSURL = () => null;
        const runtime = { voicePulse: { sessionActive: true } };
        const state = { presentationRoot: {}, model: {}, controlsDockImage: { naturalWidth: 948, naturalHeight: 1659 },
          controlsDock: { node: { getBoundingClientRect: () => ({ width: 330, height: 40 }) } } };
        \(source[start.lowerBound..<end.lowerBound])
        synchronizeVoicePresentationDrag(state);
        const handle = state.presentationDrag.node;
        assert.equal(handle.attributes.get('data-avatar-overlay-hit-region'), 'custom-voice-drag');
        assert.equal(handle.attributes.get('class'), 'no-drag');
        handle.emit('pointerover', {});
        assert.deepEqual(nativeMessages.at(-1), { type: 'avatar-overlay-pointer-interaction-changed', isInteractive: true });
        handle.emit('pointerleave', {});
        for (const callback of timers.values()) callback();
        timers.clear();
        assert.equal(nativeMessages.at(-1).isInteractive, true, 'window mode changes must not turn clicks off while the cursor stays on the phone');
        listeners.get('mousemove')({ clientX: 2000, clientY: 1100 });
        assert.equal(nativeMessages.at(-1).isInteractive, false, 'actual movement outside the phone must restore click-through');
        handle.emit('pointerdown', { button: 2 });
        assert.equal(state.presentationDrag.pointerID, null);
        handle.emit('pointerdown', {});
        assert.equal(handle.captured, 7);
        assert.equal(handle.style.getPropertyValue('width'), '1920px');
        handle.emit('pointermove', { clientX: 1000, clientY: 520 });
        handle.emit('lostpointercapture', {});
        handle.captured = null;
        assert.equal(state.presentationDrag.pointerID, 7, 'transient native capture loss must not end a held gesture');
        handle.emit('pointermove', { clientX: 1100, clientY: 460 });
        handle.emit('pointermove', { clientX: 1140, clientY: 450 });
        assert.equal(frames.size, 1, 'a burst of mouse events should paint once at the latest position');
        assert.deepEqual(runtime.voicePlacement, { x: 0, y: 0 });
        for (const [id, callback] of frames) { frames.delete(id); callback(); }
        assert.deepEqual(runtime.voicePlacement, { x: 180, y: -90 });
        assert.equal(document.documentElement.style.getPropertyValue('--cts-voice-drag-x'), '180px');
        handle.emit('pointerup', {});
        assert.equal(handle.captured, null);
        assert.equal(runtime.voiceDragDiagnostics.presses, 2);
        assert.equal(runtime.voiceDragDiagnostics.rejected, 1);
        assert.equal(runtime.voiceDragDiagnostics.moves, 3);
        assert.equal(runtime.voiceDragDiagnostics.paintedMoves, 1);
        assert.equal(runtime.voiceDragDiagnostics.lostCaptures, 1);
        assert.equal(runtime.voiceDragDiagnostics.finishes, 1);
        assert.equal(runtime.voiceDragDiagnostics.lastFinish, 'pointerup');
        assert.equal(handle.style.getPropertyValue('width'), String(voicePresentationBackgroundBounds(state).width) + 'px');
        runtime.voicePlacement = null;
        assert.deepEqual(voicePresentationOffset(), { x: 180, y: -90 });
        handle.emit('pointerdown', {});
        handle.emit('pointermove', { clientX: 10000, clientY: 10000 });
        handle.emit('mouseup', { clientX: 10000, clientY: 10000 });
        assert.equal(frames.size, 0, 'release must flush the last movement before the next animation frame');
        const bounds = voicePresentationBackgroundBounds(state);
        assert(bounds.bottom + runtime.voicePlacement.y + 40 + 12 <= window.innerHeight - 12);
        assert(window.innerWidth / 2 + runtime.voicePlacement.x + 165 <= window.innerWidth - 8);
        handle.emit('pointercancel', {});
        assert.equal(handle.captured, null);
        const nativeRegions = [];
        const drag = state.presentationDrag;
        drag.nativeRegionHost = { setPointerRegions: async regions => nativeRegions.push(regions) };
        handle.emit('pointerdown', {});
        handle.emit('pointermove', { clientX: 1000, clientY: 600 });
        assert.equal(frames.size, 1);
        releaseVoicePresentationDrag(state);
        for (const callback of timers.values()) callback();
        timers.clear();
        assert.equal(drag.pointerID, null);
        assert.equal(frames.size, 0);
        assert.deepEqual(nativeRegions.at(-1), [], 'closing Voice during a drag must release its viewport input shape');
        assert.equal(nativeMessages.at(-1).isInteractive, false);
        assert.equal(listeners.size, 0);
        assert.equal(state.presentationDrag, null);
        assert.equal(document.body.children.length, 0);
        assert.equal(document.documentElement.style.getPropertyValue('--cts-voice-drag-x'), '');
        process.stdout.write(JSON.stringify({ passed: true }));
        """
        let result = try JSONSerialization.jsonObject(with: runNode(script)) as? [String: Bool]
        XCTAssertEqual(result?["passed"], true)
    }

    func testVoiceControlsFollowBackdropAndRestoreNativePosition() throws {
        let source = try String(contentsOf: runtimeDirectory.appendingPathComponent("theme-inject.js"), encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "  function releaseVoiceControlsDock("))
        let end = try XCTUnwrap(source.range(of: "  function mountLive2DPresentationContainer(", range: start.upperBound..<source.endIndex))
        let script = """
        const assert = require('node:assert/strict');
        const window = { innerWidth: 1920, innerHeight: 1080 };
        const runtime = { voicePulse: { sessionActive: true } };
        const customProperty = () => '';
        const extractCSSURL = () => null;
        class Node {
          constructor(x, y, width, height, buttons) {
            this.base = { x, y, width, height }; this.offsetWidth = width; this.offsetHeight = height;
            this.buttons = buttons; this.attributes = new Map(); this.styles = new Map();
            this.style = { getPropertyValue: key => this.styles.get(key) || '', getPropertyPriority: () => '',
              setProperty: (key, value) => this.styles.set(key, value), removeProperty: key => this.styles.delete(key) };
          }
          querySelector() { return null; }
          querySelectorAll() { return Array(this.buttons).fill({}); }
          setAttribute(key, value) { this.attributes.set(key, value); }
          removeAttribute(key) { this.attributes.delete(key); }
          getBoundingClientRect() {
            const shift = (this.style.getPropertyValue('translate') || '0 0').split(' ').map(parseFloat);
            return { ...this.base, left: this.base.x + shift[0], top: this.base.y + shift[1] };
          }
        }
        const control = new Node(1634, 676.5, 124, 40, 3);
        const wrapper = new Node(1634, 676.5, 124, 40, 3);
        const row = new Node(1531, 676.5, 330, 40, 5);
        control.parentElement = wrapper; wrapper.parentElement = row;
        row.style.setProperty('translate', '3px 4px');
        const document = { querySelector: () => control, documentElement: {} };
        const state = { presentationRoot: {}, model: {}, container: { getBoundingClientRect: () => ({ bottom: 700 }) } };
        \(source[start.lowerBound..<end.lowerBound])
        const image = { naturalWidth: 948, naturalHeight: 1659 };
        const bounds = voiceControlsBackgroundBounds(1920, 1080, image, 'contain', 0.5);
        assert.equal(bounds.bottom, 810);
        assert.equal(bounds.height, 540);
        synchronizeVoiceControlsDock(state);
        state.controlsDockLastSync = 0; synchronizeVoiceControlsDock(state);
        let rect = row.getBoundingClientRect();
        assert.equal(rect.left + rect.width / 2, 960);
        assert.equal(rect.top, 712);
        assert.equal(row.attributes.get('data-codex-voice-controls-docked'), 'true');
        window.innerWidth = 1000;
        state.controlsDockLastSync = 0; synchronizeVoiceControlsDock(state);
        rect = row.getBoundingClientRect();
        assert.equal(rect.left + rect.width / 2, 500);
        row.base.x += 70;
        state.controlsDockLastSync = 0; synchronizeVoiceControlsDock(state);
        rect = row.getBoundingClientRect();
        assert.equal(rect.left + rect.width / 2, 500, 'native hover movement must not detach the dock');
        control.closest = () => row;
        row.querySelector = () => ({ nativeOrb: true });
        assert.equal(voiceControlsDockNode(), row, 'Quick Chat must dock the complete controls even when the native orb is inside');
        releaseVoiceControlsDock(state);
        assert.equal(row.style.getPropertyValue('translate'), '3px 4px');
        assert.equal(state.controlsDock, null);
        assert.equal(row.attributes.has('data-codex-voice-controls-docked'), false);
        process.stdout.write(JSON.stringify({ passed: true }));
        """
        let result = try JSONSerialization.jsonObject(with: runNode(script)) as? [String: Bool]
        XCTAssertEqual(result?["passed"], true)
    }

    func testCenteredAvatarUsesViewportPresentationAndCleansUpWithoutChangingNativeOpacity() throws {
        let source = try String(contentsOf: runtimeDirectory.appendingPathComponent("theme-inject.js"), encoding: .utf8)
        let helperStart = try XCTUnwrap(source.range(of: "  function synchronizeLive2DPresentationRoot("))
        let helperEnd = try XCTUnwrap(source.range(of: "  async function mountVoiceLive2D(", range: helperStart.upperBound..<source.endIndex))
        let destroyStart = try XCTUnwrap(source.range(of: "  function destroyVoiceLive2D()"))
        let destroyEnd = try XCTUnwrap(source.range(of: "  function live2DParameterHandle(", range: destroyStart.upperBound..<source.endIndex))
        let script = """
        const assert = require('node:assert/strict');
        class Element {
          constructor() {
            this.children = []; this.attributes = new Map(); this.vars = {};
            this.styles = new Map(); this.styleWrites = 0;
            this.style = {
              setProperty: (key, value) => { this.styles.set(key, value); this.styleWrites++; },
              getPropertyValue: key => this.styles.get(key) || ''
            };
          }
          appendChild(child) { child.remove(); this.children.push(child); child.parent = this; }
          remove() { if(this.parent) this.parent.children = this.parent.children.filter(c => c !== this); this.parent = null; }
          setAttribute(key, value) { this.attributes.set(key, value); }
          getAttribute(key) { return this.attributes.get(key) ?? null; }
          removeAttribute(key) { this.attributes.delete(key); }
        }
        const document = { body: new Element(), documentElement: new Element(), createElement: () => new Element() };
        const VOICE_EFFECTIVE_SCALE = '--cts-voice-effective-scale';
        const VOICE_IDLE_X = '--cts-voice-orb-idle-x';
        const VOICE_IDLE_Y = '--cts-voice-orb-idle-y';
        const VOICE_IDLE_ROTATION = '--cts-voice-orb-idle-rotation';
        const customProperty = (element, name) => element.vars[name] || '';
        document.documentElement.vars = { '--cts-voice-overlay-mascot-width': '129px', '--cts-voice-orb-lock-center': '1' };
        const nativeTransition = new Element(); nativeTransition.style.setProperty('opacity', '0');
        const root = new Element(), canvasContainer = new Element();
        nativeTransition.appendChild(root);
        root.setAttribute('data-codex-live2d-ready', 'true');
        root.vars = { [VOICE_EFFECTIVE_SCALE]: '3', [VOICE_IDLE_X]: '2px', [VOICE_IDLE_Y]: '-1px', [VOICE_IDLE_ROTATION]: '0deg' };
        const state = { root, container: canvasContainer, generation: 0, presentationRoot: null };
        const runtime = { live2D: state };
        \(source[helperStart.lowerBound..<helperEnd.lowerBound])
        \(source[destroyStart.lowerBound..<destroyEnd.lowerBound])
        mountLive2DPresentationContainer(state, root, canvasContainer);
        assert.equal(state.presentationRoot.parent, document.body);
        assert.equal(canvasContainer.parent, state.presentationRoot);
        assert.equal(nativeTransition.style.getPropertyValue('opacity'), '0');
        assert.equal(state.presentationRoot.style.getPropertyValue('position'), 'fixed');
        assert.equal(state.presentationRoot.getAttribute('data-codex-live2d-ready'), 'true');
        assert.equal(state.presentationRoot.style.getPropertyValue(VOICE_EFFECTIVE_SCALE), '3');
        const writes = state.presentationRoot.styleWrites;
        synchronizeLive2DPresentationRoot(state);
        assert.equal(state.presentationRoot.styleWrites, writes, 'unchanged frames should not invalidate CSS');
        root.vars[VOICE_IDLE_X] = '3px';
        synchronizeLive2DPresentationRoot(state);
        assert.equal(state.presentationRoot.style.getPropertyValue(VOICE_IDLE_X), '3px');
        mountLive2DPresentationContainer(state, root, canvasContainer);
        assert.equal(document.body.children.length, 1, 'reuse the viewport presentation');
        document.documentElement.vars['--cts-voice-orb-lock-center'] = '0';
        mountLive2DPresentationContainer(state, root, canvasContainer);
        assert.equal(canvasContainer.parent, root);
        assert.equal(document.body.children.length, 0);
        document.documentElement.vars['--cts-voice-orb-lock-center'] = '1';
        mountLive2DPresentationContainer(state, root, canvasContainer);
        destroyVoiceLive2D();
        assert.equal(document.body.children.length, 0, 'clearing Voice must remove its presentation');
        assert.equal(state.presentationRoot, null);
        assert.equal(canvasContainer.parent, null);
        process.stdout.write(JSON.stringify({ passed: true }));
        """
        let result = try JSONSerialization.jsonObject(with: runNode(script)) as? [String: Bool]
        XCTAssertEqual(result?["passed"], true)
    }

    func testRuntimeKeepsFlatRendererAndAddsLive2DLifecycle() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("const VERSION = 84;"))
        XCTAssertTrue(source.contains("function transformScale("))
        XCTAssertTrue(source.contains("function live2DFinalDisplayScale("))
        XCTAssertTrue(source.contains("function live2DRenderResolution("))
        XCTAssertTrue(
            source.contains("function synchronizeLive2DRendererResolution(")
        )
        XCTAssertTrue(source.contains("LIVE2D_MAX_RENDER_RESOLUTION = 8"))
        XCTAssertTrue(source.contains("getBoundingClientRect() includes"))
        XCTAssertTrue(
            source.contains(
                "matching Pixi backing resolution instead of a CSS-upscaled bitmap"
            )
        )
        XCTAssertTrue(source.contains("function presentationScale("))
        XCTAssertTrue(source.contains("function synchronizeVoiceEffectiveScale("))
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
        XCTAssertTrue(source.contains("QUICK_CHAT_VOICE_ORB_SELECTOR"))
        XCTAssertTrue(source.contains("QUICK_CHAT_VOICE_STAGE_ATTRIBUTE"))
        XCTAssertTrue(source.contains("function voiceAvatarHost("))
        XCTAssertTrue(source.contains("function installQuickChatVoiceDrag("))
        XCTAssertTrue(source.contains("QUICK_CHAT_VOICE_DRAG_SURFACE_ATTRIBUTE"))
        XCTAssertTrue(source.contains("function quickChatVoiceDragRect("))
        XCTAssertTrue(source.contains("function fitQuickChatVoiceDragSurface("))
        XCTAssertTrue(source.contains("avatar-overlay-drag-start"))
        XCTAssertTrue(source.contains("avatar-overlay-drag-move"))
        XCTAssertTrue(source.contains("avatar-overlay-drag-end"))
        XCTAssertTrue(source.contains("sendMessageFromView"))
        XCTAssertTrue(source.contains("presentation.setPointerCapture?.("))
        XCTAssertTrue(source.contains("clearQuickChatVoiceStage();"))
        XCTAssertTrue(source.contains("function findVoiceOrbRoot("))
        XCTAssertTrue(
            source.contains("data-quick-chat-presentation=\"voice\"")
        )
        XCTAssertTrue(source.contains("function prepareVoiceImages("))
        XCTAssertTrue(source.contains("function mountVoiceLive2D("))
        XCTAssertTrue(source.contains("function destroyVoiceLive2D("))
        XCTAssertTrue(source.contains("preserveLive2D = false"))
        XCTAssertTrue(source.contains("mountLive2DPresentationContainer(state, host, state.container)"))
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
            source.contains("voiceRendererOwnsAvatar()")
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

    func testLive2DBackingResolutionTracksFinalTransformedSize() throws {
        let source = try String(
            contentsOf: runtimeDirectory
                .appendingPathComponent("theme-inject.js"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(
            source.range(of: "  function transformScale(")
        )
        let end = try XCTUnwrap(
            source.range(
                of: "\n  async function mountVoiceLive2D(",
                range: start.upperBound..<source.endIndex
            )
        )
        let functions = String(source[start.lowerBound..<end.lowerBound])
        let script = """
        const window = { devicePixelRatio: 2 };
        const LIVE2D_BASE_RESOLUTION_MAX = 2;
        const LIVE2D_MAX_RENDER_RESOLUTION = 8;
        const LIVE2D_RESOLUTION_QUANTUM = 0.125;
        function clamp(value, minimum, maximum) {
          return Math.max(minimum, Math.min(maximum, value));
        }
        function computedStyle(element) {
          return { transform: element?.transform || "none" };
        }
        \(functions)
        const resizeEvents = [];
        const container = {
          clientWidth: 129,
          clientHeight: 129,
          offsetWidth: 129,
          offsetHeight: 129,
          transform: "matrix(3.78796, 0, 0, 3.78796, 0, 0)",
          getBoundingClientRect() {
            return { width: this.renderedWidth, height: this.renderedHeight };
          },
          renderedWidth: 388.86,
          renderedHeight: 388.86,
          parentElement: {
            transform: "matrix(0.791965, 0, 0, 0.791965, 0, 0)",
            parentElement: null
          }
        };
        const renderer = {
          resolution: 2,
          resize(width, height) {
            resizeEvents.push({
              width,
              height,
              resolution: this.resolution,
              backingWidth: Math.round(width * this.resolution),
              backingHeight: Math.round(height * this.resolution)
            });
          }
        };
        const state = { container, app: { renderer }, renderResolution: 2 };
        const first = live2DRenderResolution(state);
        synchronizeLive2DRendererResolution(state, 129, 129);
        container.renderedWidth = 258;
        container.renderedHeight = 258;
        synchronizeLive2DRendererResolution(state, 129, 129);
        process.stdout.write(JSON.stringify({
          first,
          finalScale: live2DFinalDisplayScale(container),
          resolution: state.renderResolution,
          resizeEvents
        }));
        """
        let data = try runNode(script)
        let result = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(result["first"] as? Double, 6.125)
        XCTAssertEqual(result["finalScale"] as? Double, 2)
        XCTAssertEqual(result["resolution"] as? Double, 4)
        let events = try XCTUnwrap(result["resizeEvents"] as? [[String: Any]])
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0]["backingWidth"] as? Int, 790)
        XCTAssertEqual(events[0]["backingHeight"] as? Int, 790)
        XCTAssertEqual(events[1]["backingWidth"] as? Int, 516)
        XCTAssertEqual(events[1]["backingHeight"] as? Int, 516)
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

        XCTAssertEqual(object["version"] as? Int, 84)

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
