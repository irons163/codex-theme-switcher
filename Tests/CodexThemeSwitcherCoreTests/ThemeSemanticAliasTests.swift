import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeSemanticAliasTests: XCTestCase {
    func testCodex26StableTokenAliasGoldenMap() {
        let golden: [ThemeSemanticRole: [String]] = [
            .backgroundPrimary: [
                "--codex-base-surface",
                "--color-background-surface",
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
                "--oai-wb-surface-secondary",
                "--vscode-sideBar-background"
            ],
            .surface: [
                "--color-background-elevated-primary",
                "--color-background-elevated-primary-opaque",
                "--color-background-control",
                "--color-surface-elevated",
                "--color-token-input-background",
                "--color-token-editor-widget-background",
                "--color-token-menu-background",
                "--bg-elevated-secondary",
                "--input",
                "--vscode-input-background"
            ],
            .textPrimary: [
                "--codex-base-ink",
                "--foreground",
                "--color-text",
                "--color-text-foreground",
                "--color-text-primary",
                "--color-token-foreground",
                "--color-token-text-primary",
                "--color-token-editor-foreground",
                "--oai-wb-text-primary",
                "--vscode-foreground"
            ],
            .textSecondary: [
                "--muted-foreground",
                "--color-text-foreground-secondary",
                "--color-text-secondary",
                "--color-icon-secondary",
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
                    css.contains("  \(alias): var(\(role.cssVariableName));"),
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
}
