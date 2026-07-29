"use strict";

(function installCodexThemeRuntime() {
  const GLOBAL_KEY = "__codexThemeSwitcherRuntime";
  const STYLE_ID = "codex-theme-switcher-style";
  const STAGING_STYLE_ID = `${STYLE_ID}-staging`;
  const VERSION = 3;
  const VOICE_ORB_SELECTOR = ".codex-avatar-root";
  const VOICE_PULSE_ENABLED = "--cts-voice-orb-pulse-enabled";
  const VOICE_PULSE_STRENGTH = "--cts-voice-orb-pulse-strength";
  const VOICE_PULSE_LIVE_SCALE = "--cts-voice-orb-live-pulse";
  const API_KEYS = {
    begin: "__codexThemeSwitcherBegin",
    appendAsset: "__codexThemeSwitcherAppendAsset",
    commit: "__codexThemeSwitcherCommit",
    abort: "__codexThemeSwitcherAbort",
    status: "__codexThemeSwitcherStatus",
    clear: "__codexThemeSwitcherClear",
  };

  const existing = window[GLOBAL_KEY];
  if (existing && existing.version === VERSION) {
    expose(existing);
    return;
  }
  if (existing && typeof existing.clear === "function") {
    try {
      existing.clear();
    } catch {
      // A stale runtime must not prevent the current bootstrap from installing.
    }
  }

  function expose(runtime) {
    window[API_KEYS.begin] = runtime.begin;
    window[API_KEYS.appendAsset] = runtime.appendAsset;
    window[API_KEYS.commit] = runtime.commit;
    window[API_KEYS.abort] = runtime.abort;
    window[API_KEYS.status] = runtime.status;
    window[API_KEYS.clear] = runtime.clear;
  }

  function fail(message) {
    throw new Error(`Codex Theme runtime: ${message}`);
  }

  function requiredString(value, field) {
    if (typeof value !== "string" || value.length === 0) {
      fail(`${field} must be a non-empty string.`);
    }
    return value;
  }

  function nonnegativeInteger(value, field) {
    if (!Number.isSafeInteger(value) || value < 0) {
      fail(`${field} must be a non-negative integer.`);
    }
    return value;
  }

  function styleHost() {
    return document.head || document.documentElement || document.body;
  }

  function activeStyle() {
    return document.getElementById(STYLE_ID);
  }

  function removeStagingStyle() {
    document.getElementById(STAGING_STYLE_ID)?.remove();
  }

  function stylePresent() {
    const style = activeStyle();
    return Boolean(style && style.parentNode && !style.disabled);
  }

  function computedStyle(element) {
    if (!element || typeof getComputedStyle !== "function") return null;
    try {
      return getComputedStyle(element);
    } catch {
      return null;
    }
  }

  function customProperty(element, name) {
    return computedStyle(element)?.getPropertyValue?.(name)?.trim() || "";
  }

  function voicePulseIsEnabled() {
    const value = customProperty(
      document.documentElement,
      VOICE_PULSE_ENABLED,
    ).toLowerCase();
    return value === "1" || value === "true";
  }

  function voicePulseIsConfigured() {
    return customProperty(
      document.documentElement,
      VOICE_PULSE_ENABLED,
    ) !== "";
  }

  function voicePulseStrength() {
    const value = Number.parseFloat(
      customProperty(document.documentElement, VOICE_PULSE_STRENGTH),
    );
    return Number.isFinite(value) ? Math.max(0, Math.min(2, value)) : 1;
  }

  function extractCSSURL(value) {
    const source = typeof value === "string" ? value.trim() : "";
    if (!source.startsWith("url(") || !source.endsWith(")")) return null;
    let url = source.slice(4, -1).trim();
    if (
      url.length >= 2
      && (
        (url.startsWith("\"") && url.endsWith("\""))
        || (url.startsWith("'") && url.endsWith("'"))
      )
    ) {
      url = url.slice(1, -1);
    }
    return url || null;
  }

  function spriteGrid(root) {
    const value = computedStyle(root)?.backgroundSize || "";
    const matches = [...value.matchAll(/([0-9]+(?:\.[0-9]+)?)%/g)];
    if (matches.length < 2) return null;
    const columns = Math.round(Number(matches[0][1]) / 100);
    const rows = Math.round(Number(matches[1][1]) / 100);
    if (
      columns < 1
      || rows < 1
      || columns > 32
      || rows > 32
      || columns * rows > 256
    ) {
      return null;
    }
    return { columns, rows };
  }

  function analyzeSprite(source, grid) {
    if (
      typeof Image !== "function"
      || typeof document.createElement !== "function"
    ) {
      return Promise.resolve(null);
    }

    return new Promise((resolve) => {
      const image = new Image();
      image.onload = () => {
        try {
          const width = Number(image.naturalWidth || image.width);
          const height = Number(image.naturalHeight || image.height);
          const frameWidth = Math.floor(width / grid.columns);
          const frameHeight = Math.floor(height / grid.rows);
          if (
            frameWidth < 1
            || frameHeight < 1
            || width * height > 32_000_000
          ) {
            resolve(null);
            return;
          }

          const canvas = document.createElement("canvas");
          canvas.width = width;
          canvas.height = height;
          const context = canvas.getContext?.("2d", {
            willReadFrequently: true,
          });
          if (!context) {
            resolve(null);
            return;
          }
          context.drawImage(image, 0, 0);

          const areas = [];
          let largestArea = 0;
          for (let row = 0; row < grid.rows; row += 1) {
            for (let column = 0; column < grid.columns; column += 1) {
              const pixels = context.getImageData(
                column * frameWidth,
                row * frameHeight,
                frameWidth,
                frameHeight,
              ).data;
              let minimumX = frameWidth;
              let minimumY = frameHeight;
              let maximumX = -1;
              let maximumY = -1;
              for (let y = 0; y < frameHeight; y += 1) {
                for (let x = 0; x < frameWidth; x += 1) {
                  const alpha = pixels[(y * frameWidth + x) * 4 + 3];
                  if (alpha < 48) continue;
                  minimumX = Math.min(minimumX, x);
                  minimumY = Math.min(minimumY, y);
                  maximumX = Math.max(maximumX, x);
                  maximumY = Math.max(maximumY, y);
                }
              }
              const area = maximumX < minimumX || maximumY < minimumY
                ? 0
                : (maximumX - minimumX + 1) * (maximumY - minimumY + 1);
              areas.push(area);
              largestArea = Math.max(largestArea, area);
            }
          }

          if (largestArea <= 0) {
            resolve(null);
            return;
          }
          resolve({
            ...grid,
            scales: areas.map((area) => (
              area > 0 ? Math.sqrt(area / largestArea) : 1
            )),
          });
        } catch {
          resolve(null);
        }
      };
      image.onerror = () => resolve(null);
      image.src = source;
    });
  }

  function spriteAnalysis(root) {
    const style = computedStyle(root);
    const source = extractCSSURL(
      root.style?.backgroundImage || style?.backgroundImage || "",
    );
    const grid = spriteGrid(root);
    if (!source || !grid) return Promise.resolve(null);

    const key = `${source}\n${grid.columns}x${grid.rows}`;
    if (!runtime.voicePulseCache.has(key)) {
      runtime.voicePulseCache.set(key, analyzeSprite(source, grid));
    }
    return runtime.voicePulseCache.get(key);
  }

  function percentPosition(value, frameCount) {
    const match = String(value).match(/(-?[0-9]+(?:\.[0-9]+)?)%/);
    if (!match || frameCount <= 1) return 0;
    return Math.max(
      0,
      Math.min(
        frameCount - 1,
        Math.round((Number(match[1]) / 100) * (frameCount - 1)),
      ),
    );
  }

  function synchronizeVoicePulse() {
    const pulse = runtime.voicePulse;
    const root = pulse.root;
    const analysis = pulse.analysis;
    if (!root || !analysis) return;

    const position = root.style?.backgroundPosition
      || computedStyle(root)?.backgroundPosition
      || "";
    if (
      position === pulse.lastPosition
      && root.style?.getPropertyValue?.(VOICE_PULSE_LIVE_SCALE)
        === pulse.lastScale
    ) {
      return;
    }
    pulse.lastPosition = position;
    const values = String(position).trim().split(/\s+/);
    const column = percentPosition(values[0], analysis.columns);
    const row = percentPosition(values[1], analysis.rows);
    const measured = analysis.scales[
      row * analysis.columns + column
    ] ?? 1;
    const scale = Math.max(
      0.5,
      Math.min(1.25, 1 + (measured - 1) * voicePulseStrength()),
    );
    const formatted = scale.toFixed(4);
    pulse.lastScale = formatted;
    if (
      root.style?.getPropertyValue?.(VOICE_PULSE_LIVE_SCALE) !== formatted
    ) {
      root.style?.setProperty?.(VOICE_PULSE_LIVE_SCALE, formatted);
    }
  }

  function loadVoicePulseAnalysis(root, generation) {
    const pulse = runtime.voicePulse;
    if (
      pulse.analysis
      || pulse.analysisLoading
      || root !== pulse.root
      || generation !== pulse.generation
    ) {
      return;
    }
    pulse.analysisLoading = true;
    spriteAnalysis(root).then((analysis) => {
      if (
        generation !== runtime.voicePulse.generation
        || root !== runtime.voicePulse.root
      ) {
        return;
      }
      runtime.voicePulse.analysisLoading = false;
      runtime.voicePulse.analysis = analysis;
      runtime.voicePulse.lastPosition = null;
      synchronizeVoicePulse();
    });
  }

  function detachVoicePulseRoot() {
    const pulse = runtime.voicePulse;
    pulse.rootObserver?.disconnect?.();
    pulse.root?.style?.removeProperty?.(VOICE_PULSE_LIVE_SCALE);
    pulse.root = null;
    pulse.rootObserver = null;
    pulse.analysis = null;
    pulse.analysisLoading = false;
    pulse.lastPosition = null;
    pulse.lastScale = null;
    pulse.active = false;
  }

  function attachVoicePulseRoot(root, generation) {
    const pulse = runtime.voicePulse;
    if (!root || generation !== pulse.generation) return;
    pulse.root = root;
    pulse.active = true;

    if (typeof MutationObserver === "function") {
      pulse.rootObserver = new MutationObserver(() => {
        if (runtime.voicePulse.analysis) {
          synchronizeVoicePulse();
        } else {
          loadVoicePulseAnalysis(root, generation);
        }
      });
      pulse.rootObserver.observe(root, {
        attributes: true,
        attributeFilter: ["style"],
      });
    }

    loadVoicePulseAnalysis(root, generation);
  }

  function stopVoicePulseSync() {
    const pulse = runtime.voicePulse;
    if (!pulse) return;
    pulse.generation += 1;
    pulse.rootObserver?.disconnect?.();
    pulse.domObserver?.disconnect?.();
    pulse.appearanceObserver?.disconnect?.();
    pulse.colorSchemeQuery?.removeEventListener?.(
      "change",
      pulse.colorSchemeListener,
    );
    detachVoicePulseRoot();
    pulse.domObserver = null;
    pulse.appearanceObserver = null;
    pulse.colorSchemeQuery = null;
    pulse.colorSchemeListener = null;
  }

  function refreshVoicePulseSync() {
    stopVoicePulseSync();
    if (!voicePulseIsConfigured()) return;

    const generation = runtime.voicePulse.generation;
    if (
      typeof MutationObserver === "function"
      && document.documentElement
    ) {
      runtime.voicePulse.appearanceObserver = new MutationObserver(() => {
        refreshVoicePulseSync();
      });
      runtime.voicePulse.appearanceObserver.observe(
        document.documentElement,
        {
          attributes: true,
          attributeFilter: ["class"],
        },
      );
    }
    if (typeof matchMedia === "function") {
      const query = matchMedia("(prefers-color-scheme: dark)");
      const listener = () => refreshVoicePulseSync();
      query.addEventListener?.("change", listener);
      runtime.voicePulse.colorSchemeQuery = query;
      runtime.voicePulse.colorSchemeListener = listener;
    }
    if (!voicePulseIsEnabled()) return;

    const findRoot = () => (
      typeof document.querySelector === "function"
        ? document.querySelector(VOICE_ORB_SELECTOR)
        : null
    );
    if (
      typeof MutationObserver === "function"
      && document.documentElement
    ) {
      runtime.voicePulse.domObserver = new MutationObserver(() => {
        if (generation !== runtime.voicePulse.generation) return;
        const nextRoot = findRoot();
        if (nextRoot === runtime.voicePulse.root) return;
        detachVoicePulseRoot();
        if (nextRoot) attachVoicePulseRoot(nextRoot, generation);
      });
      runtime.voicePulse.domObserver.observe(document.documentElement, {
        childList: true,
        subtree: true,
      });
    }
    const root = findRoot();
    if (root) attachVoicePulseRoot(root, generation);
  }

  function descriptorFrom(value, index) {
    if (!value || typeof value !== "object" || Array.isArray(value)) {
      fail(`assets[${index}] must be an object.`);
    }
    return {
      id: requiredString(value.id, `assets[${index}].id`),
      mediaType: requiredString(
        value.mediaType,
        `assets[${index}].mediaType`,
      ),
      fingerprint: requiredString(
        value.fingerprint,
        `assets[${index}].fingerprint`,
      ),
      base64Characters: nonnegativeInteger(
        value.base64Characters,
        `assets[${index}].base64Characters`,
      ),
      byteLength: nonnegativeInteger(
        value.byteLength,
        `assets[${index}].byteLength`,
      ),
    };
  }

  function validateBeginPayload(payload) {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      fail("Begin payload must be an object.");
    }
    if (typeof payload.css !== "string") {
      fail("css must be a string.");
    }
    if (!Array.isArray(payload.assets)) {
      fail("assets must be an array.");
    }

    const descriptors = payload.assets.map(descriptorFrom);
    const ids = new Set();
    const fingerprintMetadata = new Map();
    for (const descriptor of descriptors) {
      if (ids.has(descriptor.id)) {
        fail(`Duplicate asset id "${descriptor.id}".`);
      }
      ids.add(descriptor.id);

      const metadata = fingerprintMetadata.get(descriptor.fingerprint);
      if (
        metadata
        && (
          metadata.mediaType !== descriptor.mediaType
          || metadata.base64Characters !== descriptor.base64Characters
          || metadata.byteLength !== descriptor.byteLength
        )
      ) {
        fail(
          `Asset fingerprint "${descriptor.fingerprint}" has conflicting metadata.`,
        );
      }
      fingerprintMetadata.set(descriptor.fingerprint, descriptor);
    }

    return {
      transactionID: requiredString(
        payload.transactionID,
        "transactionID",
      ),
      themeID: requiredString(payload.themeID, "themeID"),
      themeName: typeof payload.themeName === "string"
        ? payload.themeName
        : fail("themeName must be a string."),
      digest: requiredString(payload.digest, "digest"),
      css: payload.css,
      descriptors,
    };
  }

  function matchingTransaction(payload, operation) {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      fail(`${operation} payload must be an object.`);
    }
    const transactionID = requiredString(
      payload.transactionID,
      "transactionID",
    );
    const transaction = runtime.transaction;
    if (!transaction || transaction.transactionID !== transactionID) {
      fail(`No active transaction "${transactionID}".`);
    }
    return transaction;
  }

  function committedAssetByFingerprint() {
    const result = new Map();
    for (const asset of runtime.assets.values()) {
      if (!result.has(asset.fingerprint)) {
        result.set(asset.fingerprint, asset);
      }
    }
    return result;
  }

  function begin(payload) {
    const value = validateBeginPayload(payload);
    runtime.transaction = null;
    removeStagingStyle();

    if (
      runtime.current
      && runtime.current.digest === value.digest
      && stylePresent()
    ) {
      return {
        ok: true,
        unchanged: true,
        requiredAssetIDs: [],
      };
    }

    const committedByFingerprint = committedAssetByFingerprint();
    const requiredAssetIDs = [];
    const requiredFingerprintIDs = new Map();
    for (const descriptor of value.descriptors) {
      if (
        committedByFingerprint.has(descriptor.fingerprint)
        || requiredFingerprintIDs.has(descriptor.fingerprint)
      ) {
        continue;
      }
      requiredFingerprintIDs.set(descriptor.fingerprint, descriptor.id);
      requiredAssetIDs.push(descriptor.id);
    }

    runtime.transaction = {
      ...value,
      descriptorByID: new Map(
        value.descriptors.map((descriptor) => [descriptor.id, descriptor]),
      ),
      requiredFingerprintIDs,
      chunksByID: new Map(
        requiredAssetIDs.map((assetID) => [assetID, []]),
      ),
      charactersByID: new Map(
        requiredAssetIDs.map((assetID) => [assetID, 0]),
      ),
    };

    return {
      ok: true,
      unchanged: false,
      transactionID: value.transactionID,
      requiredAssetIDs,
    };
  }

  function appendAsset(payload) {
    const transaction = matchingTransaction(payload, "AppendAsset");
    const assetID = requiredString(payload.assetID, "assetID");
    const chunks = transaction.chunksByID.get(assetID);
    if (!chunks) {
      fail(`Asset "${assetID}" is not required by this transaction.`);
    }
    const index = nonnegativeInteger(payload.index, "index");
    if (typeof payload.chunk !== "string") {
      fail("chunk must be a string.");
    }

    if (index < chunks.length) {
      if (chunks[index] === payload.chunk) {
        return { ok: true, duplicate: true, index };
      }
      fail(`Asset "${assetID}" chunk ${index} conflicts with prior data.`);
    }
    if (index !== chunks.length) {
      fail(
        `Asset "${assetID}" expected chunk ${chunks.length}, received ${index}.`,
      );
    }

    const descriptor = transaction.descriptorByID.get(assetID);
    const characters = transaction.charactersByID.get(assetID)
      + payload.chunk.length;
    if (characters > descriptor.base64Characters) {
      fail(`Asset "${assetID}" exceeds its declared base64 length.`);
    }
    chunks.push(payload.chunk);
    transaction.charactersByID.set(assetID, characters);
    return { ok: true, duplicate: false, index };
  }

  function decodeAsset(transaction, assetID) {
    const descriptor = transaction.descriptorByID.get(assetID);
    const chunks = transaction.chunksByID.get(assetID);
    if (
      transaction.charactersByID.get(assetID)
      !== descriptor.base64Characters
    ) {
      fail(`Asset "${assetID}" has incomplete base64 data.`);
    }

    const parts = [];
    let byteLength = 0;
    for (let index = 0; index < chunks.length; index += 1) {
      let binary;
      try {
        binary = atob(chunks[index]);
      } catch {
        fail(`Asset "${assetID}" chunk ${index} is not valid base64.`);
      }
      const part = new Uint8Array(binary.length);
      for (let offset = 0; offset < binary.length; offset += 1) {
        part[offset] = binary.charCodeAt(offset);
      }
      parts.push(part);
      byteLength += part.byteLength;
    }
    if (byteLength !== descriptor.byteLength) {
      fail(
        `Asset "${assetID}" decoded to ${byteLength} bytes, expected ${descriptor.byteLength}.`,
      );
    }
    return new Blob(parts, { type: descriptor.mediaType });
  }

  function replaceAssetReferences(css, assets) {
    let resolved = css;
    const longestIDsFirst = [...assets]
      .sort(([left], [right]) => right.length - left.length);
    for (const [assetID, asset] of longestIDsFirst) {
      resolved = resolved
        .split(`codex-theme-asset://${assetID}`)
        .join(asset.url);
    }
    if (resolved.includes("codex-theme-asset://")) {
      fail("CSS contains an asset reference without a descriptor.");
    }
    return resolved;
  }

  function revokeURLs(urls) {
    for (const url of new Set(urls)) {
      try {
        URL.revokeObjectURL(url);
      } catch {
        // Revocation is best-effort, and must not corrupt committed state.
      }
    }
  }

  function commitStyle(css, themeID) {
    const host = styleHost();
    if (!host) fail("No document host is available for the theme style.");

    removeStagingStyle();
    const previous = activeStyle();
    const themeAttribute = "data-codex-theme-switcher-theme";
    const root = document.documentElement;
    const previousThemeID = root?.getAttribute?.(themeAttribute) ?? null;
    const staging = document.createElement("style");
    staging.id = STAGING_STYLE_ID;
    staging.type = "text/css";
    staging.dataset.codexThemeSwitcher = "true";
    staging.textContent = css;
    staging.disabled = true;

    let previousDisabled = false;
    let appended = false;
    try {
      host.appendChild(staging);
      appended = true;
      root?.setAttribute(themeAttribute, themeID || "custom");
      staging.id = STYLE_ID;
      previousDisabled = Boolean(previous?.disabled);
      if (previous) previous.disabled = true;
      staging.disabled = false;
      if (previous) previous.remove();
      return staging;
    } catch (error) {
      if (appended) staging.remove();
      if (previous) previous.disabled = previousDisabled;
      if (previousThemeID === null) {
        root?.removeAttribute(themeAttribute);
      } else {
        root?.setAttribute(themeAttribute, previousThemeID);
      }
      throw error;
    }
  }

  function commit(payload) {
    const transaction = matchingTransaction(payload, "Commit");
    const reusableByFingerprint = committedAssetByFingerprint();
    const nextAssets = new Map();
    const createdURLs = [];
    const createdByFingerprint = new Map();

    try {
      for (const descriptor of transaction.descriptors) {
        let asset = reusableByFingerprint.get(descriptor.fingerprint)
          || createdByFingerprint.get(descriptor.fingerprint);
        if (!asset) {
          const sourceID = transaction.requiredFingerprintIDs.get(
            descriptor.fingerprint,
          );
          const blob = decodeAsset(transaction, sourceID);
          const url = URL.createObjectURL(blob);
          asset = {
            fingerprint: descriptor.fingerprint,
            mediaType: descriptor.mediaType,
            url,
          };
          createdURLs.push(url);
          createdByFingerprint.set(descriptor.fingerprint, asset);
        }
        nextAssets.set(descriptor.id, {
          fingerprint: descriptor.fingerprint,
          mediaType: descriptor.mediaType,
          url: asset.url,
        });
      }

      const resolvedCSS = replaceAssetReferences(
        transaction.css,
        nextAssets,
      );
      commitStyle(resolvedCSS, transaction.themeID);

      const retainedURLs = new Set(
        [...nextAssets.values()].map((asset) => asset.url),
      );
      const orphanedURLs = [...runtime.assets.values()]
        .map((asset) => asset.url)
        .filter((url) => !retainedURLs.has(url));

      runtime.current = {
        themeID: transaction.themeID,
        themeName: transaction.themeName,
        digest: transaction.digest,
      };
      runtime.assets = nextAssets;
      runtime.transaction = null;
      revokeURLs(orphanedURLs);
      refreshVoicePulseSync();
      return {
        ok: true,
        digest: runtime.current.digest,
      };
    } catch (error) {
      runtime.transaction = null;
      removeStagingStyle();
      revokeURLs(createdURLs);
      throw error;
    }
  }

  function abort(payload) {
    const transaction = matchingTransaction(payload, "Abort");
    runtime.transaction = null;
    removeStagingStyle();
    return {
      ok: true,
      transactionID: transaction.transactionID,
    };
  }

  function status() {
    return {
      ok: true,
      version: VERSION,
      digest: runtime.current?.digest || null,
      stylePresent: stylePresent(),
      voicePulseActive: runtime.voicePulse.active,
      current: runtime.current
        ? {
          themeID: runtime.current.themeID,
          themeName: runtime.current.themeName,
          digest: runtime.current.digest,
        }
        : null,
    };
  }

  function clear() {
    stopVoicePulseSync();
    activeStyle()?.remove();
    removeStagingStyle();
    document.documentElement?.removeAttribute(
      "data-codex-theme-switcher-theme",
    );
    revokeURLs([...runtime.assets.values()].map((asset) => asset.url));
    runtime.current = null;
    runtime.assets = new Map();
    runtime.voicePulseCache.clear();
    runtime.transaction = null;
    return { ok: true };
  }

  const runtime = {
    version: VERSION,
    current: null,
    assets: new Map(),
    transaction: null,
    voicePulse: {
      generation: 0,
      root: null,
      rootObserver: null,
      domObserver: null,
      appearanceObserver: null,
      colorSchemeQuery: null,
      colorSchemeListener: null,
      analysis: null,
      analysisLoading: false,
      lastPosition: null,
      lastScale: null,
      active: false,
    },
    voicePulseCache: new Map(),
    begin,
    appendAsset,
    commit,
    abort,
    status,
    clear,
  };
  window[GLOBAL_KEY] = runtime;
  expose(runtime);
  try {
    delete window.__codexThemeSwitcherApply;
  } catch {
    window.__codexThemeSwitcherApply = undefined;
  }
})();
