"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const source = fs.readFileSync(
  path.resolve(
    __dirname,
    "../Sources/CodexThemeRuntime/Resources/runtime/theme-inject.js",
  ),
  "utf8",
);

function fakeDOM() {
  const children = [];
  const attributes = new Map();
  const blobs = [];
  const createdURLs = [];
  const revokedURLs = [];

  const host = {
    appendChild(element) {
      if (!children.includes(element)) children.push(element);
      element.parentNode = host;
      return element;
    },
  };
  const documentElement = {
    setAttribute(name, value) {
      attributes.set(name, String(value));
    },
    removeAttribute(name) {
      attributes.delete(name);
    },
    getAttribute(name) {
      return attributes.get(name) ?? null;
    },
  };
  const document = {
    head: host,
    documentElement,
    body: null,
    createElement(tagName) {
      const element = {
        tagName: String(tagName).toUpperCase(),
        id: "",
        type: "",
        dataset: {},
        textContent: "",
        disabled: false,
        parentNode: null,
        remove() {
          const index = children.indexOf(element);
          if (index >= 0) children.splice(index, 1);
          element.parentNode = null;
        },
      };
      return element;
    },
    getElementById(id) {
      return children.find((element) => element.id === id) || null;
    },
  };
  class FakeBlob {
    constructor(parts, options = {}) {
      this.parts = parts;
      this.type = options.type || "";
      this.size = parts.reduce((sum, part) => sum + part.byteLength, 0);
      blobs.push(this);
    }

    bytes() {
      const result = new Uint8Array(this.size);
      let offset = 0;
      for (const part of this.parts) {
        result.set(part, offset);
        offset += part.byteLength;
      }
      return result;
    }
  }
  const FakeURL = {
    createObjectURL(blob) {
      const url = `blob:codex-theme/${createdURLs.length + 1}`;
      createdURLs.push({ url, blob });
      return url;
    },
    revokeObjectURL(url) {
      revokedURLs.push(url);
    },
  };
  const window = {};
  const sandbox = {
    atob(value) {
      return Buffer.from(value, "base64").toString("latin1");
    },
    Blob: FakeBlob,
    document,
    Uint8Array,
    URL: FakeURL,
    window,
  };
  return {
    attributes,
    blobs,
    children,
    createdURLs,
    document,
    host,
    revokedURLs,
    sandbox,
    window,
  };
}

function descriptor(id, bytes, fingerprint = `${id}-fingerprint`) {
  return {
    id,
    mediaType: "image/png",
    fingerprint,
    base64Characters: bytes.toString("base64").length,
    byteLength: bytes.length,
  };
}

function beginPayload({
  transactionID = "transaction-1",
  themeID = "theme-1",
  themeName = "Theme One",
  digest = "digest-1",
  css = ":root { color: red; }",
  assets = [],
} = {}) {
  return {
    transactionID,
    themeID,
    themeName,
    digest,
    css,
    assets,
  };
}

function appendBase64(window, transactionID, assetID, bytes, chunkSize = 8) {
  const encoded = bytes.toString("base64");
  let index = 0;
  for (let offset = 0; offset < encoded.length; offset += chunkSize) {
    window.__codexThemeSwitcherAppendAsset({
      transactionID,
      assetID,
      index,
      chunk: encoded.slice(offset, offset + chunkSize),
    });
    index += 1;
  }
}

function install(dom = fakeDOM()) {
  vm.runInNewContext(source, dom.sandbox);
  return dom;
}

test("VERSION=2 exposes transaction APIs and source evaluation is idempotent", () => {
  const dom = install();
  const runtime = dom.window.__codexThemeSwitcherRuntime;
  const functions = [
    "__codexThemeSwitcherBegin",
    "__codexThemeSwitcherAppendAsset",
    "__codexThemeSwitcherCommit",
    "__codexThemeSwitcherAbort",
    "__codexThemeSwitcherStatus",
    "__codexThemeSwitcherClear",
  ];

  assert.equal(runtime.version, 2);
  for (const name of functions) {
    assert.equal(typeof dom.window[name], "function", name);
  }
  assert.equal(dom.window.__codexThemeSwitcherApply, undefined);

  const begin = dom.window.__codexThemeSwitcherBegin;
  vm.runInNewContext(source, dom.sandbox);

  assert.equal(dom.window.__codexThemeSwitcherRuntime, runtime);
  assert.equal(dom.window.__codexThemeSwitcherBegin, begin);
  assert.equal(dom.window.__codexThemeSwitcherStatus().digest, null);
  assert.equal(dom.window.__codexThemeSwitcherStatus().stylePresent, false);
});

test("begin and commit atomically install CSS without assets", () => {
  const dom = install();
  assert.deepEqual(
    JSON.parse(JSON.stringify(
      dom.window.__codexThemeSwitcherBegin(beginPayload()),
    )),
    {
      ok: true,
      unchanged: false,
      transactionID: "transaction-1",
      requiredAssetIDs: [],
    },
  );
  assert.deepEqual(
    { ...dom.window.__codexThemeSwitcherCommit({
      transactionID: "transaction-1",
    }) },
    { ok: true, digest: "digest-1" },
  );

  assert.equal(dom.children.length, 1);
  assert.equal(dom.children[0].id, "codex-theme-switcher-style");
  assert.equal(dom.children[0].disabled, false);
  assert.equal(dom.children[0].textContent, ":root { color: red; }");
  assert.equal(
    dom.document.documentElement.getAttribute(
      "data-codex-theme-switcher-theme",
    ),
    "theme-1",
  );
  const status = dom.window.__codexThemeSwitcherStatus();
  assert.equal(status.digest, "digest-1");
  assert.equal(status.stylePresent, true);
  assert.deepEqual(
    { ...status.current },
    {
      themeID: "theme-1",
      themeName: "Theme One",
      digest: "digest-1",
    },
  );
});

test("begin reports an unchanged active digest and does not open a transaction", () => {
  const dom = install();
  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });

  const result = dom.window.__codexThemeSwitcherBegin(beginPayload({
    transactionID: "transaction-2",
    themeName: "Ignored because digest is unchanged",
  }));
  assert.deepEqual(
    JSON.parse(JSON.stringify(result)),
    { ok: true, unchanged: true, requiredAssetIDs: [] },
  );
  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: "transaction-2",
    }),
    /No active transaction/,
  );
  assert.equal(dom.children[0].textContent, ":root { color: red; }");
});

test("large base64 chunks become Uint8Array Blob parts and replace asset URLs", () => {
  const dom = install();
  const bytes = Buffer.alloc(2 * 1024 * 1024 + 3);
  for (let index = 0; index < bytes.length; index += 1) {
    bytes[index] = index % 251;
  }
  const asset = descriptor("wallpaper", bytes);
  const payload = beginPayload({
    css: [
      ".hero {",
      "  background-image: url('codex-theme-asset://wallpaper');",
      "}",
    ].join("\n"),
    assets: [asset],
  });

  const begin = dom.window.__codexThemeSwitcherBegin(payload);
  assert.equal(begin.transactionID, payload.transactionID);
  assert.deepEqual([...begin.requiredAssetIDs], ["wallpaper"]);
  appendBase64(
    dom.window,
    payload.transactionID,
    asset.id,
    bytes,
    256 * 1024,
  );
  dom.window.__codexThemeSwitcherCommit({
    transactionID: payload.transactionID,
  });

  assert.equal(dom.blobs.length, 1);
  assert.equal(dom.blobs[0].type, "image/png");
  assert.equal(dom.blobs[0].parts.length > 1, true);
  assert.deepEqual(Buffer.from(dom.blobs[0].bytes()), bytes);
  assert.match(dom.children[0].textContent, /blob:codex-theme\/1/);
  assert.doesNotMatch(
    dom.children[0].textContent,
    /codex-theme-asset:\/\//,
  );
});

test("duplicate fingerprints share and reuse one URL across commits", () => {
  const dom = install();
  const bytes = Buffer.from("shared image bytes");
  const first = descriptor("first", bytes, "shared-fingerprint");
  const alias = descriptor("alias", bytes, "shared-fingerprint");
  const initial = beginPayload({
    css: [
      "a{background:url(codex-theme-asset://first)}",
      "b{background:url(codex-theme-asset://alias)}",
    ].join(""),
    assets: [first, alias],
  });

  const firstBegin = dom.window.__codexThemeSwitcherBegin(initial);
  assert.deepEqual([...firstBegin.requiredAssetIDs], ["first"]);
  appendBase64(dom.window, initial.transactionID, "first", bytes);
  dom.window.__codexThemeSwitcherCommit({
    transactionID: initial.transactionID,
  });
  assert.equal(dom.createdURLs.length, 1);
  assert.equal(
    dom.children[0].textContent.match(/blob:codex-theme\/1/g).length,
    2,
  );

  const second = beginPayload({
    transactionID: "transaction-2",
    digest: "digest-2",
    css: "main{background:url(codex-theme-asset://new-id)}",
    assets: [descriptor("new-id", bytes, "shared-fingerprint")],
  });
  const secondBegin = dom.window.__codexThemeSwitcherBegin(second);
  assert.deepEqual([...secondBegin.requiredAssetIDs], []);
  dom.window.__codexThemeSwitcherCommit({
    transactionID: second.transactionID,
  });

  assert.equal(dom.createdURLs.length, 1);
  assert.equal(dom.revokedURLs.length, 0);
  assert.match(dom.children[0].textContent, /blob:codex-theme\/1/);
});

test("replaced and orphaned assets are revoked only after successful commit", () => {
  const dom = install();
  const firstBytes = Buffer.from("first");
  const firstAsset = descriptor("image", firstBytes, "fingerprint-1");
  const first = beginPayload({
    css: "a{background:url(codex-theme-asset://image)}",
    assets: [firstAsset],
  });
  dom.window.__codexThemeSwitcherBegin(first);
  appendBase64(dom.window, first.transactionID, "image", firstBytes);
  dom.window.__codexThemeSwitcherCommit({
    transactionID: first.transactionID,
  });

  const secondBytes = Buffer.from("second");
  const secondAsset = descriptor("image", secondBytes, "fingerprint-2");
  const second = beginPayload({
    transactionID: "transaction-2",
    digest: "digest-2",
    css: "a{background:url(codex-theme-asset://image)}",
    assets: [secondAsset],
  });
  dom.window.__codexThemeSwitcherBegin(second);
  appendBase64(dom.window, second.transactionID, "image", secondBytes);
  dom.window.__codexThemeSwitcherCommit({
    transactionID: second.transactionID,
  });

  assert.deepEqual(
    dom.createdURLs.map(({ url }) => url),
    ["blob:codex-theme/1", "blob:codex-theme/2"],
  );
  assert.deepEqual(dom.revokedURLs, ["blob:codex-theme/1"]);
  assert.match(dom.children[0].textContent, /blob:codex-theme\/2/);
});

test("commit failure rolls back style and revokes only newly created URLs", () => {
  const dom = install();
  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  const activeStyle = dom.children[0];

  const bytes = Buffer.from("new bytes");
  const asset = descriptor("known", bytes);
  const broken = beginPayload({
    transactionID: "transaction-broken",
    digest: "digest-broken",
    css: [
      "a{background:url(codex-theme-asset://known)}",
      "b{background:url(codex-theme-asset://missing)}",
    ].join(""),
    assets: [asset],
  });
  dom.window.__codexThemeSwitcherBegin(broken);
  appendBase64(dom.window, broken.transactionID, "known", bytes);

  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: broken.transactionID,
    }),
    /without a descriptor/,
  );
  assert.equal(dom.children.length, 1);
  assert.equal(dom.children[0], activeStyle);
  assert.equal(activeStyle.disabled, false);
  assert.equal(activeStyle.textContent, ":root { color: red; }");
  assert.deepEqual(dom.revokedURLs, ["blob:codex-theme/1"]);
  assert.equal(dom.window.__codexThemeSwitcherStatus().digest, "digest-1");
  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: broken.transactionID,
    }),
    /No active transaction/,
  );
});

test("invalid or incomplete chunks fail without mutating the active theme", () => {
  const dom = install();
  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  const bytes = Buffer.from("asset bytes");
  const asset = descriptor("asset", bytes);
  const next = beginPayload({
    transactionID: "transaction-2",
    digest: "digest-2",
    css: "a{background:url(codex-theme-asset://asset)}",
    assets: [asset],
  });
  dom.window.__codexThemeSwitcherBegin(next);

  assert.throws(
    () => dom.window.__codexThemeSwitcherAppendAsset({
      transactionID: next.transactionID,
      assetID: "asset",
      index: 1,
      chunk: "AAAA",
    }),
    /expected chunk 0/,
  );
  dom.window.__codexThemeSwitcherAppendAsset({
    transactionID: next.transactionID,
    assetID: "asset",
    index: 0,
    chunk: bytes.toString("base64").slice(0, 4),
  });
  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: next.transactionID,
    }),
    /incomplete base64 data/,
  );
  assert.equal(dom.window.__codexThemeSwitcherStatus().digest, "digest-1");
  assert.equal(dom.children[0].textContent, ":root { color: red; }");
});

test("abort discards chunks while preserving the active theme", () => {
  const dom = install();
  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  const bytes = Buffer.from("asset");
  const next = beginPayload({
    transactionID: "transaction-2",
    digest: "digest-2",
    assets: [descriptor("asset", bytes)],
  });
  dom.window.__codexThemeSwitcherBegin(next);
  appendBase64(dom.window, next.transactionID, "asset", bytes);

  assert.deepEqual(
    { ...dom.window.__codexThemeSwitcherAbort({
      transactionID: next.transactionID,
    }) },
    { ok: true, transactionID: next.transactionID },
  );
  assert.equal(dom.window.__codexThemeSwitcherStatus().digest, "digest-1");
  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: next.transactionID,
    }),
    /No active transaction/,
  );
});

test("clear removes styles, aborts staging, and revokes each URL once", () => {
  const dom = install();
  const bytes = Buffer.from("shared image bytes");
  const first = descriptor("first", bytes, "shared-fingerprint");
  const second = descriptor("second", bytes, "shared-fingerprint");
  const payload = beginPayload({
    css: [
      "a{background:url(codex-theme-asset://first)}",
      "b{background:url(codex-theme-asset://second)}",
    ].join(""),
    assets: [first, second],
  });
  dom.window.__codexThemeSwitcherBegin(payload);
  appendBase64(dom.window, payload.transactionID, "first", bytes);
  dom.window.__codexThemeSwitcherCommit({
    transactionID: payload.transactionID,
  });

  assert.deepEqual(
    { ...dom.window.__codexThemeSwitcherClear() },
    { ok: true },
  );
  assert.equal(dom.children.length, 0);
  assert.deepEqual(dom.revokedURLs, ["blob:codex-theme/1"]);
  assert.equal(
    dom.document.documentElement.getAttribute(
      "data-codex-theme-switcher-theme",
    ),
    null,
  );
  assert.equal(dom.window.__codexThemeSwitcherStatus().digest, null);
  assert.equal(dom.window.__codexThemeSwitcherStatus().stylePresent, false);

  dom.window.__codexThemeSwitcherClear();
  assert.deepEqual(dom.revokedURLs, ["blob:codex-theme/1"]);
});

test("commit rejects decoded byte-length mismatch without leaking a Blob URL", () => {
  const dom = install();
  const bytes = Buffer.from("actual");
  const asset = {
    ...descriptor("asset", bytes),
    byteLength: bytes.length + 1,
  };
  const payload = beginPayload({
    css: "a{background:url(codex-theme-asset://asset)}",
    assets: [asset],
  });
  dom.window.__codexThemeSwitcherBegin(payload);
  appendBase64(dom.window, payload.transactionID, "asset", bytes);

  assert.throws(
    () => dom.window.__codexThemeSwitcherCommit({
      transactionID: payload.transactionID,
    }),
    /decoded to 6 bytes, expected 7/,
  );
  assert.equal(dom.createdURLs.length, 0);
  assert.equal(dom.revokedURLs.length, 0);
  assert.equal(dom.children.length, 0);
});

test("runtime uses documentElement as style host and never schedules revival", () => {
  const dom = fakeDOM();
  dom.document.head = null;
  dom.document.documentElement.appendChild = dom.host.appendChild;
  let timeoutCalls = 0;
  dom.sandbox.setTimeout = () => {
    timeoutCalls += 1;
  };
  install(dom);

  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  assert.equal(dom.children.length, 1);
  assert.equal(timeoutCalls, 0);
});
