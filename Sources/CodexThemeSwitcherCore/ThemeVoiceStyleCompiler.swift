import Foundation

enum ThemeVoiceStyleCompiler {
    private static let root =
        "html:root[data-codex-theme-switcher-theme]"

    static func compile(_ style: ThemeVoiceStyle) -> String {
        guard style.isEnabled else { return "" }

        var output = ["/* Codex Theme Voice Overlay */"]
        output.append(contentsOf: sharedRules(style))
        output.append(overlayFoundationRules)
        output.append(orbFoundationRules)
        let advanced = style.rawCSS.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !advanced.isEmpty {
            output.append("/* Voice Overlay Advanced CSS */\n\(advanced)")
        }
        return output.joined(separator: "\n\n") + "\n"
    }

    static func compileEmbeddedOrb(_ style: ThemeVoiceStyle) -> String {
        guard style.isEnabled else { return "" }

        var output = ["/* Codex Theme Voice Embedded Orb */"]
        output.append(contentsOf: sharedRules(style, embeddedOrbOnly: true))
        output.append(orbFoundationRules)
        return output.joined(separator: "\n\n") + "\n"
    }

    private static func sharedRules(
        _ style: ThemeVoiceStyle,
        embeddedOrbOnly: Bool = false
    ) -> [String] {
        let assetIDs = Set(
            [
                embeddedOrbOnly ? nil : style.light.backgroundAssetID,
                embeddedOrbOnly ? nil : style.dark.backgroundAssetID,
                style.light.orbBackgroundAssetID,
                style.dark.orbBackgroundAssetID,
                style.light.orbBlinkAssetID,
                style.dark.orbBlinkAssetID
            ].compactMap { $0 }
                + style.light.orbMouthFrameAssetIDs
                + style.dark.orbMouthFrameAssetIDs
        ).sorted { $0.uuidString < $1.uuidString }

        var output: [String] = []
        if !assetIDs.isEmpty {
            output.append(
                """
                :root {
                \(assetIDs.map {
                    "  \(assetVariable($0)): theme-asset(\"\($0.uuidString)\");"
                }.joined(separator: "\n"))
                }
                """
            )
        }
        let rule: (String, ThemeVoiceVariant) -> String = {
            selector,
            variant in
            embeddedOrbOnly
                ? embeddedOrbAppearanceRule(
                    selector: selector,
                    variant: variant
                )
                : appearanceRule(selector: selector, variant: variant)
        }
        output.append(contentsOf: [
            rule(":root", style.light),
            """
            @media (prefers-color-scheme: dark) {
            \(indent(rule(
                ":root:where(:not(.electron-light):not(.electron-dark))",
                style.dark
            )))
            }
            """,
            rule(
                ":root:where(.electron-dark:not(.electron-light))",
                style.dark
            ),
            rule(
                ":root:where(.electron-light)",
                style.light
            )
        ])
        return output
    }

    private static func appearanceRule(
        selector: String,
        variant: ThemeVoiceVariant
    ) -> String {
        let sizing = imageSizing(for: variant.backgroundImageFit)
        let orbSizing = imageSizing(for: variant.orbBackgroundImageFit)
        let image = variant.backgroundAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
        let orbImage = variant.orbBackgroundAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
        let blinkImage = variant.orbBlinkAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
        let mouthFrameIDs =
            (variant.orbBackgroundAssetID.map { [$0] } ?? [])
            + variant.orbMouthFrameAssetIDs
        let mouthFrameVariables = (0..<9).map { index -> String in
            let value = mouthFrameIDs.indices.contains(index)
                ? "var(\(assetVariable(mouthFrameIDs[index])))"
                : "none"
            return "  --cts-voice-orb-mouth-frame-\(index): \(value);"
        }.joined(separator: "\n")
        let usesBlurOverscan =
            variant.backgroundImageBlur > 0
            && (
                variant.backgroundImageFit == .cover
                    || variant.backgroundImageFit == .fill
            )
        let inset = usesBlurOverscan
            ? variant.backgroundImageBlur * 2 + 4
            : 0
        let insetValue = inset == 0
            ? "0px"
            : "-\(number(inset))px"

        return """
        \(selector) {
          --cts-voice-background-image: \(image);
          --cts-voice-background-size: \(sizing.size);
          --cts-voice-background-repeat: \(sizing.repeatMode);
          --cts-voice-background-position: \(percent(variant.backgroundPositionX)) \(percent(variant.backgroundPositionY));
          --cts-voice-background-origin: \(percent(variant.backgroundPositionX)) \(percent(variant.backgroundPositionY));
          --cts-voice-background-scale: \(number(variant.backgroundZoom));
          --cts-voice-background-opacity: \(number(variant.backgroundImageOpacity));
          --cts-voice-background-blur: \(number(variant.backgroundImageBlur))px;
          --cts-voice-background-inset: \(insetValue);
          --cts-voice-orb-background-image: \(orbImage);
          --cts-voice-orb-background-size: \(orbSizing.size);
          --cts-voice-orb-background-repeat: \(orbSizing.repeatMode);
          --cts-voice-orb-background-position: \(percent(variant.orbBackgroundPositionX)) \(percent(variant.orbBackgroundPositionY));
          --cts-voice-orb-background-opacity: \(number(variant.orbBackgroundImageOpacity));
          --cts-voice-orb-background-blur: \(number(variant.orbBackgroundImageBlur))px;
          --cts-voice-orb-background-inset: \(number(variant.orbBackgroundInset))px;
          --cts-voice-orb-image-enabled: \(variant.orbBackgroundAssetID != nil ? "1" : "0");
          --cts-voice-orb-pulse-enabled: \(variant.orbBackgroundAssetID != nil && variant.orbBackgroundFollowsVoicePulse ? "1" : "0");
          --cts-voice-orb-pulse-strength: \(number(variant.orbBackgroundPulseStrength));
          --cts-voice-orb-mouth-frame-count: \(mouthFrameIDs.count);
          --cts-voice-orb-mouth-sensitivity: \(number(variant.orbMouthSensitivity));
          --cts-voice-orb-mouth-attack-ms: \(number(variant.orbMouthAttackMilliseconds));
          --cts-voice-orb-mouth-release-ms: \(number(variant.orbMouthReleaseMilliseconds));
          --cts-voice-orb-mouth-noise-gate: \(number(variant.orbMouthNoiseGate));
          --cts-voice-orb-mouth-response-curve: \(number(variant.orbMouthResponseCurve));
          --cts-voice-orb-mouth-smoothing: \(number(variant.orbMouthSmoothing));
          --cts-voice-orb-mouth-hold-ms: \(number(variant.orbMouthFrameHoldMilliseconds));
          --cts-voice-orb-idle-enabled: \(variant.orbIdleMotionEnabled ? "1" : "0");
          --cts-voice-orb-idle-strength: \(number(variant.orbIdleMotionStrength));
          --cts-voice-orb-idle-period-ms: \(number(variant.orbIdleMotionPeriodSeconds * 1_000));
          --cts-voice-orb-blink-enabled: \(variant.orbBlinkAssetID != nil ? "1" : "0");
          --cts-voice-orb-blink-image: \(blinkImage);
          --cts-voice-orb-blink-interval-ms: \(number(variant.orbBlinkIntervalSeconds * 1_000));
          --cts-voice-orb-blink-duration-ms: \(number(variant.orbBlinkDurationMilliseconds));
        \(mouthFrameVariables)
          --cts-voice-scale: \(number(variant.orbScale));
          --cts-voice-opacity: \(number(variant.orbOpacity));
          --cts-voice-brightness: \(number(variant.brightness));
          --cts-voice-contrast: \(number(variant.contrast));
          --cts-voice-saturation: \(number(variant.saturation));
          --cts-voice-hue: \(number(variant.hueRotation))deg;
          --cts-voice-blur: \(number(variant.blur))px;
          --cts-voice-glow-color: \(alphaColor(
              variant.glowColor,
              variant.glowOpacity
          ));
          --cts-voice-glow-blur: \(number(variant.glowBlur))px;
          --cts-voice-backdrop: \(alphaColor(
              variant.backdropColor,
              variant.backdropOpacity
          ));
        }
        """
    }

    private static func embeddedOrbAppearanceRule(
        selector: String,
        variant: ThemeVoiceVariant
    ) -> String {
        let orbSizing = imageSizing(for: variant.orbBackgroundImageFit)
        let orbImage = variant.orbBackgroundAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
        let blinkImage = variant.orbBlinkAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
        let mouthFrameIDs =
            (variant.orbBackgroundAssetID.map { [$0] } ?? [])
            + variant.orbMouthFrameAssetIDs
        let mouthFrameVariables = (0..<9).map { index -> String in
            let value = mouthFrameIDs.indices.contains(index)
                ? "var(\(assetVariable(mouthFrameIDs[index])))"
                : "none"
            return "  --cts-voice-orb-mouth-frame-\(index): \(value);"
        }.joined(separator: "\n")

        return """
        \(selector) {
          --cts-voice-orb-background-image: \(orbImage);
          --cts-voice-orb-background-size: \(orbSizing.size);
          --cts-voice-orb-background-repeat: \(orbSizing.repeatMode);
          --cts-voice-orb-background-position: \(percent(variant.orbBackgroundPositionX)) \(percent(variant.orbBackgroundPositionY));
          --cts-voice-orb-background-opacity: \(number(variant.orbBackgroundImageOpacity));
          --cts-voice-orb-background-blur: \(number(variant.orbBackgroundImageBlur))px;
          --cts-voice-orb-background-inset: \(number(variant.orbBackgroundInset))px;
          --cts-voice-orb-image-enabled: \(variant.orbBackgroundAssetID != nil ? "1" : "0");
          --cts-voice-orb-pulse-enabled: \(variant.orbBackgroundAssetID != nil && variant.orbBackgroundFollowsVoicePulse ? "1" : "0");
          --cts-voice-orb-pulse-strength: \(number(variant.orbBackgroundPulseStrength));
          --cts-voice-orb-mouth-frame-count: \(mouthFrameIDs.count);
          --cts-voice-orb-mouth-sensitivity: \(number(variant.orbMouthSensitivity));
          --cts-voice-orb-mouth-attack-ms: \(number(variant.orbMouthAttackMilliseconds));
          --cts-voice-orb-mouth-release-ms: \(number(variant.orbMouthReleaseMilliseconds));
          --cts-voice-orb-mouth-noise-gate: \(number(variant.orbMouthNoiseGate));
          --cts-voice-orb-mouth-response-curve: \(number(variant.orbMouthResponseCurve));
          --cts-voice-orb-mouth-smoothing: \(number(variant.orbMouthSmoothing));
          --cts-voice-orb-mouth-hold-ms: \(number(variant.orbMouthFrameHoldMilliseconds));
          --cts-voice-orb-idle-enabled: \(variant.orbIdleMotionEnabled ? "1" : "0");
          --cts-voice-orb-idle-strength: \(number(variant.orbIdleMotionStrength));
          --cts-voice-orb-idle-period-ms: \(number(variant.orbIdleMotionPeriodSeconds * 1_000));
          --cts-voice-orb-blink-enabled: \(variant.orbBlinkAssetID != nil ? "1" : "0");
          --cts-voice-orb-blink-image: \(blinkImage);
          --cts-voice-orb-blink-interval-ms: \(number(variant.orbBlinkIntervalSeconds * 1_000));
          --cts-voice-orb-blink-duration-ms: \(number(variant.orbBlinkDurationMilliseconds));
        \(mouthFrameVariables)
          --cts-voice-scale: \(number(variant.orbScale));
          --cts-voice-opacity: \(number(variant.orbOpacity));
          --cts-voice-brightness: \(number(variant.brightness));
          --cts-voice-contrast: \(number(variant.contrast));
          --cts-voice-saturation: \(number(variant.saturation));
          --cts-voice-hue: \(number(variant.hueRotation))deg;
          --cts-voice-blur: \(number(variant.blur))px;
          --cts-voice-glow-color: \(alphaColor(
              variant.glowColor,
              variant.glowOpacity
          ));
          --cts-voice-glow-blur: \(number(variant.glowBlur))px;
        }
        """
    }

    private static var overlayFoundationRules: String {
        """
        \(root),
        \(root) body {
          background-color: var(--cts-voice-backdrop) !important;
        }

        \(root) body {
          isolation: isolate;
          overflow: hidden;
          position: relative;
        }

        \(root) body::before {
          background-image: var(--cts-voice-background-image);
          background-position: var(--cts-voice-background-position);
          background-repeat: var(--cts-voice-background-repeat);
          background-size: var(--cts-voice-background-size);
          content: "";
          filter: blur(var(--cts-voice-background-blur));
          inset: var(--cts-voice-background-inset);
          opacity: var(--cts-voice-background-opacity);
          pointer-events: none;
          position: fixed;
          scale: var(--cts-voice-background-scale);
          transform-origin: var(--cts-voice-background-origin);
          z-index: 0;
        }

        \(root) #root {
          background-color: transparent !important;
          min-height: 100%;
          position: relative;
          z-index: 1;
        }

        \(root) [data-avatar-overlay-hit-region="mascot"] {
          bottom: auto !important;
          left: 50vw !important;
          margin: 0 !important;
          right: auto !important;
          top: 50vh !important;
          translate:
            var(--cts-voice-orb-layout-shift-x, 0px)
            var(--cts-voice-orb-layout-shift-y, 0px) !important;
          will-change: left, top, translate;
        }
        """
    }

    private static var orbFoundationRules: String {
        """
        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        ) {
          filter:
            brightness(var(--cts-voice-brightness))
            contrast(var(--cts-voice-contrast))
            saturate(var(--cts-voice-saturation))
            hue-rotate(var(--cts-voice-hue))
            blur(var(--cts-voice-blur))
            drop-shadow(
              0 0 var(--cts-voice-glow-blur)
              var(--cts-voice-glow-color)
            ) !important;
          will-change: filter;
        }

        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        ) canvas {
          opacity: var(--cts-voice-opacity) !important;
          scale: var(--cts-voice-scale) !important;
          transform-origin: center !important;
          will-change: filter, opacity, scale;
        }

        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        ) {
          position: relative !important;
        }

        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        )::before,
        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        )::after {
          background-position: var(--cts-voice-orb-background-position);
          background-repeat: var(--cts-voice-orb-background-repeat);
          background-size: var(--cts-voice-orb-background-size);
          border-radius: 50%;
          clip-path: circle(50%);
          content: "";
          filter: blur(var(--cts-voice-orb-background-blur));
          height: calc(
            var(--cts-voice-orb-live-height, 68.2692%)
            - var(--cts-voice-orb-background-inset)
            - var(--cts-voice-orb-background-inset)
          );
          left: calc(
            var(--cts-voice-orb-live-left, 15.625%)
            + var(--cts-voice-orb-background-inset)
          );
          overflow: hidden;
          pointer-events: none;
          position: absolute;
          top: calc(
            var(--cts-voice-orb-live-top, 14.9038%)
            + var(--cts-voice-orb-background-inset)
          );
          width: calc(
            var(--cts-voice-orb-live-width, 69.2708%)
            - var(--cts-voice-orb-background-inset)
            - var(--cts-voice-orb-background-inset)
          );
          transform:
            translate(
              var(--cts-voice-orb-idle-x, 0px),
              var(--cts-voice-orb-idle-y, 0px)
            )
            rotate(var(--cts-voice-orb-idle-rotation, 0deg))
            scale(var(--cts-voice-scale));
          transform-origin: center;
          will-change: left, top, width, height, opacity, transform;
          z-index: 2;
        }

        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        )::before {
          background-image: var(--cts-voice-orb-blink-image, none);
          opacity: var(--cts-voice-orb-blink-opacity, 0);
          z-index: 3;
        }

        \(root) :is(
          .codex-avatar-root,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        )::after {
          background-image: var(
            --cts-voice-orb-mouth-image-b,
            var(
              --cts-voice-orb-active-image,
              var(--cts-voice-orb-background-image)
            )
          );
          opacity: var(
            --cts-voice-orb-mouth-opacity-b,
            var(--cts-voice-orb-background-opacity)
          );
        }

        \(root) .codex-avatar-root[data-realtime-voice-orb]::before,
        \(root) .codex-avatar-root[data-realtime-voice-orb]::after {
          height: calc(
            var(--cts-voice-orb-live-height, 73%)
            - var(--cts-voice-orb-background-inset)
            - var(--cts-voice-orb-background-inset)
          );
          left: calc(
            var(--cts-voice-orb-live-left, -7.5%)
            + var(--cts-voice-orb-background-inset)
          );
          top: calc(
            var(--cts-voice-orb-live-top, 30%)
            + var(--cts-voice-orb-background-inset)
          );
          width: calc(
            var(--cts-voice-orb-live-width, 79%)
            - var(--cts-voice-orb-background-inset)
            - var(--cts-voice-orb-background-inset)
          );
        }
        """
    }

    private static func imageSizing(
        for fit: ThemeSkinImageFit
    ) -> (size: String, repeatMode: String) {
        switch fit {
        case .cover:
            ("cover", "no-repeat")
        case .contain:
            ("contain", "no-repeat")
        case .fill:
            ("100% 100%", "no-repeat")
        case .fitWidth:
            ("100% auto", "no-repeat")
        case .fitHeight:
            ("auto 100%", "no-repeat")
        case .original:
            ("auto", "no-repeat")
        case .tile:
            ("auto", "repeat")
        }
    }

    private static func alphaColor(_ color: String, _ opacity: Double) -> String {
        "color-mix(in srgb, \(color) \(number(opacity * 100))%, transparent)"
    }

    private static func number(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        var formatted = String(
            format: "%.4f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
        while formatted.contains(".") && formatted.last == "0" {
            formatted.removeLast()
        }
        if formatted.last == "." {
            formatted.removeLast()
        }
        return formatted == "-0" ? "0" : formatted
    }

    private static func percent(_ value: Double) -> String {
        "\(number(value * 100))%"
    }

    private static func assetVariable(_ id: UUID) -> String {
        "--cts-voice-asset-\(id.uuidString.lowercased())"
    }

    private static func indent(_ value: String) -> String {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  \($0)" }
            .joined(separator: "\n")
    }
}
