import Foundation

enum ThemeVoiceStyleCompiler {
    private static let root =
        "html:root[data-codex-theme-switcher-theme]"

    static func compile(_ style: ThemeVoiceStyle) -> String {
        guard style.isEnabled else { return "" }

        let assetIDs = Set(
            [
                style.light.backgroundAssetID,
                style.dark.backgroundAssetID
            ].compactMap { $0 }
        ).sorted { $0.uuidString < $1.uuidString }

        var output = ["/* Codex Theme Voice Overlay */"]
        if !assetIDs.isEmpty {
            output.append(":root {")
            for id in assetIDs {
                output.append(
                    "  \(assetVariable(id)): theme-asset(\"\(id.uuidString)\");"
                )
            }
            output.append("}")
        }
        output.append(contentsOf: [
            appearanceRule(selector: ":root", variant: style.light),
            """
            @media (prefers-color-scheme: dark) {
            \(indent(appearanceRule(
                selector: ":root:where(:not(.electron-light):not(.electron-dark))",
                variant: style.dark
            )))
            }
            """,
            appearanceRule(
                selector: ":root:where(.electron-dark:not(.electron-light))",
                variant: style.dark
            ),
            appearanceRule(
                selector: ":root:where(.electron-light)",
                variant: style.light
            ),
            foundationRules
        ])
        let advanced = style.rawCSS.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !advanced.isEmpty {
            output.append("/* Voice Overlay Advanced CSS */\n\(advanced)")
        }
        return output.joined(separator: "\n\n") + "\n"
    }

    private static func appearanceRule(
        selector: String,
        variant: ThemeVoiceVariant
    ) -> String {
        let sizing: (size: String, repeatMode: String)
        switch variant.backgroundImageFit {
        case .cover:
            sizing = ("cover", "no-repeat")
        case .contain:
            sizing = ("contain", "no-repeat")
        case .fill:
            sizing = ("100% 100%", "no-repeat")
        case .fitWidth:
            sizing = ("100% auto", "no-repeat")
        case .fitHeight:
            sizing = ("auto 100%", "no-repeat")
        case .original:
            sizing = ("auto", "no-repeat")
        case .tile:
            sizing = ("auto", "repeat")
        }
        let image = variant.backgroundAssetID
            .map { "var(\(assetVariable($0)))" }
            ?? "none"
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

    private static var foundationRules: String {
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

        \(root) :is(
          canvas,
          svg,
          [data-voice-orb],
          [data-codex-voice-orb],
          [class*="voice-orb" i],
          [class*="voiceorb" i]
        ) {
          opacity: var(--cts-voice-opacity) !important;
          scale: var(--cts-voice-scale) !important;
          transform-origin: center !important;
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
          will-change: filter, opacity, scale;
        }
        """
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
