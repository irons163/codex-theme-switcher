"use strict";

const childProcess = require("node:child_process");

function isCodexMainProcessCommand(command) {
  return /^(?:\/Applications|\/Users\/[^/]+\/Applications)\/(?:Codex\.app\/Contents\/MacOS\/Codex|ChatGPT\.app\/Contents\/MacOS\/ChatGPT)(?:\s|$)/
    .test(String(command || ""));
}

function codexMainProcessIds(output) {
  return String(output || "")
    .split(/\r?\n/)
    .map((line) => {
      const match = line.match(/^\s*(\d+)\s+(.+)$/);
      if (!match || !isCodexMainProcessCommand(match[2])) return null;
      return Number(match[1]);
    })
    .filter((pid) => Number.isInteger(pid) && pid > 0);
}

function runningCodexMainProcessIds() {
  const result = childProcess.spawnSync(
    "ps",
    ["-axo", "pid=,command="],
    { encoding: "utf8" },
  );
  if (result.status !== 0 && !result.stdout) return [];
  return codexMainProcessIds(result.stdout);
}

function isCodexRunning() {
  return runningCodexMainProcessIds().length > 0;
}

async function quitCodex() {
  childProcess.spawnSync(
    "osascript",
    ["-e", "tell application id \"com.openai.codex\" to quit"],
    { stdio: "ignore" },
  );
  if (await waitForCodexExit(15000)) return;
  terminateCodexMainProcesses("SIGTERM");
  if (await waitForCodexExit(5000)) return;
  terminateCodexMainProcesses("SIGKILL");
  await waitForCodexExit(3000);
}

async function waitForCodexExit(timeoutMs) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    if (!isCodexRunning()) return true;
    await sleep(250);
  }
  return !isCodexRunning();
}

function terminateCodexMainProcesses(signal) {
  for (const pid of runningCodexMainProcessIds()) {
    try {
      process.kill(pid, signal);
    } catch {}
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = {
  codexMainProcessIds,
  isCodexMainProcessCommand,
  isCodexRunning,
  quitCodex,
  sleep,
};
