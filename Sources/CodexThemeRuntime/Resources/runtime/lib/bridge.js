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
  broadcastTheme,
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
const PROTOCOL_VERSION = 1;
const MAX_THEME_CSS_BYTES = 64 * 1024 * 1024;

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
  return decodeCSSEscapes(removeCSSComments(source));
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
  if (Buffer.byteLength(theme.css, "utf8") > MAX_THEME_CSS_BYTES) {
    throw Object.assign(new Error("Compiled theme CSS exceeds the 64 MB limit."), {
      code: "theme-too-large",
    });
  }
  if (containsUnsafeThemeCSS(theme.css)) {
    throw Object.assign(
      new Error(
        "Theme CSS may not use @import or load external/local file URLs.",
      ),
      { code: "unsafe-css" },
    );
  }
  return {
    themeID: theme.themeID.trim(),
    themeName: theme.themeName.trim(),
    css: theme.css,
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
      const status = await cdpStatus(state.debugPort);
      if (!status.hasCodexTarget) {
        throw Object.assign(
          new Error("Codex is not attached. Launch + Attach before applying."),
          { code: "missing-cdp-target" },
        );
      }
      await injectOnce();
      await broadcastTheme(state.sessions, validated, log);
      await persistActiveTheme(options.userRoot, validated);
    } catch (error) {
      state.activeTheme = previous;
      throw error;
    }
  }

  async function clearTheme() {
    await clearRenderers(state.sessions, log);
    state.activeTheme = null;
    await removeActiveTheme(options.userRoot);
  }

  async function bridgeStatus() {
    const cdp = await cdpStatus(state.debugPort);
    let activeSessionCount = 0;
    for (const session of state.sessions.values()) {
      if (!session.closed) activeSessionCount += 1;
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
        lastError: state.lastError,
      },
    };
  }

  const server = http.createServer((request, response) => {
    handleRequest(request, response).catch((error) => {
      state.lastError = error.message || String(error);
      log(`request failed: ${state.lastError}`);
      const status = error.code === "payload-too-large" ? 413 : 500;
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
      await launchAndInject();
      writeJSON(response, 200, await bridgeStatus());
      return;
    }
    if (request.method === "POST" && request.url === "/inject") {
      await injectOnce();
      writeJSON(response, 200, await bridgeStatus());
      return;
    }
    if (request.method === "PUT" && request.url === "/theme") {
      await applyTheme(await readJSONBody(request));
      writeJSON(response, 200, await bridgeStatus());
      return;
    }
    if (request.method === "DELETE" && request.url === "/theme") {
      await clearTheme();
      writeJSON(response, 200, await bridgeStatus());
      return;
    }
    if (request.method === "POST" && request.url === "/stop") {
      await clearRenderers(state.sessions, log);
      for (const session of state.sessions.values()) session.close();
      state.sessions.clear();
      writeJSON(response, 200, {
        app: APP_ID,
        ok: true,
        stopped: true,
        status: {
          ...(await bridgeStatus()).status,
          isInjected: false,
          bridgeRunning: false,
          injectedRendererCount: 0,
        },
      });
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
    cdpStatus(state.debugPort)
      .then((status) => status.hasCodexTarget ? injectOnce() : null)
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
  try {
    return await waitForBridge(options, 500);
  } catch {}

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
  MAX_THEME_CSS_BYTES,
  PROTOCOL_VERSION,
  activeThemePath,
  containsUnsafeThemeCSS,
  ensureTokenFile,
  loadActiveTheme,
  persistActiveTheme,
  removeActiveTheme,
  serveBridge,
  startBridgeDaemon,
  validateThemePayload,
  waitForBridge,
};
