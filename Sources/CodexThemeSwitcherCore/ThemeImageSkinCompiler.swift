import Foundation

enum ThemeImageSkinCompiler {
    private static let root =
        "html:root[data-codex-theme-switcher-theme]"
    private static var variableRoot: String {
        ":root"
    }

    static func compile(_ skin: ThemeImageSkin) -> String {
        guard skin.isEnabled else { return "" }

        let assetIDs = Set(
            [
                skin.light.backgroundAssetID,
                skin.dark.backgroundAssetID
            ].compactMap { $0 }
        ).sorted { $0.uuidString < $1.uuidString }

        var output = ["/* Codex Theme Image Skin */"]
        if !assetIDs.isEmpty {
            output.append("\(variableRoot) {")
            for id in assetIDs {
                output.append(
                    "  \(assetVariable(id)): theme-asset(\"\(id.uuidString)\");"
                )
            }
            output.append("}")
        }

        output.append(appearanceRule(
            selector: variableRoot,
            variant: skin.light,
            centerPanelEnabled: skin.centerPanel.isEnabled
        ))
        output.append(
            """
            @media (prefers-color-scheme: dark) {
            \(indent(appearanceRule(
                selector: ":root:where(:not(.electron-light):not(.electron-dark))",
                variant: skin.dark,
                centerPanelEnabled: skin.centerPanel.isEnabled
            )))
            }
            """
        )
        output.append(appearanceRule(
            selector: ":root:where(.electron-dark:not(.electron-light))",
            variant: skin.dark,
            centerPanelEnabled: skin.centerPanel.isEnabled
        ))
        output.append(appearanceRule(
            selector: ":root:where(.electron-light)",
            variant: skin.light,
            centerPanelEnabled: skin.centerPanel.isEnabled
        ))
        output.append(foundationRules(skin))

        return output.joined(separator: "\n\n")
    }

    private static func appearanceRule(
        selector: String,
        variant: ThemeSkinVariant,
        centerPanelEnabled: Bool
    ) -> String {
        let sizing: (size: String, repeatMode: String)
        switch variant.imageFit {
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
        let filter = [
            "blur(\(number(variant.imageBlur))px)",
            "brightness(\(number(variant.brightness)))",
            "contrast(\(number(variant.contrast)))",
            "saturate(\(number(variant.saturation)))"
        ].joined(separator: " ")
        let usesBlurOverscan =
            variant.imageBlur > 0
            && (variant.imageFit == .cover || variant.imageFit == .fill)
        let inset = usesBlurOverscan
            ? variant.imageBlur * 2 + 4
            : 0
        let insetValue = inset == 0
            ? "0px"
            : "-\(number(inset))px"
        let centerPanelDeclarations = centerPanelEnabled
            ? """

              --cts-skin-center-panel-background: \(alphaColor(
                  variant.centerPanelTint,
                  variant.centerPanelOpacity
              ));
              --cts-skin-center-panel-border: \(alphaColor(
                  variant.centerPanelBorderColor,
                  variant.centerPanelBorderOpacity
              ));
              --cts-skin-center-panel-shadow: \(alphaColor(
                  variant.centerPanelShadowColor,
                  variant.centerPanelShadowOpacity
              ));
            """
            : ""

        return """
        \(selector) {
          --cts-skin-background-image: \(image);
          --cts-skin-background-color: \(variant.backgroundColor);
          --cts-skin-background-size: \(sizing.size);
          --cts-skin-background-repeat: \(sizing.repeatMode);
          --cts-skin-background-position: \(percent(variant.positionX)) \(percent(variant.positionY));
          --cts-skin-image-opacity: \(number(variant.imageOpacity));
          --cts-skin-image-filter: \(filter);
          --cts-skin-image-transform: scale(\(number(variant.zoom)));
          --cts-skin-image-origin: \(percent(variant.positionX)) \(percent(variant.positionY));
          --cts-skin-image-inset: \(insetValue);
          --cts-skin-image-blend: \(blendMode(variant.blendMode));
          --cts-skin-overlay: \(alphaColor(variant.overlayColor, variant.overlayOpacity));
          --cts-skin-scrim: \(scrim(variant));
          --cts-skin-vignette: \(vignette(variant.vignetteOpacity));
          --cts-skin-text-primary: \(variant.primaryTextColor);
          --cts-skin-text-secondary: \(variant.secondaryTextColor);
          --cts-skin-accent: \(variant.accentColor);
          --cts-skin-sidebar: \(alphaColor(variant.sidebarTint, variant.sidebarOpacity));
          --cts-skin-content: \(alphaColor(variant.contentTint, variant.contentOpacity));
          --cts-skin-composer: \(alphaColor(variant.composerTint, variant.composerOpacity));
          --cts-skin-card: \(alphaColor(variant.cardTint, variant.cardOpacity));
          --cts-skin-border: \(alphaColor(variant.borderColor, variant.borderOpacity));
        \(centerPanelDeclarations)
        }
        """
    }

    private static func foundationRules(_ skin: ThemeImageSkin) -> String {
        let glass = skin.glass
        var rootDeclarations = [
            "--cts-skin-glass-blur: \(number(glass.blurRadius))px;",
            "--cts-skin-glass-saturation: \(number(glass.saturation));",
            "--cts-skin-border-width: \(number(glass.borderWidth))px;",
            "--cts-skin-corner-radius: \(number(glass.cornerRadius))px;",
            "--cts-skin-shadow: 0 18px \(number(glass.shadowBlur))px rgb(0 0 0 / \(number(glass.shadowOpacity)));",
            "--cts-skin-text-shadow: 0 1px 3px rgb(0 0 0 / \(number(glass.textShadowOpacity)));"
        ]
        if skin.centerPanel.isEnabled {
            let panel = skin.centerPanel
            rootDeclarations.append(contentsOf: [
                "--cts-skin-center-panel-backdrop-blur: \(number(panel.backdropBlur))px;",
                "--cts-skin-center-panel-backdrop-saturation: \(number(panel.backdropSaturation));",
                "--cts-skin-center-panel-border-width: \(number(panel.borderWidth))px;",
                "--cts-skin-center-panel-corner-radius: \(number(panel.cornerRadius))px;",
                "--cts-skin-center-panel-shadow-blur: \(number(panel.shadowBlur))px;",
                "--cts-skin-center-panel-shadow-offset-x: \(number(panel.shadowOffsetX))px;",
                "--cts-skin-center-panel-shadow-offset-y: \(number(panel.shadowOffsetY))px;",
                "--cts-skin-center-panel-maximum-width: \(number(panel.maximumWidth))px;",
                "--cts-skin-center-panel-padding-x: \(number(panel.horizontalPadding))px;",
                "--cts-skin-center-panel-padding-y: \(number(panel.verticalPadding))px;"
            ])
        }
        rootDeclarations.append(contentsOf: semanticTokenDeclarations(
            role: .textPrimary,
            value: "var(--cts-skin-text-primary)"
        ))
        rootDeclarations.append(contentsOf: semanticTokenDeclarations(
            role: .textSecondary,
            value: "var(--cts-skin-text-secondary)"
        ))
        rootDeclarations.append(contentsOf: semanticTokenDeclarations(
            role: .accent,
            value: "var(--cts-skin-accent)"
        ))
        if skin.targets.content {
            rootDeclarations.append(
                "--color-token-main-surface-primary: var(--cts-skin-content);"
            )
        }
        if skin.targets.sidebar {
            rootDeclarations.append(contentsOf: [
                "--color-token-side-bar-background: var(--cts-skin-sidebar);",
                "--color-token-bg-primary: var(--cts-skin-sidebar);",
                "--vscode-sideBar-background: var(--cts-skin-sidebar);"
            ])
        }
        if skin.targets.composer {
            rootDeclarations.append(contentsOf: [
                "--color-token-input-background: var(--cts-skin-composer);",
                "--composer-top-tray-background: var(--cts-skin-composer);",
                "--composer-top-tray-border: var(--cts-skin-border);"
            ])
        }
        if skin.targets.cards || skin.targets.popovers {
            rootDeclarations.append(
                "--color-background-elevated-primary: var(--cts-skin-card);"
            )
        }
        if skin.targets.cards {
            rootDeclarations.append(
                "--color-token-bg-secondary: var(--cts-skin-card);"
            )
        }
        if skin.targets.popovers {
            rootDeclarations.append(
                "--color-token-dropdown-background: var(--cts-skin-card);"
            )
        }
        if skin.targets.codeBlocks {
            rootDeclarations.append(
                "--color-token-text-code-block-background: var(--cts-skin-card);"
            )
        }
        if skin.targets.titlebar {
            rootDeclarations.append(
                "--codex-titlebar-tint: transparent;"
            )
        }
        let rootDeclarationText = rootDeclarations
            .map { "  \($0)" }
            .joined(separator: "\n")
        let wallpaperRules = wallpaperRules(for: skin)

        var rules: [String] = [
            """
            \(variableRoot) {
            \(rootDeclarationText)
            }

            \(root) {
              background: var(--cts-skin-background-color) !important;
              min-height: 100%;
              isolation: isolate;
            }

            \(wallpaperRules)

            \(root) body,
            \(root) body #root {
              position: relative;
              z-index: 1;
              min-height: 100vh;
              background-color: transparent !important;
              background-image: none !important;
              color: var(--cts-skin-text-primary) !important;
              text-shadow: var(--cts-skin-text-shadow);
            }
            """
        ]

        if skin.targets.content {
            if skin.wallpaperScope == .fullWindow {
                rules.append(surfaceRule(
                    selectors: [
                        "main.main-surface"
                    ],
                    background: "var(--cts-skin-content)"
                ))
            }
        }
        if skin.targets.content || skin.wallpaperScope == .mainContent {
            rules.append(transparentRule(selectors: [
                "[data-app-shell-main-content-layout]",
                ".app-shell-main-content-frame"
            ]))
        }

        if skin.targets.sidebar {
            rules.append(glassRule(
                selectors: [
                    "aside.app-shell-left-panel"
                ],
                background: "var(--cts-skin-sidebar)",
                radius: false,
                border: false,
                shadow: false,
                extra: "border-inline-end: var(--cts-skin-border-width) solid var(--cts-skin-border) !important;"
            ))
        }

        if skin.targets.titlebar {
            rules.append(surfaceRule(
                selectors: [".app-header-tint"],
                background: "var(--cts-skin-content)"
            ))
        }

        if skin.targets.composer {
            rules.append(glassRule(
                selectors: [
                    "[data-codex-composer-root] .composer-surface-chrome",
                    "[data-codex-composer-request-navigation]",
                    "[data-codex-approval-surface]"
                ],
                background: "var(--cts-skin-composer)"
            ))
            rules.append(controlRule(
                selectors: [
                    "[data-composer-navigation-target=\"workspace-project\"]"
                ],
                background: "var(--cts-skin-composer)"
            ))
        }

        if skin.targets.cards {
            rules.append(glassRule(
                selectors: [
                    "[data-home-ambient-suggestions] button[aria-labelledby]"
                ],
                background: "var(--cts-skin-card)"
            ))
        }

        if skin.targets.popovers {
            rules.append(glassRule(
                selectors: [
                    "[role=\"menu\"][data-state=\"open\"]",
                    "[role=\"listbox\"][data-state=\"open\"]",
                    "[data-radix-popper-content-wrapper]:has([cmdk-root]) > [data-state=\"open\"]"
                ],
                background: "var(--cts-skin-card)"
            ))
            rules.append(transparentRule(selectors: [
                "[data-radix-popper-content-wrapper]:has([cmdk-root]) [cmdk-input]"
            ]))
        }

        if skin.targets.codeBlocks {
            rules.append(glassRule(
                selectors: ["[data-message-author-role] pre"],
                background: "var(--cts-skin-card)"
            ))
        }

        if skin.centerPanel.isEnabled {
            rules.append(centerPanelRule())
        }

        rules.append(
            """
            \(root) a,
            \(root) [data-accent-color] {
              color: var(--cts-skin-accent);
            }
            """
        )
        return rules.joined(separator: "\n\n")
    }

    private static func centerPanelRule() -> String {
        rule(
            selectors: [
                "[data-mcp-app-portal-target=\"true\"]:has(> [data-thread-find-target=\"conversation\"])",
                "main.main-surface [role=\"main\"] div:has(> [data-feature=\"game-source\"])"
            ],
            declarations: [
                "box-sizing: border-box !important;",
                "width: 100% !important;",
                "max-width: min(var(--cts-skin-center-panel-maximum-width), 100%) !important;",
                "padding: var(--cts-skin-center-panel-padding-y) var(--cts-skin-center-panel-padding-x) !important;",
                "background: var(--cts-skin-center-panel-background) !important;",
                "border: var(--cts-skin-center-panel-border-width) solid var(--cts-skin-center-panel-border) !important;",
                "border-radius: var(--cts-skin-center-panel-corner-radius) !important;",
                "-webkit-backdrop-filter: blur(var(--cts-skin-center-panel-backdrop-blur)) saturate(var(--cts-skin-center-panel-backdrop-saturation));",
                "backdrop-filter: blur(var(--cts-skin-center-panel-backdrop-blur)) saturate(var(--cts-skin-center-panel-backdrop-saturation));",
                "box-shadow: var(--cts-skin-center-panel-shadow-offset-x) var(--cts-skin-center-panel-shadow-offset-y) var(--cts-skin-center-panel-shadow-blur) var(--cts-skin-center-panel-shadow) !important;"
            ]
        )
    }

    private static func wallpaperRules(for skin: ThemeImageSkin) -> String {
        switch skin.wallpaperScope {
        case .fullWindow:
            return """
            \(root)::before {
              content: "";
              position: fixed;
              inset: var(--cts-skin-image-inset);
              z-index: 0;
              pointer-events: none;
              background-image: var(--cts-skin-background-image);
              background-size: var(--cts-skin-background-size);
              background-repeat: var(--cts-skin-background-repeat);
              background-position: var(--cts-skin-background-position);
              mix-blend-mode: var(--cts-skin-image-blend);
              filter: var(--cts-skin-image-filter);
              opacity: var(--cts-skin-image-opacity);
              transform: var(--cts-skin-image-transform);
              transform-origin: var(--cts-skin-image-origin);
            }

            \(root)::after {
              content: "";
              position: fixed;
              inset: 0;
              z-index: 0;
              pointer-events: none;
              background:
                var(--cts-skin-vignette),
                var(--cts-skin-scrim),
                linear-gradient(var(--cts-skin-overlay), var(--cts-skin-overlay));
            }
            """
        case .mainContent:
            var overlayLayers: [String] = []
            if skin.targets.content {
                overlayLayers.append(
                    "linear-gradient(var(--cts-skin-content), var(--cts-skin-content))"
                )
            }
            overlayLayers.append(contentsOf: [
                "var(--cts-skin-vignette)",
                "var(--cts-skin-scrim)",
                "linear-gradient(var(--cts-skin-overlay), var(--cts-skin-overlay))"
            ])
            let overlayBackground = overlayLayers
                .map { "    \($0)" }
                .joined(separator: ",\n")
            return """
            \(root) main.main-surface {
              position: relative;
              isolation: isolate;
              overflow: hidden;
              background-color: var(--cts-skin-background-color) !important;
              background-image: none !important;
            }

            \(root) main.main-surface::before {
              content: "";
              position: absolute;
              inset: var(--cts-skin-image-inset);
              z-index: -2;
              pointer-events: none;
              background-image: var(--cts-skin-background-image);
              background-size: var(--cts-skin-background-size);
              background-repeat: var(--cts-skin-background-repeat);
              background-position: var(--cts-skin-background-position);
              mix-blend-mode: var(--cts-skin-image-blend);
              filter: var(--cts-skin-image-filter);
              opacity: var(--cts-skin-image-opacity);
              transform: var(--cts-skin-image-transform);
              transform-origin: var(--cts-skin-image-origin);
            }

            \(root) main.main-surface::after {
              content: "";
              position: absolute;
              inset: 0;
              z-index: -1;
              pointer-events: none;
              background:
            \(overlayBackground);
            }
            """
        }
    }

    private static func surfaceRule(
        selectors: [String],
        background: String
    ) -> String {
        rule(
            selectors: selectors,
            declarations: [
                "background-color: \(background) !important;",
                "background-image: none !important;"
            ]
        )
    }

    private static func controlRule(
        selectors: [String],
        background: String
    ) -> String {
        rule(
            selectors: selectors,
            declarations: [
                "background: \(background) !important;",
                "border: var(--cts-skin-border-width) solid var(--cts-skin-border) !important;",
                "border-radius: min(10px, var(--cts-skin-corner-radius)) !important;"
            ]
        )
    }

    private static func glassRule(
        selectors: [String],
        background: String,
        radius: Bool = true,
        border: Bool = true,
        shadow: Bool = true,
        extra: String? = nil
    ) -> String {
        var declarations = [
            "background: \(background) !important;",
            "-webkit-backdrop-filter: blur(var(--cts-skin-glass-blur)) saturate(var(--cts-skin-glass-saturation));",
            "backdrop-filter: blur(var(--cts-skin-glass-blur)) saturate(var(--cts-skin-glass-saturation));"
        ]
        if border {
            declarations.append(
                "border: var(--cts-skin-border-width) solid var(--cts-skin-border) !important;"
            )
        }
        if radius {
            declarations.append(
                "border-radius: var(--cts-skin-corner-radius) !important;"
            )
        }
        if shadow {
            declarations.append(
                "box-shadow: var(--cts-skin-shadow) !important;"
            )
        }
        if let extra {
            declarations.append(extra)
        }
        return rule(selectors: selectors, declarations: declarations)
    }

    private static func transparentRule(selectors: [String]) -> String {
        rule(
            selectors: selectors,
            declarations: [
                "background-color: transparent !important;",
                "background-image: none !important;"
            ]
        )
    }

    private static func rule(
        selectors: [String],
        declarations: [String]
    ) -> String {
        let scoped = selectors
            .map { "\(root) \($0)" }
            .joined(separator: ",\n")
        let body = declarations
            .map { "  \($0)" }
            .joined(separator: "\n")
        return "\(scoped) {\n\(body)\n}"
    }

    private static func assetVariable(_ id: UUID) -> String {
        "--cts-skin-asset-"
            + id.uuidString
                .lowercased()
                .replacingOccurrences(of: "-", with: "")
    }

    private static func semanticTokenDeclarations(
        role: ThemeSemanticRole,
        value: String
    ) -> [String] {
        ([role.cssVariableName] + role.codexStableTokenAliases).map {
            "\($0): \(value);"
        }
    }

    private static func alphaColor(_ color: String, _ opacity: Double) -> String {
        "color-mix(in srgb, \(color) \(percent(opacity)), transparent)"
    }

    private static func scrim(_ variant: ThemeSkinVariant) -> String {
        let opaque = "rgb(0 0 0 / \(number(variant.scrimOpacity)))"
        switch variant.scrimDirection {
        case .none:
            return "linear-gradient(transparent, transparent)"
        case .left:
            return "linear-gradient(to right, \(opaque), transparent 58%)"
        case .right:
            return "linear-gradient(to left, \(opaque), transparent 58%)"
        case .top:
            return "linear-gradient(to bottom, \(opaque), transparent 58%)"
        case .bottom:
            return "linear-gradient(to top, \(opaque), transparent 58%)"
        }
    }

    private static func vignette(_ opacity: Double) -> String {
        "radial-gradient(ellipse at center, transparent 34%, rgb(0 0 0 / \(number(opacity))) 100%)"
    }

    private static func blendMode(_ mode: ThemeSkinBlendMode) -> String {
        switch mode {
        case .normal:
            return "normal"
        case .multiply:
            return "multiply"
        case .screen:
            return "screen"
        case .overlay:
            return "overlay"
        case .softLight:
            return "soft-light"
        }
    }

    private static func percent(_ value: Double) -> String {
        "\(number(value * 100))%"
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
