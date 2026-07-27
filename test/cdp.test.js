"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  codexDebugArgs,
  codexPageTargets,
  targetWebSocket,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/cdp");

function target(overrides = {}) {
  return {
    id: "target",
    type: "page",
    url: "app://-/index.html",
    webSocketDebuggerUrl: "ws://127.0.0.1/devtools/page/target",
    ...overrides,
  };
}

test("codexDebugArgs binds the DevTools endpoint to loopback", () => {
  assert.deepEqual(codexDebugArgs(57340), [
    "--remote-debugging-address=127.0.0.1",
    "--remote-debugging-port=57340",
    "--remote-allow-origins=http://127.0.0.1:57340",
  ]);
});

test("targetWebSocket accepts Chromium's documented and alternate keys", () => {
  assert.equal(targetWebSocket(target()), "ws://127.0.0.1/devtools/page/target");
  assert.equal(
    targetWebSocket(target({
      webSocketDebuggerUrl: undefined,
      web_socket_debugger_url: "ws://alternate",
    })),
    "ws://alternate",
  );
  assert.equal(targetWebSocket({}), null);
});

test("codexPageTargets accepts main renderer pages and excludes overlays", () => {
  const accepted = target({ id: "main" });
  const withQuery = target({
    id: "query",
    url: "app://-/index.html?window=second",
  });
  const withFragment = target({
    id: "fragment",
    url: "app://-/index.html#settings",
  });
  const avatar = target({
    id: "avatar",
    url: "app://-/index.html?avatar-overlay=1",
  });

  assert.deepEqual(
    codexPageTargets([accepted, withQuery, withFragment, avatar])
      .map(({ id }) => id),
    ["main", "query", "fragment"],
  );
});

test("codexPageTargets rejects non-page, non-app, and non-debuggable targets", () => {
  const candidates = [
    target({ id: "worker", type: "worker" }),
    target({ id: "http", url: "https://example.com/index.html" }),
    target({ id: "other-app", url: "app://-/settings.html" }),
    target({ id: "no-socket", webSocketDebuggerUrl: null }),
    target({ id: "empty-socket", webSocketDebuggerUrl: "" }),
  ];
  assert.deepEqual(codexPageTargets(candidates), []);
});

test("codexPageTargets rejects lookalike index document paths", () => {
  const candidates = [
    target({ id: "extension", url: "app://-/index.html.attacker" }),
    target({ id: "subpath", url: "app://-/index.html/other" }),
  ];
  assert.deepEqual(codexPageTargets(candidates), []);
});
