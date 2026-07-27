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
  MAX_THEME_CSS_BYTES,
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
  assert.deepEqual(
    validateThemePayload({
      themeID: "  midnight  ",
      themeName: "  Midnight  ",
      css,
      ignored: true,
    }),
    {
      themeID: "midnight",
      themeName: "Midnight",
      css,
    },
  );
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
  assert.deepEqual(validateThemePayload(payload), payload);
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
  assert.deepEqual(await loadActiveTheme(userRoot), theme);

  await fsp.writeFile(activeThemePath(userRoot), "{not-json");
  assert.equal(await loadActiveTheme(userRoot), null);

  await removeActiveTheme(userRoot);
  await removeActiveTheme(userRoot);
  assert.equal(fs.existsSync(activeThemePath(userRoot)), false);
});
