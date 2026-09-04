import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeSemanticAliasTests: XCTestCase {
    func testCodex26StableTokenAliasGoldenMap() {
        let golden: [ThemeSemanticRole: [String]] = [
            .backgroundPrimary: [
                "--codex-base-surface",
                "--color-background-surface",
                "--color-background-surface-under",
                "--color-background-primary",
                "--color-token-bg-primary",
                "--color-token-main-surface-primary",
                "--main-surface-primary",
                "--bg-primary",
                "--color-surface",
                "--oai-wb-surface-primary",
                "--color-token-editor-background"
            ],
            .backgroundSecondary: [
                "--color-background-secondary",
                "--color-background-panel",
                "--color-token-bg-secondary",
                "--color-token-side-bar-background",
                "--main-surface-secondary",
                "--color-surface-secondary",
                "--color-surface-tertiary",
                "--oai-wb-surface-secondary",
                "--vscode-sideBar-background"
            ],
            .surface: [
                "--color-background-elevated-primary",
                "--color-background-elevated-primary-opaque",
                "--color-background-elevated-secondary",
                "--color-background-elevated-secondary-opaque",
                "--color-background-control",
                "--color-background-control-opaque",
                "--color-background-application-menu",
                "--color-codex-application-menu",
                "--color-surface-elevated",
                "--color-surface-elevated-secondary",
                "--color-token-input-background",
                "--color-token-editor-widget-background",
                "--color-token-menu-background",
                "--color-token-dropdown-background",
                "--bg-elevated-secondary",
                "--input",
                "--vscode-input-background"
            ],
            .textPrimary: [
                "--codex-base-ink",
                "--foreground",
                "--color-text",
                "--color-text-foreground",
                "--color-icon-primary",
                "--color-text-primary",
                "--color-text-primary-solid",
                "--color-foreground-application-menu",
                "--color-token-dropdown-foreground",
                "--color-text-emphasis",
                "--color-token-foreground",
                "--color-token-text-primary",
                "--color-token-editor-foreground",
                "--oai-wb-text-primary",
                "--vscode-foreground"
            ],
            .textSecondary: [
                "--muted-foreground",
                "--color-text-foreground-secondary",
                "--color-text-foreground-tertiary",
                "--color-text-secondary",
                "--color-text-tertiary",
                "--color-icon-secondary",
                "--color-icon-tertiary",
                "--color-text-button-secondary",
                "--color-text-button-tertiary",
                "--color-token-text-secondary",
                "--color-token-description-foreground",
                "--color-token-input-placeholder-foreground",
                "--oai-wb-text-secondary",
                "--vscode-descriptionForeground"
            ],
            .accent: [
                "--codex-base-accent",
                "--accent",
                "--primary",
                "--color-background-accent",
                "--color-text-accent",
                "--color-icon-accent",
                "--color-token-primary",
                "--color-token-link",
                "--color-token-text-link-foreground",
                "--color-token-interactive-label-accent-default",
                "--interactive-bg-accent-default",
                "--oai-wb-accent"
            ],
            .border: [
                "--border",
                "--color-border",
                "--color-border-primary",
                "--color-border-light",
                "--color-border-heavy",
                "--color-border-subtle",
                "--color-border-strong",
                "--color-border-application-menu-separator",
                "--color-token-border",
                "--color-token-border-default",
                "--color-token-input-border",
                "--color-token-menu-border",
                "--oai-wb-border",
                "--vscode-panel-border"
            ],
            .success: [
                "--color-text-success",
                "--color-icon-success",
                "--color-border-success",
                "--color-background-status-success",
                "--color-token-git-decoration-added-resource-foreground",
                "--diffs-addition-color",
                "--diffs-addition-color-override",
                "--codex-diffs-addition-number",
                "--state-success"
            ],
            .warning: [
                "--color-text-warning",
                "--color-icon-warning",
                "--color-border-warning",
                "--color-background-status-warning",
                "--color-token-editor-warning-foreground",
                "--color-token-git-decoration-modified-resource-foreground",
                "--diffs-modified-color",
                "--diffs-modified-color-override",
                "--viz-warning"
            ],
            .error: [
                "--color-text-error",
                "--color-icon-error",
                "--color-border-error",
                "--color-background-status-error",
                "--color-token-error-foreground",
                "--color-token-editor-error-foreground",
                "--color-token-git-decoration-deleted-resource-foreground",
                "--diffs-deletion-color",
                "--diffs-deletion-color-override",
                "--codex-diffs-deletion-number",
                "--state-error"
            ]
        ]

        XCTAssertEqual(Set(golden.keys), Set(ThemeSemanticRole.allCases))
        for role in ThemeSemanticRole.allCases {
            XCTAssertEqual(
                role.codexStableTokenAliases,
                golden[role],
                "Stable alias map changed for \(role.rawValue)"
            )
        }
    }

    func testCompilerEmitsEverySemanticAliasAndLeavesCustomTokensLast() throws {
        let semanticVariables = ThemeSemanticRole.allCases.enumerated().map {
            ThemeVariable(
                value: "semantic-\($0.offset)",
                semanticRole: $0.element
            )
        }
        // Deliberately place the custom alias first in the model. The compiler
        // must move it after generated aliases so expert overrides always win.
        let customAlias = ThemeVariable(
            name: "--color-token-primary",
            value: "#custom-accent"
        )
        let document = ThemeDocument(
            metadata: ThemeMetadata(name: "Alias Golden"),
            layers: [
                ThemeLayer(
                    name: "All roles",
                    variables: [customAlias] + semanticVariables,
                    rawCSS: ":root { --color-token-link: #raw-link-override; }"
                )
            ]
        )

        let css = try ThemeCompiler().compile(document).css

        for role in ThemeSemanticRole.allCases {
            for alias in role.codexStableTokenAliases {
                XCTAssertTrue(
                    css.contains("  \(alias): var(\(role.cssVariableName));")
                        || css.contains("  \(alias): var(\(role.cssVariableName)) !important;"),
                    "Missing \(alias) for \(role.rawValue)"
                )
            }
        }

        let generatedAccent = try XCTUnwrap(
            css.range(of: "  --color-token-primary: var(--codex-theme-accent);")
        )
        let customAccent = try XCTUnwrap(
            css.range(of: "  --color-token-primary: #custom-accent;")
        )
        let generatedLink = try XCTUnwrap(
            css.range(of: "  --color-token-link: var(--codex-theme-accent);")
        )
        let rawLink = try XCTUnwrap(
            css.range(of: ":root { --color-token-link: #raw-link-override; }")
        )

        XCTAssertLessThan(generatedAccent.lowerBound, customAccent.lowerBound)
        XCTAssertLessThan(generatedLink.lowerBound, rawLink.lowerBound)
    }

    func testNativeInlineColorsAreOverriddenWithoutLosingExplicitCustomValues() throws {
        let document = ThemeDocument(
            metadata: ThemeMetadata(name: "Native settings colors"),
            layers: [ThemeLayer(name: "Colors", variables: [
                ThemeVariable(name: "--color-background-panel", value: "#faf7f0"),
                ThemeVariable(value: "#eee8da", semanticRole: .backgroundSecondary),
                ThemeVariable(value: "#29251f", semanticRole: .textPrimary),
                ThemeVariable(value: "#676057", semanticRole: .textSecondary),
                ThemeVariable(name: "--color-border", value: "#c8bdaa !important")
            ])]
        )
        let css = try ThemeCompiler().compile(document).css
        let generated = try XCTUnwrap(css.range(of:
            "--color-background-panel: var(--codex-theme-background-secondary) !important;"
        ))
        let custom = try XCTUnwrap(css.range(of:
            "--color-background-panel: #faf7f0 !important;"
        ))
        XCTAssertLessThan(generated.lowerBound, custom.lowerBound)
        XCTAssertTrue(css.contains(
            "--color-text-foreground: var(--codex-theme-text-primary) !important;"
        ))
        XCTAssertTrue(css.contains(
            "--color-text-foreground-secondary: var(--codex-theme-text-secondary) !important;"
        ))
        XCTAssertTrue(css.contains("--color-border: #c8bdaa !important;"))
        XCTAssertFalse(css.contains("!important !important"))
        XCTAssertTrue(css.contains("--codex-theme-text-primary: #29251f;"))
    }

    func testImageSkinCardsOverrideNativePanelButRespectDisabledCardTarget() throws {
        var theme = BuiltInThemes.paper
        theme.imageSkin = ThemeImageSkin()
        let enabled = try ThemeCompiler().compile(theme).css
        XCTAssertTrue(enabled.contains(
            "--color-background-panel: var(--cts-skin-card) !important;"
        ))
        XCTAssertTrue(enabled.contains(
            "--color-background-elevated-primary: var(--cts-skin-card) !important;"
        ))
        XCTAssertTrue(enabled.contains(
            "--color-text-foreground: var(--cts-skin-text-primary) !important;"
        ))
        theme.imageSkin?.targets.cards = false
        let disabled = try ThemeCompiler().compile(theme).css
        XCTAssertFalse(disabled.contains(
            "--color-background-panel: var(--cts-skin-card)"
        ))
    }
}
