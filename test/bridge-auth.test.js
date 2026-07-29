"use strict";

const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const fsp = require("node:fs/promises");
const net = require("node:net");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const cliPath = path.resolve(
  __dirname,
  "../Sources/CodexThemeRuntime/Resources/runtime/cli.js",
);

async function availablePort() {
  const server = net.createServer();
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const { port } = server.address();
  await new Promise((resolve) => server.close(resolve));
  return port;
}

async function waitFor(check, timeoutMs = 6000) {
  const startedAt = Date.now();
  let lastError;
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const value = await check();
      if (value) return value;
    } catch (error) {
      lastError = error;
    }
    await new Promise((resolve) => setTimeout(resolve, 30));
  }
  throw lastError || new Error("Timed out waiting for bridge.");
}

async function terminate(child) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  const exited = new Promise((resolve) => child.once("exit", resolve));
  child.kill("SIGTERM");
  await Promise.race([
    exited,
    new Promise((resolve) => setTimeout(resolve, 2000)),
  ]);
  if (child.exitCode === null && child.signalCode === null) {
    child.kill("SIGKILL");
    await exited;
  }
}

test("bridge requires the exact bearer token", { timeout: 15000 }, async (t) => {
  const root = await fsp.mkdtemp(
    path.join(os.tmpdir(), "codex-theme-auth-test-"),
  );
  t.after(() => fsp.rm(root, { recursive: true, force: true }));

  const codexApp = path.join(root, "FakeCodex.app");
  const executable = path.join(codexApp, "Contents", "MacOS", "Codex");
  await fsp.mkdir(path.dirname(executable), { recursive: true });
  await fsp.writeFile(executable, "#!/bin/sh\nexit 0\n", { mode: 0o700 });

  const userRoot = path.join(root, "User");
  const bridgePort = await availablePort();
  const debugPort = await availablePort();
  const child = spawn(
    process.execPath,
    [
      cliPath,
      "serve",
      "--codex-app", codexApp,
      "--user-root", userRoot,
      "--bridge-port", String(bridgePort),
      "--debug-port", String(debugPort),
    ],
    { stdio: ["ignore", "pipe", "pipe"] },
  );
  t.after(() => terminate(child));

  const tokenFile = path.join(userRoot, "Runtime", "bridge-token");
  const token = await waitFor(async () => {
    if (!fs.existsSync(tokenFile)) return null;
    const value = (await fsp.readFile(tokenFile, "utf8")).trim();
    try {
      await fetch(`http://127.0.0.1:${bridgePort}/status`);
      return value;
    } catch {
      return null;
    }
  });

  const missing = await fetch(`http://127.0.0.1:${bridgePort}/status`);
  assert.equal(missing.status, 401);
  assert.equal((await missing.json()).error.code, "unauthorized");

  const wrong = await fetch(`http://127.0.0.1:${bridgePort}/status`, {
    headers: { Authorization: `Bearer ${token}0` },
  });
  assert.equal(wrong.status, 401);
  assert.equal((await wrong.json()).error.code, "unauthorized");

  const wrongScheme = await fetch(`http://127.0.0.1:${bridgePort}/status`, {
    headers: { Authorization: `Basic ${token}` },
  });
  assert.equal(wrongScheme.status, 401);

  const accepted = await fetch(`http://127.0.0.1:${bridgePort}/status`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  assert.equal(accepted.status, 200);
  const payload = await accepted.json();
  assert.equal(payload.ok, true);
  assert.equal(payload.app, "codex-theme-switcher");
  assert.equal(payload.protocolVersion, 3);

  assert.equal(fs.statSync(tokenFile).mode & 0o777, 0o600);
});
