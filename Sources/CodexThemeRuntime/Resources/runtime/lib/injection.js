"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const {
  CdpSession,
  codexAvatarOverlayTargets,
  codexPageTargets,
  listTargets,
  targetWebSocket,
} = require("./cdp");

const BASE64_CHUNK_CHARACTERS = 256 * 1024;
const RENDERER_RUNTIME_VERSION = 23;
const TARGET_KIND_MAIN = "main";
const TARGET_KIND_AVATAR_OVERLAY = "avatar-overlay";
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
    if (begun.unchanged === true) return begun;

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

    return await evaluateRuntime(
      session,
      commitExpression({ transactionID }),
      "commit theme transaction",
    );
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
  const overlayTargets = codexAvatarOverlayTargets(listedTargets)
    .filter(({ id }) => overlayTheme || sessions.has(id))
    .map((target) => ({
      target,
      kind: TARGET_KIND_AVATAR_OVERLAY,
    }));
  const targets = [...mainTargets, ...overlayTargets];
  const liveTargetIDs = new Set(
    [
      ...codexPageTargets(listedTargets),
      ...codexAvatarOverlayTargets(listedTargets),
    ].map((target) => target.id),
  );

  for (const [targetID, session] of sessions) {
    if (session.closed || !liveTargetIDs.has(targetID)) {
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
        await installRuntime(session);
        sessions.set(target.id, session);
        if (targetTheme) await applyTheme(session, targetTheme);
      } else {
        session.codexThemeTargetKind = kind;
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
  evaluateRuntime,
  injectRenderers,
  installRuntime,
  reconcileExistingSession,
  rendererInjectionSource,
  rendererStatus,
  runtimeCallExpression,
  statusExpression,
};
