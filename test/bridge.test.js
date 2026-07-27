"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const fsp = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const {
  activeThemePath,
  ensureTokenFile,
  loadActiveTheme,
  MAX_THEME_ASSET_BYTES,
  MAX_THEME_CSS_BYTES,
  MAX_THEME_TOTAL_ASSET_BYTES,
  persistActiveTheme,
  removeActiveTheme,
  validateThemePayload,
} = require("../Sources/CodexThemeRuntime/Resources/runtime/lib/bridge");

async function temporaryDirectory(t) {
  const directory = await fsp.mkdtemp(
    path.join(os.tmpdir(), "codex-theme-runtime-test-"),
  );
  t.after(() => fsp.rm(directory, { recursive: true, force: true }));
  return directory;
}

function fileMode(file) {
  return fs.statSync(file).mode & 0o777;
}

test("validateThemePayload trims metadata and preserves CSS verbatim", () => {
  const css = ":root { --color-text: #fff; }\n";
  const validated = validateThemePayload({
    themeID: "  midnight  ",
    themeName: "  Midnight  ",
    css,
    ignored: true,
  });

  assert.equal(validated.themeID, "midnight");
  assert.equal(validated.themeName, "Midnight");
  assert.equal(validated.css, css);
  assert.deepEqual(validated.assets, []);
  assert.match(validated.digest, /^[0-9a-f]{64}$/);
});

test("validateThemePayload rejects missing and oversized fields", () => {
  const invalidPayloads = [
    null,
    {},
    { themeID: " ", themeName: "Name", css: "" },
    { themeID: "id", themeName: " ", css: "" },
    { themeID: "id", themeName: "Name", css: null },
  ];

  for (const payload of invalidPayloads) {
    assert.throws(
      () => validateThemePayload(payload),
      (error) => error.code === "invalid-theme",
    );
  }

  assert.throws(
    () => validateThemePayload({
      themeID: "large",
      themeName: "Large",
      css: "x".repeat(MAX_THEME_CSS_BYTES + 1),
    }),
    (error) => error.code === "theme-too-large",
  );
});

test("validateThemePayload rejects imports and external or local URLs", () => {
  const unsafeRules = [
    '@import "https://example.com/theme.css";',
    "@IMPORT url(data:text/css,:root{});",
    ".x { background: url(https://example.com/x.png); }",
    ".x { background: URL( 'http://example.com/x.png' ); }",
    ".x { background: url( file:///tmp/secret ); }",
  ];

  for (const css of unsafeRules) {
    assert.throws(
      () => validateThemePayload({
        themeID: "unsafe",
        themeName: "Unsafe",
        css,
      }),
      (error) => error.code === "unsafe-css",
      css,
    );
  }
});

test("validateThemePayload rejects protocol-relative network URLs", () => {
  assert.throws(
    () => validateThemePayload({
      themeID: "network",
      themeName: "Network",
      css: ".avatar { background-image: url(//tracker.example/pixel); }",
    }),
    (error) => error.code === "unsafe-css",
  );
});

test("validateThemePayload rejects comment and escape obfuscated CSS", () => {
  const unsafeRules = [
    String.raw`@\69mport u/**/rl("\68ttps://tracker.invalid/theme.css"); :root { color: red; }`,
    String.raw`.x { background: u\72l(f\69le:///tmp/secret); }`,
    String.raw`.x { background: u/**/rl("\66tp://tracker.invalid/pixel"); }`,
  ];

  for (const css of unsafeRules) {
    assert.throws(
      () => validateThemePayload({
        themeID: "obfuscated",
        themeName: "Obfuscated",
        css,
      }),
      (error) => error.code === "unsafe-css",
      css,
    );
  }
});

test("validateThemePayload allows self-contained data and fragment URLs", () => {
  const payload = {
    themeID: "portable",
    themeName: "Portable",
    css: [
      ".image { background-image: url(data:image/png;base64,AAAA); }",
      ".mask { mask-image: url(#portable-mask); }",
    ].join("\n"),
  };
  const validated = validateThemePayload(payload);
  assert.equal(validated.themeID, payload.themeID);
  assert.equal(validated.themeName, payload.themeName);
  assert.equal(validated.css, payload.css);
  assert.deepEqual(validated.assets, []);
  assert.match(validated.digest, /^[0-9a-f]{64}$/);
});

test("validateThemePayload canonicalizes referenced runtime assets", () => {
  const id = "A8D603E1-F01D-48D0-BD8F-CBFE4D179A66";
  const dataBase64 = Buffer.from([0, 1, 2, 3]).toString("base64");
  const validated = validateThemePayload({
    themeID: "asset-theme",
    themeName: "Asset theme",
    css: `.hero{background:url("codex-theme-asset://${id}")}`,
    assets: [{
      id,
      mediaType: "IMAGE/PNG",
      dataBase64,
    }],
  });

  assert.equal(validated.assets.length, 1);
  assert.deepEqual(
    {
      id: validated.assets[0].id,
      mediaType: validated.assets[0].mediaType,
      dataBase64: validated.assets[0].dataBase64,
      byteLength: validated.assets[0].byteLength,
    },
    {
      id: id.toLowerCase(),
      mediaType: "image/png",
      dataBase64,
      byteLength: 4,
    },
  );
  assert.match(validated.assets[0].fingerprint, /^[0-9a-f]{64}$/);
  assert.match(validated.digest, /^[0-9a-f]{64}$/);
});

test("validateThemePayload rejects malformed, duplicate, missing, and unused assets", () => {
  const first = "a8d603e1-f01d-48d0-bd8f-cbfe4d179a66";
  const second = "99b56d29-fdfa-44a6-bafd-780d68a419bb";
  const asset = {
    id: first,
    mediaType: "image/png",
    dataBase64: "AA==",
  };
  const base = {
    themeID: "asset-theme",
    themeName: "Asset theme",
    css: `.hero{background:url("codex-theme-asset://${first}")}`,
    assets: [asset],
  };

  const invalidPayloads = [
    { ...base, assets: [{ ...asset, id: "not-a-uuid" }] },
    { ...base, assets: [{ ...asset, mediaType: "not a mime" }] },
    { ...base, assets: [{ ...asset, dataBase64: "%%%=" }] },
    { ...base, assets: [asset, asset] },
    { ...base, assets: [] },
    {
      ...base,
      css: ":root{}",
      assets: [asset],
    },
    {
      ...base,
      css: `.hero{background:url("codex-theme-asset://${second}")}`,
    },
    {
      ...base,
      css: ".hero{background:url(\"codex-theme-asset://broken\")}",
    },
  ];

  for (const payload of invalidPayloads) {
    assert.throws(
      () => validateThemePayload(payload),
      (error) => [
        "invalid-theme-asset",
        "missing-theme-asset",
        "unreferenced-theme-asset",
      ].includes(error.code),
    );
  }
});

test("validateThemePayload enforces decoded per-asset and total limits", () => {
  const ids = [
    "a8d603e1-f01d-48d0-bd8f-cbfe4d179a66",
    "99b56d29-fdfa-44a6-bafd-780d68a419bb",
    "81955af3-2db8-496f-bce6-adf6c3fe9857",
  ];
  const makeAsset = (id, bytes) => ({
    id,
    mediaType: "application/octet-stream",
    dataBase64: Buffer.alloc(bytes).toString("base64"),
  });

  assert.throws(
    () => validateThemePayload({
      themeID: "too-large",
      themeName: "Too large",
      css: `.x{src:url("codex-theme-asset://${ids[0]}")}`,
      assets: [makeAsset(ids[0], MAX_THEME_ASSET_BYTES + 1)],
    }),
    (error) => error.code === "theme-asset-too-large",
  );

  const perAsset = Math.floor(MAX_THEME_TOTAL_ASSET_BYTES / 3) + 1;
  assert.throws(
    () => validateThemePayload({
      themeID: "too-large-total",
      themeName: "Too large total",
      css: ids.map(
        (id) => `.x{src:url("codex-theme-asset://${id}")}`,
      ).join("\n"),
      assets: ids.map((id) => makeAsset(id, perAsset)),
    }),
    (error) => error.code === "theme-assets-too-large",
  );
});

test("ensureTokenFile creates a stable private 256-bit token", async (t) => {
  const userRoot = await temporaryDirectory(t);
  const tokenFile = path.join(userRoot, "Runtime", "bridge-token");
  const options = { userRoot, tokenFile };

  const first = ensureTokenFile(options);
  const second = ensureTokenFile(options);

  assert.match(first, /^[0-9a-f]{64}$/);
  assert.equal(second, first);
  assert.equal(fs.readFileSync(tokenFile, "utf8"), `${first}\n`);
  assert.equal(fileMode(tokenFile), 0o600);
  assert.equal(fileMode(path.dirname(tokenFile)), 0o700);
});

test("persistActiveTheme atomically replaces a private JSON file", async (t) => {
  const userRoot = await temporaryDirectory(t);
  const themes = Array.from({ length: 24 }, (_, index) => ({
    themeID: `theme-${index}`,
    themeName: `Theme ${index}`,
    css: `:root { --test-index: ${index}; }`,
  }));

  await persistActiveTheme(userRoot, themes[0]);
  const observations = [];
  let reading = true;
  const reader = (async () => {
    while (reading) {
      const text = await fsp.readFile(activeThemePath(userRoot), "utf8");
      observations.push(JSON.parse(text).themeID);
      await new Promise((resolve) => setImmediate(resolve));
    }
  })();

  await Promise.all(themes.slice(1).map(
    (theme) => persistActiveTheme(userRoot, theme),
  ));
  reading = false;
  await reader;

  const persisted = JSON.parse(
    await fsp.readFile(activeThemePath(userRoot), "utf8"),
  );
  assert.ok(themes.some((theme) => theme.themeID === persisted.themeID));
  assert.ok(observations.length > 0);
  assert.ok(observations.every(
    (themeID) => themes.some((theme) => theme.themeID === themeID),
  ));
  assert.equal(fileMode(activeThemePath(userRoot)), 0o600);

  const runtimeEntries = await fsp.readdir(
    path.dirname(activeThemePath(userRoot)),
  );
  assert.deepEqual(runtimeEntries, ["active-theme.json"]);
});

test("loadActiveTheme validates persisted content and remove is idempotent", async (t) => {
  const userRoot = await temporaryDirectory(t);
  const theme = {
    themeID: "loaded",
    themeName: "Loaded",
    css: ":root {}",
  };

  assert.equal(await loadActiveTheme(userRoot), null);
  await persistActiveTheme(userRoot, theme);
  const loaded = await loadActiveTheme(userRoot);
  assert.equal(loaded.themeID, theme.themeID);
  assert.equal(loaded.themeName, theme.themeName);
  assert.equal(loaded.css, theme.css);
  assert.deepEqual(loaded.assets, []);
  assert.match(loaded.digest, /^[0-9a-f]{64}$/);

  await fsp.writeFile(activeThemePath(userRoot), "{not-json");
  assert.equal(await loadActiveTheme(userRoot), null);

  await removeActiveTheme(userRoot);
  await removeActiveTheme(userRoot);
  assert.equal(fs.existsSync(activeThemePath(userRoot)), false);
});
