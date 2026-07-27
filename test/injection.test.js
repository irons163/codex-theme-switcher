"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const vm = require("node:vm");

const injectionPath =
  "../Sources/CodexThemeRuntime/Resources/runtime/lib/injection";
const {
  BASE64_CHUNK_CHARACTERS,
  applyTheme,
  beginExpression,
  beginPayload,
  broadcastTheme,
  checkedEvaluationValue,
  clearRenderers,
  rendererInjectionSource,
} = require(injectionPath);

function theme(overrides = {}) {
  return {
    themeID: "theme-id",
    themeName: "Theme",
    digest: "digest-one",
    css: ":root{}",
    assets: [],
    ...overrides,
  };
}

function asset(id, dataBase64) {
  return {
    id,
    mediaType: "image/png",
    dataBase64,
    fingerprint: `fingerprint-${id}`,
    byteLength: Math.floor(dataBase64.length * 0.75),
  };
}

function evaluation(value) {
  return { result: { value } };
}

function transactionSession(options = {}) {
  const calls = [];
  const state = {
    digest: options.digest ?? null,
    stylePresent: options.stylePresent ?? false,
    pending: null,
  };
  const sandbox = {
    window: {
      __codexThemeSwitcherBegin(payload) {
        calls.push({ operation: "begin", payload });
        state.pending = payload;
        return {
          ok: true,
          unchanged: false,
          transactionID: "transaction-1",
          requiredAssetIDs: options.requiredAssetIDs
            ?? payload.assets.map(({ id }) => id),
        };
      },
      __codexThemeSwitcherAppendAsset(payload) {
        calls.push({ operation: "append", payload });
        if (
          options.exceptionOnAppend
          && payload.index === options.exceptionOnAppend.index
        ) {
          throw new Error(options.exceptionOnAppend.message);
        }
        return { ok: true };
      },
      __codexThemeSwitcherCommit(payload) {
        calls.push({ operation: "commit", payload });
        state.digest = state.pending.digest;
        state.stylePresent = true;
        state.pending = null;
        return { ok: true, digest: state.digest };
      },
      __codexThemeSwitcherAbort(payload) {
        calls.push({ operation: "abort", payload });
        state.pending = null;
        return { ok: true };
      },
      __codexThemeSwitcherStatus() {
        calls.push({ operation: "status" });
        return {
          ok: true,
          digest: state.digest,
          stylePresent: state.stylePresent,
          current: state.stylePresent ? { digest: state.digest } : null,
        };
      },
      __codexThemeSwitcherClear() {
        calls.push({ operation: "clear" });
        state.digest = null;
        state.stylePresent = false;
        return { ok: true };
      },
    },
  };

  return {
    calls,
    closed: false,
    closeCalls: 0,
    messages: [],
    state,
    async send(method, params = {}) {
      this.messages.push({ method, params });
      if (method !== "Runtime.evaluate") return {};
      if (params.expression.includes("installCodexThemeRuntime")) {
        return evaluation({ ok: true });
      }
      try {
        const value = await vm.runInNewContext(params.expression, sandbox);
        return evaluation(value);
      } catch (error) {
        return {
          exceptionDetails: {
            text: "Uncaught",
            exception: { description: error.stack || error.message },
          },
        };
      }
    },
    close() {
      this.closed = true;
      this.closeCalls += 1;
    },
  };
}

test("Begin transports CSS as data and omits asset base64", async () => {
  const payload = theme({
    css: '"); globalThis.compromised = true; //',
    assets: [asset("hero", "AAAA")],
  });
  const prepared = beginPayload(payload);
  let received;
  const sandbox = {
    window: {
      __codexThemeSwitcherBegin(value) {
        received = value;
        return { ok: true };
      },
    },
  };

  const result = await vm.runInNewContext(
    beginExpression(prepared.payload),
    sandbox,
  );

  assert.equal(result.ok, true);
  assert.equal(sandbox.compromised, undefined);
  assert.equal(received.css, payload.css);
  assert.match(
    received.transactionID,
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
  );
  assert.deepEqual(
    JSON.parse(JSON.stringify(received.assets)),
    [{
      id: "hero",
      mediaType: "image/png",
      fingerprint: "fingerprint-hero",
      byteLength: 3,
      base64Characters: 4,
    }],
  );
  assert.equal(JSON.stringify(received).includes("dataBase64"), false);
});

test("asset frames preserve every 256 KiB base64 boundary", async () => {
  const lengths = [
    BASE64_CHUNK_CHARACTERS - 1,
    BASE64_CHUNK_CHARACTERS,
    BASE64_CHUNK_CHARACTERS + 1,
    BASE64_CHUNK_CHARACTERS * 2,
    BASE64_CHUNK_CHARACTERS * 2 + 1,
  ];
  const assets = lengths.map((length, index) => (
    asset(`asset-${index}`, String(index).repeat(length))
  ));
  const session = transactionSession();

  await applyTheme(session, theme({ assets }));

  const begin = session.calls.find(({ operation }) => operation === "begin");
  assert.deepEqual(
    Array.from(
      begin.payload.assets,
      ({ base64Characters }) => base64Characters,
    ),
    lengths,
  );
  for (let assetIndex = 0; assetIndex < assets.length; assetIndex += 1) {
    const frames = session.calls.filter(
      (call) => call.operation === "append"
        && call.payload.assetID === assets[assetIndex].id,
    );
    assert.deepEqual(
      frames.map(({ payload }) => payload.index),
      Array.from({ length: Math.ceil(lengths[assetIndex]
        / BASE64_CHUNK_CHARACTERS) }, (_, index) => index),
    );
    assert.ok(frames.every(
      ({ payload }) => payload.chunk.length <= BASE64_CHUNK_CHARACTERS,
    ));
    assert.equal(
      frames.map(({ payload }) => payload.chunk).join(""),
      assets[assetIndex].dataBase64,
    );
  }
  assert.equal(session.calls.at(-1).operation, "commit");
  assert.ok(session.messages
    .filter(({ method }) => method === "Runtime.evaluate")
    .every(({ params }) => (
      params.awaitPromise === true && params.returnByValue === true
    )));
});

test("renderer exceptions reject the transaction and best-effort Abort", async () => {
  const session = transactionSession({
    exceptionOnAppend: { index: 1, message: "frame exploded" },
  });

  await assert.rejects(
    applyTheme(session, theme({
      assets: [asset(
        "large",
        "A".repeat(BASE64_CHUNK_CHARACTERS + 1),
      )],
    })),
    (error) => (
      error.code === "renderer-exception"
      && /frame exploded/.test(error.message)
    ),
  );
  assert.deepEqual(
    session.calls.map(({ operation }) => operation),
    ["begin", "append", "append", "abort"],
  );
});

test("Runtime.evaluate rejects protocol errors and non-ok values", () => {
  assert.throws(
    () => checkedEvaluationValue({
      error: { message: "protocol failed" },
    }, "operation"),
    (error) => (
      error.code === "cdp-protocol-error"
      && /protocol failed/.test(error.message)
    ),
  );
  assert.throws(
    () => checkedEvaluationValue(
      evaluation({ ok: false, error: "renderer refused" }),
      "operation",
    ),
    /renderer refused/,
  );
  assert.deepEqual(
    checkedEvaluationValue(evaluation({ ok: true, value: 1 }), "operation"),
    { ok: true, value: 1 },
  );
});

test("broadcastTheme closes and prunes failed sessions", async () => {
  const live = transactionSession();
  const closed = transactionSession();
  closed.closed = true;
  const failed = transactionSession({
    exceptionOnAppend: { index: 0, message: "failed" },
  });
  const sessions = new Map([
    ["live", live],
    ["closed", closed],
    ["failed", failed],
  ]);
  const logs = [];
  const payload = theme({ assets: [asset("asset", "AAAA")] });

  const successful = await broadcastTheme(
    sessions,
    payload,
    (message) => logs.push(message),
  );

  assert.equal(successful, 1);
  assert.deepEqual([...sessions.keys()], ["live"]);
  assert.equal(failed.closeCalls, 1);
  assert.match(logs[0], /apply target failed failed/);
});

test("clearRenderers closes and prunes failed sessions", async () => {
  const live = transactionSession({ digest: "old", stylePresent: true });
  const failed = transactionSession({ digest: "old", stylePresent: true });
  failed.send = async function send(method, params) {
    this.messages.push({ method, params });
    return {
      exceptionDetails: {
        text: "clear failed",
      },
    };
  };
  const sessions = new Map([
    ["live", live],
    ["failed", failed],
  ]);
  const logs = [];

  const successful = await clearRenderers(
    sessions,
    (message) => logs.push(message),
  );

  assert.equal(successful, 1);
  assert.deepEqual([...sessions.keys()], ["live"]);
  assert.equal(failed.closeCalls, 1);
  assert.match(logs[0], /clear target failed failed/);
});

async function isolatedInjection(t, targetPages) {
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
  cdp.listTargets = async () => targetPages();
  cdp.CdpSession = {
    async connect(url, id) {
      const session = transactionSession();
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
  return { created, isolated };
}

function page(id) {
  return {
    id,
    type: "page",
    url: "app://-/index.html",
    webSocketDebuggerUrl: `ws://${id}`,
  };
}

test("poll status skips resending a matching digest and style", async (t) => {
  let targets = [page("main")];
  const { created, isolated } = await isolatedInjection(t, () => targets);
  const payload = theme();

  const sessions = await isolated.injectRenderers(57340, payload);
  const operationsAfterFirstPass = created[0].calls.map(
    ({ operation }) => operation,
  );
  await isolated.injectRenderers(57340, payload, sessions);

  assert.equal(created.length, 1);
  assert.deepEqual(operationsAfterFirstPass, ["begin", "commit"]);
  assert.deepEqual(
    created[0].calls.map(({ operation }) => operation),
    ["begin", "commit", "status"],
  );
  assert.equal(
    created[0].messages.filter(
      ({ method }) => method === "Page.addScriptToEvaluateOnNewDocument",
    ).length,
    1,
  );
  assert.equal(targets.length, 1);
});

test("poll applies to a new target while retaining a matching target", async (t) => {
  let targets = [page("main")];
  const { created, isolated } = await isolatedInjection(t, () => targets);
  const payload = theme();
  const sessions = await isolated.injectRenderers(57340, payload);

  targets = [page("main"), page("secondary")];
  await isolated.injectRenderers(57340, payload, sessions);

  assert.equal(created.length, 2);
  assert.deepEqual(
    created[0].calls.map(({ operation }) => operation),
    ["begin", "commit", "status"],
  );
  assert.deepEqual(
    created[1].calls.map(({ operation }) => operation),
    ["begin", "commit"],
  );
  assert.deepEqual([...sessions.keys()], ["main", "secondary"]);
  assert.equal(created[1].url, "ws://secondary");
  assert.equal(
    created[1].messages[2].params.source,
    rendererInjectionSource(),
  );
});

test("poll reapplies when the renderer digest does not match", async (t) => {
  const targets = [page("main")];
  const { created, isolated } = await isolatedInjection(t, () => targets);
  const sessions = await isolated.injectRenderers(57340, theme());

  await isolated.injectRenderers(
    57340,
    theme({ digest: "digest-two", css: ":root{color:red}" }),
    sessions,
  );

  assert.deepEqual(
    created[0].calls.map(({ operation }) => operation),
    ["begin", "commit", "status", "begin", "commit"],
  );
  assert.equal(created[0].state.digest, "digest-two");
});

test("null theme clears current renderer once and later polls stay idle", async (t) => {
  const targets = [page("main")];
  const { created, isolated } = await isolatedInjection(t, () => targets);
  const sessions = await isolated.injectRenderers(57340, theme());

  await isolated.injectRenderers(57340, null, sessions);
  await isolated.injectRenderers(57340, null, sessions);

  assert.deepEqual(
    created[0].calls.map(({ operation }) => operation),
    ["begin", "commit", "status", "clear", "status"],
  );
  assert.equal(created[0].state.stylePresent, false);
  assert.equal(created[0].state.digest, null);
});

test("poll closes and prunes a session whose Status evaluation fails", async (t) => {
  const targets = [page("main")];
  const { created, isolated } = await isolatedInjection(t, () => targets);
  const sessions = await isolated.injectRenderers(57340, theme());
  const session = created[0];
  const originalSend = session.send;
  session.send = async function send(method, params) {
    if (
      method === "Runtime.evaluate"
      && params.expression.includes("__codexThemeSwitcherStatus")
    ) {
      this.messages.push({ method, params });
      return { exceptionDetails: { text: "status exploded" } };
    }
    return originalSend.call(this, method, params);
  };

  await assert.rejects(
    isolated.injectRenderers(57340, theme(), sessions),
    (error) => error.code === "missing-cdp-target",
  );

  assert.equal(session.closeCalls, 1);
  assert.equal(sessions.size, 0);
});
