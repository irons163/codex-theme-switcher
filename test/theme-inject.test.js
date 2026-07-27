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
  const elements = new Map();
  const children = [];
  const attributes = new Map();

  const host = {
    appendChild(element) {
      if (!children.includes(element)) children.push(element);
      element.parentNode = host;
      if (element.id) elements.set(element.id, element);
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
          if (element.id) elements.delete(element.id);
          element.parentNode = null;
        },
      };
      return element;
    },
    getElementById(id) {
      return elements.get(id) || null;
    },
  };
  const window = {};
  const sandbox = {
    document,
    window,
    TextEncoder,
    setTimeout,
  };
  return { attributes, children, document, host, sandbox, window };
}

test("runtime applies, replaces, clears, and reinstalls a single style", () => {
  const dom = fakeDOM();
  vm.runInNewContext(source, dom.sandbox);

  assert.equal(typeof dom.window.__codexThemeSwitcherApply, "function");
  assert.equal(typeof dom.window.__codexThemeSwitcherClear, "function");
  assert.equal(dom.children.length, 0);

  const firstResult = dom.window.__codexThemeSwitcherApply({
    themeID: "first",
    themeName: "First",
    css: ":root { color: red; }",
  });
  assert.equal(firstResult.ok, true);
  assert.equal(firstResult.themeID, "first");
  assert.equal(firstResult.cssBytes, 21);
  assert.equal(dom.children.length, 1);
  const style = dom.children[0];
  assert.equal(style.id, "codex-theme-switcher-style");
  assert.equal(style.type, "text/css");
  assert.equal(style.dataset.codexThemeSwitcher, "true");
  assert.equal(style.textContent, ":root { color: red; }");
  assert.equal(
    dom.document.documentElement.getAttribute(
      "data-codex-theme-switcher-theme",
    ),
    "first",
  );

  dom.window.__codexThemeSwitcherApply({
    themeID: "second",
    themeName: "Second",
    css: ":root { color: 🟣; }",
  });
  assert.equal(dom.children.length, 1);
  assert.equal(dom.children[0], style);
  assert.equal(style.textContent, ":root { color: 🟣; }");
  assert.deepEqual(
    { ...dom.window.__codexThemeSwitcherRuntime.current },
    { themeID: "second", themeName: "Second" },
  );

  assert.deepEqual(
    { ...dom.window.__codexThemeSwitcherClear() },
    { ok: true },
  );
  assert.equal(dom.children.length, 0);
  assert.equal(
    dom.document.documentElement.getAttribute(
      "data-codex-theme-switcher-theme",
    ),
    null,
  );
  assert.equal(dom.window.__codexThemeSwitcherRuntime.current, null);
});

test("runtime source evaluation is idempotent and preserves active state", () => {
  const dom = fakeDOM();
  vm.runInNewContext(source, dom.sandbox);
  dom.window.__codexThemeSwitcherApply({
    themeID: "preserved",
    themeName: "Preserved",
    css: ":root{}",
  });
  const runtime = dom.window.__codexThemeSwitcherRuntime;
  const apply = runtime.apply;
  const clear = runtime.clear;

  vm.runInNewContext(source, dom.sandbox);

  assert.equal(dom.window.__codexThemeSwitcherRuntime, runtime);
  assert.equal(dom.window.__codexThemeSwitcherApply, apply);
  assert.equal(dom.window.__codexThemeSwitcherClear, clear);
  assert.equal(runtime.current.themeID, "preserved");
  assert.equal(dom.children.length, 1);
});

test("runtime rejects malformed payloads without mutating the document", () => {
  const dom = fakeDOM();
  vm.runInNewContext(source, dom.sandbox);

  for (const payload of [null, {}, { css: null }]) {
    assert.throws(
      () => dom.window.__codexThemeSwitcherApply(payload),
      /Invalid Codex Theme payload/,
    );
  }
  assert.equal(dom.children.length, 0);
  assert.equal(dom.window.__codexThemeSwitcherRuntime.current, null);
});

test("runtime falls back to documentElement when head is unavailable", () => {
  const dom = fakeDOM();
  dom.document.head = null;
  dom.document.documentElement.appendChild = dom.host.appendChild;
  vm.runInNewContext(source, dom.sandbox);

  const result = dom.window.__codexThemeSwitcherApply({
    themeID: "",
    themeName: "",
    css: "",
  });

  assert.equal(result.ok, true);
  assert.equal(result.themeID, "");
  assert.equal(dom.children.length, 1);
  assert.equal(
    dom.document.documentElement.getAttribute(
      "data-codex-theme-switcher-theme",
    ),
    "custom",
  );
});
