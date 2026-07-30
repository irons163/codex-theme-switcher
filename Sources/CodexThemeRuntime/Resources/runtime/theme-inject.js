"use strict";

(function installCodexThemeRuntime() {
  const GLOBAL_KEY = "__codexThemeSwitcherRuntime";
  const STYLE_ID = "codex-theme-switcher-style";
  const STAGING_STYLE_ID = `${STYLE_ID}-staging`;
  const VERSION = 24;
  const PUBLISHED_AUDIO_SMOOTHING = 0.86;
  const VOICE_ORB_SELECTOR = ".codex-avatar-root";
  const VOICE_PULSE_ENABLED = "--cts-voice-orb-pulse-enabled";
  const VOICE_PULSE_STRENGTH = "--cts-voice-orb-pulse-strength";
  const VOICE_PULSE_LIVE_SCALE = "--cts-voice-orb-live-pulse";
  const VOICE_ORB_IMAGE_ENABLED = "--cts-voice-orb-image-enabled";
  const VOICE_MOUTH_ACTIVE_IMAGE = "--cts-voice-orb-active-image";
  const VOICE_MOUTH_FRAME_COUNT = "--cts-voice-orb-mouth-frame-count";
  const VOICE_MOUTH_FRAME_PREFIX = "--cts-voice-orb-mouth-frame-";
  const VOICE_MOUTH_SENSITIVITY = "--cts-voice-orb-mouth-sensitivity";
  const VOICE_MOUTH_ATTACK = "--cts-voice-orb-mouth-attack-ms";
  const VOICE_MOUTH_RELEASE = "--cts-voice-orb-mouth-release-ms";
  const VOICE_MOUTH_NOISE_GATE = "--cts-voice-orb-mouth-noise-gate";
  const VOICE_MOUTH_RESPONSE_CURVE =
    "--cts-voice-orb-mouth-response-curve";
  const VOICE_MOUTH_IMAGE_A = "--cts-voice-orb-mouth-image-a";
  const VOICE_MOUTH_IMAGE_B = "--cts-voice-orb-mouth-image-b";
  const VOICE_MOUTH_OPACITY_A = "--cts-voice-orb-mouth-opacity-a";
  const VOICE_MOUTH_OPACITY_B = "--cts-voice-orb-mouth-opacity-b";
  const VOICE_IDLE_ENABLED = "--cts-voice-orb-idle-enabled";
  const VOICE_IDLE_STRENGTH = "--cts-voice-orb-idle-strength";
  const VOICE_IDLE_PERIOD = "--cts-voice-orb-idle-period-ms";
  const VOICE_IDLE_X = "--cts-voice-orb-idle-x";
  const VOICE_IDLE_Y = "--cts-voice-orb-idle-y";
  const VOICE_IDLE_ROTATION = "--cts-voice-orb-idle-rotation";
  const VOICE_BLINK_ENABLED = "--cts-voice-orb-blink-enabled";
  const VOICE_BLINK_IMAGE = "--cts-voice-orb-blink-image";
  const VOICE_BLINK_INTERVAL = "--cts-voice-orb-blink-interval-ms";
  const VOICE_BLINK_DURATION = "--cts-voice-orb-blink-duration-ms";
  const VOICE_BLINK_OPACITY = "--cts-voice-orb-blink-opacity";
  const VOICE_ORB_LAYOUT_SHIFT = Object.freeze({
    x: "--cts-voice-orb-layout-shift-x",
    y: "--cts-voice-orb-layout-shift-y",
  });
  const VOICE_ORB_LIVE_GEOMETRY = Object.freeze({
    left: "--cts-voice-orb-live-left",
    top: "--cts-voice-orb-live-top",
    width: "--cts-voice-orb-live-width",
    height: "--cts-voice-orb-live-height",
  });
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
      VOICE_ORB_IMAGE_ENABLED,
    ) !== "";
  }

  function voiceOrbImageIsEnabled() {
    const value = customProperty(
      document.documentElement,
      VOICE_ORB_IMAGE_ENABLED,
    ).toLowerCase();
    return value === "1" || value === "true";
  }

  function numericCustomProperty(name, fallback) {
    const value = Number.parseFloat(
      customProperty(document.documentElement, name),
    );
    return Number.isFinite(value) ? value : fallback;
  }

  function booleanCustomProperty(name) {
    const value = customProperty(
      document.documentElement,
      name,
    ).toLowerCase();
    return value === "1" || value === "true";
  }

  function voiceMouthFrameSources() {
    const count = Math.round(clamp(
      numericCustomProperty(VOICE_MOUTH_FRAME_COUNT, 0),
      0,
      9,
    ));
    const sources = [];
    for (let index = 0; index < count; index += 1) {
      const source = customProperty(
        document.documentElement,
        `${VOICE_MOUTH_FRAME_PREFIX}${index}`,
      );
      if (!source || source.toLowerCase() === "none") break;
      sources.push(source);
    }
    return sources;
  }

  function voiceBlinkSource() {
    if (!booleanCustomProperty(VOICE_BLINK_ENABLED)) return "";
    const source = customProperty(
      document.documentElement,
      VOICE_BLINK_IMAGE,
    );
    return source && source.toLowerCase() !== "none" ? source : "";
  }

  function resetVoiceMouthDynamics(pulse, clearCache = true) {
    pulse.mouthLevel = 0;
    pulse.mouthFrameIndex = 0;
    pulse.mouthLastTimestamp = 0;
    pulse.mouthRawLevel = 0;
    pulse.mouthNoiseFloor = 0;
    pulse.mouthPeakLevel = 0;
    pulse.mouthEnvelopeReady = false;
    pulse.mouthGateOpen = false;
    if (clearCache) resetVoiceMouthCache(pulse);
  }

  function clearVoiceMouth(root) {
    root?.style?.removeProperty?.(VOICE_MOUTH_ACTIVE_IMAGE);
    root?.style?.removeProperty?.(VOICE_MOUTH_IMAGE_A);
    root?.style?.removeProperty?.(VOICE_MOUTH_IMAGE_B);
    root?.style?.removeProperty?.(VOICE_MOUTH_OPACITY_A);
    root?.style?.removeProperty?.(VOICE_MOUTH_OPACITY_B);
  }

  function setVoiceMouthProperty(root, cacheKey, property, value) {
    const pulse = runtime.voicePulse;
    if (pulse[cacheKey] === value) return;
    root.style?.setProperty?.(property, value);
    pulse[cacheKey] = value;
  }

  function resetVoiceMouthCache(pulse) {
    pulse.mouthActiveSource = "";
    pulse.mouthSourceA = "";
    pulse.mouthSourceB = "";
    pulse.mouthOpacityA = "";
    pulse.mouthOpacityB = "";
  }

  function resetVoiceIdleCache(pulse) {
    pulse.idleConfiguration = null;
    pulse.idleLastTimestamp = 0;
    pulse.idleAmount = 0;
    pulse.idleX = "";
    pulse.idleY = "";
    pulse.idleRotation = "";
    pulse.blinkOpacity = "";
    pulse.blinkStartedAt = 0;
    pulse.nextBlinkAt = 0;
  }

  function pinVoiceMouthClosed(root) {
    if (!root) return;
    const pulse = runtime.voicePulse;
    const source = pulse.mouthSources[0];
    resetVoiceMouthDynamics(pulse, false);
    setVoiceMouthProperty(
      root,
      "blinkOpacity",
      VOICE_BLINK_OPACITY,
      "0.0000",
    );
    if (!source) {
      clearVoiceMouth(root);
      resetVoiceMouthCache(pulse);
      return;
    }
    const baseOpacity = clamp(
      numericCustomProperty("--cts-voice-orb-background-opacity", 1),
      0,
      1,
    );
    setVoiceMouthProperty(
      root,
      "mouthActiveSource",
      VOICE_MOUTH_ACTIVE_IMAGE,
      source,
    );
    setVoiceMouthProperty(
      root,
      "mouthSourceA",
      VOICE_MOUTH_IMAGE_A,
      source,
    );
    setVoiceMouthProperty(
      root,
      "mouthSourceB",
      VOICE_MOUTH_IMAGE_B,
      source,
    );
    setVoiceMouthProperty(
      root,
      "mouthOpacityA",
      VOICE_MOUTH_OPACITY_A,
      "0.0000",
    );
    setVoiceMouthProperty(
      root,
      "mouthOpacityB",
      VOICE_MOUTH_OPACITY_B,
      baseOpacity.toFixed(4),
    );
  }

  function preloadVoiceImageSource(source) {
    const url = extractCSSURL(source);
    if (!url || typeof Image !== "function") {
      return Promise.resolve({
        image: null,
        ready: typeof Image !== "function",
      });
    }

    return new Promise((resolve) => {
      const image = new Image();
      let settled = false;
      let decodingStarted = false;
      const finish = (ready) => {
        if (settled) return;
        settled = true;
        image.onload = null;
        image.onerror = null;
        resolve({ image, ready });
      };
      image.onerror = () => finish(false);
      image.onload = () => {
        if (decodingStarted) return;
        decodingStarted = true;
        if (typeof image.decode !== "function") {
          finish(true);
          return;
        }
        let decoding;
        try {
          decoding = image.decode();
        } catch {
          finish(false);
          return;
        }
        Promise.resolve(decoding).then(
          () => finish(true),
          () => finish(false),
        );
      };
      image.src = url;
      if (
        image.complete
        && Number(image.naturalWidth || image.width) > 0
      ) {
        image.onload();
      }
    });
  }

  function clearVoiceImageWarmup(pulse) {
    pulse.voiceImageWarmup?.remove?.();
    pulse.voiceImageWarmup = null;
  }

  function warmVoiceImageSources(sources, generation, key) {
    const pulse = runtime.voicePulse;
    clearVoiceImageWarmup(pulse);
    const host = document.body || document.documentElement;
    if (
      sources.length === 0
      || typeof document.createElement !== "function"
      || typeof host?.appendChild !== "function"
      || typeof requestAnimationFrame !== "function"
    ) {
      return Promise.resolve(true);
    }

    let container;
    try {
      container = document.createElement("div");
      container.dataset.codexThemeVoiceImageWarmup = "true";
      Object.assign(container.style, {
        position: "fixed",
        inset: "0 auto auto 0",
        width: "1px",
        height: "1px",
        overflow: "hidden",
        opacity: "0.001",
        pointerEvents: "none",
        zIndex: "2147483647",
      });
      for (const source of sources) {
        const frame = document.createElement("span");
        Object.assign(frame.style, {
          position: "absolute",
          inset: "0",
          width: "1px",
          height: "1px",
          backgroundImage: source,
          backgroundPosition: "center",
          backgroundRepeat: "no-repeat",
          backgroundSize: "cover",
          transform: "translateZ(0)",
        });
        container.appendChild(frame);
      }
      host.appendChild(container);
      container.getBoundingClientRect?.();
      pulse.voiceImageWarmup = container;
    } catch {
      container?.remove?.();
      return Promise.resolve(true);
    }

    return new Promise((resolve) => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          resolve(
            generation === runtime.voicePulse.generation
              && key === runtime.voicePulse.mouthSourcesKey
              && container.parentNode != null,
          );
        });
      });
    });
  }

  function resetVoiceImagePreparation(pulse) {
    clearVoiceImageWarmup(pulse);
    pulse.mouthSourcesKey = "";
    pulse.mouthSources = [];
    pulse.mouthSourcesReady = false;
    pulse.mouthImagesPreparing = false;
    pulse.mouthImagesFailed = false;
    pulse.preloadedVoiceImages = [];
  }

  function prepareVoiceImages(generation) {
    const pulse = runtime.voicePulse;
    const sources = voiceMouthFrameSources();
    const blinkSource = voiceBlinkSource();
    const key = [...sources, blinkSource].join("\u0000");
    pulse.mouthSourcesKey = key;
    pulse.mouthSources = sources;
    pulse.mouthSourcesReady = false;
    pulse.mouthImagesPreparing = false;
    pulse.mouthImagesFailed = false;
    pulse.preloadedVoiceImages = [];
    resetVoiceMouthDynamics(pulse);
    resetVoiceIdleCache(pulse);
    pinVoiceMouthClosed(pulse.root);

    const imageSources = [...new Set(
      [...sources, blinkSource].filter(Boolean),
    )];
    if (imageSources.length === 0 || typeof Image !== "function") {
      pulse.mouthSourcesReady = true;
      return;
    }

    pulse.mouthImagesPreparing = true;
    Promise.all(imageSources.map(preloadVoiceImageSource)).then((results) => {
      if (
        generation !== runtime.voicePulse.generation
        || key !== runtime.voicePulse.mouthSourcesKey
      ) {
        return;
      }
      const current = runtime.voicePulse;
      current.preloadedVoiceImages = results
        .map(({ image }) => image)
        .filter(Boolean);
      current.mouthImagesFailed = results.some(({ ready }) => !ready);
      pinVoiceMouthClosed(current.root);
      if (current.mouthImagesFailed) {
        current.mouthImagesPreparing = false;
        return;
      }
      warmVoiceImageSources(imageSources, generation, key).then((painted) => {
        if (
          generation !== runtime.voicePulse.generation
          || key !== runtime.voicePulse.mouthSourcesKey
        ) {
          return;
        }
        const prepared = runtime.voicePulse;
        prepared.mouthImagesPreparing = false;
        prepared.mouthSourcesReady = painted;
        pinVoiceMouthClosed(prepared.root);
      });
    });
  }

  function voiceIdleConfiguration() {
    const pulse = runtime.voicePulse;
    if (pulse.idleConfiguration) return pulse.idleConfiguration;
    pulse.idleConfiguration = {
      motionEnabled: booleanCustomProperty(VOICE_IDLE_ENABLED),
      strength: clamp(
        numericCustomProperty(VOICE_IDLE_STRENGTH, 0.35),
        0,
        2,
      ),
      period: clamp(
        numericCustomProperty(VOICE_IDLE_PERIOD, 4800),
        1500,
        12000,
      ),
      blinkEnabled: booleanCustomProperty(VOICE_BLINK_ENABLED),
      blinkInterval: clamp(
        numericCustomProperty(VOICE_BLINK_INTERVAL, 4200),
        1000,
        15000,
      ),
      blinkDuration: clamp(
        numericCustomProperty(VOICE_BLINK_DURATION, 140),
        60,
        400,
      ),
    };
    return pulse.idleConfiguration;
  }

  function nextBlinkDelay(interval) {
    return interval * (0.72 + Math.random() * 0.56);
  }

  function synchronizeVoiceIdle(root, rawEnergy) {
    if (!root) return;
    const pulse = runtime.voicePulse;
    const config = voiceIdleConfiguration();
    const now = typeof performance !== "undefined"
      && typeof performance.now === "function"
      ? performance.now()
      : Date.now();
    const elapsed = pulse.idleLastTimestamp > 0
      ? clamp(now - pulse.idleLastTimestamp, 1, 100)
      : 16.667;
    const gate = clamp(
      numericCustomProperty(VOICE_MOUTH_NOISE_GATE, 0.05),
      0,
      0.2,
    );
    const raw = clamp(Number(rawEnergy) || 0, 0, 1);
    const speaking = pulse.mouthGateOpen
      || pulse.mouthLevel > 0.02
      || raw >= gate + 0.008;
    const idleTarget = speaking ? 0 : 1;
    const idleResponse = 1 - Math.exp(
      -elapsed / (idleTarget > pulse.idleAmount ? 320 : 80),
    );
    pulse.idleAmount += (
      idleTarget - pulse.idleAmount
    ) * idleResponse;
    if (pulse.idleAmount < 0.001) pulse.idleAmount = 0;

    const motionAmount = config.motionEnabled
      ? config.strength * pulse.idleAmount
      : 0;
    const phase = (now / config.period) * Math.PI * 2;
    setVoiceMouthProperty(
      root,
      "idleX",
      VOICE_IDLE_X,
      `${(Math.sin(phase) * 3.2 * motionAmount).toFixed(3)}px`,
    );
    setVoiceMouthProperty(
      root,
      "idleY",
      VOICE_IDLE_Y,
      `${
        (
          Math.sin(phase * 0.61 + 1.2)
          * 1.8
          * motionAmount
        ).toFixed(3)
      }px`,
    );
    setVoiceMouthProperty(
      root,
      "idleRotation",
      VOICE_IDLE_ROTATION,
      `${
        (
          Math.sin(phase * 0.83 - 0.7)
          * 1.05
          * motionAmount
        ).toFixed(3)
      }deg`,
    );

    let blink = 0;
    if (
      !config.blinkEnabled
      || !pulse.mouthSourcesReady
      || pulse.mouthImagesFailed
      || speaking
    ) {
      pulse.blinkStartedAt = 0;
      pulse.nextBlinkAt = now + nextBlinkDelay(config.blinkInterval);
    } else {
      if (pulse.nextBlinkAt <= 0) {
        pulse.nextBlinkAt = now + nextBlinkDelay(config.blinkInterval);
      } else if (
        pulse.blinkStartedAt <= 0
        && now >= pulse.nextBlinkAt
      ) {
        pulse.blinkStartedAt = now;
      }
      if (pulse.blinkStartedAt > 0) {
        const progress = clamp(
          (now - pulse.blinkStartedAt) / config.blinkDuration,
          0,
          1,
        );
        blink = Math.sin(progress * Math.PI) ** 2;
        if (progress >= 1) {
          blink = 0;
          pulse.blinkStartedAt = 0;
          pulse.nextBlinkAt = now + nextBlinkDelay(
            config.blinkInterval,
          );
        }
      }
    }
    const baseOpacity = clamp(
      numericCustomProperty("--cts-voice-orb-background-opacity", 1),
      0,
      1,
    );
    setVoiceMouthProperty(
      root,
      "blinkOpacity",
      VOICE_BLINK_OPACITY,
      (baseOpacity * blink).toFixed(4),
    );
    pulse.idleLastTimestamp = now;
  }

  function synchronizeVoiceMouth(root, rawEnergy) {
    const pulse = runtime.voicePulse;
    if (!pulse.mouthSourcesReady) {
      pinVoiceMouthClosed(root);
      return;
    }
    const sources = pulse.mouthSources;
    if (!root || sources.length < 2) {
      clearVoiceMouth(root);
      resetVoiceMouthDynamics(pulse);
      return;
    }
    const sensitivity = clamp(
      numericCustomProperty(VOICE_MOUTH_SENSITIVITY, 1),
      0.25,
      3,
    );
    const attack = clamp(
      numericCustomProperty(VOICE_MOUTH_ATTACK, 18),
      8,
      120,
    );
    const release = clamp(
      numericCustomProperty(VOICE_MOUTH_RELEASE, 72),
      5,
      300,
    );
    const gate = clamp(
      numericCustomProperty(VOICE_MOUTH_NOISE_GATE, 0.05),
      0,
      0.2,
    );
    const curve = clamp(
      numericCustomProperty(VOICE_MOUTH_RESPONSE_CURVE, 0.9),
      0.35,
      1.5,
    );
    const raw = clamp(Number(rawEnergy) || 0, 0, 1);
    const now = typeof performance !== "undefined"
      && typeof performance.now === "function"
      ? performance.now()
      : Date.now();
    const elapsed = pulse.mouthLastTimestamp > 0
      ? clamp(now - pulse.mouthLastTimestamp, 1, 100)
      : 16.667;
    if (!pulse.mouthEnvelopeReady) {
      pulse.mouthNoiseFloor = gate;
      pulse.mouthPeakLevel = Math.max(raw, gate + 0.14);
      pulse.mouthEnvelopeReady = true;
    } else {
      if (raw < pulse.mouthNoiseFloor || !pulse.mouthGateOpen) {
        const floorTimeConstant = raw > pulse.mouthNoiseFloor
          ? 650
          : 45;
        const floorResponse = 1
          - Math.exp(-elapsed / floorTimeConstant);
        pulse.mouthNoiseFloor += (
          Math.max(raw, gate) - pulse.mouthNoiseFloor
        ) * floorResponse;
      }

      const peakTimeConstant = raw > pulse.mouthPeakLevel
        ? 18
        : 180;
      const peakResponse = 1 - Math.exp(-elapsed / peakTimeConstant);
      pulse.mouthPeakLevel += (
        Math.max(raw, gate + 0.08) - pulse.mouthPeakLevel
      ) * peakResponse;
    }
    pulse.mouthNoiseFloor = clamp(
      pulse.mouthNoiseFloor,
      gate,
      0.44,
    );
    pulse.mouthPeakLevel = clamp(
      Math.max(
        pulse.mouthPeakLevel,
        pulse.mouthNoiseFloor + 0.08,
      ),
      pulse.mouthNoiseFloor + 0.01,
      1,
    );

    const openThreshold = clamp(
      Math.max(gate + 0.008, pulse.mouthNoiseFloor + 0.012),
      0.008,
      0.24,
    );
    const closeThreshold = clamp(
      Math.max(gate * 0.72, pulse.mouthNoiseFloor + 0.002),
      0,
      Math.max(openThreshold - 0.004, 0),
    );
    if (pulse.mouthGateOpen) {
      if (raw <= closeThreshold) pulse.mouthGateOpen = false;
    } else if (raw >= openThreshold) {
      pulse.mouthGateOpen = true;
    }

    const absoluteLevel = clamp(
      (raw - closeThreshold)
        / Math.max(0.46 - closeThreshold, 0.01),
      0,
      1,
    );
    const relativeLevel = clamp(
      (raw - pulse.mouthNoiseFloor)
        / Math.max(
          pulse.mouthPeakLevel - pulse.mouthNoiseFloor,
          0.01,
        ),
      0,
      1,
    );
    const responsiveLevel = smoothstep(
      0.02,
      0.94,
      absoluteLevel * 0.82 + relativeLevel * 0.18,
    );
    const rising = Math.max(0, raw - pulse.mouthRawLevel);
    const target = !pulse.mouthGateOpen
      ? 0
      : Math.pow(
        clamp(
          responsiveLevel * sensitivity + rising * 0.16,
          0,
          1,
        ),
        curve,
      );
    const timeConstant = target > pulse.mouthLevel ? attack : release;
    const response = 1 - Math.exp(-elapsed / timeConstant);
    pulse.mouthLevel += (target - pulse.mouthLevel) * response;
    if (target === 0 && pulse.mouthLevel < 0.005) {
      pulse.mouthLevel = 0;
    }
    pulse.mouthLastTimestamp = now;
    pulse.mouthRawLevel = raw;

    const scaled = pulse.mouthLevel * (sources.length - 1);
    pulse.mouthFrameIndex = Math.min(
      Math.round(scaled),
      sources.length - 1,
    );
    const activeSource = sources[pulse.mouthFrameIndex] || sources[0];
    const baseOpacity = clamp(
      numericCustomProperty("--cts-voice-orb-background-opacity", 1),
      0,
      1,
    );
    setVoiceMouthProperty(
      root,
      "mouthActiveSource",
      VOICE_MOUTH_ACTIVE_IMAGE,
      activeSource,
    );
    setVoiceMouthProperty(
      root,
      "mouthSourceA",
      VOICE_MOUTH_IMAGE_A,
      activeSource,
    );
    setVoiceMouthProperty(
      root,
      "mouthSourceB",
      VOICE_MOUTH_IMAGE_B,
      activeSource,
    );
    setVoiceMouthProperty(
      root,
      "mouthOpacityA",
      VOICE_MOUTH_OPACITY_A,
      "0.0000",
    );
    setVoiceMouthProperty(
      root,
      "mouthOpacityB",
      VOICE_MOUTH_OPACITY_B,
      baseOpacity.toFixed(4),
    );
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
          const frames = [];
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
                  if (alpha === 0) continue;
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
              frames.push(
                area > 0
                  ? {
                    left: (minimumX / frameWidth) * 100,
                    top: (minimumY / frameHeight) * 100,
                    width: ((maximumX - minimumX + 1) / frameWidth) * 100,
                    height: ((maximumY - minimumY + 1) / frameHeight) * 100,
                  }
                  : null,
              );
              largestArea = Math.max(largestArea, area);
            }
          }

          if (largestArea <= 0) {
            resolve(null);
            return;
          }
          resolve({
            ...grid,
            frames,
            reference: frames.find(Boolean),
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

  function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
  }

  function smoothstep(minimum, maximum, value) {
    const amount = clamp((value - minimum) / (maximum - minimum), 0, 1);
    return amount * amount * (3 - 2 * amount);
  }

  function numericUniform(gl, program, name, fallback = 0) {
    try {
      const location = gl.getUniformLocation?.(program, name);
      if (location == null) return fallback;
      const value = gl.getUniform?.(program, location);
      return Number.isFinite(value) ? Number(value) : fallback;
    } catch {
      return fallback;
    }
  }

  function vectorUniform(gl, program, name) {
    try {
      const location = gl.getUniformLocation?.(program, name);
      if (location == null) return null;
      const value = gl.getUniform?.(program, location);
      if (!value || typeof value.length !== "number") return null;
      const numbers = Array.from(value, Number);
      return numbers.every(Number.isFinite) ? numbers : null;
    } catch {
      return null;
    }
  }

  function voiceCanvas(root) {
    return root?.querySelector?.(
      "canvas[data-avatar-overlay-placement]",
    ) || null;
  }

  function isVoiceRendererInstance(value, canvas) {
    try {
      return Boolean(
        value
        && typeof value === "object"
        && value.canvas === canvas
        && "publishedAudioLevels" in value
        && typeof value.setPublishedAudioLevels === "function"
      );
    } catch {
      return false;
    }
  }

  function reactVoiceRenderer(canvas) {
    if (!canvas) return null;
    let fiber;
    try {
      const key = Reflect.ownKeys(canvas).find((candidate) => (
        typeof candidate === "string"
        && candidate.startsWith("__reactFiber$")
      ));
      fiber = key ? canvas[key] : null;
    } catch {
      return null;
    }

    for (let depth = 0; fiber && depth < 40; depth += 1) {
      let hook = fiber.memoizedState;
      for (let index = 0; hook && index < 80; index += 1) {
        const state = hook.memoizedState;
        for (const candidate of [state, state?.current]) {
          if (isVoiceRendererInstance(candidate, canvas)) {
            return candidate;
          }
        }
        hook = hook.next;
      }
      fiber = fiber.return;
    }
    return null;
  }

  function publishedVoiceLevel(canvas) {
    const pulse = runtime.voicePulse;
    let renderer = pulse.publishedAudioRenderer;
    if (!isVoiceRendererInstance(renderer, canvas)) {
      renderer = null;
      pulse.publishedAudioRenderer = null;
      pulse.publishedAudioSnapshot = null;
      pulse.publishedAudioLevel = null;
      pulse.publishedAudioEstimate = 0;
      if (pulse.publishedAudioSearchCountdown > 0) {
        pulse.publishedAudioSearchCountdown -= 1;
      } else {
        renderer = reactVoiceRenderer(canvas);
        pulse.publishedAudioRenderer = renderer;
        pulse.publishedAudioSearchCountdown = 60;
      }
    }

    const levels = renderer?.publishedAudioLevels;
    const overall = Number(levels?.overall);
    if (!Number.isFinite(overall)) {
      pulse.publishedAudioSnapshot = null;
      pulse.publishedAudioLevel = null;
      pulse.publishedAudioEstimate = 0;
      pulse.mouthEnergySource = "webgl-output-level";
      return null;
    }
    const current = clamp(overall, 0, 1);
    if (
      levels !== pulse.publishedAudioSnapshot
      || current !== pulse.publishedAudioLevel
    ) {
      const previous = pulse.publishedAudioLevel;
      pulse.publishedAudioEstimate = previous == null
        ? current
        : clamp(
          (
            current - PUBLISHED_AUDIO_SMOOTHING * previous
          ) / (1 - PUBLISHED_AUDIO_SMOOTHING),
          0,
          1,
        );
      pulse.publishedAudioSnapshot = levels;
      pulse.publishedAudioLevel = current;
    }
    pulse.mouthEnergySource = "published-audio-levels-desmoothed";
    return pulse.publishedAudioEstimate;
  }

  function voiceCanvasContext(canvas) {
    if (!canvas?.getContext) return null;
    try {
      return canvas.getContext("webgl")
        || canvas.getContext("experimental-webgl");
    } catch {
      return null;
    }
  }

  function layoutRectWithin(element, ancestor) {
    const width = Number(element?.offsetWidth);
    const height = Number(element?.offsetHeight);
    if (
      !element
      || !ancestor
      || !Number.isFinite(width)
      || !Number.isFinite(height)
      || width <= 0
      || height <= 0
    ) {
      return null;
    }

    let left = 0;
    let top = 0;
    let current = element;
    for (let depth = 0; current && depth < 20; depth += 1) {
      if (current === ancestor) {
        return { left, top, width, height };
      }
      left += Number(current.offsetLeft) || 0;
      top += Number(current.offsetTop) || 0;
      current = current.offsetParent;
    }
    return null;
  }

  function voiceCanvasGeometry(root) {
    const canvas = voiceCanvas(root);
    const gl = voiceCanvasContext(canvas);
    if (!canvas || !gl) return null;

    let program;
    try {
      program = gl.getParameter?.(gl.CURRENT_PROGRAM);
    } catch {
      return null;
    }
    if (!program) return null;

    const resolution = vectorUniform(gl, program, "u_resolution");
    if (
      !resolution
      || resolution.length < 2
      || resolution[0] <= 0
      || resolution[1] <= 0
    ) {
      return null;
    }

    const rootRect = root.getBoundingClientRect?.();
    const canvasRect = canvas.getBoundingClientRect?.();
    if (
      !rootRect
      || !canvasRect
      || rootRect.width <= 0
      || rootRect.height <= 0
      || canvasRect.width <= 0
      || canvasRect.height <= 0
    ) {
      return null;
    }
    const layoutRect = layoutRectWithin(canvas, root) || {
      left: canvasRect.left - rootRect.left,
      top: canvasRect.top - rootRect.top,
      width: canvasRect.width,
      height: canvasRect.height,
    };

    const time = numericUniform(gl, program, "u_time");
    const outputLevel = numericUniform(
      gl,
      program,
      "u_outputLevel",
    );
    const rawOutputLevel = publishedVoiceLevel(canvas);
    const stateListen = numericUniform(
      gl,
      program,
      "u_stateListen",
    );
    const stateThink = numericUniform(
      gl,
      program,
      "u_stateThink",
    );
    const stateSpeak = numericUniform(
      gl,
      program,
      "u_stateSpeak",
    );
    const stateAmount = Math.max(stateListen, stateThink, stateSpeak);
    const outputEnergy = smoothstep(0.04, 0.46, outputLevel);
    const breath = Math.sin(time * Math.PI * 0.34) * 0.5 + 0.5;
    const entry = smoothstep(0, 0.9, stateAmount);
    const aspect = resolution[0] / resolution[1];
    const maximumRadius = Math.min(
      0.36,
      Math.min(0.5, 0.5 * aspect) - 0.16,
    );
    if (!Number.isFinite(maximumRadius) || maximumRadius <= 0) {
      return null;
    }

    const thinking = clamp(stateThink, 0, 1);
    const baseRadius = maximumRadius
      * (0.88 + (0.94 - 0.88) * thinking);
    const enteredRadius = baseRadius * (0.82 + (1 - 0.82) * entry);
    const restingBreath = (1 - thinking)
      * (1 - outputEnergy)
      * breath
      * maximumRadius
      * 0.01;
    const nativeRadius = Math.min(
      maximumRadius,
      enteredRadius
        + outputEnergy * maximumRadius * 0.12
        + restingBreath,
    );
    const referenceRadius = Math.min(
      maximumRadius,
      enteredRadius + (1 - thinking) * breath * maximumRadius * 0.01,
    );
    const strength = voicePulseIsEnabled() ? voicePulseStrength() : 0;
    const radius = clamp(
      referenceRadius + (nativeRadius - referenceRadius) * strength,
      maximumRadius * 0.25,
      maximumRadius * 1.35,
    );

    const horizontalDrift = Math.sin(time * 0.43) * 0.0028;
    const verticalDrift = Math.sin(time * 0.36 + 1.7) * 0.0035;
    const diameter = radius * 2 * layoutRect.height;
    const centerX = layoutRect.left
      + layoutRect.width * (0.5 + horizontalDrift / aspect);
    const centerY = layoutRect.top
      + layoutRect.height * (0.5 - verticalDrift);

    return {
      left: ((centerX - diameter / 2) / rootRect.width) * 100,
      top: ((centerY - diameter / 2) / rootRect.height) * 100,
      width: (diameter / rootRect.width) * 100,
      height: (diameter / rootRect.height) * 100,
      pulse: referenceRadius > 0 ? radius / referenceRadius : 1,
      speechEnergy: rawOutputLevel ?? outputLevel,
    };
  }

  function setVoiceOrbLayoutShift(root, geometry) {
    const layoutTarget = root?.closest?.(
      '[data-avatar-overlay-hit-region="mascot"]',
    ) || root;
    const rootRect = root?.getBoundingClientRect?.();
    const targetRect = layoutTarget?.getBoundingClientRect?.();
    if (
      !rootRect
      || !targetRect
      || rootRect.width <= 0
      || rootRect.height <= 0
    ) {
      return;
    }
    const localCenterX = rootRect.left - targetRect.left + (
      geometry.left + geometry.width / 2
    ) / 100 * rootRect.width;
    const localCenterY = rootRect.top - targetRect.top + (
      geometry.top + geometry.height / 2
    ) / 100 * rootRect.height;
    const values = {
      [VOICE_ORB_LAYOUT_SHIFT.x]: -localCenterX,
      [VOICE_ORB_LAYOUT_SHIFT.y]: -localCenterY,
    };
    for (const [property, value] of Object.entries(values)) {
      const quantized = Math.round(value * 4) / 4;
      const formatted = `${quantized.toFixed(2)}px`;
      if (
        layoutTarget.style?.getPropertyValue?.(property)
        !== formatted
      ) {
        layoutTarget.style?.setProperty?.(property, formatted);
      }
    }
  }

  function setVoiceOrbLiveGeometry(root, geometry) {
    if (!root || !geometry) return false;
    for (const [name, property] of Object.entries(
      VOICE_ORB_LIVE_GEOMETRY,
    )) {
      const minimum = name === "width" || name === "height" ? 1 : -100;
      const maximum = name === "width" || name === "height" ? 250 : 200;
      const value = Number(geometry[name]);
      if (!Number.isFinite(value)) return false;
      const formatted = `${clamp(value, minimum, maximum).toFixed(4)}%`;
      if (root.style?.getPropertyValue?.(property) !== formatted) {
        root.style?.setProperty?.(property, formatted);
      }
    }
    setVoiceOrbLayoutShift(root, geometry);
    const pulse = Number(geometry.pulse);
    if (Number.isFinite(pulse)) {
      const formatted = clamp(pulse, 0.25, 2.5).toFixed(4);
      if (
        root.style?.getPropertyValue?.(VOICE_PULSE_LIVE_SCALE)
        !== formatted
      ) {
        root.style?.setProperty?.(
          VOICE_PULSE_LIVE_SCALE,
          formatted,
        );
      }
    }
    const speechEnergy = Number(geometry.speechEnergy) || 0;
    synchronizeVoiceMouth(root, speechEnergy);
    synchronizeVoiceIdle(root, speechEnergy);
    return true;
  }

  function synchronizeVoiceCanvas() {
    const pulse = runtime.voicePulse;
    if (!pulse.root) return false;
    return setVoiceOrbLiveGeometry(
      pulse.root,
      voiceCanvasGeometry(pulse.root),
    );
  }

  function scheduleVoiceCanvasFrame(generation) {
    const pulse = runtime.voicePulse;
    if (
      generation !== pulse.generation
      || !pulse.root
      || !voiceCanvas(pulse.root)
      || typeof requestAnimationFrame !== "function"
      || pulse.canvasFrameID != null
    ) {
      return;
    }
    pulse.canvasFrameID = requestAnimationFrame(() => {
      pulse.canvasFrameID = null;
      if (
        generation !== runtime.voicePulse.generation
        || !runtime.voicePulse.root
      ) {
        return;
      }
      synchronizeVoiceCanvas();
      scheduleVoiceCanvasFrame(generation);
    });
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
    const liveGeometryIsPresent = Object.values(
      VOICE_ORB_LIVE_GEOMETRY,
    ).every((property) => (
      Boolean(root.style?.getPropertyValue?.(property))
    ));
    if (position === pulse.lastPosition && liveGeometryIsPresent) {
      return;
    }
    pulse.lastPosition = position;
    const values = String(position).trim().split(/\s+/);
    const column = percentPosition(values[0], analysis.columns);
    const row = percentPosition(values[1], analysis.rows);
    const frame = analysis.frames[
      row * analysis.columns + column
    ] || analysis.reference;
    if (!frame || !analysis.reference) return;

    const strength = voicePulseIsEnabled() ? voicePulseStrength() : 0;
    const width = analysis.reference.width
      + (frame.width - analysis.reference.width) * strength;
    const height = analysis.reference.height
      + (frame.height - analysis.reference.height) * strength;
    const geometry = {
      left: frame.left + frame.width / 2 - width / 2,
      top: frame.top + frame.height / 2 - height / 2,
      width,
      height,
      speechEnergy: clamp(
        (
          Math.max(
            frame.width / analysis.reference.width,
            frame.height / analysis.reference.height,
          ) - 1
        ) / 0.25,
        0,
        1,
      ) * 0.46,
    };
    setVoiceOrbLiveGeometry(root, geometry);
  }

  function removeVoiceOrbLiveGeometry(root) {
    root?.style?.removeProperty?.(VOICE_PULSE_LIVE_SCALE);
    clearVoiceMouth(root);
    root?.style?.removeProperty?.(VOICE_IDLE_X);
    root?.style?.removeProperty?.(VOICE_IDLE_Y);
    root?.style?.removeProperty?.(VOICE_IDLE_ROTATION);
    root?.style?.removeProperty?.(VOICE_BLINK_OPACITY);
    const layoutTarget = root?.closest?.(
      '[data-avatar-overlay-hit-region="mascot"]',
    ) || root;
    for (const property of Object.values(VOICE_ORB_LAYOUT_SHIFT)) {
      layoutTarget?.style?.removeProperty?.(property);
    }
    for (const property of Object.values(VOICE_ORB_LIVE_GEOMETRY)) {
      root?.style?.removeProperty?.(property);
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
    if (
      pulse.canvasFrameID != null
      && typeof cancelAnimationFrame === "function"
    ) {
      cancelAnimationFrame(pulse.canvasFrameID);
    }
    removeVoiceOrbLiveGeometry(pulse.root);
    pulse.root = null;
    pulse.rootObserver = null;
    pulse.canvasFrameID = null;
    pulse.analysis = null;
    pulse.analysisLoading = false;
    pulse.lastPosition = null;
    resetVoiceMouthDynamics(pulse);
    pulse.publishedAudioRenderer = null;
    pulse.publishedAudioSearchCountdown = 0;
    pulse.publishedAudioSnapshot = null;
    pulse.publishedAudioLevel = null;
    pulse.publishedAudioEstimate = 0;
    pulse.mouthEnergySource = "webgl-output-level";
    resetVoiceMouthCache(pulse);
    resetVoiceIdleCache(pulse);
    pulse.active = false;
  }

  function attachVoicePulseRoot(root, generation) {
    const pulse = runtime.voicePulse;
    if (!root || generation !== pulse.generation) return;
    pulse.root = root;
    pulse.active = true;
    if (!pulse.mouthSourcesReady) {
      pinVoiceMouthClosed(root);
    }

    if (typeof MutationObserver === "function") {
      pulse.rootObserver = new MutationObserver((records = []) => {
        if (voiceCanvas(root)) {
          const hasStructuralChange = records.length === 0
            || records.some(({ type }) => type === "childList");
          if (!hasStructuralChange) return;
          synchronizeVoiceCanvas();
          scheduleVoiceCanvasFrame(generation);
        } else if (runtime.voicePulse.analysis) {
          synchronizeVoicePulse();
        } else {
          loadVoicePulseAnalysis(root, generation);
        }
      });
      pulse.rootObserver.observe(root, {
        attributes: true,
        attributeFilter: ["style"],
        childList: true,
        subtree: true,
      });
    }

    if (voiceCanvas(root)) {
      synchronizeVoiceCanvas();
      scheduleVoiceCanvasFrame(generation);
    } else {
      loadVoicePulseAnalysis(root, generation);
    }
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
    resetVoiceImagePreparation(pulse);
    pulse.domObserver = null;
    pulse.appearanceObserver = null;
    pulse.colorSchemeQuery = null;
    pulse.colorSchemeListener = null;
  }

  function refreshVoicePulseSync() {
    stopVoicePulseSync();
    if (!voicePulseIsConfigured()) {
      return;
    }

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
    if (!voiceOrbImageIsEnabled()) {
      return;
    }
    prepareVoiceImages(generation);

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
      canvasFrameID: null,
      mouthLevel: 0,
      mouthFrameIndex: 0,
      mouthLastTimestamp: 0,
      mouthRawLevel: 0,
      mouthNoiseFloor: 0,
      mouthPeakLevel: 0,
      mouthEnvelopeReady: false,
      mouthGateOpen: false,
      mouthSourcesKey: "",
      mouthSources: [],
      mouthSourcesReady: false,
      mouthImagesPreparing: false,
      mouthImagesFailed: false,
      preloadedVoiceImages: [],
      voiceImageWarmup: null,
      publishedAudioRenderer: null,
      publishedAudioSearchCountdown: 0,
      publishedAudioSnapshot: null,
      publishedAudioLevel: null,
      publishedAudioEstimate: 0,
      mouthEnergySource: "webgl-output-level",
      mouthActiveSource: "",
      mouthSourceA: "",
      mouthSourceB: "",
      mouthOpacityA: "",
      mouthOpacityB: "",
      idleConfiguration: null,
      idleLastTimestamp: 0,
      idleAmount: 0,
      idleX: "",
      idleY: "",
      idleRotation: "",
      blinkOpacity: "",
      blinkStartedAt: 0,
      nextBlinkAt: 0,
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
