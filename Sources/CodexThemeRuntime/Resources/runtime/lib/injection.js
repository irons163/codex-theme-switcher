"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {
  CdpSession,
  codexPageTargets,
  listTargets,
  targetWebSocket,
} = require("./cdp");

function rendererInjectionSource() {
  return fs.readFileSync(
    path.resolve(__dirname, "..", "theme-inject.js"),
    "utf8",
  );
}

function applyExpression(theme) {
  return `window.__codexThemeSwitcherApply && window.__codexThemeSwitcherApply(${JSON.stringify(theme)});`;
}

function clearExpression() {
  return "window.__codexThemeSwitcherClear && window.__codexThemeSwitcherClear();";
}

async function installRuntime(session) {
  const source = rendererInjectionSource();
  await session.send("Runtime.enable");
  await session.send("Page.enable");
  await session.send("Page.addScriptToEvaluateOnNewDocument", { source });
  await session.send("Runtime.evaluate", {
    expression: source,
    awaitPromise: false,
    allowUnsafeEvalBlockedByCSP: true,
  });
}

async function applyTheme(session, theme) {
  if (!theme) return;
  await session.send("Runtime.evaluate", {
    expression: applyExpression(theme),
    awaitPromise: false,
    returnByValue: true,
    allowUnsafeEvalBlockedByCSP: true,
  });
}

async function clearTheme(session) {
  await session.send("Runtime.evaluate", {
    expression: clearExpression(),
    awaitPromise: false,
    returnByValue: true,
    allowUnsafeEvalBlockedByCSP: true,
  });
}

async function injectRenderers(
  debugPort,
  theme,
  sessions = new Map(),
  logger = () => {},
) {
  const targets = codexPageTargets(await listTargets(debugPort));
  const liveTargetIDs = new Set(targets.map((target) => target.id));

  for (const [targetID, session] of sessions) {
    if (session.closed || !liveTargetIDs.has(targetID)) {
      session.close();
      sessions.delete(targetID);
    }
  }

  let successful = 0;
  for (const target of targets) {
    let session = sessions.get(target.id);
    try {
      if (!session || session.closed) {
        session = await CdpSession.connect(
          targetWebSocket(target),
          target.id,
          logger,
        );
        await installRuntime(session);
        sessions.set(target.id, session);
      }
      await applyTheme(session, theme);
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
      await applyTheme(session, theme);
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
    }
  }
  return successful;
}

module.exports = {
  applyExpression,
  broadcastTheme,
  clearExpression,
  clearRenderers,
  injectRenderers,
  rendererInjectionSource,
};
