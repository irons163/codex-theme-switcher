"use strict";

(function installCodexThemeRuntime() {
  const GLOBAL_KEY = "__codexThemeSwitcherRuntime";
  const STYLE_ID = "codex-theme-switcher-style";
  const VERSION = 1;

  const existing = window[GLOBAL_KEY];
  if (existing && existing.version === VERSION) {
    window.__codexThemeSwitcherApply = existing.apply;
    window.__codexThemeSwitcherClear = existing.clear;
    return;
  }

  function styleHost() {
    return document.head || document.documentElement || document.body;
  }

  function ensureStyle() {
    let style = document.getElementById(STYLE_ID);
    if (!style) {
      style = document.createElement("style");
      style.id = STYLE_ID;
      style.type = "text/css";
      style.dataset.codexThemeSwitcher = "true";
      const host = styleHost();
      if (host) host.appendChild(style);
    }
    return style;
  }

  function apply(payload) {
    if (!payload || typeof payload.css !== "string") {
      throw new Error("Invalid Codex Theme payload.");
    }
    const style = ensureStyle();
    if (!style.parentNode) {
      setTimeout(() => apply(payload), 0);
      return { ok: true, pending: true };
    }
    style.textContent = payload.css;
    style.disabled = false;
    document.documentElement?.setAttribute(
      "data-codex-theme-switcher-theme",
      String(payload.themeID || "custom"),
    );
    window[GLOBAL_KEY].current = {
      themeID: String(payload.themeID || ""),
      themeName: String(payload.themeName || ""),
    };
    return {
      ok: true,
      themeID: window[GLOBAL_KEY].current.themeID,
      cssBytes: new TextEncoder().encode(payload.css).byteLength,
    };
  }

  function clear() {
    document.getElementById(STYLE_ID)?.remove();
    document.documentElement?.removeAttribute(
      "data-codex-theme-switcher-theme",
    );
    if (window[GLOBAL_KEY]) window[GLOBAL_KEY].current = null;
    return { ok: true };
  }

  window[GLOBAL_KEY] = {
    version: VERSION,
    current: null,
    apply,
    clear,
  };
  window.__codexThemeSwitcherApply = apply;
  window.__codexThemeSwitcherClear = clear;
})();
