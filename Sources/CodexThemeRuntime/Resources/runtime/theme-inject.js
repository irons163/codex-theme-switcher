"use strict";

(function installCodexThemeRuntime() {
  const GLOBAL_KEY = "__codexThemeSwitcherRuntime";
  const STYLE_ID = "codex-theme-switcher-style";
  const STAGING_STYLE_ID = `${STYLE_ID}-staging`;
  const VERSION = 2;
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
    activeStyle()?.remove();
    removeStagingStyle();
    document.documentElement?.removeAttribute(
      "data-codex-theme-switcher-theme",
    );
    revokeURLs([...runtime.assets.values()].map((asset) => asset.url));
    runtime.current = null;
    runtime.assets = new Map();
    runtime.transaction = null;
    return { ok: true };
  }

  const runtime = {
    version: VERSION,
    current: null,
    assets: new Map(),
    transaction: null,
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
