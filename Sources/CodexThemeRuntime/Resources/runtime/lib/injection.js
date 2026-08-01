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
const RENDERER_RUNTIME_VERSION = 50;
const LIVE2D_CORE_URL =
  "https://cubism.live2d.com/sdk-web/core/06/live2dcubismcore.min.js";
const LIVE2D_MARKER = "__codexThemeSwitcherLive2DReady";
const LIVE2D_CSP_MARKER = "__codexThemeSwitcherLive2DCspReady";
const MAX_LIVE2D_CORE_CHARACTERS = 4 * 1024 * 1024;
const LIVE2D_CORE_RETRY_DELAY_MILLISECONDS = 30_000;
const TARGET_KIND_MAIN = "main";
const TARGET_KIND_AVATAR_OVERLAY = "avatar-overlay";
const AVATAR_OVERLAY_INDEX_PATTERN =
  /^app:\/\/-\/index\.html(?:[?#]|$)/;
const VOICE_COMPOSITION_PATTERN =
  /^app:\/\/-\/avatar-overlay-composition-surface\.html(?:[?#]|$)/;
const LIVE2D_NATIVE_COMPOSITION_GATE = "620613358";
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

function live2DNativeCompositionOverrideSource() {
  return [
    "(() => {",
    "  const original = Storage.prototype.getItem;",
    "  if (original.__codexThemeSwitcherNativeCompositionOverride) return;",
    "  function getItem(key) {",
    "    const value = original.call(this, key);",
    "    if (",
    "      typeof key !== \"string\"",
    "      || !key.includes(\"statsig.cached.evaluations\")",
    "      || typeof value !== \"string\"",
    "    ) return value;",
    "    try {",
    "      const outer = JSON.parse(value);",
    "      if (typeof outer.data !== \"string\") return value;",
    "      const inner = JSON.parse(outer.data);",
    `      const gate = inner.feature_gates?.[${JSON.stringify(
      LIVE2D_NATIVE_COMPOSITION_GATE,
    )}];`,
    "      if (!gate || gate.value === false) return value;",
    `      inner.feature_gates[${JSON.stringify(
      LIVE2D_NATIVE_COMPOSITION_GATE,
    )}] = { ...gate, value: false };`,
    "      outer.data = JSON.stringify(inner);",
    "      return JSON.stringify(outer);",
    "    } catch {",
    "      return value;",
    "    }",
    "  }",
    "  Object.defineProperty(",
    "    getItem,",
    "    \"__codexThemeSwitcherNativeCompositionOverride\",",
    "    { value: true },",
    "  );",
    "  Storage.prototype.getItem = getItem;",
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
  // ChatGPT 26.727 reads the native-composition gate in the main renderer
  // before it creates the detachable Voice surfaces. Installing the override
  // only in the legacy overlay is too late and leaves two renderers competing
  // for the same session. Keep the main and legacy index documents aligned.
  if (!isCodexIndexURL(targetURL)) return false;
  const shouldDisable = themeUsesLive2D(theme);
  const scriptID = session.codexThemeLive2DNativeCompositionScriptID;
  if (shouldDisable && !scriptID) {
    const result = await session.send(
      "Page.addScriptToEvaluateOnNewDocument",
      { source: live2DNativeCompositionOverrideSource() },
    );
    session.codexThemeLive2DNativeCompositionScriptID =
      result.identifier || true;
    await reloadRenderer(session);
    return true;
  }
  if (!shouldDisable && scriptID) {
    if (typeof scriptID === "string") {
      await session.send("Page.removeScriptToEvaluateOnNewDocument", {
        identifier: scriptID,
      });
    }
    session.codexThemeLive2DNativeCompositionScriptID = null;
    await reloadRenderer(session);
    return true;
  }
  return false;
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
      "  return { ok: true, active: value === \"live2D\" };",
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

function themeForTargetKind(theme, targetKind) {
  return targetKind === TARGET_KIND_AVATAR_OVERLAY
    ? avatarOverlayTheme(theme)
    : theme;
}

function preferredAvatarOverlayTargets(allOverlayTargets, overlayTheme) {
  if (!themeUsesLive2D(overlayTheme)) return allOverlayTargets;
  const legacyOverlayTargets = allOverlayTargets.filter(({ url }) => (
    isAvatarOverlayIndexURL(url)
  ));
  return legacyOverlayTargets.length > 0
    ? legacyOverlayTargets
    : allOverlayTargets;
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
  // Live2D owns one renderer only. When the legacy overlay exists, prefer it
  // and reject the transient voice-output surface which otherwise remounts a
  // second Pixi app at a different size during the handoff animation.
  const selectedOverlayTargets = preferredAvatarOverlayTargets(
    allOverlayTargets,
    overlayTheme,
  );
  const overlayTargets = selectedOverlayTargets
    .filter(({ id }) => overlayTheme || sessions.has(id))
    .map((target) => ({
      target,
      kind: TARGET_KIND_AVATAR_OVERLAY,
    }));
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
  for (const { target, kind } of targets) {
    let session = sessions.get(target.id);
    const isNew = !session || session.closed;
    try {
      const targetTheme = themeForTargetKind(theme, kind);
      if (kind === TARGET_KIND_AVATAR_OVERLAY && !targetTheme) {
        if (session && !session.closed) {
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
  abortExpression,
  appendAssetExpression,
  avatarOverlayTheme,
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
