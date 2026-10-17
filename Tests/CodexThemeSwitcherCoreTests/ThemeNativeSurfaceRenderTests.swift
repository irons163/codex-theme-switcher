import Foundation
import WebKit
import XCTest
@testable import CodexThemeSwitcherCore

/// Exercise the CSS cascade in a separate local WebKit document, not in the
/// user's running Codex window. Native inline tokens previously beat :root
/// aliases, leaving settings panels dark while their text became dark too.
final class ThemeNativeSurfaceRenderTests: XCTestCase {
    @MainActor
    func testVoiceFollowsExplicitAppearanceAndPreservesNativeCaptionMask() async throws {
        var voice = ThemeVoiceStyle(isEnabled: true)
        voice.light.orbScale = 0.7
        voice.dark.orbScale = 1.8
        voice.light.orbOpacity = 0
        voice.dark.orbOpacity = 0
        voice.light.orbLocksToOverlayCenter = false
        voice.dark.orbLocksToOverlayCenter = false
        let css = ThemeVoiceStyleCompiler.compile(voice)
        for (appearance, expectedScale) in [("light", "0.7"), ("dark", "1.8")] {
            let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 500, height: 400))
            let loaded = expectation(description: "local voice mask fixture loaded")
            let navigation = LocalNavigation(loaded: loaded)
            view.navigationDelegate = navigation
            let oppositeClass = appearance == "light" ? "electron-dark" : "electron-light"
            view.loadHTMLString("""
            <!doctype html><html class="\(oppositeClass)" data-theme="\(appearance)" data-codex-theme-switcher-theme="fixture">
              <head><style>\(css)</style></head><body>
                <svg width="0" height="0"><defs><mask id="native-caption-mask"><rect width="500" height="400" fill="white"/></mask></defs></svg>
                <div id="mask" data-avatar-overlay-caption-orb-mask style="mask-image: url(#native-caption-mask)">
                  <div id="orb" class="codex-avatar-root" data-realtime-voice-orb>
                    <canvas id="native"></canvas>
                    <div data-codex-live2d-avatar><canvas id="avatar" data-codex-live2d-canvas></canvas></div>
                  </div>
                </div>
                <div id="unrelated" data-avatar-overlay-caption-orb-mask style="mask-image: url(#native-caption-mask)">Native presentation</div>
              </body>
            </html>
            """, baseURL: nil)
            await fulfillment(of: [loaded], timeout: 10)
            if let error = navigation.error { throw error }
            let result = try await view.evaluateJavaScript("""
            (() => {
              const root = document.documentElement, orb = document.getElementById('orb');
              const pendingMask = getComputedStyle(document.getElementById('mask')).maskImage;
              orb.setAttribute('data-codex-live2d-ready', 'true');
              root.setAttribute('data-codex-voice-session-active', 'true');
              return {
                scale: getComputedStyle(root).getPropertyValue('--cts-voice-scale').trim(),
                pendingMask,
                readyMask: getComputedStyle(document.getElementById('mask')).maskImage,
                unrelatedMask: getComputedStyle(document.getElementById('unrelated')).maskImage,
                avatarOpacity: getComputedStyle(document.getElementById('avatar')).opacity,
                nativeOpacity: getComputedStyle(document.getElementById('native')).opacity
              };
            })()
            """)
            let values = try XCTUnwrap(result as? [String: String])
            XCTAssertEqual(values["scale"], expectedScale)
            XCTAssertNotEqual(values["pendingMask"], "none")
            XCTAssertNotEqual(values["readyMask"], "none")
            XCTAssertNotEqual(values["unrelatedMask"], "none")
            XCTAssertEqual(values["avatarOpacity"], "1")
            XCTAssertEqual(values["nativeOpacity"], "0")
        }
    }

    @MainActor
    func testPrimarySolidButtonsKeepContrastAcrossThemeAndAppAppearances() async throws {
        for (theme, ink, inverse) in [
            (BuiltInThemes.paper, "rgb(41, 37, 31)", "rgb(246, 241, 231)"),
            (BuiltInThemes.midnight, "rgb(238, 245, 255)", "rgb(11, 16, 32)")
        ] {
            let css = try ThemeCompiler().compile(theme).css
            for appearance in ["light", "dark"] {
                let values = try await renderPrimaryButtons(css, appearance: appearance)
                XCTAssertEqual(values["buttonColor"], inverse)
                XCTAssertEqual(values["buttonBackground"], ink)
                XCTAssertEqual(values["noticeColor"], inverse)
                XCTAssertEqual(values["ghostColor"], ink)
                for state in ["button", "notice", "hover", "active"] {
                    XCTAssertGreaterThanOrEqual(
                        try XCTUnwrap(Double(values[state + "Contrast"] ?? "")), 4.5,
                        "Low contrast for \(theme.metadata.name) / \(appearance) / \(state)"
                    )
                }
            }
        }
    }

    @MainActor
    func testPrimarySolidButtonsUseOpaqueImageSkinColorAndPreserveExpertOverrides() async throws {
        var theme = BuiltInThemes.midnight
        var skin = ThemeImageSkin()
        skin.light.primaryTextColor = "#211B18"
        skin.light.backgroundColor = "#F6F0EA"
        skin.dark = skin.light
        theme.imageSkin = skin
        let css = try ThemeCompiler().compile(theme).css
        let values = try await renderPrimaryButtons(css, appearance: "dark")
        XCTAssertEqual(values["buttonColor"], "rgb(246, 240, 234)")
        XCTAssertEqual(values["noticeColor"], "rgb(246, 240, 234)")
        XCTAssertEqual(values["buttonBackground"], "rgb(33, 27, 24)")
        for state in ["button", "notice", "hover", "active"] {
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(Double(values[state + "Contrast"] ?? "")), 4.5)
        }
        theme.layers[0].rawCSS += "\n:root { --color-text-primary-solid: #FFEEDD; }"
        let custom = try await renderPrimaryButtons(ThemeCompiler().compile(theme).css, appearance: "dark")
        XCTAssertEqual(custom["buttonColor"], "rgb(255, 238, 221)")
    }

    @MainActor
    func testProjectFormFieldsKeepContrastAcrossThemeAndAppAppearances() async throws {
        for theme in [BuiltInThemes.paper, BuiltInThemes.midnight] {
            let css = try ThemeCompiler().compile(theme).css
            for appearance in ["light", "dark"] {
                let values = try await renderProjectFields(css, appearance: appearance)
                for field in ["name", "placeholder", "folders", "softHover", "softActive", "ghostHover", "focusedName"] {
                    XCTAssertGreaterThanOrEqual(
                        try XCTUnwrap(Double(values[field + "Contrast"] ?? "")), 4.5,
                        "Low contrast for \(theme.metadata.name) / \(appearance) / \(field)"
                    )
                }
            }
        }
    }

    @MainActor
    func testHomeComposerRailSharesGlassWithoutChangingWarningRails() async throws {
        var skin = ThemeImageSkin()
        skin.light.composerOpacity = 0.5
        skin.dark = skin.light
        let values = try await renderShell(ThemeCompiler().compile(
            TestFixtures.theme(imageSkin: skin)
        ).css)
        XCTAssertEqual(values["homeRail"], "0")
        XCTAssertEqual(try XCTUnwrap(Double(values["detachedRail"] ?? "")), 0.5, accuracy: 1 / 255)
        XCTAssertEqual(values["warningRail"], "1")
    }

    @MainActor
    func testImageSkinClearsNestedSurfacesAndComposerBackdropWithoutDoubleTinting() async throws {
        var skin = ThemeImageSkin()
        skin.light.contentOpacity = 0.4
        skin.light.composerOpacity = 0.5
        skin.dark = skin.light
        let values = try await renderShell(ThemeCompiler().compile(
            TestFixtures.theme(imageSkin: skin)
        ).css)
        for id in ["page", "viewport", "workspaceFade", "sidebarInner", "footer", "footerSurface", "composerBody"] {
            XCTAssertEqual(values[id], "0", "Unexpected background on \(id)")
        }
        XCTAssertEqual(try XCTUnwrap(Double(values["main"] ?? "")), 0.4, accuracy: 1 / 255)
        XCTAssertEqual(try XCTUnwrap(Double(values["composer"] ?? "")), 0.5, accuracy: 1 / 255)
        XCTAssertEqual(values["unrelated"], "1")
    }

    @MainActor
    func testImageSkinClearsTranscriptEdgeFadesOnlyWhenContentIsEnabled() async throws {
        var skin = ThemeImageSkin()
        for enabled in [true, false] {
            skin.targets.content = enabled
            let values = try await renderShell(ThemeCompiler().compile(
                TestFixtures.theme(imageSkin: skin)
            ).css)
            for id in ["headerFade", "transcriptFade"] {
                if enabled {
                    XCTAssertEqual(values[id + "Image"], "none", "Opaque edge fade remains on \(id)")
                } else {
                    XCTAssertNotEqual(values[id + "Image"], "none", "Disabled content target changed \(id)")
                }
            }
            XCTAssertNotEqual(values["unrelatedImage"], "none")
        }
    }

    @MainActor
    func testImageSkinLeavesDisabledSidebarContentAndComposerSurfacesAlone() async throws {
        var skin = ThemeImageSkin()
        skin.targets.sidebar = false
        skin.targets.content = false
        skin.targets.composer = false
        let values = try await renderShell(ThemeCompiler().compile(
            TestFixtures.theme(imageSkin: skin)
        ).css)
        for id in ["page", "viewport", "workspaceFade", "footer", "footerSurface", "composerBody", "homeRail", "detachedRail"] {
            XCTAssertEqual(values[id], "1", "Disabled target changed \(id)")
        }
        XCTAssertGreaterThan(try XCTUnwrap(Double(values["sidebarInner"] ?? "")), 0.6)
    }

    @MainActor
    func testImageSkinFollowsExplicitDataThemeInsteadOfSystemAppearance() async throws {
        var skin = ThemeImageSkin()
        skin.light.backgroundColor = "#123456"
        skin.dark.backgroundColor = "#ABCDEF"
        let css = try ThemeCompiler().compile(TestFixtures.theme(imageSkin: skin)).css
        for (appearance, expected) in [("light", "#123456"), ("dark", "#ABCDEF")] {
            let values = try await renderShell(css, appearance: appearance)
            XCTAssertEqual(values["wallpaperColor"], expected)
        }
    }

    @MainActor
    func testSidebarUsesThemeInkAfterNativeNavigationRedefinesTextTokens() async throws {
        for (theme, primary, secondary) in [
            (BuiltInThemes.paper, "rgb(41, 37, 31)", "rgb(105, 96, 85)"),
            (BuiltInThemes.midnight, "rgb(238, 245, 255)", "rgb(169, 184, 208)")
        ] {
            let values = try await renderSidebar(ThemeCompiler().compile(theme).css)
            XCTAssertEqual(values["project"], primary)
            XCTAssertEqual(values["thread"], primary)
            XCTAssertEqual(values["hover"], primary)
            XCTAssertEqual(values["description"], secondary)
            XCTAssertEqual(values["icon"], secondary)
        }
    }

    @MainActor
    func testSidebarUsesImageSkinInkInsteadOfBasePalette() async throws {
        var skin = ThemeImageSkin()
        skin.light.primaryTextColor = "#123456"
        skin.dark.primaryTextColor = "#123456"
        skin.light.secondaryTextColor = "#654321"
        skin.dark.secondaryTextColor = "#654321"
        for var theme in [BuiltInThemes.midnight, TestFixtures.theme()] {
            theme.imageSkin = skin
            let values = try await renderSidebar(ThemeCompiler().compile(theme).css)
            XCTAssertEqual(values["project"], "rgb(18, 52, 86)")
            XCTAssertEqual(values["thread"], "rgb(18, 52, 86)")
            XCTAssertEqual(values["description"], "rgb(101, 67, 33)")
            XCTAssertEqual(values["icon"], "rgb(101, 67, 33)")
        }
    }

    @MainActor
    func testSidebarCompatibilityPreservesRawCSSOverride() async throws {
        var theme = BuiltInThemes.paper
        theme.layers[0].rawCSS += """

        aside[data-app-shell-left-panel-appearance] nav { --color-text: #123456; }
        """
        let values = try await renderSidebar(ThemeCompiler().compile(theme).css)
        XCTAssertEqual(values["project"], "rgb(18, 52, 86)")
        XCTAssertEqual(values["thread"], "rgb(18, 52, 86)")
    }

    @MainActor
    func testPaperSettingsCardOverridesNativeDarkInlineColors() async throws {
        let values = try await render(ThemeCompiler().compile(BuiltInThemes.paper).css)
        XCTAssertEqual(values["panel"], "rgb(238, 230, 215)")
        XCTAssertEqual(values["rightPanel"], "rgb(238, 230, 215)")
        XCTAssertEqual(values["rightPanelSurface"], "rgb(246, 241, 231)")
        XCTAssertEqual(values["label"], "rgb(41, 37, 31)")
        XCTAssertEqual(values["description"], "rgb(105, 96, 85)")
        XCTAssertEqual(values["directLabel"], "rgb(41, 37, 31)")
        XCTAssertEqual(values["directDescription"], "rgb(105, 96, 85)")
        XCTAssertEqual(values["baseSurface"], "rgb(246, 241, 231)")
        XCTAssertEqual(values["surfaceUnder"], "rgb(246, 241, 231)")
        XCTAssertEqual(values["primaryIcon"], "rgb(41, 37, 31)")
        XCTAssertEqual(values["primaryButton"], "rgb(246, 241, 231)")
    }

    @MainActor
    func testDarkPrimaryButtonUsesDarkInverseText() async throws {
        let values = try await render(ThemeCompiler().compile(BuiltInThemes.midnight).css)
        XCTAssertEqual(values["primaryButton"], "rgb(11, 16, 32)")
        XCTAssertEqual(values["label"], "rgb(238, 245, 255)")
    }

    @MainActor
    func testImageSkinRightPanelUsesCardColorThroughNestedSurface() async throws {
        var skin = ThemeImageSkin()
        skin.dark.cardTint = "#123456"
        skin.dark.cardOpacity = 1
        let values = try await render(
            ThemeCompiler().compile(TestFixtures.theme(imageSkin: skin)).css
        )

        XCTAssertEqual(values["rightPanel"], values["rightPanelSurface"])
        XCTAssertNotEqual(values["rightPanel"], "rgb(246, 241, 231)")
    }

    @MainActor
    func testExplicitPanelOverrideStillWinsOverGeneratedAlias() async throws {
        var theme = BuiltInThemes.paper
        theme.layers[0].variables.append(ThemeVariable(
            name: "--color-background-panel", value: "#ffffff"
        ))
        let values = try await render(ThemeCompiler().compile(theme).css)
        XCTAssertEqual(values["panel"], "rgb(255, 255, 255)")
        XCTAssertEqual(values["label"], "rgb(41, 37, 31)")
    }

    @MainActor
    func testScheduledTaskListGetsCenterPanelSurfaceWithoutPaintingOtherLists() async throws {
        var skin = ThemeImageSkin()
        skin.centerPanel.isEnabled = true
        skin.light.centerPanelTint = "#123456"
        skin.light.centerPanelOpacity = 1
        skin.light.centerPanelBorderColor = "#ABCDEF"
        skin.light.centerPanelBorderOpacity = 1
        skin.light.centerPanelShadowOpacity = 0
        let css = try ThemeCompiler()
            .compile(TestFixtures.theme(imageSkin: skin))
            .css
        let values = try await renderScheduledTaskList(css)

        XCTAssertNotEqual(values["panelBackground"], "rgba(0, 0, 0, 0)")
        XCTAssertEqual(values["panelPaddingTop"], "20px")
        XCTAssertEqual(values["panelBorderTopWidth"], "1px")
        XCTAssertEqual(values["otherListBackground"], "rgba(0, 0, 0, 0)")
    }

    @MainActor
    private func renderProjectFields(_ css: String, appearance: String) async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
        let loaded = expectation(description: "local project form fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        let nativeControl = appearance == "dark" ? "#333333" : "#f2f2f2"
        let nativeHover = appearance == "dark" ? "#404040" : "#e8e8e8"
        let nativeActive = appearance == "dark" ? "#4d4d4d" : "#dedede"
        view.loadHTMLString("""
        <!doctype html>
        <html data-theme="\(appearance)" data-codex-theme-switcher-theme="fixture"
          style="--app-color-background-control: \(nativeControl); --app-color-background-button-secondary-hover: \(nativeHover); --app-color-background-button-secondary: \(nativeActive)">
          <head><style>
            :where(:root, [data-theme]) {
              --color-background-primary-soft: var(--app-color-background-control);
              --color-background-primary-soft-hover: var(--app-color-background-button-secondary-hover);
              --color-background-primary-soft-active: var(--app-color-background-button-secondary);
              --color-background-primary-ghost-hover: var(--app-color-background-button-secondary-hover);
            }
            body { background: var(--codex-theme-background-primary); }
            input { background: transparent; }
            .bg-primary-soft { background: var(--color-background-primary-soft); }
            .text-default { color: var(--color-text); }
            input::placeholder { color: var(--color-text-secondary); opacity: 1; }
            #softHover { background: var(--color-background-primary-soft-hover); }
            #softActive { background: var(--color-background-primary-soft-active); }
            #ghostHover, .native-field:focus-within { background: var(--color-background-primary-ghost-hover); }
            \(css)
          </style></head>
          <body>
            <div class="bg-primary-soft"><input id="name" class="text-default" value="Project"></div>
            <div class="bg-primary-soft"><input id="placeholder" placeholder="Project name"></div>
            <div id="folders" class="bg-primary-soft text-default">Source folders</div>
            <div id="softHover" class="text-default">Hovered control</div>
            <div id="softActive" class="text-default">Pressed control</div>
            <div class="bg-primary-soft"><div id="ghostHover" class="text-default">Add folder</div></div>
            <div class="native-field bg-primary-soft"><input id="focusedName" class="text-default" value="Focused project"></div>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        (() => {
          document.getElementById('focusedName').focus();
          const canvas = document.createElement('canvas');
          canvas.width = canvas.height = 1;
          const context = canvas.getContext('2d');
          const luminance = rgb => {
            const channels = rgb.slice(0, 3).map(value => {
              const c = value / 255;
              return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
            });
            return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
          };
          const values = {};
          for (const id of ['name', 'placeholder', 'folders', 'softHover', 'softActive', 'ghostHover', 'focusedName']) {
            const element = document.getElementById(id);
            const ancestors = [];
            for (let node = element; node; node = node.parentElement) ancestors.unshift(node);
            context.fillStyle = '#ffffff';
            context.fillRect(0, 0, 1, 1);
            for (const node of ancestors) {
              context.fillStyle = getComputedStyle(node).backgroundColor;
              context.fillRect(0, 0, 1, 1);
            }
            const background = [...context.getImageData(0, 0, 1, 1).data];
            const color = getComputedStyle(element, id === 'placeholder' ? '::placeholder' : null).color;
            context.fillStyle = color;
            context.fillRect(0, 0, 1, 1);
            const foreground = [...context.getImageData(0, 0, 1, 1).data];
            const a = luminance(foreground), b = luminance(background);
            values[id + 'Contrast'] = String((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05));
            values[id + 'Background'] = background.slice(0, 3).join(',');
          }
          return values;
        })()
        """)
        return try XCTUnwrap(result as? [String: String])
    }

    @MainActor
    private func renderPrimaryButtons(_ css: String, appearance: String) async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 260))
        let loaded = expectation(description: "local primary button fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        view.loadHTMLString("""
        <!doctype html>
        <html data-theme="\(appearance)" data-codex-theme-switcher-theme="fixture">
          <head><style>
            :root {
              --app-color-text-foreground: #ffffff;
              --color-background-primary-solid: var(--app-color-text-foreground);
              --color-background-control-opaque: #202020;
              --color-text-primary-solid: var(--color-background-control-opaque);
              --color-background-primary-solid-hover: #ededed;
              --color-background-primary-solid-active: #dedede;
            }
            .native-button {
              --button-text-color: var(--color-text-primary-solid);
              --button-background-color: var(--color-background-primary-solid);
              --button-background-color-hover: var(--color-background-primary-solid-hover);
              --button-background-color-active: var(--color-background-primary-solid-active);
              color: var(--button-text-color);
              background-color: var(--button-background-color);
            }
            .native-button[data-preview-state=hover] { background-color: var(--button-background-color-hover); }
            .native-button[data-preview-state=active] { background-color: var(--button-background-color-active); }
            .native-notice-primary { background: var(--color-background-primary-solid); color: var(--color-text-primary-solid); }
            .text-default { color: var(--color-text); }
            \(css)
          </style></head>
          <body>
            <button id="button" class="native-button">Continue</button>
            <button id="notice" class="native-notice-primary">Use reset</button>
            <button id="hover" class="native-button" data-preview-state="hover">Continue</button>
            <button id="active" class="native-button" data-preview-state="active">Continue</button>
            <button id="ghost" class="text-default">Close</button>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        (() => {
          const canvas = document.createElement('canvas');
          canvas.width = canvas.height = 1;
          const context = canvas.getContext('2d');
          const luminance = color => {
            context.clearRect(0, 0, 1, 1);
            context.fillStyle = color;
            context.fillRect(0, 0, 1, 1);
            const rgb = [...context.getImageData(0, 0, 1, 1).data].slice(0, 3).map(value => {
              const channel = value / 255;
              return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
            });
            return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
          };
          const values = {};
          for (const id of ['button', 'notice', 'hover', 'active', 'ghost']) {
            const style = getComputedStyle(document.getElementById(id));
            values[id + 'Color'] = style.color;
            values[id + 'Background'] = style.backgroundColor;
            if (id !== 'ghost') {
              const foreground = luminance(style.color), background = luminance(style.backgroundColor);
              values[id + 'Contrast'] = String((Math.max(foreground, background) + 0.05) / (Math.min(foreground, background) + 0.05));
            }
          }
          return values;
        })()
        """)
        return try XCTUnwrap(result as? [String: String])
    }

    @MainActor
    private func renderShell(_ css: String, appearance: String = "light") async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
        let loaded = expectation(description: "local updated app shell fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        view.loadHTMLString("""
        <!doctype html>
        <html class="electron-opaque" data-theme="\(appearance)" data-codex-theme-switcher-theme="fixture">
          <head><style>
            :root { --color-surface: #eee6d7; --color-background-composer-action-bar: #252525; }
            [data-app-shell-page-surface], [data-app-shell-main-content-layout] { background: #eee6d7; }
            .sidebar-navigation { background: color-mix(in srgb, #eee6d7 65%, transparent); }
            .native-workspace::before { content: ""; background: #eee6d7; }
            [data-thread-scroll-footer], [data-thread-scroll-footer] > [aria-hidden="true"] { background: #eee6d7; }
            [data-composer-surface-variant] { --composer-layout-surface-background: #eee6d7; }
            .native-composer-body { background-color: var(--composer-layout-surface-background); }
            .native-home-rail { background-color: var(--color-background-composer-action-bar); }
            .native-edge-fade { background-image: linear-gradient(to bottom, var(--color-surface), transparent); }
            #warningRail { background-color: #ffd166; }
            #unrelated { background: linear-gradient(to top, #123456, transparent) #123456; }
            \(css)
          </style></head>
          <body>
            <div id="page" data-app-shell-page-surface="default">
              <aside data-app-shell-left-panel-appearance="default">
                <div id="sidebarInner" class="sidebar-navigation"><nav>Project</nav></div>
              </aside>
              <main id="main" data-app-shell-main-surface="default">
                <div id="workspace" class="native-workspace">
                  <div id="viewport" data-app-shell-main-content-layout="default">
                    <div data-app-shell-main-content-top-fade="visible">
                      <div id="headerFade" aria-hidden="true" class="native-edge-fade"></div>
                    </div>
                    <div class="thread-scroll-container">
                      <div>
                        <div aria-hidden="true" class="sticky">
                          <div id="transcriptFade" aria-hidden="true" class="native-edge-fade"></div>
                        </div>
                      </div>
                    </div>
                    <div id="footer" data-thread-scroll-footer="true">
                      <div id="footerSurface" aria-hidden="true"></div>
                      <div data-codex-composer-root>
                        <div id="composer" data-composer-surface-variant="default" data-composer-utility-bar-variant="home">
                          <div id="homeRail" class="native-home-rail" data-composer-rail-item="present" data-composer-placement="home">Project / This computer</div>
                          <div id="warningRail" data-composer-rail-item="present" data-composer-rail-framed>Warning</div>
                          <div id="composerBody" class="native-composer-body">Message</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </main>
            </div>
            <div data-codex-composer-root><div id="detachedRail" class="native-home-rail" data-composer-rail-item="present" data-composer-placement="home">Detached project</div></div>
            <div id="unrelated">Other content</div>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        (() => {
          const canvas = document.createElement('canvas');
          canvas.width = canvas.height = 1;
          const context = canvas.getContext('2d');
          const alpha = style => {
            context.clearRect(0, 0, 1, 1);
            context.fillStyle = style.backgroundColor;
            context.fillRect(0, 0, 1, 1);
            return String(context.getImageData(0, 0, 1, 1).data[3] / 255);
          };
          const values = Object.fromEntries(['page', 'main', 'viewport', 'sidebarInner', 'footer', 'footerSurface', 'composer', 'composerBody', 'unrelated', 'homeRail', 'detachedRail', 'warningRail'].map(id =>
            [id, alpha(getComputedStyle(document.getElementById(id)))]
          ));
          values.workspaceFade = alpha(getComputedStyle(document.getElementById('workspace'), '::before'));
          values.wallpaperColor = getComputedStyle(document.documentElement).getPropertyValue('--cts-skin-background-color').trim();
          for (const id of ['headerFade', 'transcriptFade', 'unrelated']) {
            values[id + 'Image'] = getComputedStyle(document.getElementById(id)).backgroundImage;
          }
          return values;
        })()
        """)
        return try XCTUnwrap(result as? [String: String])
    }

    @MainActor
    private func renderSidebar(_ css: String) async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 260))
        let loaded = expectation(description: "local updated sidebar fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        view.loadHTMLString("""
        <!doctype html>
        <html data-codex-theme-switcher-theme="fixture">
          <head><style>
            :root {
              --color-background-primary-solid: #ffffff;
              --app-color-text-foreground: #ffffff;
              --app-color-text-foreground-secondary: rgba(255, 255, 255, 0.71);
              --app-color-text-foreground-tertiary: rgba(255, 255, 255, 0.498);
              --color-codex-description: var(--app-color-text-foreground-tertiary);
            }
            .native-navigation {
              --color-text: var(--color-background-primary-solid);
              --color-text-primary-ghost-hover: var(--color-text);
            }
            .text-default { color: var(--color-text); }
            .text-codex-description { color: var(--color-codex-description); }
            .hover-label { color: var(--color-text-primary-ghost-hover); }
            \(css)
          </style></head>
          <body>
            <aside data-app-shell-left-panel-appearance="default">
              <span id="icon" class="text-codex-description">Icon</span>
              <nav class="native-navigation">
                <span id="project" class="text-default">Project</span>
                <span id="thread" class="text-default">Thread</span>
                <span id="hover" class="hover-label">Hover</span>
                <span id="description" class="text-codex-description">Description</span>
              </nav>
            </aside>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        Object.fromEntries(['project', 'thread', 'hover', 'description', 'icon'].map(id =>
          [id, getComputedStyle(document.getElementById(id)).color]
        ))
        """)
        return try XCTUnwrap(result as? [String: String])
    }

    @MainActor
    private func render(_ css: String) async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 260))
        let loaded = expectation(description: "local settings fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        view.loadHTMLString("""
        <!doctype html>
        <html class="electron-dark" data-codex-theme-switcher-theme="paper"
          style="--color-background-panel:#222222; --color-text-foreground:#ffffff;
                 --color-text-foreground-secondary:#aaaaaa; --color-background-surface:#181818;
                 --codex-base-surface:#181818; --codex-base-ink:#ffffff; --color-text-inverse:#0d0d0d;
                 --color-background-surface-under:#141414; --color-icon-primary:#ffffff">
          <head><style>
            .text-default { color: var(--color-text); }
            .text-secondary { color: var(--color-text-secondary); }
            \(css)
          </style></head>
          <body>
            <div id="panel" style="background-color:var(--color-background-panel, var(--color-background-primary-soft-alpha))">
              <aside data-app-shell-focus-area="right-panel">
                <div id="rightPanel" style="background-color:var(--app-shell-panel-background, var(--color-surface))">
                  <div id="rightPanelSurface" style="background-color:var(--color-surface)">Right</div>
                </div>
              </aside>
              <div id="label" class="text-default">Setting</div>
              <div id="description" class="text-secondary">Description</div>
              <span id="directLabel" style="color:var(--color-text-foreground)">Label</span>
              <span id="directDescription" style="color:var(--color-text-foreground-secondary)">Description</span>
              <div id="baseSurface" style="background-color:var(--codex-base-surface)">Base</div>
              <div id="surfaceUnder" style="background-color:var(--color-background-surface-under)">Under</div>
              <span id="primaryIcon" style="color:var(--color-icon-primary)">Icon</span>
              <button id="primaryButton" style="background:var(--color-text);color:var(--color-text-inverse)">New task</button>
            </div>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        Object.fromEntries(['panel', 'rightPanel', 'rightPanelSurface', 'label', 'description', 'directLabel', 'directDescription', 'baseSurface', 'surfaceUnder', 'primaryIcon', 'primaryButton'].map(id => {
          const style = getComputedStyle(document.getElementById(id));
          const backgroundIDs = new Set(['panel', 'rightPanel', 'rightPanelSurface', 'baseSurface', 'surfaceUnder']);
          return [id, backgroundIDs.has(id) ? style.backgroundColor : style.color];
        }))
        """)
        return try XCTUnwrap(result as? [String: String])
    }

    @MainActor
    private func renderScheduledTaskList(_ css: String) async throws -> [String: String] {
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
        let loaded = expectation(description: "local scheduled task fixture loaded")
        let navigation = LocalNavigation(loaded: loaded)
        view.navigationDelegate = navigation
        view.loadHTMLString("""
        <!doctype html>
        <html class="electron-light" data-codex-theme-switcher-theme="taipei-afterglow">
          <head><style>
            html, body, main, [data-app-shell-focus-area="main"] { margin: 0; min-height: 100%; }
            main { background: #f0c0a0; }
            #scheduled-panel { display: flex; flex-direction: column; }
            #other-list { margin-top: 20px; }
            \(css)
          </style></head>
          <body>
            <main data-app-shell-main-surface="default">
              <div data-app-shell-focus-area="main">
                <input id="scheduled-page-search" aria-label="Search scheduled tasks">
                <div id="scheduled-panel">
                  <div role="list">
                    <div role="listitem">Task one</div>
                  </div>
                </div>
              </div>
              <div id="other-list">
                <div role="list"><div role="listitem">Not a scheduled task</div></div>
              </div>
            </main>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        Object.fromEntries(['panelBackground', 'panelPaddingTop', 'panelBorderTopWidth', 'otherListBackground'].map(id => {
          const panel = document.getElementById('scheduled-panel');
          const other = document.getElementById('other-list');
          const style = id === 'otherListBackground' ? getComputedStyle(other) : getComputedStyle(panel);
          const property = id === 'panelBackground' || id === 'otherListBackground' ? 'backgroundColor' : id.replace('panel', '').replace(/^./, c => c.toLowerCase());
          return [id, style[property]];
        }))
        """)
        return try XCTUnwrap(result as? [String: String])
    }
}

@MainActor
private final class LocalNavigation: NSObject, WKNavigationDelegate {
    let loaded: XCTestExpectation
    var error: Error?

    init(loaded: XCTestExpectation) { self.loaded = loaded }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaded.fulfill()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.error = error
        loaded.fulfill()
    }
}
