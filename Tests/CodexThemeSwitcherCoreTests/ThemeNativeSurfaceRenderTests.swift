import Foundation
import WebKit
import XCTest
@testable import CodexThemeSwitcherCore

/// Exercise the CSS cascade in a separate local WebKit document, not in the
/// user's running Codex window. Native inline tokens previously beat :root
/// aliases, leaving settings panels dark while their text became dark too.
final class ThemeNativeSurfaceRenderTests: XCTestCase {
    @MainActor
    func testPaperSettingsCardOverridesNativeDarkInlineColors() async throws {
        let values = try await render(ThemeCompiler().compile(BuiltInThemes.paper).css)
        XCTAssertEqual(values["panel"], "rgb(238, 230, 215)")
        XCTAssertEqual(values["label"], "rgb(41, 37, 31)")
        XCTAssertEqual(values["description"], "rgb(105, 96, 85)")
        XCTAssertEqual(values["directLabel"], "rgb(41, 37, 31)")
        XCTAssertEqual(values["directDescription"], "rgb(105, 96, 85)")
        XCTAssertEqual(values["baseSurface"], "rgb(246, 241, 231)")
        XCTAssertEqual(values["surfaceUnder"], "rgb(246, 241, 231)")
        XCTAssertEqual(values["primaryIcon"], "rgb(41, 37, 31)")
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
                 --codex-base-surface:#181818; --codex-base-ink:#ffffff;
                 --color-background-surface-under:#141414; --color-icon-primary:#ffffff">
          <head><style>
            .text-default { color: var(--color-text); }
            .text-secondary { color: var(--color-text-secondary); }
            \(css)
          </style></head>
          <body>
            <div id="panel" style="background-color:var(--color-background-panel, var(--color-background-primary-soft-alpha))">
              <div id="label" class="text-default">Setting</div>
              <div id="description" class="text-secondary">Description</div>
              <span id="directLabel" style="color:var(--color-text-foreground)">Label</span>
              <span id="directDescription" style="color:var(--color-text-foreground-secondary)">Description</span>
              <div id="baseSurface" style="background-color:var(--codex-base-surface)">Base</div>
              <div id="surfaceUnder" style="background-color:var(--color-background-surface-under)">Under</div>
              <span id="primaryIcon" style="color:var(--color-icon-primary)">Icon</span>
            </div>
          </body>
        </html>
        """, baseURL: nil)
        await fulfillment(of: [loaded], timeout: 10)
        if let error = navigation.error { throw error }
        let result = try await view.evaluateJavaScript("""
        Object.fromEntries(['panel', 'label', 'description', 'directLabel', 'directDescription', 'baseSurface', 'surfaceUnder', 'primaryIcon'].map(id => {
          const style = getComputedStyle(document.getElementById(id));
          const backgroundIDs = new Set(['panel', 'baseSurface', 'surfaceUnder']);
          return [id, backgroundIDs.has(id) ? style.backgroundColor : style.color];
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
