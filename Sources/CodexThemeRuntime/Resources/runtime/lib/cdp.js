"use strict";

const childProcess = require("node:child_process");
const fs = require("node:fs");
const net = require("node:net");
const path = require("node:path");
const { isCodexRunning, quitCodex, sleep } = require("./processes");
const { fetchJSON } = require("./http");

class CdpSession {
  constructor(socket, targetID, logger = () => {}) {
    this.socket = socket;
    this.targetID = targetID;
    this.logger = logger;
    this.nextID = 1;
    this.pending = new Map();
    this.closed = false;
    socket.addEventListener("message", (event) => this.handleMessage(event));
    socket.addEventListener("close", () => this.handleClose());
    socket.addEventListener("error", (event) => {
      logger(`CDP websocket error: ${event.message || "unknown"}`);
    });
  }

  static connect(websocketURL, targetID, logger) {
    return new Promise((resolve, reject) => {
      const socket = new WebSocket(websocketURL);
      const timeout = setTimeout(
        () => reject(new Error("Timed out connecting to Codex renderer.")),
        5000,
      );
      socket.addEventListener("open", () => {
        clearTimeout(timeout);
        resolve(new CdpSession(socket, targetID, logger));
      }, { once: true });
      socket.addEventListener("error", () => {
        clearTimeout(timeout);
        reject(new Error("Failed to connect to Codex renderer."));
      }, { once: true });
    });
  }

  send(method, params = {}) {
    if (this.closed) {
      return Promise.reject(new Error("CDP websocket is closed."));
    }
    const id = this.nextID++;
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Timed out waiting for CDP command ${method}.`));
      }, 7000);
      this.pending.set(id, { resolve, reject, timeout, method });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  handleMessage(event) {
    let message;
    try {
      message = JSON.parse(String(event.data));
    } catch {
      return;
    }
    if (!message.id || !this.pending.has(message.id)) return;
    const pending = this.pending.get(message.id);
    this.pending.delete(message.id);
    clearTimeout(pending.timeout);
    if (message.error) {
      pending.reject(
        new Error(
          `CDP command ${pending.method} failed: ${JSON.stringify(message.error)}`,
        ),
      );
    } else {
      pending.resolve(message.result || {});
    }
  }

  handleClose() {
    this.closed = true;
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeout);
      pending.reject(new Error("CDP websocket closed."));
    }
    this.pending.clear();
  }

  close() {
    this.closed = true;
    try {
      this.socket.close();
    } catch {}
  }
}

function targetWebSocket(target) {
  return target.webSocketDebuggerUrl || target.web_socket_debugger_url || null;
}

function codexPageTargets(targets) {
  return targets.filter((target) => {
    if (target.type !== "page" || !targetWebSocket(target)) return false;
    const url = String(target.url || "");
    return /^app:\/\/-\/index\.html(?:[?#]|$)/.test(url)
      && !url.includes("avatar-overlay");
  });
}

async function listTargets(debugPort) {
  return fetchJSON(`http://127.0.0.1:${debugPort}/json`, {}, 1000);
}

async function cdpStatus(debugPort) {
  try {
    await fetchJSON(
      `http://127.0.0.1:${debugPort}/json/version`,
      {},
      500,
    );
  } catch {
    return { isDebugPortReady: false, hasCodexTarget: false };
  }
  try {
    const targets = await listTargets(debugPort);
    return {
      isDebugPortReady: true,
      hasCodexTarget: codexPageTargets(targets).length > 0,
    };
  } catch {
    return { isDebugPortReady: true, hasCodexTarget: false };
  }
}

function portIsAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.once("error", () => resolve(false));
    server.once("listening", () => {
      server.close(() => resolve(true));
    });
    server.listen(port, "127.0.0.1");
  });
}

async function findAvailablePort(startPort) {
  for (let port = startPort; port < startPort + 200; port += 1) {
    if (await portIsAvailable(port)) return port;
  }
  throw new Error(`No free local port found starting at ${startPort}.`);
}

async function findExistingCodexDebugPort(preferredPort) {
  const candidates = [
    preferredPort,
    57330,
    57331,
    57332,
    57333,
    57334,
    57335,
    57336,
    57337,
    57338,
    57339,
    57340,
    57341,
  ];
  const unique = [...new Set(candidates)];
  const results = await Promise.all(
    unique.map(async (port) => ({
      port,
      status: await cdpStatus(port),
    })),
  );
  return results.find((item) => item.status.hasCodexTarget)?.port || null;
}

function codexDebugArgs(debugPort) {
  return [
    "--remote-debugging-address=127.0.0.1",
    `--remote-debugging-port=${debugPort}`,
    `--remote-allow-origins=http://127.0.0.1:${debugPort}`,
  ];
}

async function launchCodex(codexApp, debugPort) {
  childProcess.spawn(
    "open",
    [codexApp, "--args", ...codexDebugArgs(debugPort)],
    { detached: true, stdio: "ignore" },
  ).unref();
}

async function ensureCodexLaunched(codexApp, debugPort) {
  if ((await cdpStatus(debugPort)).hasCodexTarget) {
    return { launched: false };
  }
  if (isCodexRunning()) await quitCodex();
  await launchCodex(codexApp, debugPort);
  const startedAt = Date.now();
  let lastError = null;
  while (Date.now() - startedAt < 25000) {
    try {
      if ((await cdpStatus(debugPort)).hasCodexTarget) {
        return { launched: true };
      }
    } catch (error) {
      lastError = error;
    }
    await sleep(500);
  }
  throw lastError
    || new Error(`Timed out waiting for Codex on debug port ${debugPort}.`);
}

function readBundleValue(codexApp, key) {
  try {
    return childProcess.execFileSync(
      "/usr/libexec/PlistBuddy",
      ["-c", `Print :${key}`, path.join(codexApp, "Contents", "Info.plist")],
      { encoding: "utf8" },
    ).trim();
  } catch {
    return null;
  }
}

function ensureCodexApp(codexApp) {
  const executableName = readBundleValue(codexApp, "CFBundleExecutable");
  const candidates = [executableName, "Codex", "ChatGPT"]
    .filter(Boolean)
    .map((name) => path.join(codexApp, "Contents", "MacOS", name));
  if (!candidates.some((candidate) => {
    try {
      fs.accessSync(candidate, fs.constants.X_OK);
      return true;
    } catch {
      return false;
    }
  })) {
    const error = new Error(
      `Codex desktop app not found or missing executable: ${codexApp}`,
    );
    error.code = "missing-codex-app";
    throw error;
  }
}

module.exports = {
  CdpSession,
  cdpStatus,
  codexDebugArgs,
  codexPageTargets,
  ensureCodexApp,
  ensureCodexLaunched,
  findAvailablePort,
  findExistingCodexDebugPort,
  isCodexRunning,
  listTargets,
  portIsAvailable,
  quitCodex,
  readBundleValue,
  targetWebSocket,
};
