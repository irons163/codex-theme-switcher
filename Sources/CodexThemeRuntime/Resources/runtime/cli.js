#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {
  cdpStatus,
  ensureCodexApp,
  findExistingCodexDebugPort,
  isCodexRunning,
  readBundleValue,
} = require("./lib/cdp");
const {
  loadActiveTheme,
  removeActiveTheme,
  serveBridge,
  startBridgeDaemon,
} = require("./lib/bridge");
const { queryBridge } = require("./lib/http");

async function main() {
  const { command, options } = parseArgs(process.argv.slice(2));
  const resolved = resolveOptions(options);
  try {
    if (!command) {
      throw Object.assign(new Error("Missing command."), { code: "usage" });
    }
    ensureCodexApp(resolved.codexApp);

    if (command === "serve") {
      await serveBridge(resolved);
      return;
    }

    let payload;
    if (command === "status") {
      payload = await statusPayload(resolved);
    } else if (command === "launch") {
      await startBridgeDaemon(resolved);
      payload = await queryBridge(resolved, "/launch", "POST");
    } else if (command === "inject") {
      await startBridgeDaemon(resolved);
      payload = await queryBridge(resolved, "/inject", "POST");
    } else if (command === "apply") {
      const theme = await readStandardInputJSON();
      await startBridgeDaemon(resolved);
      payload = await queryBridge(resolved, "/theme", "PUT", theme);
    } else if (command === "clear") {
      try {
        await startBridgeDaemon(resolved);
        payload = await queryBridge(resolved, "/theme", "DELETE");
      } catch {
        await removeActiveTheme(resolved.userRoot);
        payload = await statusPayload(resolved);
      }
    } else if (command === "stop") {
      try {
        payload = await queryBridge(resolved, "/stop", "POST");
      } catch {
        payload = await statusPayload(resolved);
      }
    } else {
      throw Object.assign(new Error(`Unknown command: ${command}`), {
        code: "usage",
      });
    }

    writeJSON(payload);
    process.exitCode = payload.ok ? 0 : 1;
  } catch (error) {
    writeJSON({
      ok: false,
      status: null,
      error: {
        message: error && error.message ? error.message : String(error),
        code: error && error.code ? String(error.code) : "runtime-error",
      },
    });
    process.exitCode = 1;
  }
}

async function statusPayload(options) {
  if (fs.existsSync(options.tokenFile)) {
    try {
      return await queryBridge(options);
    } catch {}
  }

  const debugPort = await findExistingCodexDebugPort(options.debugPort)
    || options.debugPort;
  const cdp = await cdpStatus(debugPort);
  const activeTheme = await loadActiveTheme(options.userRoot);
  return {
    ok: true,
    status: {
      codexPath: options.codexApp,
      codexVersion: readBundleValue(
        options.codexApp,
        "CFBundleShortVersionString",
      ),
      mode: "cdp-css",
      isInjected: false,
      bridgeRunning: false,
      debugPort,
      bridgePort: options.bridgePort,
      isRunning: isCodexRunning(),
      isDebugPortReady: cdp.isDebugPortReady,
      hasCodexTarget: cdp.hasCodexTarget,
      activeThemeID: activeTheme?.themeID || null,
      activeThemeName: activeTheme?.themeName || null,
      injectedRendererCount: 0,
      lastError: null,
    },
  };
}

async function readStandardInputJSON(maxBytes = 72 * 1024 * 1024) {
  const chunks = [];
  let size = 0;
  for await (const chunk of process.stdin) {
    size += chunk.length;
    if (size > maxBytes) {
      const error = new Error("Theme payload exceeds the 72 MB limit.");
      error.code = "payload-too-large";
      throw error;
    }
    chunks.push(chunk);
  }
  if (!chunks.length) {
    throw Object.assign(new Error("Theme payload is missing."), {
      code: "invalid-theme",
    });
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw Object.assign(new Error("Theme payload is not valid JSON."), {
      code: "invalid-json",
    });
  }
}

function resolveOptions(options) {
  const userRoot = options["user-root"]
    || path.join(
      process.env.HOME,
      "Library",
      "Application Support",
      "CodexThemeSwitcher",
    );
  return {
    cliPath: __filename,
    codexApp: options["codex-app"] || "/Applications/Codex.app",
    userRoot,
    debugPort: Number(
      options["debug-port"]
        || process.env.CODEX_THEME_SWITCHER_DEBUG_PORT
        || 57340,
    ),
    bridgePort: Number(
      options["bridge-port"]
        || process.env.CODEX_THEME_SWITCHER_BRIDGE_PORT
        || 57342,
    ),
    tokenFile: path.join(userRoot, "Runtime", "bridge-token"),
  };
}

function parseArgs(args) {
  const result = { command: null, options: {} };
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (!result.command && !argument.startsWith("--")) {
      result.command = argument;
      continue;
    }
    if (!argument.startsWith("--")) continue;
    const key = argument.slice(2);
    if (key === "json") {
      result.options[key] = true;
    } else {
      result.options[key] = args[index + 1];
      index += 1;
    }
  }
  return result;
}

function writeJSON(payload) {
  process.stdout.write(`${JSON.stringify(payload, null, 2)}\n`);
}

if (require.main === module) {
  main();
}

module.exports = {
  parseArgs,
  readStandardInputJSON,
  resolveOptions,
  statusPayload,
};
