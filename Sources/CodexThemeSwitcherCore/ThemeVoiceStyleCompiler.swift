import Foundation

enum ThemeVoiceStyleCompiler {
    private static let root =
        "html:root[data-codex-theme-switcher-theme]"

    static func compile(_ style: ThemeVoiceStyle) -> String {
        guard style.isEnabled else { return "" }

        var output = [
            "/* Codex Theme Voice Overlay */",
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
        ]
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
        """
        \(selector) {
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
        \(root) body,
        \(root) #root {
          background-color: var(--cts-voice-backdrop) !important;
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

    private static func indent(_ value: String) -> String {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  \($0)" }
            .joined(separator: "\n")
    }
}
