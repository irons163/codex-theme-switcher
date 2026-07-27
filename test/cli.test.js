"use strict";

const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");

const {
  parseArgs,
  resolveOptions,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/cli");

test("parseArgs handles command, value options, and boolean JSON flag", () => {
  assert.deepEqual(
    parseArgs([
      "apply",
      "--codex-app", "/Applications/ChatGPT.app",
      "--user-root", "/tmp/theme root",
      "--debug-port", "6000",
      "--bridge-port", "6001",
      "--json",
    ]),
    {
      command: "apply",
      options: {
        "codex-app": "/Applications/ChatGPT.app",
        "user-root": "/tmp/theme root",
        "debug-port": "6000",
        "bridge-port": "6001",
        json: true,
      },
    },
  );
});

test("parseArgs accepts flags before command and last duplicate wins", () => {
  assert.deepEqual(
    parseArgs([
      "--json",
      "--debug-port", "1",
      "status",
      "--debug-port", "2",
      "ignored-positional",
    ]),
    {
      command: "status",
      options: {
        json: true,
        "debug-port": "2",
      },
    },
  );
});

test("resolveOptions applies explicit values and derives token path", () => {
  const resolved = resolveOptions({
    "codex-app": "/custom/Codex.app",
    "user-root": "/tmp/custom-root",
    "debug-port": "6100",
    "bridge-port": "6101",
  });
  assert.equal(resolved.codexApp, "/custom/Codex.app");
  assert.equal(resolved.userRoot, "/tmp/custom-root");
  assert.equal(resolved.debugPort, 6100);
  assert.equal(resolved.bridgePort, 6101);
  assert.equal(
    resolved.tokenFile,
    path.join("/tmp/custom-root", "Runtime", "bridge-token"),
  );
  assert.equal(path.basename(resolved.cliPath), "cli.js");
});

test("resolveOptions honors environment ports and defaults", { concurrency: false }, () => {
  const previousDebug = process.env.CODEX_THEME_SWITCHER_DEBUG_PORT;
  const previousBridge = process.env.CODEX_THEME_SWITCHER_BRIDGE_PORT;
  try {
    process.env.CODEX_THEME_SWITCHER_DEBUG_PORT = "6200";
    process.env.CODEX_THEME_SWITCHER_BRIDGE_PORT = "6201";
    const resolved = resolveOptions({});
    assert.equal(resolved.codexApp, "/Applications/Codex.app");
    assert.equal(resolved.debugPort, 6200);
    assert.equal(resolved.bridgePort, 6201);
    assert.equal(
      resolved.userRoot,
      path.join(
        process.env.HOME,
        "Library",
        "Application Support",
        "CodexThemeSwitcher",
      ),
    );
  } finally {
    if (previousDebug === undefined) {
      delete process.env.CODEX_THEME_SWITCHER_DEBUG_PORT;
    } else {
      process.env.CODEX_THEME_SWITCHER_DEBUG_PORT = previousDebug;
    }
    if (previousBridge === undefined) {
      delete process.env.CODEX_THEME_SWITCHER_BRIDGE_PORT;
    } else {
      process.env.CODEX_THEME_SWITCHER_BRIDGE_PORT = previousBridge;
    }
  }
});
