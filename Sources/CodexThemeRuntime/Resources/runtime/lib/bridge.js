"use strict";

const crypto = require("node:crypto");
const fs = require("node:fs");
const fsp = require("node:fs/promises");
const http = require("node:http");
const path = require("node:path");
const {
  cdpStatus,
  ensureCodexLaunched,
  findAvailablePort,
  findExistingCodexDebugPort,
  isCodexRunning,
  portIsAvailable,
  readBundleValue,
} = require("./cdp");
const {
  clearRenderers,
  injectRenderers,
} = require("./injection");
const {
  queryBridge,
  readJSONBody,
  readToken,
  writeJSON,
} = require("./http");
const { sleep } = require("./processes");

const APP_ID = "codex-theme-switcher";
const PROTOCOL_VERSION = 25;
const MAX_THEME_CSS_BYTES = 64 * 1024 * 1024;
const MAX_THEME_ASSET_BYTES = 16 * 1024 * 1024;
const MAX_THEME_TOTAL_ASSET_BYTES = 32 * 1024 * 1024;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MEDIA_TYPE_PATTERN =
  /^[a-z0-9][a-z0-9!#$&^_.+-]*\/[a-z0-9][a-z0-9!#$&^_.+-]*$/i;
const THEME_ASSET_URL_PATTERN =
  /codex-theme-asset:\/\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/gi;

function createMutationQueue() {
  let tail = Promise.resolve();
  return function enqueueMutation(operation) {
    const result = tail.then(() => operation());
    tail = result.then(
      () => undefined,
      () => undefined,
    );
    return result;
  };
}

function collapseCompilerDataURLs(source) {
  return source.replace(
    /url\s*\(\s*(["']?)data:([a-z0-9!#$&^_.+-]+\/[a-z0-9!#$&^_.+-]+);base64,[a-z0-9+/=\s]*\1\s*\)/gi,
    "url(data:application/octet-stream;base64,AA==)",
  );
}

function removeCSSComments(source) {
  let result = "";
  let quote = null;
  let escaped = false;

  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (quote) {
      result += character;
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === quote) {
        quote = null;
      }
      continue;
    }

    if (character === "\"" || character === "'") {
      quote = character;
      result += character;
      continue;
    }

    if (character === "/" && source[index + 1] === "*") {
      const end = source.indexOf("*/", index + 2);
      index = end < 0 ? source.length : end + 1;
      continue;
    }

    result += character;
  }
  return result;
}

function decodeCSSEscapes(source) {
  let result = "";
  for (let index = 0; index < source.length; index += 1) {
    if (source[index] !== "\\") {
      result += source[index];
      continue;
    }

    index += 1;
    if (index >= source.length) {
      result += "\\";
      break;
    }

    let hex = "";
    while (
      index < source.length
      && hex.length < 6
      && /[0-9a-f]/i.test(source[index])
    ) {
      hex += source[index];
      index += 1;
    }
    if (hex) {
      if (index < source.length && /\s/.test(source[index])) {
        if (source[index] === "\r" && source[index + 1] === "\n") {
          index += 1;
        }
      } else {
        index -= 1;
      }
      const value = Number.parseInt(hex, 16);
      const scalar = value === 0
        || value > 0x10FFFF
        || (value >= 0xD800 && value <= 0xDFFF)
        ? 0xFFFD
        : value;
      result += String.fromCodePoint(scalar);
      continue;
    }

    if (source[index] === "\r" && source[index + 1] === "\n") {
      index += 1;
      continue;
    }
    if (source[index] !== "\n" && source[index] !== "\r") {
      result += source[index];
    }
  }
  return result;
}

function normalizedCSSForSecurity(source) {
  return decodeCSSEscapes(removeCSSComments(collapseCompilerDataURLs(source)));
}

function isUnsafeThemeURL(rawValue) {
  let value = rawValue.trim();
  if (
    value.length >= 2
    && (value[0] === "\"" || value[0] === "'")
    && value.at(-1) === value[0]
  ) {
    value = value.slice(1, -1).trim();
  }
  const lowered = value.toLowerCase();
  if (!lowered || lowered.startsWith("#")) return false;
  if (lowered.startsWith("//")) return true;

  const colon = lowered.indexOf(":");
  if (colon < 0) return false;
  const scheme = lowered.slice(0, colon);
  if (!/^[a-z][a-z0-9+.-]*$/.test(scheme)) return false;
  return !["data", "theme-asset", "codex-theme-asset"].includes(scheme);
}

function containsUnsafeThemeCSS(source) {
  const normalized = normalizedCSSForSecurity(source);
  if (/@\s*import\b/i.test(normalized)) return true;

  for (const match of normalized.matchAll(/\burl\s*\((.*?)\)/gis)) {
    if (isUnsafeThemeURL(match[1])) return true;
  }
  return false;
}

function runtimeDirectory(userRoot) {
  return path.join(userRoot, "Runtime");
}

function activeThemePath(userRoot) {
  return path.join(runtimeDirectory(userRoot), "active-theme.json");
}

function bridgePortPath(userRoot) {
  return path.join(runtimeDirectory(userRoot), "bridge-port");
}

function validBridgePort(value) {
  return Number.isInteger(value) && value > 0 && value <= 65_535;
}

function readPersistedBridgePort(userRoot) {
  try {
    const rawValue = fs.readFileSync(
      bridgePortPath(userRoot),
      "utf8",
    ).trim();
    if (!/^\d+$/.test(rawValue)) return null;
    const value = Number(rawValue);
    return validBridgePort(value) ? value : null;
  } catch {
    return null;
  }
}

function persistBridgePort(userRoot, bridgePort) {
  if (!validBridgePort(bridgePort)) {
    throw new Error(`Invalid bridge port: ${bridgePort}.`);
  }
  const directory = runtimeDirectory(userRoot);
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  const destination = bridgePortPath(userRoot);
  const temporary = path.join(
    directory,
    `.bridge-port.${process.pid}.${crypto.randomUUID()}.tmp`,
  );
  fs.writeFileSync(temporary, `${bridgePort}\n`, { mode: 0o600 });
  fs.renameSync(temporary, destination);
  fs.chmodSync(destination, 0o600);
}

function decodeCanonicalBase64(value) {
  if (typeof value !== "string" || value.length % 4 !== 0) {
    throw Object.assign(new Error("Theme asset data is not valid Base64."), {
      code: "invalid-theme-asset",
    });
  }
  const padding = value.endsWith("==") ? 2 : value.endsWith("=") ? 1 : 0;
  const contentLength = value.length - padding;
  for (let index = 0; index < contentLength; index += 1) {
    const code = value.charCodeAt(index);
    const isUpper = code >= 65 && code <= 90;
    const isLower = code >= 97 && code <= 122;
    const isDigit = code >= 48 && code <= 57;
    if (!isUpper && !isLower && !isDigit && code !== 43 && code !== 47) {
      throw Object.assign(new Error("Theme asset data is not valid Base64."), {
        code: "invalid-theme-asset",
      });
    }
  }
  for (let index = contentLength; index < value.length; index += 1) {
    if (value.charCodeAt(index) !== 61) {
      throw Object.assign(new Error("Theme asset data is not valid Base64."), {
        code: "invalid-theme-asset",
      });
    }
  }
  const decoded = Buffer.from(value, "base64");
  if (decoded.toString("base64") !== value) {
    throw Object.assign(new Error("Theme asset data is not canonical Base64."), {
      code: "invalid-theme-asset",
    });
  }
  return decoded;
}

function assetFingerprint(mediaType, decoded) {
  return crypto.createHash("sha256")
    .update(mediaType)
    .update("\0")
    .update(decoded)
    .digest("hex");
}

function themeDigest(themeID, css, avatarOverlayCSS, assets) {
  const digest = crypto.createHash("sha256")
    .update(themeID)
    .update("\0")
    .update(css)
    .update("\0")
    .update(avatarOverlayCSS);
  for (const asset of assets) {
    digest
      .update("\0")
      .update(asset.id)
      .update("\0")
      .update(asset.fingerprint);
  }
  return digest.digest("hex");
}

function referencedThemeAssetIDs(css) {
  const ids = new Set();
  for (const match of css.matchAll(THEME_ASSET_URL_PATTERN)) {
    ids.add(match[1].toLowerCase());
  }
  const withoutValidReferences = css.replace(THEME_ASSET_URL_PATTERN, "");
  if (/codex-theme-asset:/i.test(withoutValidReferences)) {
    throw Object.assign(
      new Error("Compiled theme CSS contains a malformed asset URL."),
      { code: "invalid-theme-asset" },
    );
  }
  return ids;
}

function validateThemePayload(theme) {
  if (!theme || typeof theme !== "object") {
    throw Object.assign(new Error("Theme payload is missing."), {
      code: "invalid-theme",
    });
  }
  if (typeof theme.themeID !== "string" || !theme.themeID.trim()) {
    throw Object.assign(new Error("Theme ID is missing."), {
      code: "invalid-theme",
    });
  }
  if (typeof theme.themeName !== "string" || !theme.themeName.trim()) {
    throw Object.assign(new Error("Theme name is missing."), {
      code: "invalid-theme",
    });
  }
  if (typeof theme.css !== "string") {
    throw Object.assign(new Error("Theme CSS is missing."), {
      code: "invalid-theme",
    });
  }
  const avatarOverlayCSS = theme.avatarOverlayCSS === undefined
    ? ""
    : theme.avatarOverlayCSS;
  if (typeof avatarOverlayCSS !== "string") {
    throw Object.assign(new Error("Avatar overlay CSS must be a string."), {
      code: "invalid-theme",
    });
  }
  if (
    Buffer.byteLength(theme.css, "utf8")
      + Buffer.byteLength(avatarOverlayCSS, "utf8")
    > MAX_THEME_CSS_BYTES
  ) {
    throw Object.assign(new Error("Compiled theme CSS exceeds the 64 MB limit."), {
      code: "theme-too-large",
    });
  }
  if (
    containsUnsafeThemeCSS(theme.css)
    || containsUnsafeThemeCSS(avatarOverlayCSS)
  ) {
    throw Object.assign(
      new Error(
        "Theme CSS may not use @import or load external/local file URLs.",
      ),
      { code: "unsafe-css" },
    );
  }
  if (theme.assets !== undefined && !Array.isArray(theme.assets)) {
    throw Object.assign(new Error("Theme assets must be an array."), {
      code: "invalid-theme-asset",
    });
  }

  const assets = [];
  const assetIDs = new Set();
  let totalAssetBytes = 0;
  for (const rawAsset of theme.assets || []) {
    if (!rawAsset || typeof rawAsset !== "object") {
      throw Object.assign(new Error("Theme asset is not an object."), {
        code: "invalid-theme-asset",
      });
    }
    if (typeof rawAsset.id !== "string" || !UUID_PATTERN.test(rawAsset.id)) {
      throw Object.assign(new Error("Theme asset ID is not a valid UUID."), {
        code: "invalid-theme-asset",
      });
    }
    const id = rawAsset.id.toLowerCase();
    if (assetIDs.has(id)) {
      throw Object.assign(new Error(`Duplicate theme asset ID: ${id}`), {
        code: "invalid-theme-asset",
      });
    }
    assetIDs.add(id);

    if (
      typeof rawAsset.mediaType !== "string"
      || !MEDIA_TYPE_PATTERN.test(rawAsset.mediaType)
    ) {
      throw Object.assign(
        new Error(`Theme asset ${id} has an invalid media type.`),
        { code: "invalid-theme-asset" },
      );
    }
    const mediaType = rawAsset.mediaType.toLowerCase();
    const decoded = decodeCanonicalBase64(rawAsset.dataBase64);
    if (decoded.length > MAX_THEME_ASSET_BYTES) {
      throw Object.assign(
        new Error(`Theme asset ${id} exceeds the 16 MB limit.`),
        { code: "theme-asset-too-large" },
      );
    }
    totalAssetBytes += decoded.length;
    if (totalAssetBytes > MAX_THEME_TOTAL_ASSET_BYTES) {
      throw Object.assign(
        new Error("Theme assets exceed the 32 MB combined limit."),
        { code: "theme-assets-too-large" },
      );
    }
    assets.push({
      id,
      mediaType,
      dataBase64: rawAsset.dataBase64,
      fingerprint: assetFingerprint(mediaType, decoded),
      byteLength: decoded.length,
    });
  }
  assets.sort((left, right) => left.id.localeCompare(right.id));

  const referencedIDs = referencedThemeAssetIDs(
    `${theme.css}\n${avatarOverlayCSS}`,
  );
  for (const id of referencedIDs) {
    if (!assetIDs.has(id)) {
      throw Object.assign(
        new Error(`Compiled theme CSS references missing asset ${id}.`),
        { code: "missing-theme-asset" },
      );
    }
  }
  for (const id of assetIDs) {
    if (!referencedIDs.has(id)) {
      throw Object.assign(
        new Error(`Theme payload contains unreferenced asset ${id}.`),
        { code: "unreferenced-theme-asset" },
      );
    }
  }

  const themeID = theme.themeID.trim();
  const css = theme.css;
  return {
    themeID,
    themeName: theme.themeName.trim(),
    css,
    avatarOverlayCSS,
    assets,
    digest: themeDigest(themeID, css, avatarOverlayCSS, assets),
  };
}

async function loadActiveTheme(userRoot) {
  try {
    return validateThemePayload(
      JSON.parse(await fsp.readFile(activeThemePath(userRoot), "utf8")),
    );
  } catch {
    return null;
  }
}

async function persistActiveTheme(userRoot, theme) {
  const directory = runtimeDirectory(userRoot);
  await fsp.mkdir(directory, { recursive: true, mode: 0o700 });
  const destination = activeThemePath(userRoot);
  const temporary = path.join(
    directory,
    `.active-theme.${process.pid}.${crypto.randomUUID()}.tmp`,
  );
  await fsp.writeFile(
    temporary,
    `${JSON.stringify(theme, null, 2)}\n`,
    { mode: 0o600 },
  );
  await fsp.rename(temporary, destination);
  await fsp.chmod(destination, 0o600);
}

async function removeActiveTheme(userRoot) {
  await fsp.rm(activeThemePath(userRoot), { force: true });
}

function ensureTokenFile(options) {
  fs.mkdirSync(runtimeDirectory(options.userRoot), {
    recursive: true,
    mode: 0o700,
  });
  if (!fs.existsSync(options.tokenFile)) {
    fs.writeFileSync(
      options.tokenFile,
      `${crypto.randomBytes(32).toString("hex")}\n`,
      { mode: 0o600, flag: "wx" },
    );
  }
  fs.chmodSync(options.tokenFile, 0o600);
  return readToken(options.tokenFile);
}

function authorized(request, expectedToken) {
  const value = request.headers.authorization || "";
  if (!value.startsWith("Bearer ")) return false;
  const actual = Buffer.from(value.slice(7));
  const expected = Buffer.from(expectedToken);
  return actual.length === expected.length
    && crypto.timingSafeEqual(actual, expected);
}

async function serveBridge(options) {
  ensureTokenFile(options);
  const expectedToken = readToken(options.tokenFile);
  const logDirectory = path.join(options.userRoot, "Logs");
  await fsp.mkdir(logDirectory, { recursive: true, mode: 0o700 });
  const logPath = path.join(logDirectory, "runtime.log");
  const log = (message) => {
    fs.appendFileSync(
      logPath,
      `[${new Date().toISOString()}] ${message}\n`,
    );
  };

  const state = {
    debugPort: options.debugPort,
    sessions: new Map(),
    activeTheme: await loadActiveTheme(options.userRoot),
    injectedAt: null,
    lastError: null,
    launching: false,
  };
  const enqueueMutation = createMutationQueue();

  async function chooseDebugPort() {
    const existing = await findExistingCodexDebugPort(state.debugPort);
    if (existing) {
      state.debugPort = existing;
      return;
    }
    if (!(await portIsAvailable(state.debugPort))) {
      state.debugPort = await findAvailablePort(state.debugPort + 1);
    }
  }

  async function injectOnce() {
    const status = await cdpStatus(state.debugPort);
    if (!status.hasCodexTarget) {
      const error = new Error(
        `Codex is not accepting theme injection on debug port ${state.debugPort}. Use “Launch + Attach” first.`,
      );
      error.code = "missing-cdp-target";
      throw error;
    }
    await injectRenderers(
      state.debugPort,
      state.activeTheme,
      state.sessions,
      log,
    );
    state.injectedAt = new Date().toISOString();
    state.lastError = null;
  }

  async function injectWhenReady(timeoutMs = 2000) {
    const startedAt = Date.now();
    let lastError = null;
    do {
      try {
        await injectOnce();
        return;
      } catch (error) {
        lastError = error;
        if (error.code !== "missing-cdp-target") throw error;
      }
      await sleep(100);
    } while (Date.now() - startedAt < timeoutMs);
    throw lastError;
  }

  async function launchAndInject() {
    if (state.launching) {
      const started = Date.now();
      while (state.launching && Date.now() - started < 30000) {
        await sleep(100);
      }
      return;
    }
    state.launching = true;
    try {
      for (const session of state.sessions.values()) session.close();
      state.sessions.clear();
      await chooseDebugPort();
      await ensureCodexLaunched(options.codexApp, state.debugPort);
      await injectOnce();
    } finally {
      state.launching = false;
    }
  }

  async function applyTheme(theme) {
    const validated = validateThemePayload(theme);
    const previous = state.activeTheme;
    state.activeTheme = validated;
    try {
      await injectWhenReady();
      await persistActiveTheme(options.userRoot, validated);
    } catch (error) {
      state.activeTheme = previous;
      try {
        await injectOnce();
      } catch (rollbackError) {
        log(`theme rollback failed: ${rollbackError.message}`);
      }
      throw error;
    }
  }

  async function clearTheme() {
    state.activeTheme = null;
    await removeActiveTheme(options.userRoot);
    await clearRenderers(state.sessions, log);
  }

  async function bridgeStatus() {
    const cdp = await cdpStatus(state.debugPort);
    let activeSessionCount = 0;
    let avatarOverlayRendererCount = 0;
    for (const session of state.sessions.values()) {
      if (!session.closed) {
        activeSessionCount += 1;
        if (session.codexThemeTargetKind === "avatar-overlay") {
          avatarOverlayRendererCount += 1;
        }
      }
    }
    return {
      app: APP_ID,
      protocolVersion: PROTOCOL_VERSION,
      ok: true,
      status: {
        codexPath: options.codexApp,
        codexVersion: readBundleValue(
          options.codexApp,
          "CFBundleShortVersionString",
        ),
        mode: "cdp-css",
        isInjected: activeSessionCount > 0,
        bridgeRunning: true,
        debugPort: state.debugPort,
        bridgePort: options.bridgePort,
        isRunning: isCodexRunning(),
        isDebugPortReady: cdp.isDebugPortReady,
        hasCodexTarget: cdp.hasCodexTarget,
        activeThemeID: state.activeTheme?.themeID || null,
        activeThemeName: state.activeTheme?.themeName || null,
        injectedRendererCount: activeSessionCount,
        avatarOverlayRendererCount,
        voiceStyleEnabled: Boolean(
          state.activeTheme?.avatarOverlayCSS?.trim(),
        ),
        lastError: state.lastError,
      },
    };
  }

  const server = http.createServer((request, response) => {
    handleRequest(request, response).catch((error) => {
      state.lastError = error.message || String(error);
      log(`request failed: ${state.lastError}`);
      const status = [
        "payload-too-large",
        "theme-too-large",
        "theme-asset-too-large",
        "theme-assets-too-large",
      ].includes(error.code) ? 413 : 500;
      writeJSON(response, status, {
        ok: false,
        error: {
          message: state.lastError,
          code: error.code || "bridge-error",
        },
      });
    });
  });

  async function handleRequest(request, response) {
    if (!authorized(request, expectedToken)) {
      writeJSON(response, 401, {
        ok: false,
        error: { message: "Unauthorized.", code: "unauthorized" },
      });
      return;
    }
    if (request.method === "GET" && request.url === "/status") {
      writeJSON(response, 200, await bridgeStatus());
      return;
    }
    if (request.method === "POST" && request.url === "/launch") {
      const payload = await enqueueMutation(async () => {
        await launchAndInject();
        return bridgeStatus();
      });
      writeJSON(response, 200, payload);
      return;
    }
    if (request.method === "POST" && request.url === "/inject") {
      const payload = await enqueueMutation(async () => {
        await injectWhenReady();
        return bridgeStatus();
      });
      writeJSON(response, 200, payload);
      return;
    }
    if (request.method === "PUT" && request.url === "/theme") {
      const theme = await readJSONBody(request);
      const payload = await enqueueMutation(async () => {
        await applyTheme(theme);
        return bridgeStatus();
      });
      writeJSON(response, 200, payload);
      return;
    }
    if (request.method === "DELETE" && request.url === "/theme") {
      const payload = await enqueueMutation(async () => {
        await clearTheme();
        return bridgeStatus();
      });
      writeJSON(response, 200, payload);
      return;
    }
    if (request.method === "POST" && request.url === "/stop") {
      const payload = await enqueueMutation(async () => {
        await clearRenderers(state.sessions, log);
        for (const session of state.sessions.values()) session.close();
        state.sessions.clear();
        return {
          app: APP_ID,
          ok: true,
          stopped: true,
          status: {
            ...(await bridgeStatus()).status,
            isInjected: false,
            bridgeRunning: false,
            injectedRendererCount: 0,
          },
        };
      });
      writeJSON(response, 200, payload);
      server.close(() => process.exit(0));
      return;
    }
    writeJSON(response, 404, {
      ok: false,
      error: { message: "Not found.", code: "not-found" },
    });
  }

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(options.bridgePort, "127.0.0.1", resolve);
  });

  setInterval(() => {
    if (state.launching) return;
    enqueueMutation(async () => {
      const status = await cdpStatus(state.debugPort);
      return status.hasCodexTarget ? injectOnce() : null;
    })
      .catch((error) => {
        state.lastError = error.message || String(error);
      });
  }, 3000).unref();

  log(
    `bridge listening on 127.0.0.1:${options.bridgePort}, debug port ${state.debugPort}`,
  );
}

async function waitForBridge(options, timeoutMs = 6000) {
  const startedAt = Date.now();
  let lastError = null;
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const result = await queryBridge(options);
      if (
        result.app === APP_ID
        && result.protocolVersion === PROTOCOL_VERSION
      ) {
        return result;
      }
      lastError = new Error(
        `Port ${options.bridgePort} belongs to an incompatible service.`,
      );
    } catch (error) {
      lastError = error;
    }
    await sleep(150);
  }
  throw lastError || new Error("Timed out waiting for theme runtime.");
}

async function startBridgeDaemon(options) {
  ensureTokenFile(options);

  let existing = null;
  try {
    existing = await queryBridge(options);
  } catch {}
  if (existing) {
    if (existing.app !== APP_ID) {
      if (options.bridgePortPinned === true) {
        throw new Error(
          `Port ${options.bridgePort} belongs to an incompatible service.`,
        );
      }
      options.bridgePort = await findAvailablePort(options.bridgePort + 1);
    } else if (existing.protocolVersion === PROTOCOL_VERSION) {
      persistBridgePort(options.userRoot, options.bridgePort);
      return existing;
    } else {
      await queryBridge(options, "/stop", "POST");
      let released = false;
      for (let attempt = 0; attempt < 60; attempt += 1) {
        if (await portIsAvailable(options.bridgePort)) {
          released = true;
          break;
        }
        await sleep(50);
      }
      if (!released) {
        if (options.bridgePortPinned === true) {
          throw new Error(
            `Old theme runtime did not release port ${options.bridgePort}.`,
          );
        }
        options.bridgePort = await findAvailablePort(options.bridgePort + 1);
      }
    }
  } else if (!(await portIsAvailable(options.bridgePort))) {
    if (options.bridgePortPinned === true) {
      throw new Error(
        `Port ${options.bridgePort} is occupied by an unavailable service.`,
      );
    }
    options.bridgePort = await findAvailablePort(options.bridgePort + 1);
  }

  persistBridgePort(options.userRoot, options.bridgePort);
  const logDirectory = path.join(options.userRoot, "Logs");
  await fsp.mkdir(logDirectory, { recursive: true, mode: 0o700 });
  const logFD = fs.openSync(path.join(logDirectory, "runtime.log"), "a");
  const child = require("node:child_process").spawn(
    process.execPath,
    [
      options.cliPath,
      "serve",
      "--codex-app", options.codexApp,
      "--user-root", options.userRoot,
      "--debug-port", String(options.debugPort),
      "--bridge-port", String(options.bridgePort),
    ],
    {
      detached: true,
      stdio: ["ignore", logFD, logFD],
      env: { ...process.env, CODEX_THEME_SWITCHER_BRIDGE: "1" },
    },
  );
  child.unref();
  fs.closeSync(logFD);
  return waitForBridge(options);
}

module.exports = {
  APP_ID,
  MAX_THEME_ASSET_BYTES,
  MAX_THEME_CSS_BYTES,
  MAX_THEME_TOTAL_ASSET_BYTES,
  PROTOCOL_VERSION,
  activeThemePath,
  bridgePortPath,
  containsUnsafeThemeCSS,
  createMutationQueue,
  ensureTokenFile,
  loadActiveTheme,
  persistActiveTheme,
  persistBridgePort,
  readPersistedBridgePort,
  removeActiveTheme,
  serveBridge,
  startBridgeDaemon,
  validateThemePayload,
  waitForBridge,
};
