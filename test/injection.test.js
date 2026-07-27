"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const vm = require("node:vm");

const injectionPath =
  "../Sources/CodexThemeRuntime/Resources/runtime/lib/injection";
const {
  applyExpression,
  broadcastTheme,
  clearExpression,
  clearRenderers,
  rendererInjectionSource,
} = require(injectionPath);

function recordingSession({ fail = false, closed = false } = {}) {
  return {
    closed,
    messages: [],
    closeCalls: 0,
    async send(method, params) {
      this.messages.push({ method, params });
      if (fail) throw new Error("simulated CDP failure");
      return {};
    },
    close() {
      this.closed = true;
      this.closeCalls += 1;
    },
  };
}

test("applyExpression transports untrusted CSS as data, not executable code", () => {
  const theme = {
    themeID: 'quote-"',
    themeName: "Injection test",
    css: '"); globalThis.compromised = true; //\n:root{color:red}',
  };
  let received;
  const sandbox = {
    window: {
      __codexThemeSwitcherApply(payload) {
        received = payload;
      },
    },
  };

  vm.runInNewContext(applyExpression(theme), sandbox);

  assert.deepEqual(
    JSON.parse(JSON.stringify(received)),
    theme,
  );
  assert.equal(sandbox.compromised, undefined);
});

test("clearExpression is guarded when runtime is absent and invokes when present", () => {
  assert.doesNotThrow(() => vm.runInNewContext(clearExpression(), {
    window: {},
  }));

  let calls = 0;
  vm.runInNewContext(clearExpression(), {
    window: {
      __codexThemeSwitcherClear() {
        calls += 1;
      },
    },
  });
  assert.equal(calls, 1);
});

test("rendererInjectionSource returns the complete idempotent runtime", () => {
  const source = rendererInjectionSource();
  assert.match(source, /__codexThemeSwitcherRuntime/);
  assert.match(source, /codex-theme-switcher-style/);
  assert.match(source, /__codexThemeSwitcherApply/);
  assert.match(source, /__codexThemeSwitcherClear/);
});

test("broadcastTheme prunes closed and failed sessions", async () => {
  const live = recordingSession();
  const closed = recordingSession({ closed: true });
  const failed = recordingSession({ fail: true });
  const sessions = new Map([
    ["live", live],
    ["closed", closed],
    ["failed", failed],
  ]);
  const logs = [];

  const successful = await broadcastTheme(
    sessions,
    { themeID: "id", themeName: "Name", css: ":root{}" },
    (message) => logs.push(message),
  );

  assert.equal(successful, 1);
  assert.deepEqual([...sessions.keys()], ["live"]);
  assert.equal(live.messages.length, 1);
  assert.equal(live.messages[0].method, "Runtime.evaluate");
  assert.equal(failed.closeCalls, 1);
  assert.match(logs[0], /apply target failed failed/);
});

test("clearRenderers skips closed sessions and retains failures for retry", async () => {
  const live = recordingSession();
  const closed = recordingSession({ closed: true });
  const failed = recordingSession({ fail: true });
  const sessions = new Map([
    ["live", live],
    ["closed", closed],
    ["failed", failed],
  ]);
  const logs = [];

  const successful = await clearRenderers(
    sessions,
    (message) => logs.push(message),
  );

  assert.equal(successful, 1);
  assert.deepEqual([...sessions.keys()], ["live", "failed"]);
  assert.equal(live.messages[0].method, "Runtime.evaluate");
  assert.equal(live.messages[0].params.expression, clearExpression());
  assert.match(logs[0], /clear target failed failed/);
});

test("injectRenderers installs once per target and reuses live sessions", async (t) => {
  const cdpPath = require.resolve(
    "../Sources/CodexThemeRuntime/Resources/runtime/lib/cdp",
  );
  const resolvedInjectionPath = require.resolve(injectionPath);
  const cdp = require(cdpPath);
  const originals = {
    CdpSession: cdp.CdpSession,
    listTargets: cdp.listTargets,
  };
  const created = [];
  cdp.listTargets = async () => [{
    id: "main",
    type: "page",
    url: "app://-/index.html",
    webSocketDebuggerUrl: "ws://main",
  }];
  cdp.CdpSession = {
    async connect(url, id) {
      const session = recordingSession();
      session.url = url;
      session.id = id;
      created.push(session);
      return session;
    },
  };
  delete require.cache[resolvedInjectionPath];
  const isolated = require(resolvedInjectionPath);
  t.after(() => {
    cdp.CdpSession = originals.CdpSession;
    cdp.listTargets = originals.listTargets;
    delete require.cache[resolvedInjectionPath];
  });

  const sessions = await isolated.injectRenderers(
    57340,
    { themeID: "one", themeName: "One", css: ":root{}" },
  );
  await isolated.injectRenderers(
    57340,
    { themeID: "two", themeName: "Two", css: ":root{color:red}" },
    sessions,
  );

  assert.equal(created.length, 1);
  assert.equal(created[0].url, "ws://main");
  assert.deepEqual(
    created[0].messages.map(({ method }) => method),
    [
      "Runtime.enable",
      "Page.enable",
      "Page.addScriptToEvaluateOnNewDocument",
      "Runtime.evaluate",
      "Runtime.evaluate",
      "Runtime.evaluate",
    ],
  );
  assert.equal(
    created[0].messages[2].params.source,
    rendererInjectionSource(),
  );
  assert.match(
    created[0].messages.at(-1).params.expression,
    /"themeID":"two"/,
  );
});
