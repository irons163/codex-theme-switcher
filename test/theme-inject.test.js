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
    appendChild: host.appendChild,
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
      const elementChildren = [];
      const element = {
        tagName: String(tagName).toUpperCase(),
        id: "",
        type: "",
        dataset: {},
        style: {},
        textContent: "",
        disabled: false,
        parentNode: null,
        children: elementChildren,
        appendChild(child) {
          if (!elementChildren.includes(child)) elementChildren.push(child);
          child.parentNode = element;
          return child;
        },
        getBoundingClientRect() {
          return { left: 0, top: 0, width: 1, height: 1 };
        },
        remove() {
          const siblings = element.parentNode === host
            ? children
            : element.parentNode?.children;
          const index = siblings?.indexOf?.(element) ?? -1;
          if (index >= 0) siblings.splice(index, 1);
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

function activeThemeStyle(dom) {
  return dom.document.getElementById("codex-theme-switcher-style");
}

function isVoiceOrbSelector(selector) {
  return String(selector).includes(
    ".codex-avatar-root[data-realtime-voice-orb]",
  );
}

test("VERSION=50 exposes transaction APIs and source evaluation is idempotent", () => {
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

  assert.equal(runtime.version, 50);
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

  assert.equal(dom.children.length, 2);
  assert.equal(activeThemeStyle(dom).disabled, false);
  assert.equal(activeThemeStyle(dom).textContent, ":root { color: red; }");
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
  assert.equal(activeThemeStyle(dom).textContent, ":root { color: red; }");
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
  assert.match(activeThemeStyle(dom).textContent, /blob:codex-theme\/1/);
  assert.doesNotMatch(
    activeThemeStyle(dom).textContent,
    /codex-theme-asset:\/\//,
  );
});

test("committed assets retain their Blob for Live2D file loading", () => {
  const dom = install();
  const bytes = Buffer.from("MOC3 live2d model bytes");
  const asset = {
    ...descriptor("live2d-model", bytes),
    mediaType: "application/octet-stream",
  };
  const payload = beginPayload({ assets: [asset] });

  dom.window.__codexThemeSwitcherBegin(payload);
  appendBase64(
    dom.window,
    payload.transactionID,
    asset.id,
    bytes,
  );
  dom.window.__codexThemeSwitcherCommit({
    transactionID: payload.transactionID,
  });

  const committed = dom.window.__codexThemeSwitcherRuntime.assets.get(
    asset.id,
  );
  assert.equal(committed.mediaType, "application/octet-stream");
  assert.equal(committed.blob, dom.blobs[0]);
  assert.deepEqual(Buffer.from(committed.blob.bytes()), bytes);
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
    activeThemeStyle(dom).textContent.match(/blob:codex-theme\/1/g).length,
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
  assert.match(activeThemeStyle(dom).textContent, /blob:codex-theme\/1/);
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
  assert.match(activeThemeStyle(dom).textContent, /blob:codex-theme\/2/);
});

test("commit failure rolls back style and revokes only newly created URLs", () => {
  const dom = install();
  dom.window.__codexThemeSwitcherBegin(beginPayload());
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  const activeStyle = activeThemeStyle(dom);

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
  assert.equal(dom.children.length, 2);
  assert.equal(activeThemeStyle(dom), activeStyle);
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
  assert.equal(activeThemeStyle(dom).textContent, ":root { color: red; }");
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
  assert.equal(dom.children.length, 2);
  assert.equal(timeoutCalls, 0);
});

function voiceImagePreloadDOM({ paintFrames = false } = {}) {
  const dom = fakeDOM();
  const liveProperties = new Map();
  const observers = [];
  const images = [];
  const pendingDecodes = new Map();
  const paintCallbacks = [];
  const orb = {
    style: {
      getPropertyValue(name) {
        return liveProperties.get(name) || "";
      },
      setProperty(name, value) {
        liveProperties.set(name, value);
      },
      removeProperty(name) {
        liveProperties.delete(name);
      },
    },
    getBoundingClientRect() {
      return { left: 0, top: 0, width: 112, height: 112 };
    },
    querySelector() {
      return null;
    },
  };
  dom.document.querySelector = (selector) => (
    isVoiceOrbSelector(selector) ? orb : null
  );
  dom.sandbox.getComputedStyle = (element) => ({
    backgroundImage: "",
    backgroundPosition: "",
    backgroundSize: "",
    getPropertyValue(name) {
      if (element !== dom.document.documentElement) return "";
      if (name === "--cts-voice-orb-image-enabled") return "1";
      if (name === "--cts-voice-orb-mouth-frame-count") return "3";
      if (name === "--cts-voice-orb-mouth-frame-0") {
        return 'url("frame-0")';
      }
      if (name === "--cts-voice-orb-mouth-frame-1") {
        return 'url("frame-1")';
      }
      if (name === "--cts-voice-orb-mouth-frame-2") {
        return 'url("frame-2")';
      }
      if (name === "--cts-voice-orb-background-opacity") return "1";
      if (name === "--cts-voice-orb-blink-enabled") return "1";
      if (name === "--cts-voice-orb-blink-image") {
        return 'url("blink")';
      }
      return "";
    },
  });
  dom.sandbox.MutationObserver = class FakeMutationObserver {
    constructor(callback) {
      this.callback = callback;
      this.disconnected = false;
      observers.push(this);
    }

    observe(target, options) {
      this.target = target;
      this.options = options;
    }

    disconnect() {
      this.disconnected = true;
    }
  };
  dom.sandbox.Image = class FakeImage {
    constructor() {
      this.complete = false;
      this.naturalWidth = 627;
      this.naturalHeight = 627;
    }

    decode() {
      return new Promise((resolve, reject) => {
        pendingDecodes.set(this.source, { reject, resolve });
      });
    }

    set src(value) {
      this.source = value;
      this.complete = true;
      images.push(this);
    }
  };
  if (paintFrames) {
    dom.sandbox.requestAnimationFrame = (callback) => {
      paintCallbacks.push(callback);
      return paintCallbacks.length;
    };
  }

  install(dom);
  dom.window.__codexThemeSwitcherBegin(beginPayload({
    css: ":root { --cts-voice-orb-image-enabled: 1; }",
  }));
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  return {
    dom,
    images,
    liveProperties,
    observers,
    paintCallbacks,
    pendingDecodes,
  };
}

test("Voice images decode before mouth animation is unlocked", async () => {
  const fixture = voiceImagePreloadDOM();
  const pulse = fixture.dom.window
    .__codexThemeSwitcherRuntime.voicePulse;

  assert.deepEqual(
    fixture.images.map((image) => image.source),
    ["frame-0", "frame-1", "frame-2", "blink"],
  );
  assert.equal(pulse.mouthImagesPreparing, true);
  assert.equal(pulse.mouthSourcesReady, false);
  assert.equal(pulse.mouthImagesFailed, false);
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-active-image"),
    'url("frame-0")',
  );
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-mouth-image-b"),
    'url("frame-0")',
  );
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-mouth-opacity-b"),
    "1.0000",
  );
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-blink-opacity"),
    "0.0000",
  );

  for (const source of ["frame-0", "frame-1", "frame-2"]) {
    fixture.pendingDecodes.get(source).resolve();
  }
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(pulse.mouthSourcesReady, false);
  assert.equal(pulse.mouthImagesPreparing, true);

  fixture.pendingDecodes.get("blink").resolve();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(pulse.mouthSourcesReady, true);
  assert.equal(pulse.mouthImagesPreparing, false);
  assert.equal(pulse.mouthImagesFailed, false);
  assert.equal(pulse.preloadedVoiceImages.length, 4);
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-active-image"),
    'url("frame-0")',
  );
});

test("failed Voice image decode keeps the closed mouth pinned", async () => {
  const fixture = voiceImagePreloadDOM();
  const pulse = fixture.dom.window
    .__codexThemeSwitcherRuntime.voicePulse;

  for (const source of ["frame-0", "frame-1", "blink"]) {
    fixture.pendingDecodes.get(source).resolve();
  }
  fixture.pendingDecodes.get("frame-2").reject(
    new Error("decode failed"),
  );
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(pulse.mouthSourcesReady, false);
  assert.equal(pulse.mouthImagesPreparing, false);
  assert.equal(pulse.mouthImagesFailed, true);
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-active-image"),
    'url("frame-0")',
  );
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-mouth-image-b"),
    'url("frame-0")',
  );
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-blink-opacity"),
    "0.0000",
  );
});

test("Voice images paint for two frames before mouth animation unlocks", async () => {
  const fixture = voiceImagePreloadDOM({ paintFrames: true });
  const pulse = fixture.dom.window
    .__codexThemeSwitcherRuntime.voicePulse;

  for (const source of ["frame-0", "frame-1", "frame-2", "blink"]) {
    fixture.pendingDecodes.get(source).resolve();
  }
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(pulse.mouthSourcesReady, false);
  assert.equal(pulse.mouthImagesPreparing, true);
  assert.ok(pulse.voiceImageWarmup);
  assert.equal(pulse.voiceImageWarmup.children.length, 4);
  assert.equal(fixture.paintCallbacks.length, 1);

  fixture.paintCallbacks.shift()();
  assert.equal(pulse.mouthSourcesReady, false);
  assert.equal(pulse.mouthImagesPreparing, true);
  assert.equal(fixture.paintCallbacks.length, 1);

  fixture.paintCallbacks.shift()();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(pulse.mouthSourcesReady, true);
  assert.equal(pulse.mouthImagesPreparing, false);
  assert.ok(pulse.voiceImageWarmup);
  assert.equal(
    fixture.liveProperties.get("--cts-voice-orb-active-image"),
    'url("frame-0")',
  );

  fixture.dom.window.__codexThemeSwitcherClear();
  assert.equal(pulse.voiceImageWarmup, null);
});

test("custom Voice orb image follows native sprite frame size", async () => {
  const dom = fakeDOM();
  const liveProperties = new Map();
  const observers = [];
  let pulseEnabled = "1";
  const orb = {
    style: {
      backgroundImage: 'url("sprite:test")',
      backgroundPosition: "0% 0%",
      getPropertyValue(name) {
        return liveProperties.get(name) || "";
      },
      setProperty(name, value) {
        liveProperties.set(name, value);
      },
      removeProperty(name) {
        liveProperties.delete(name);
      },
    },
    getBoundingClientRect() {
      return {
        left: 178 + (
          Number.parseFloat(
            liveProperties.get("--cts-voice-orb-layout-shift-x"),
          ) || 0
        ),
        top: 160 + (
          Number.parseFloat(
            liveProperties.get("--cts-voice-orb-layout-shift-y"),
          ) || 0
        ),
        width: 112,
        height: 121,
      };
    },
  };
  dom.window.innerWidth = 356;
  dom.window.innerHeight = 320;
  dom.document.querySelector = (selector) => (
    isVoiceOrbSelector(selector) ? orb : null
  );
  dom.sandbox.getComputedStyle = (element) => {
    if (element === dom.document.documentElement) {
      return {
        getPropertyValue(name) {
          if (name === "--cts-voice-orb-pulse-enabled") {
            return pulseEnabled;
          }
          if (name === "--cts-voice-orb-image-enabled") return "1";
          if (name === "--cts-voice-orb-pulse-strength") return "1";
          return "";
        },
      };
    }
    return {
      backgroundImage: orb.style.backgroundImage,
      backgroundPosition: orb.style.backgroundPosition,
      backgroundSize: "200% 100%",
      getPropertyValue() {
        return "";
      },
    };
  };
  dom.sandbox.MutationObserver = class FakeMutationObserver {
    constructor(callback) {
      this.callback = callback;
      this.disconnected = false;
      observers.push(this);
    }

    observe(target, options) {
      this.target = target;
      this.options = options;
    }

    disconnect() {
      this.disconnected = true;
    }
  };
  dom.sandbox.Image = class FakeImage {
    constructor() {
      this.naturalWidth = 6;
      this.naturalHeight = 3;
    }

    set src(value) {
      this.source = value;
      this.onload();
    }
  };
  const createElement = dom.document.createElement;
  dom.document.createElement = (tagName) => {
    if (tagName !== "canvas") return createElement(tagName);
    return {
      getContext() {
        return {
          drawImage() {},
          getImageData(x, _y, width, height) {
            const pixels = new Uint8ClampedArray(width * height * 4);
            if (x === 0) {
              pixels[3] = 255;
            } else {
              for (let index = 3; index < pixels.length; index += 4) {
                pixels[index] = 255;
              }
            }
            return { data: pixels };
          },
        };
      },
    };
  };

  install(dom);
  dom.window.__codexThemeSwitcherBegin(beginPayload({
    css: [
      ":root {",
      "  --cts-voice-orb-image-enabled: 1;",
      "  --cts-voice-orb-pulse-enabled: 1;",
      "}",
    ].join("\n"),
  }));
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(
    liveProperties.get("--cts-voice-orb-live-width"),
    "33.3333%",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-left"),
    "0.0000%",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-height"),
    "33.3333%",
  );
  assert.ok(
    Math.abs(
      178
        + Number.parseFloat(
          liveProperties.get("--cts-voice-orb-layout-shift-x"),
        )
        + 112 / 6
        - 178
    ) < 0.14,
  );
  assert.ok(
    Math.abs(
      160
        + Number.parseFloat(
          liveProperties.get("--cts-voice-orb-layout-shift-y"),
        )
        + 121 / 6
        - 160
    ) < 0.14,
  );
  assert.equal(
    dom.window.__codexThemeSwitcherStatus().voicePulseActive,
    true,
  );
  const rootObserver = observers.find((observer) => observer.target === orb);
  assert.ok(rootObserver);
  assert.equal(rootObserver.options.attributes, true);
  assert.deepEqual(
    [...rootObserver.options.attributeFilter],
    ["style"],
  );
  assert.equal(rootObserver.options.childList, true);
  assert.equal(rootObserver.options.subtree, true);

  orb.style.backgroundPosition = "100% 0%";
  rootObserver.callback();
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-width"),
    "100.0000%",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-height"),
    "100.0000%",
  );
  assert.ok(
    Math.abs(
      178
        + Number.parseFloat(
          liveProperties.get("--cts-voice-orb-layout-shift-x"),
        )
        + 112 / 2
        - 178
    ) < 0.14,
  );
  assert.ok(
    Math.abs(
      160
        + Number.parseFloat(
          liveProperties.get("--cts-voice-orb-layout-shift-y"),
        )
        + 121 / 2
        - 160
    ) < 0.14,
  );

  pulseEnabled = "0";
  observers.find((observer) => (
    observer.target === dom.document.documentElement
    && !observer.disconnected
  )).callback();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(
    dom.window.__codexThemeSwitcherStatus().voicePulseActive,
    true,
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-width"),
    "33.3333%",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-live-left"),
    "33.3333%",
  );

  pulseEnabled = "1";
  observers.find((observer) => (
    observer.target === dom.document.documentElement
    && !observer.disconnected
  )).callback();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(
    dom.window.__codexThemeSwitcherStatus().voicePulseActive,
    true,
  );

  dom.window.__codexThemeSwitcherClear();
  assert.equal(
    liveProperties.has("--cts-voice-orb-live-width"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-layout-shift-x"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-layout-shift-y"),
    false,
  );
  assert.equal(observers.every((observer) => observer.disconnected), true);
  assert.equal(
    dom.window.__codexThemeSwitcherStatus().voicePulseActive,
    false,
  );
});

test("custom Voice orb image follows the realtime WebGL canvas", () => {
  const dom = fakeDOM();
  const liveProperties = new Map();
  const layoutProperties = new Map();
  const propertySetCounts = new Map();
  const computedPropertyReadCounts = new Map();
  const observers = [];
  const uniforms = new Map([
    ["u_resolution", new Float32Array([228, 242])],
    ["u_time", 0],
    ["u_outputLevel", 0],
    ["u_stateListen", 1],
    ["u_stateThink", 0],
    ["u_stateSpeak", 0],
  ]);
  let nextFrameID = 0;
  let frameCallback = null;
  let now = 0;
  const cancelledFrames = [];
  const program = {};
  const gl = {
    CURRENT_PROGRAM: 0x8b8d,
    getParameter(parameter) {
      return parameter === this.CURRENT_PROGRAM ? program : null;
    },
    getUniformLocation(_program, name) {
      return uniforms.has(name) ? name : null;
    },
    getUniform(_program, location) {
      return uniforms.get(location);
    },
  };
  const canvas = {
    offsetLeft: -40,
    offsetTop: 0,
    offsetWidth: 152,
    offsetHeight: 161,
    offsetParent: null,
    getAttribute(name) {
      return name === "data-avatar-overlay-placement"
        ? "bottom-end"
        : null;
    },
    getBoundingClientRect() {
      return {
        left: 163,
        top: 8,
        width: 152,
        height: 161,
      };
    },
    getContext(kind) {
      return kind === "webgl" ? gl : null;
    },
  };
  const voiceRenderer = {
    canvas,
    inputs: { voiceActivity: "listening" },
    outputLevel: 0,
    publishedAudioLevels: null,
    setPublishedAudioLevels(levels) {
      this.publishedAudioLevels = levels;
    },
  };
  canvas.__reactFiber$voiceTest = {
    memoizedState: {
      memoizedState: { current: voiceRenderer },
      next: null,
    },
    return: null,
  };
  const layoutTarget = {
    style: {
      getPropertyValue(name) {
        return layoutProperties.get(name) || "";
      },
      setProperty(name, value) {
        layoutProperties.set(name, value);
      },
      removeProperty(name) {
        layoutProperties.delete(name);
      },
    },
    getBoundingClientRect() {
      return {
        left: 178 + (
          Number.parseFloat(
            layoutProperties.get("--cts-voice-orb-layout-shift-x"),
          ) || 0
        ),
        top: 160 + (
          Number.parseFloat(
            layoutProperties.get("--cts-voice-orb-layout-shift-y"),
          ) || 0
        ),
        width: 112,
        height: 121,
      };
    },
  };
  const orb = {
    offsetWidth: 112,
    offsetHeight: 121,
    style: {
      getPropertyValue(name) {
        return liveProperties.get(name) || "";
      },
      setProperty(name, value) {
        liveProperties.set(name, value);
        propertySetCounts.set(name, (propertySetCounts.get(name) || 0) + 1);
      },
      removeProperty(name) {
        liveProperties.delete(name);
      },
    },
    getBoundingClientRect() {
      return layoutTarget.getBoundingClientRect();
    },
    closest(selector) {
      return selector === '[data-avatar-overlay-hit-region="mascot"]'
        ? layoutTarget
        : null;
    },
    querySelector(selector) {
      return selector === "canvas[data-avatar-overlay-placement]"
        ? canvas
        : null;
    },
  };
  canvas.offsetParent = orb;
  dom.window.innerWidth = 356;
  dom.window.innerHeight = 320;
  dom.document.querySelector = (selector) => (
    isVoiceOrbSelector(selector) ? orb : null
  );
  dom.sandbox.getComputedStyle = (element) => ({
    getPropertyValue(name) {
      if (element !== dom.document.documentElement) return "";
      computedPropertyReadCounts.set(
        name,
        (computedPropertyReadCounts.get(name) || 0) + 1,
      );
      if (name === "--cts-voice-orb-image-enabled") return "1";
      if (name === "--cts-voice-orb-pulse-enabled") return "1";
      if (name === "--cts-voice-orb-pulse-strength") return "1";
      if (name === "--cts-voice-scale") return "3";
      if (name === "--cts-voice-orb-mouth-frame-count") return "3";
      if (name === "--cts-voice-orb-mouth-frame-0") return "url(frame-0)";
      if (name === "--cts-voice-orb-mouth-frame-1") return "url(frame-1)";
      if (name === "--cts-voice-orb-mouth-frame-2") return "url(frame-2)";
      if (name === "--cts-voice-orb-mouth-sensitivity") return "1";
      if (name === "--cts-voice-orb-mouth-attack-ms") return "8";
      if (name === "--cts-voice-orb-mouth-release-ms") return "5";
      if (name === "--cts-voice-orb-mouth-noise-gate") return "0.05";
      if (name === "--cts-voice-orb-mouth-response-curve") return "0.72";
      if (name === "--cts-voice-orb-background-opacity") return "1";
      if (name === "--cts-voice-orb-idle-enabled") return "1";
      if (name === "--cts-voice-orb-idle-strength") return "1";
      if (name === "--cts-voice-orb-idle-period-ms") return "4000";
      if (name === "--cts-voice-orb-blink-enabled") return "1";
      if (name === "--cts-voice-orb-blink-interval-ms") return "1000";
      if (name === "--cts-voice-orb-blink-duration-ms") return "100";
      return "";
    },
  });
  dom.sandbox.MutationObserver = class FakeMutationObserver {
    constructor(callback) {
      this.callback = callback;
      this.disconnected = false;
      observers.push(this);
    }

    observe(target, options) {
      this.target = target;
      this.options = options;
    }

    disconnect() {
      this.disconnected = true;
    }
  };
  dom.sandbox.requestAnimationFrame = (callback) => {
    nextFrameID += 1;
    frameCallback = callback;
    return nextFrameID;
  };
  dom.sandbox.cancelAnimationFrame = (frameID) => {
    cancelledFrames.push(frameID);
  };
  dom.sandbox.performance = {
    now() {
      return now;
    },
  };
  dom.sandbox.Math = Object.create(Math);
  dom.sandbox.Math.random = () => 0.5;

  install(dom);
  dom.window.__codexThemeSwitcherBegin(beginPayload({
    css: [
      ":root {",
      "  --cts-voice-orb-image-enabled: 1;",
      "  --cts-voice-orb-pulse-enabled: 1;",
      "}",
    ].join("\n"),
  }));
  dom.window.__codexThemeSwitcherCommit({ transactionID: "transaction-1" });

  const number = (name) => Number.parseFloat(liveProperties.get(name));
  const layoutNumber = (name) => Number.parseFloat(
    layoutProperties.get(name),
  );
  assert.ok(number("--cts-voice-orb-live-left") > -9);
  assert.ok(number("--cts-voice-orb-live-left") < -6);
  assert.ok(number("--cts-voice-orb-live-top") > 28);
  assert.ok(number("--cts-voice-orb-live-top") < 32);
  assert.ok(number("--cts-voice-orb-live-width") > 77);
  assert.ok(number("--cts-voice-orb-live-width") < 81);
  assert.ok(number("--cts-voice-orb-live-height") > 71);
  assert.ok(number("--cts-voice-orb-live-height") < 75);
  assert.equal(liveProperties.get("--cts-voice-orb-live-pulse"), "1.0000");
  assert.ok(
    Math.abs(
      178
        + layoutNumber("--cts-voice-orb-layout-shift-x")
        + (
          number("--cts-voice-orb-live-left")
          + number("--cts-voice-orb-live-width") / 2
        ) * 1.12
        - 178
    ) < 0.14,
  );
  assert.ok(
    Math.abs(
      160
        + layoutNumber("--cts-voice-orb-layout-shift-y")
        + (
          number("--cts-voice-orb-live-top")
          + number("--cts-voice-orb-live-height") / 2
        ) * 1.21
        - 160
    ) < 0.14,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-scale-shift-x"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-scale-shift-y"),
    false,
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-active-image"),
    "url(frame-0)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-image-a"),
    "url(frame-0)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-image-b"),
    "url(frame-0)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-opacity-a"),
    "0.0000",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-opacity-b"),
    "1.0000",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-blink-opacity"),
    "0.0000",
  );
  assert.equal(typeof frameCallback, "function");
  const canvasRootObserver = observers.find(
    (observer) => observer.target === orb,
  );
  assert.ok(canvasRootObserver);
  const propertyWritesBeforeOwnStyleMutation = [
    ...propertySetCounts.values(),
  ].reduce((total, count) => total + count, 0);
  canvasRootObserver.callback([
    { type: "attributes", attributeName: "style" },
  ]);
  assert.equal(
    [...propertySetCounts.values()].reduce(
      (total, count) => total + count,
      0,
    ),
    propertyWritesBeforeOwnStyleMutation,
  );

  const unchangedImageCounts = new Map([
    [
      "--cts-voice-orb-active-image",
      propertySetCounts.get("--cts-voice-orb-active-image"),
    ],
    [
      "--cts-voice-orb-mouth-image-a",
      propertySetCounts.get("--cts-voice-orb-mouth-image-a"),
    ],
    [
      "--cts-voice-orb-mouth-image-b",
      propertySetCounts.get("--cts-voice-orb-mouth-image-b"),
    ],
  ]);
  const cachedFrameReadCounts = [0, 1, 2].map((index) => {
    const property = `--cts-voice-orb-mouth-frame-${index}`;
    return [property, computedPropertyReadCounts.get(property)];
  });
  now = 16;
  frameCallback();
  for (const [property, count] of unchangedImageCounts) {
    assert.equal(propertySetCounts.get(property), count);
  }
  for (const [property, count] of cachedFrameReadCounts) {
    assert.equal(computedPropertyReadCounts.get(property), count);
  }
  assert.equal(
    dom.window.__codexThemeSwitcherRuntime.voicePulse.mouthEnergySource,
    "webgl-output-level",
  );

  voiceRenderer.inputs.voiceActivity = "speaking";
  voiceRenderer.setPublishedAudioLevels({
    high: 0,
    low: 0,
    mid: 0,
    overall: 0,
  });
  uniforms.set("u_outputLevel", 0);
  uniforms.set("u_stateListen", 0);
  uniforms.set("u_stateSpeak", 1);
  now = 48;
  frameCallback();
  assert.ok(
    dom.window.__codexThemeSwitcherRuntime.voicePulse.mouthRawLevel > 0.1,
  );
  assert.equal(
    dom.window.__codexThemeSwitcherRuntime.voicePulse.mouthEnergySource,
    "speaking-state-fallback",
  );

  voiceRenderer.inputs.voiceActivity = "listening";
  uniforms.set("u_stateListen", 1);
  uniforms.set("u_stateSpeak", 0);

  voiceRenderer.setPublishedAudioLevels({
    high: 0.42,
    low: 0.44,
    mid: 0.45,
    overall: 0.46,
  });
  uniforms.set("u_outputLevel", 0.46);
  now = 100;
  const currentFrame = frameCallback;
  currentFrame();
  assert.ok(number("--cts-voice-orb-live-width") > 88);
  assert.ok(number("--cts-voice-orb-live-height") > 81);
  assert.ok(number("--cts-voice-orb-live-pulse") > 1.1);
  assert.equal(
    liveProperties.get("--cts-voice-orb-active-image"),
    "url(frame-2)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-image-a"),
    "url(frame-2)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-image-b"),
    "url(frame-2)",
  );
  assert.equal(number("--cts-voice-orb-mouth-opacity-a"), 0);
  assert.equal(number("--cts-voice-orb-mouth-opacity-b"), 1);
  assert.ok(
    Math.abs(number("--cts-voice-orb-idle-x")) < 0.5,
  );
  assert.equal(
    dom.window.__codexThemeSwitcherRuntime.voicePulse.mouthEnergySource,
    "published-audio-levels-desmoothed",
  );

  voiceRenderer.setPublishedAudioLevels({
    high: 0.36,
    low: 0.38,
    mid: 0.39,
    overall: 0.4,
  });
  now = 116;
  frameCallback();
  assert.equal(voiceRenderer.publishedAudioLevels.overall, 0.4);
  assert.ok(
    dom.window.__codexThemeSwitcherRuntime.voicePulse.mouthRawLevel < 0.05,
  );
  assert.equal(number("--cts-voice-orb-mouth-opacity-a"), 0);
  assert.equal(number("--cts-voice-orb-mouth-opacity-b"), 1);
  for (let index = 0; index < 30; index += 1) {
    now += 16;
    frameCallback();
  }
  assert.equal(
    liveProperties.get("--cts-voice-orb-active-image"),
    "url(frame-0)",
  );
  assert.equal(
    liveProperties.get("--cts-voice-orb-mouth-image-a"),
    "url(frame-0)",
  );
  assert.ok(
    Math.abs(number("--cts-voice-orb-idle-x")) > 0.5,
  );

  now = 1600;
  frameCallback();
  now = 1650;
  frameCallback();
  assert.ok(number("--cts-voice-orb-blink-opacity") > 0.95);

  voiceRenderer.setPublishedAudioLevels({
    high: 0.42,
    low: 0.44,
    mid: 0.45,
    overall: 0.46,
  });
  now = 1666;
  frameCallback();
  assert.equal(number("--cts-voice-orb-blink-opacity"), 0);
  assert.equal(number("--cts-voice-orb-mouth-opacity-a"), 0);
  assert.equal(number("--cts-voice-orb-mouth-opacity-b"), 1);

  dom.window.__codexThemeSwitcherBegin(beginPayload({
    transactionID: "transaction-refresh",
    digest: "digest-refresh",
    css: ":root { --cts-voice-orb-image-enabled: 1; }",
  }));
  dom.window.__codexThemeSwitcherCommit({
    transactionID: "transaction-refresh",
  });

  dom.window.__codexThemeSwitcherClear();
  assert.equal(
    liveProperties.has("--cts-voice-orb-live-width"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-active-image"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-mouth-image-a"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-mouth-opacity-b"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-idle-x"),
    false,
  );
  assert.equal(
    liveProperties.has("--cts-voice-orb-blink-opacity"),
    false,
  );
  assert.equal(
    layoutProperties.has("--cts-voice-orb-layout-shift-x"),
    false,
  );
  assert.equal(
    layoutProperties.has("--cts-voice-orb-layout-shift-y"),
    false,
  );
  assert.equal(cancelledFrames.length, 2);
  assert.equal(observers.every((observer) => observer.disconnected), true);
});
