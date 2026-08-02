"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const https = require("node:https");
const path = require("node:path");
const {
  CdpSession,
  codexAvatarOverlayTargets,
  codexPageTargets,
  listTargets,
  targetWebSocket,
} = require("./cdp");

const BASE64_CHUNK_CHARACTERS = 256 * 1024;
const RENDERER_RUNTIME_VERSION = 54;
const LIVE2D_CORE_URL =
  "https://cubism.live2d.com/sdk-web/core/06/live2dcubismcore.min.js";
const LIVE2D_MARKER = "__codexThemeSwitcherLive2DReady";
const LIVE2D_CSP_MARKER = "__codexThemeSwitcherLive2DCspReady";
const MAX_LIVE2D_CORE_CHARACTERS = 4 * 1024 * 1024;
const LIVE2D_CORE_RETRY_DELAY_MILLISECONDS = 30_000;
const TARGET_KIND_MAIN = "main";
const TARGET_KIND_AVATAR_OVERLAY = "avatar-overlay";
const OVERLAY_ROLE_FULL = "full";
const OVERLAY_ROLE_BACKGROUND = "background";
const OVERLAY_ROLE_FOREGROUND = "foreground";
const AVATAR_OVERLAY_INDEX_PATTERN =
  /^app:\/\/-\/index\.html(?:[?#]|$)/;
const VOICE_COMPOSITION_PATTERN =
  /^app:\/\/-\/avatar-overlay-composition-surface\.html(?:[?#]|$)/;
const LIVE2D_FORCE_NON_NATIVE_RENDERING_KEY =
  "avatar-overlay-force-non-native-rendering";
const LIVE2D_NATIVE_COMPOSITION_TIMER_GLOBAL =
  "__codexThemeSwitcherLive2DNativeCompositionTimers";
const RUNTIME_GLOBALS = Object.freeze({
  begin: "__codexThemeSwitcherBegin",
  appendAsset: "__codexThemeSwitcherAppendAsset",
  commit: "__codexThemeSwitcherCommit",
  abort: "__codexThemeSwitcherAbort",
  status: "__codexThemeSwitcherStatus",
  clear: "__codexThemeSwitcherClear",
});

function rendererInjectionSource() {
  return fs.readFileSync(
    path.resolve(__dirname, "..", "theme-inject.js"),
    "utf8",
  );
}

function themeUsesLive2D(theme) {
  return typeof theme?.css === "string"
    && /--cts-voice-avatar-mode\s*:\s*live2D\b/.test(theme.css);
}

function isAvatarOverlayIndexURL(url) {
  return AVATAR_OVERLAY_INDEX_PATTERN.test(String(url || ""))
    && String(url || "").includes("avatar-overlay");
}

function isCodexIndexURL(url) {
  return AVATAR_OVERLAY_INDEX_PATTERN.test(String(url || ""));
}

function isVoiceCompositionURL(url) {
  const value = String(url || "");
  return VOICE_COMPOSITION_PATTERN.test(value)
    && /(?:[?&])surfaceId=voice-output(?:&|$)/.test(value);
}

function live2DNativeCompositionOverrideSource(forceNonNative = true) {
  const message = forceNonNative
    ? {
        type: "persisted-atom-updated",
        key: LIVE2D_FORCE_NON_NATIVE_RENDERING_KEY,
        value: true,
        deleted: false,
      }
    : {
        type: "persisted-atom-updated",
        key: LIVE2D_FORCE_NON_NATIVE_RENDERING_KEY,
        deleted: true,
      };
  return [
    "(() => {",
    `  const timerKey = ${JSON.stringify(
      LIVE2D_NATIVE_COMPOSITION_TIMER_GLOBAL,
    )};`,
    `  const message = ${JSON.stringify(message)};`,
    "  const existing = globalThis[timerKey];",
    "  if (Array.isArray(existing)) {",
    "    for (const timer of existing) window.clearTimeout(timer);",
    "  }",
    "  const dispatch = () => {",
    "    window.dispatchEvent(new MessageEvent(\"message\", {",
    "      data: message,",
    "      origin: window.location?.origin || \"\",",
    "    }));",
    "  };",
    "  dispatch();",
    "  globalThis[timerKey] = [50, 250, 1000, 4000].map((delay) =>",
    "    window.setTimeout(dispatch, delay)",
    "  );",
    `  return { ok: true, forceNonNative: ${JSON.stringify(
      forceNonNative,
    )} };`,
    "})();",
  ].join("\n");
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function waitForRendererDocument(session, previousDocumentMarker) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    try {
      const response = await session.send("Runtime.evaluate", {
        expression: [
          "JSON.stringify({",
          "  readyState: document.readyState,",
          `  previousDocument: globalThis[${JSON.stringify(
            previousDocumentMarker,
          )}] === true,`,
          "})",
        ].join("\n"),
        returnByValue: true,
      });
      const state = JSON.parse(response?.result?.value || "null");
      if (
        state?.previousDocument === false
        && (
          state.readyState === "interactive"
          || state.readyState === "complete"
        )
      ) return;
    } catch {}
    await delay(50);
  }
  throw rendererError(
    "reload avatar overlay",
    "renderer did not finish reloading",
    "renderer-reload-timeout",
  );
}

async function reloadRenderer(session) {
  await session.send("Page.enable");
  const previousDocumentMarker =
    `__codexThemeSwitcherReload_${crypto.randomUUID().replaceAll("-", "")}`;
  await session.send("Runtime.evaluate", {
    expression: `globalThis[${JSON.stringify(previousDocumentMarker)}] = true`,
  });
  await session.send("Page.reload", { ignoreCache: false });
  // Page.reload resolves before Chromium swaps in the new document. Waiting
  // only for readyState can accidentally observe the old complete document,
  // so also require the old global marker to disappear.
  await waitForRendererDocument(session, previousDocumentMarker);
}

async function configureLive2DNativeComposition(
  session,
  targetURL,
  theme,
) {
  // ChatGPT 26.727+ stages the legacy avatar window at roughly 1% opacity and
  // extracts only its registered surfaces into native child windows. Live2D
  // is an additional canvas, so it remains in the faded legacy window. The
  // renderer already exposes a debug atom for opting out of that composition.
  // Update the atom in this document only: using the host's persisted update
  // would leave ChatGPT in legacy mode after Theme Switcher exits.
  if (!isAvatarOverlayIndexURL(targetURL)) return false;

  const forceNonNative = themeUsesLive2D(theme);
  const hadKnownState =
    typeof session.codexThemeLive2DForceNonNativeRendering === "boolean";
  const wasForceNonNative =
    session.codexThemeLive2DForceNonNativeRendering === true;

  // Reassert the Live2D state on every poll because ChatGPT may resync its
  // persisted atoms after a renderer lifecycle transition. For the native
  // state one initial delete event is enough.
  if (!hadKnownState || forceNonNative !== wasForceNonNative || forceNonNative) {
    await evaluateRuntime(
      session,
      live2DNativeCompositionOverrideSource(forceNonNative),
      forceNonNative
        ? "show Live2D Voice renderer"
        : "restore native Voice composition",
    );
  }
  session.codexThemeLive2DForceNonNativeRendering = forceNonNative;
  return !hadKnownState || forceNonNative !== wasForceNonNative;
}

function live2DVendorSource() {
  return [
    fs.readFileSync(
      path.resolve(__dirname, "..", "vendor", "pixi.min.js"),
      "utf8",
    ),
    fs.readFileSync(
      path.resolve(
        __dirname,
        "..",
        "vendor",
        "pixi-unsafe-eval.min.js",
      ),
      "utf8",
    ),
    fs.readFileSync(
      path.resolve(
        __dirname,
        "..",
        "vendor",
        "pixi-live2d-display-cubism4.min.js",
      ),
      "utf8",
    ),
  ].join("\n;\n");
}

let live2DCoreSourcePromise = null;
let live2DCoreRetryAfter = 0;
let live2DCoreLastError = null;

function downloadText(url, redirectsRemaining = 4) {
  return new Promise((resolve, reject) => {
    const request = https.get(url, (response) => {
      const status = Number(response.statusCode) || 0;
      if (
        status >= 300
        && status < 400
        && response.headers.location
        && redirectsRemaining > 0
      ) {
        response.resume();
        resolve(downloadText(
          new URL(response.headers.location, url).href,
          redirectsRemaining - 1,
        ));
        return;
      }
      if (status !== 200) {
        response.resume();
        reject(new Error(
          `Cubism Core download returned HTTP ${status}.`,
        ));
        return;
      }
      response.setEncoding("utf8");
      let source = "";
      response.on("data", (chunk) => {
        source += chunk;
        if (source.length > MAX_LIVE2D_CORE_CHARACTERS) {
          request.destroy(
            new Error("Cubism Core download exceeded the size limit."),
          );
        }
      });
      response.on("end", () => {
        if (
          !source.includes("Live2DCubismCore")
          || !source.includes("Moc")
        ) {
          reject(new Error("Cubism Core download was not recognized."));
          return;
        }
        resolve(source);
      });
    });
    request.setTimeout(15_000, () => {
      request.destroy(new Error("Cubism Core download timed out."));
    });
    request.on("error", reject);
  });
}

function live2DCoreSource() {
  if (
    !live2DCoreSourcePromise
    && live2DCoreLastError
    && Date.now() < live2DCoreRetryAfter
  ) {
    return Promise.reject(live2DCoreLastError);
  }
  if (!live2DCoreSourcePromise) {
    live2DCoreSourcePromise = downloadText(LIVE2D_CORE_URL).then(
      (source) => {
        live2DCoreLastError = null;
        live2DCoreRetryAfter = 0;
        return source;
      },
      (error) => {
        live2DCoreSourcePromise = null;
        live2DCoreLastError = error;
        live2DCoreRetryAfter =
          Date.now() + LIVE2D_CORE_RETRY_DELAY_MILLISECONDS;
        throw error;
      },
    );
  }
  return live2DCoreSourcePromise;
}

async function rendererLive2DSource() {
  const core = await live2DCoreSource();
  return [
    core,
    live2DVendorSource(),
    `window[${JSON.stringify(LIVE2D_CSP_MARKER)}] = true;`,
    `window[${JSON.stringify(LIVE2D_MARKER)}] = Boolean(`,
    "  window.PIXI",
    "  && window.PIXI.Application",
    "  && window.PIXI.live2d",
    "  && window.PIXI.live2d.Live2DModel",
    ");",
  ].join("\n");
}

async function ensureLive2DRenderer(session) {
  const status = await evaluateRuntime(
    session,
    [
      "({",
      "  ok: true,",
      `  ready: window[${JSON.stringify(LIVE2D_MARKER)}] === true`,
      `  && window[${JSON.stringify(LIVE2D_CSP_MARKER)}] === true`,
      "})",
    ].join("\n"),
    "check Live2D runtime",
  );
  if (status.ready === true) return;

  const source = await rendererLive2DSource();
  if (session.codexThemeLive2DSourceInstalled !== true) {
    await session.send(
      "Page.addScriptToEvaluateOnNewDocument",
      { source },
    );
    session.codexThemeLive2DSourceInstalled = true;
  }
  await evaluateRuntime(
    session,
    `${source}\n;({ ok: true, ready: window[${JSON.stringify(
      LIVE2D_MARKER,
    )}] === true })`,
    "install Live2D runtime",
  );
  await evaluateRuntime(
    session,
    [
      "(() => {",
      "  const runtime = window.__codexThemeSwitcherRuntime;",
      "  runtime?.refreshVoicePulseSync?.();",
      "  return { ok: true };",
      "})()",
    ].join("\n"),
    "refresh Live2D runtime",
  );
}

async function bestEffortEnsureLive2DRenderer(session) {
  try {
    await ensureLive2DRenderer(session);
    session.codexThemeLive2DError = null;
    return true;
  } catch (error) {
    session.codexThemeLive2DError = error?.message || String(error);
    return false;
  }
}

async function rendererUsesLive2D(session) {
  const result = await evaluateRuntime(
    session,
    [
      "(() => {",
      "  const root = document.documentElement;",
      "  const value = root && typeof getComputedStyle === \"function\"",
      "    ? getComputedStyle(root)",
      "      .getPropertyValue(\"--cts-voice-avatar-mode\")",
      "      .trim()",
      "      .replace(/^[\\\"']|[\\\"']$/g, \"\")",
      "    : \"\";",
      "  const role = root && typeof getComputedStyle === \"function\"",
      "    ? getComputedStyle(root)",
      "      .getPropertyValue(\"--cts-voice-renderer-role\")",
      "      .trim()",
      "      .replace(/^[\\\"']|[\\\"']$/g, \"\")",
      "    : \"\";",
      "  return {",
      "    ok: true,",
      "    active: value === \"live2D\" && role !== \"background\",",
      "  };",
      "})()",
    ].join("\n"),
    "check active Voice avatar mode",
  );
  return result.active === true;
}

async function ensureActiveLive2DRenderer(session, theme) {
  if (!themeUsesLive2D(theme)) return false;
  try {
    if (!await rendererUsesLive2D(session)) return false;
  } catch {
    return false;
  }
  return bestEffortEnsureLive2DRenderer(session);
}

function runtimeCallExpression(globalName, payload, hasArgument = true) {
  const argument = hasArgument ? JSON.stringify(payload) : "";
  return [
    "(async () => {",
    `  const operation = window[${JSON.stringify(globalName)}];`,
    "  if (typeof operation !== \"function\") {",
    `    return { ok: false, error: ${JSON.stringify(
      `Renderer runtime operation ${globalName} is unavailable.`,
    )} };`,
    "  }",
    `  return await operation(${argument});`,
    "})()",
  ].join("\n");
}

function beginExpression(payload) {
  return runtimeCallExpression(RUNTIME_GLOBALS.begin, payload);
}

function appendAssetExpression(payload) {
  return runtimeCallExpression(RUNTIME_GLOBALS.appendAsset, payload);
}

function commitExpression(payload) {
  return runtimeCallExpression(RUNTIME_GLOBALS.commit, payload);
}

function abortExpression(payload) {
  return runtimeCallExpression(RUNTIME_GLOBALS.abort, payload);
}

function statusExpression() {
  return runtimeCallExpression(RUNTIME_GLOBALS.status, undefined, false);
}

function clearExpression() {
  return runtimeCallExpression(RUNTIME_GLOBALS.clear, undefined, false);
}

function clearIfPresentExpression() {
  return [
    "(async () => {",
    `  const operation = window[${JSON.stringify(RUNTIME_GLOBALS.clear)}];`,
    "  if (typeof operation !== \"function\") {",
    "    return { ok: true, skipped: true };",
    "  }",
    "  return await operation();",
    "})()",
  ].join("\n");
}

// Kept as a compatibility export for callers that previously inspected the
// single-frame expression. Applying now starts a renderer transaction.
function applyExpression(theme) {
  return beginExpression(beginPayload(theme).payload);
}

function rendererError(operation, message, code = "renderer-error") {
  const error = new Error(`${operation} failed: ${message}`);
  error.code = code;
  return error;
}

function exceptionMessage(details) {
  return details?.exception?.description
    || details?.exception?.value
    || details?.text
    || "renderer raised an exception";
}

function checkedEvaluationValue(response, operation) {
  if (response?.error) {
    const message = response.error.message
      || JSON.stringify(response.error);
    throw rendererError(operation, message, "cdp-protocol-error");
  }
  if (response?.exceptionDetails) {
    throw rendererError(
      operation,
      exceptionMessage(response.exceptionDetails),
      "renderer-exception",
    );
  }

  const value = response?.result?.value;
  if (!value || typeof value !== "object" || value.ok !== true) {
    const message = value?.error?.message
      || value?.error
      || response?.result?.description
      || "renderer did not return { ok: true }";
    throw rendererError(operation, String(message));
  }
  return value;
}

async function evaluateRuntime(session, expression, operation) {
  const response = await session.send("Runtime.evaluate", {
    expression,
    awaitPromise: true,
    returnByValue: true,
    allowUnsafeEvalBlockedByCSP: true,
  });
  return checkedEvaluationValue(response, operation);
}

function installExpression() {
  const source = rendererInjectionSource();
  return [
    "(async () => {",
    source,
    "  return { ok: true };",
    "})()",
  ].join("\n");
}

async function installRuntime(session) {
  const source = rendererInjectionSource();
  await session.send("Runtime.enable");
  await session.send("Page.enable");
  await session.send("Page.addScriptToEvaluateOnNewDocument", { source });
  await evaluateRuntime(session, installExpression(), "install runtime");
}

function validateAsset(asset) {
  if (
    !asset
    || typeof asset !== "object"
    || typeof asset.id !== "string"
    || !asset.id
    || typeof asset.mediaType !== "string"
    || !asset.mediaType
    || typeof asset.dataBase64 !== "string"
    || typeof asset.fingerprint !== "string"
    || !Number.isSafeInteger(asset.byteLength)
    || asset.byteLength < 0
  ) {
    throw rendererError(
      "prepare theme",
      "theme asset does not match the runtime wire contract",
      "invalid-theme-asset",
    );
  }
  return asset;
}

function beginPayload(theme) {
  if (!theme || typeof theme !== "object") {
    throw rendererError(
      "prepare theme",
      "theme payload is missing",
      "invalid-theme",
    );
  }
  const assets = theme.assets === undefined ? [] : theme.assets;
  if (!Array.isArray(assets)) {
    throw rendererError(
      "prepare theme",
      "theme assets must be an array",
      "invalid-theme-assets",
    );
  }

  const assetData = new Map();
  const descriptors = assets.map((candidate) => {
    const asset = validateAsset(candidate);
    if (assetData.has(asset.id)) {
      throw rendererError(
        "prepare theme",
        `duplicate theme asset ID ${asset.id}`,
        "invalid-theme-assets",
      );
    }
    assetData.set(asset.id, asset.dataBase64);
    return {
      id: asset.id,
      mediaType: asset.mediaType,
      fingerprint: asset.fingerprint,
      byteLength: asset.byteLength,
      base64Characters: asset.dataBase64.length,
    };
  });

  return {
    payload: {
      ...theme,
      transactionID: crypto.randomUUID(),
      assets: descriptors,
    },
    assetData,
  };
}

function base64Chunks(value) {
  const chunks = [];
  for (
    let offset = 0;
    offset < value.length;
    offset += BASE64_CHUNK_CHARACTERS
  ) {
    chunks.push(value.slice(offset, offset + BASE64_CHUNK_CHARACTERS));
  }
  return chunks;
}

async function bestEffortAbort(session, transactionID) {
  if (!transactionID) return;
  try {
    await evaluateRuntime(
      session,
      abortExpression({ transactionID }),
      "abort theme transaction",
    );
  } catch {}
}

async function applyTheme(session, theme) {
  if (!theme) return null;

  const prepared = beginPayload(theme);
  let transactionID = null;
  try {
    const begun = await evaluateRuntime(
      session,
      beginExpression(prepared.payload),
      "begin theme transaction",
    );
    if (begun.unchanged === true) {
      await ensureActiveLive2DRenderer(session, theme);
      return begun;
    }

    transactionID = begun.transactionID;
    if (typeof transactionID !== "string" || !transactionID) {
      throw rendererError(
        "begin theme transaction",
        "renderer omitted transactionID",
      );
    }
    if (!Array.isArray(begun.requiredAssetIDs)) {
      throw rendererError(
        "begin theme transaction",
        "renderer omitted requiredAssetIDs",
      );
    }

    const requested = new Set();
    for (const assetID of begun.requiredAssetIDs) {
      if (
        typeof assetID !== "string"
        || requested.has(assetID)
        || !prepared.assetData.has(assetID)
      ) {
        throw rendererError(
          "begin theme transaction",
          `renderer requested invalid asset ID ${String(assetID)}`,
        );
      }
      requested.add(assetID);

      const chunks = base64Chunks(prepared.assetData.get(assetID));
      for (let index = 0; index < chunks.length; index += 1) {
        await evaluateRuntime(
          session,
          appendAssetExpression({
            transactionID,
            assetID,
            index,
            chunk: chunks[index],
          }),
          `append theme asset ${assetID} chunk ${index}`,
        );
      }
    }

    const committed = await evaluateRuntime(
      session,
      commitExpression({ transactionID }),
      "commit theme transaction",
    );
    await ensureActiveLive2DRenderer(session, theme);
    return committed;
  } catch (error) {
    await bestEffortAbort(session, transactionID);
    throw error;
  }
}

async function rendererStatus(session) {
  return evaluateRuntime(
    session,
    statusExpression(),
    "read renderer theme status",
  );
}

async function clearTheme(session) {
  return evaluateRuntime(
    session,
    clearExpression(),
    "clear renderer theme",
  );
}

function statusDigest(status) {
  return status?.digest ?? status?.current?.digest ?? null;
}

function statusHasCurrentTheme(status) {
  return status?.stylePresent === true
    || status?.current != null
    || statusDigest(status) != null;
}

async function reconcileExistingSession(session, theme) {
  let status = await rendererStatus(session);
  if (status.version !== RENDERER_RUNTIME_VERSION) {
    await installRuntime(session);
    status = await rendererStatus(session);
  }
  if (!theme) {
    if (statusHasCurrentTheme(status)) await clearTheme(session);
    return;
  }
  if (
    typeof theme.digest === "string"
    && theme.digest
    && statusDigest(status) === theme.digest
    && status.stylePresent === true
  ) {
    await ensureActiveLive2DRenderer(session, theme);
    return;
  }
  await applyTheme(session, theme);
}

function avatarOverlayTheme(theme) {
  if (
    !theme
    || typeof theme.avatarOverlayCSS !== "string"
    || !theme.avatarOverlayCSS.trim()
  ) {
    return null;
  }
  const css = theme.avatarOverlayCSS;
  const referencedAssetIDs = new Set(
    [...css.matchAll(
      /codex-theme-asset:\/\/([0-9a-f-]{36})/gi,
    )].map((match) => match[1].toLowerCase()),
  );
  return {
    ...theme,
    css,
    digest: `${theme.digest}:avatar-overlay`,
    assets: (theme.assets || []).filter(
      ({ id }) => referencedAssetIDs.has(String(id).toLowerCase()),
    ),
  };
}

function avatarOverlayRoleCSS(role) {
  const marker = `:root { --cts-voice-renderer-role: ${role}; }`;
  if (role === OVERLAY_ROLE_BACKGROUND) {
    return [
      marker,
      [
        ":root[data-codex-theme-switcher-theme] :is(",
        "  .codex-avatar-root[data-realtime-voice-orb],",
        "  [data-codex-voice-orb],",
        "  [data-avatar-overlay-native-surface-id=\"voice-output\"]",
        ") {",
        "  opacity: 0 !important;",
        "  pointer-events: none !important;",
        "  visibility: hidden !important;",
        "}",
      ].join("\n"),
    ].join("\n");
  }
  if (role === OVERLAY_ROLE_FOREGROUND) {
    return [
      marker,
      [
        ":root[data-codex-theme-switcher-theme],",
        ":root[data-codex-theme-switcher-theme] body {",
        "  background-color: transparent !important;",
        "}",
        ":root[data-codex-theme-switcher-theme] body::before {",
        "  content: none !important;",
        "  display: none !important;",
        "}",
        [
          ":root[data-codex-theme-switcher-theme]",
          "[data-codex-voice-session-active=\"true\"] :is(",
          "  .codex-avatar-root[data-realtime-voice-orb],",
          "  [data-codex-voice-orb],",
          "  [data-avatar-overlay-native-surface-id=\"voice-output\"]",
          ") {",
          "  opacity: 1 !important;",
          "  visibility: visible !important;",
          "}",
        ].join("\n"),
        [
          ":root[data-codex-theme-switcher-theme]",
          "[data-codex-voice-session-active=\"true\"]",
          "[data-avatar-overlay-native-surface-id=\"voice-output\"]",
          "[data-codex-live2d-avatar] {",
          "  opacity: 1 !important;",
          "  visibility: visible !important;",
          "}",
        ].join("\n"),
      ].join("\n"),
    ].join("\n");
  }
  return marker;
}

function avatarOverlayThemeForRole(theme, role = OVERLAY_ROLE_FULL) {
  const overlay = avatarOverlayTheme(theme);
  if (!overlay) return null;
  const normalizedRole = [
    OVERLAY_ROLE_BACKGROUND,
    OVERLAY_ROLE_FOREGROUND,
  ].includes(role) ? role : OVERLAY_ROLE_FULL;
  if (normalizedRole === OVERLAY_ROLE_FULL) return overlay;
  return {
    ...overlay,
    css: `${overlay.css}\n${avatarOverlayRoleCSS(normalizedRole)}\n`,
    digest: `${overlay.digest}:${normalizedRole}`,
  };
}

function themeForTargetKind(
  theme,
  targetKind,
  overlayRole = OVERLAY_ROLE_FULL,
) {
  return targetKind === TARGET_KIND_AVATAR_OVERLAY
    ? avatarOverlayThemeForRole(theme, overlayRole)
    : theme;
}

function preferredAvatarOverlayTargets(allOverlayTargets, overlayTheme) {
  // ChatGPT 26.727 reuses `surfaceId=voice-output` for the 24 px mute/output
  // control. The actual Voice orb and its draggable presentation remain in
  // the legacy avatar-overlay renderer. Injecting an avatar into the control
  // surface hides the real avatar and mounts Live2D on top of the speaker
  // button instead. Prefer the legacy renderer whenever it is available.
  // Keep the composition surface as a fallback for older builds that expose
  // no legacy overlay at all.
  const legacyTargets = allOverlayTargets.filter(({ url }) => (
    isAvatarOverlayIndexURL(url)
  ));
  return legacyTargets.length > 0 ? legacyTargets : allOverlayTargets;
}

function avatarOverlayTargetRole(target, allOverlayTargets, overlayTheme) {
  return OVERLAY_ROLE_FULL;
}

function suppressedAvatarOverlayTargetIDs(sessions) {
  if (!(sessions.codexThemeSuppressedTargetIDs instanceof Set)) {
    Object.defineProperty(sessions, "codexThemeSuppressedTargetIDs", {
      configurable: true,
      value: new Set(),
    });
  }
  return sessions.codexThemeSuppressedTargetIDs;
}

async function clearSuppressedAvatarOverlayTargets(
  allOverlayTargets,
  selectedOverlayTargets,
  sessions,
  logger,
) {
  const selectedIDs = new Set(selectedOverlayTargets.map(({ id }) => id));
  const availableIDs = new Set(allOverlayTargets.map(({ id }) => id));
  const suppressedIDs = suppressedAvatarOverlayTargetIDs(sessions);
  for (const targetID of suppressedIDs) {
    if (!availableIDs.has(targetID)) suppressedIDs.delete(targetID);
  }
  for (const target of allOverlayTargets) {
    if (selectedIDs.has(target.id) || suppressedIDs.has(target.id)) continue;
    let session = null;
    try {
      session = await CdpSession.connect(
        targetWebSocket(target),
        target.id,
        logger,
      );
      await evaluateRuntime(
        session,
        clearIfPresentExpression(),
        "clear suppressed avatar overlay",
      );
      suppressedIDs.add(target.id);
    } catch (error) {
      logger(
        `clear suppressed target ${target.id} failed: ${error.message}`,
      );
    } finally {
      session?.close();
    }
  }
}

async function injectRenderers(
  debugPort,
  theme,
  sessions = new Map(),
  logger = () => {},
) {
  const listedTargets = await listTargets(debugPort);
  const mainTargets = codexPageTargets(listedTargets).map((target) => ({
    target,
    kind: TARGET_KIND_MAIN,
  }));
  const overlayTheme = avatarOverlayTheme(theme);
  const allOverlayTargets = codexAvatarOverlayTargets(listedTargets);
  // The legacy overlay owns the visual Voice presentation. Current
  // `voice-output` composition targets are control buttons, so mounting the
  // theme there would replace the wrong surface.
  const selectedOverlayTargets = preferredAvatarOverlayTargets(
    allOverlayTargets,
    overlayTheme,
  );
  await clearSuppressedAvatarOverlayTargets(
    allOverlayTargets,
    selectedOverlayTargets,
    sessions,
    logger,
  );
  const overlayTargets = selectedOverlayTargets
    .filter(({ id }) => overlayTheme || sessions.has(id))
    .map((target) => ({
      target,
      kind: TARGET_KIND_AVATAR_OVERLAY,
      overlayRole: avatarOverlayTargetRole(
        target,
        allOverlayTargets,
        overlayTheme,
      ),
    }))
    .sort((left, right) => (
      left.overlayRole === OVERLAY_ROLE_FOREGROUND
        ? -1
        : right.overlayRole === OVERLAY_ROLE_FOREGROUND ? 1 : 0
    ));
  const targets = [...mainTargets, ...overlayTargets];
  const selectedTargetIDs = new Set(
    [
      ...codexPageTargets(listedTargets),
      ...selectedOverlayTargets,
    ].map((target) => target.id),
  );

  for (const [targetID, session] of sessions) {
    if (session.closed || !selectedTargetIDs.has(targetID)) {
      if (!session.closed) {
        try {
          await reconcileExistingSession(session, null);
        } catch {}
      }
      session.close();
      sessions.delete(targetID);
    }
  }

  let successful = 0;
  for (const { target, kind, overlayRole } of targets) {
    let session = sessions.get(target.id);
    const isNew = !session || session.closed;
    try {
      const targetTheme = themeForTargetKind(theme, kind, overlayRole);
      if (kind === TARGET_KIND_AVATAR_OVERLAY && !targetTheme) {
        if (session && !session.closed) {
          await configureLive2DNativeComposition(
            session,
            session.codexThemeTargetURL || String(target.url || ""),
            null,
          );
          await reconcileExistingSession(session, null);
          session.close();
          sessions.delete(target.id);
        }
        continue;
      }
      if (isNew) {
        session = await CdpSession.connect(
          targetWebSocket(target),
          target.id,
          logger,
        );
        session.codexThemeTargetKind = kind;
        session.codexThemeTargetURL = String(target.url || "");
        session.codexThemeOverlayRole = overlayRole || null;
        await configureLive2DNativeComposition(
          session,
          session.codexThemeTargetURL,
          targetTheme,
        );
        await installRuntime(session);
        sessions.set(target.id, session);
        if (targetTheme) await applyTheme(session, targetTheme);
      } else {
        session.codexThemeTargetKind = kind;
        session.codexThemeTargetURL = String(target.url || "");
        session.codexThemeOverlayRole = overlayRole || null;
        await configureLive2DNativeComposition(
          session,
          session.codexThemeTargetURL,
          targetTheme,
        );
        await reconcileExistingSession(session, targetTheme);
      }
      successful += 1;
    } catch (error) {
      logger(`inject target ${target.id} failed: ${error.message}`);
      session?.close();
      sessions.delete(target.id);
    }
  }
  if (!successful) {
    const error = new Error("No Codex renderer accepted theme injection.");
    error.code = "missing-cdp-target";
    throw error;
  }
  return sessions;
}

async function broadcastTheme(sessions, theme, logger = () => {}) {
  let successful = 0;
  for (const [targetID, session] of sessions) {
    if (session.closed) {
      sessions.delete(targetID);
      continue;
    }
    try {
      const targetTheme = themeForTargetKind(
        theme,
        session.codexThemeTargetKind || TARGET_KIND_MAIN,
        session.codexThemeOverlayRole || OVERLAY_ROLE_FULL,
      );
      await configureLive2DNativeComposition(
        session,
        session.codexThemeTargetURL,
        targetTheme,
      );
      if (targetTheme) {
        await reconcileExistingSession(session, targetTheme);
      } else {
        await reconcileExistingSession(session, null);
      }
      successful += 1;
    } catch (error) {
      logger(`apply target ${targetID} failed: ${error.message}`);
      session.close();
      sessions.delete(targetID);
    }
  }
  return successful;
}

async function clearRenderers(sessions, logger = () => {}) {
  let successful = 0;
  for (const [targetID, session] of sessions) {
    if (session.closed) {
      sessions.delete(targetID);
      continue;
    }
    try {
      await configureLive2DNativeComposition(
        session,
        session.codexThemeTargetURL,
        null,
      );
      await clearTheme(session);
      successful += 1;
    } catch (error) {
      logger(`clear target ${targetID} failed: ${error.message}`);
      session.close();
      sessions.delete(targetID);
    }
  }
  return successful;
}

module.exports = {
  BASE64_CHUNK_CHARACTERS,
  MAX_LIVE2D_CORE_CHARACTERS,
  RENDERER_RUNTIME_VERSION,
  RUNTIME_GLOBALS,
  TARGET_KIND_AVATAR_OVERLAY,
  TARGET_KIND_MAIN,
  OVERLAY_ROLE_BACKGROUND,
  OVERLAY_ROLE_FOREGROUND,
  OVERLAY_ROLE_FULL,
  abortExpression,
  appendAssetExpression,
  avatarOverlayTheme,
  avatarOverlayThemeForRole,
  avatarOverlayTargetRole,
  applyExpression,
  applyTheme,
  base64Chunks,
  beginExpression,
  beginPayload,
  broadcastTheme,
  checkedEvaluationValue,
  clearExpression,
  clearRenderers,
  clearTheme,
  commitExpression,
  configureLive2DNativeComposition,
  evaluateRuntime,
  injectRenderers,
  isAvatarOverlayIndexURL,
  isCodexIndexURL,
  isVoiceCompositionURL,
  installRuntime,
  preferredAvatarOverlayTargets,
  reconcileExistingSession,
  rendererInjectionSource,
  live2DNativeCompositionOverrideSource,
  ensureLive2DRenderer,
  bestEffortEnsureLive2DRenderer,
  ensureActiveLive2DRenderer,
  rendererUsesLive2D,
  themeUsesLive2D,
  rendererStatus,
  runtimeCallExpression,
  statusExpression,
};
