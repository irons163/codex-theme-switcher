"use strict";

const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const fsp = require("node:fs/promises");
const net = require("node:net");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  bridgePortPath,
  startBridgeDaemon,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/bridge");
const {
  queryBridge,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/http");
const {
  portIsAvailable,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/cdp");

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

test("different user roots select separate bridge ports", {
  timeout: 20000,
}, async (t) => {
  const root = await fsp.mkdtemp(
    path.join(os.tmpdir(), "codex-theme-port-test-"),
  );
  let first = null;
  let secondOptions = null;
  t.after(async () => {
    if (secondOptions) {
      try {
        await queryBridge(secondOptions, "/stop", "POST");
        await waitFor(
          () => portIsAvailable(secondOptions.bridgePort),
          3000,
        );
      } catch {}
    }
    if (first) await terminate(first);
    await fsp.rm(root, { recursive: true, force: true });
  });

  const codexApp = path.join(root, "FakeCodex.app");
  const executable = path.join(codexApp, "Contents", "MacOS", "Codex");
  await fsp.mkdir(path.dirname(executable), { recursive: true });
  await fsp.writeFile(executable, "#!/bin/sh\nexit 0\n", { mode: 0o700 });

  const firstRoot = path.join(root, "First");
  const secondRoot = path.join(root, "Second");
  const occupiedPort = await availablePort();
  const firstTokenFile = path.join(firstRoot, "Runtime", "bridge-token");
  first = spawn(
    process.execPath,
    [
      cliPath,
      "serve",
      "--codex-app", codexApp,
      "--user-root", firstRoot,
      "--bridge-port", String(occupiedPort),
      "--debug-port", String(await availablePort()),
    ],
    { stdio: ["ignore", "pipe", "pipe"] },
  );

  await waitFor(async () => {
    if (!fs.existsSync(firstTokenFile)) return false;
    const response = await fetch(
      `http://127.0.0.1:${occupiedPort}/status`,
      {
        headers: {
          Authorization: `Bearer ${
            (await fsp.readFile(firstTokenFile, "utf8")).trim()
          }`,
        },
      },
    );
    return response.ok;
  });

  secondOptions = {
    cliPath,
    codexApp,
    userRoot: secondRoot,
    debugPort: await availablePort(),
    bridgePort: occupiedPort,
    bridgePortPinned: false,
    tokenFile: path.join(secondRoot, "Runtime", "bridge-token"),
  };

  const secondStatus = await startBridgeDaemon(secondOptions);
  assert.equal(secondStatus.ok, true);
  assert.notEqual(secondOptions.bridgePort, occupiedPort);
  assert.equal(
    Number.parseInt(
      await fsp.readFile(bridgePortPath(secondRoot), "utf8"),
      10,
    ),
    secondOptions.bridgePort,
  );
  assert.equal(fs.statSync(bridgePortPath(secondRoot)).mode & 0o777, 0o600);
  assert.equal(
    (await queryBridge(secondOptions)).status.bridgePort,
    secondOptions.bridgePort,
  );

  const pinnedOptions = {
    ...secondOptions,
    userRoot: path.join(root, "Pinned"),
    bridgePort: occupiedPort,
    bridgePortPinned: true,
    tokenFile: path.join(root, "Pinned", "Runtime", "bridge-token"),
  };
  await assert.rejects(
    startBridgeDaemon(pinnedOptions),
    /occupied by an unavailable service/,
  );
});
