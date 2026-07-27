import Foundation

public enum ThemeCompilationWarningCode: String, Codable, Equatable, Sendable {
    case unknownComponent
    case emptyRule
}

public struct ThemeCompilationWarning: Codable, Equatable, Sendable, Identifiable {
    public var id: String {
        "\(code.rawValue):\(path):\(message)"
    }

    public var code: ThemeCompilationWarningCode
    public var path: String
    public var message: String

    public init(code: ThemeCompilationWarningCode, path: String, message: String) {
        self.code = code
        self.path = path
        self.message = message
    }
}

public struct CompiledTheme: Equatable, Sendable {
    public var themeID: UUID
    public var css: String
    public var warnings: [ThemeCompilationWarning]
    public var inlinedAssetIDs: Set<UUID>

    public init(
        themeID: UUID,
        css: String,
        warnings: [ThemeCompilationWarning] = [],
        inlinedAssetIDs: Set<UUID> = []
    ) {
        self.themeID = themeID
        self.css = css
        self.warnings = warnings
        self.inlinedAssetIDs = inlinedAssetIDs
    }
}

public enum ThemeCompilationError: LocalizedError, Equatable, Sendable {
    case validationFailed(ThemeValidationError)
    case missingAsset(UUID)
    case malformedAssetReference(String)

    public var errorDescription: String? {
        switch self {
        case let .validationFailed(error):
            return error.localizedDescription
        case let .missingAsset(id):
            return "CSS references missing theme asset \(id.uuidString)."
        case let .malformedAssetReference(reference):
            return "Malformed theme asset reference: \(reference)"
        }
    }
}

/// Maps stable editor component IDs to selectors used by the current Codex UI.
///
/// The catalog is injectable so a runtime-specific selector profile can replace
/// these conservative defaults without changing `ThemeDocument`.
public struct ThemeComponentCatalog: Codable, Equatable, Sendable {
    public var selectorsByComponentID: [String: [String]]

    public init(selectorsByComponentID: [String: [String]]) {
        self.selectorsByComponentID = selectorsByComponentID
    }

    public func selectors(for componentID: String) -> [String]? {
        selectorsByComponentID[componentID]
    }

    public static let `default` = ThemeComponentCatalog(
        selectorsByComponentID: [
            "app": [
                "html",
                "body",
                "#root"
            ],
            "titlebar": [
                ".app-header-tint"
            ],
            "sidebar": [
                "aside.app-shell-left-panel"
            ],
            "navigation": [
                "aside.app-shell-left-panel nav"
            ],
            "conversation": [
                "main.main-surface",
                "[data-app-shell-main-content-layout]",
                ".app-shell-main-content-frame"
            ],
            "userMessage": [
                "[data-message-author-role=\"user\"]"
            ],
            "assistantMessage": [
                "[data-message-author-role=\"assistant\"]"
            ],
            "composer": [
                "[data-codex-composer-root] .composer-surface-chrome"
            ],
            "composerTray": [
                "[data-codex-composer-root]",
                "[data-codex-composer-request-navigation]",
                "[data-codex-approval-surface]"
            ],
            "homeCard": [
                "[data-home-ambient-suggestions] button[aria-labelledby]"
            ],
            "projectPicker": [
                "[data-composer-navigation-target=\"workspace-project\"]",
                "[data-radix-popper-content-wrapper]:has([cmdk-root]) > [data-state=\"open\"]"
            ],
            "button": [
                "button"
            ],
            "input": [
                "input",
                "textarea",
                "[contenteditable=\"true\"]"
            ],
            "menu": [
                "[role=\"menu\"]"
            ],
            "popover": [
                "[data-radix-popper-content-wrapper] > [data-state=\"open\"]"
            ],
            "dialog": [
                "[role=\"dialog\"]"
            ],
            "codeBlock": [
                "pre"
            ],
            "inlineCode": [
                ":not(pre) > code"
            ],
            "scrollbar": [
                "::-webkit-scrollbar"
            ]
        ]
    )
}

public struct ThemeCompiler: Sendable {
    public var validator: ThemeValidator
    public var componentCatalog: ThemeComponentCatalog

    public init(
        validator: ThemeValidator = ThemeValidator(),
        componentCatalog: ThemeComponentCatalog = .default
    ) {
        self.validator = validator
        self.componentCatalog = componentCatalog
    }

    public func compile(_ document: ThemeDocument) throws -> CompiledTheme {
        let validation = validator.validate(document)
        guard validation.isValid else {
            throw ThemeCompilationError.validationFailed(
                ThemeValidationError(issues: validation.issues)
            )
        }

        var output: [String] = [
            "/* Codex Theme: \(CSSEscaper.escapeComment(document.metadata.name)) */",
            "/* Theme ID: \(document.id.uuidString.lowercased()) */"
        ]
        var warnings: [ThemeCompilationWarning] = []
        var advancedCSSOutput: [String] = []

        for (layerIndex, layer) in document.layers.enumerated() where layer.isEnabled {
            var body: [String] = [
                "/* Layer: \(CSSEscaper.escapeComment(layer.name)) */"
            ]

            let variables = layer.variables.filter(\.isEnabled)
            if !variables.isEmpty {
                body.append(":root {")
                // Semantic roles are emitted first so their Codex compatibility
                // aliases reach native surfaces. Arbitrary variables are emitted
                // afterwards regardless of editor ordering, so they override the
                // structured semantic aliases within this layer.
                for variable in variables where variable.semanticRole != nil {
                    body.append("  \(variable.resolvedName): \(variable.value);")
                    if let role = variable.semanticRole {
                        for alias in role.codexStableTokenAliases
                        where alias != variable.resolvedName {
                            body.append(
                                "  \(alias): var(\(variable.resolvedName));"
                            )
                        }
                    }
                }
                for variable in variables where variable.semanticRole == nil {
                    body.append("  \(variable.resolvedName): \(variable.value);")
                }
                body.append("}")
            }

            for (componentIndex, component) in layer.components.enumerated()
            where component.isEnabled {
                let path = "layers[\(layerIndex)].components[\(componentIndex)]"
                let selectors: [String]
                if component.selectors.isEmpty {
                    guard let catalogSelectors = componentCatalog.selectors(for: component.componentID),
                          !catalogSelectors.isEmpty else {
                        warnings.append(
                            ThemeCompilationWarning(
                                code: .unknownComponent,
                                path: path,
                                message: "No selectors are registered for component \(component.componentID)."
                            )
                        )
                        continue
                    }
                    selectors = catalogSelectors
                } else {
                    selectors = component.selectors
                }

                guard let block = declarationBlock(
                    selectors: selectors,
                    declarations: component.declarations
                ) else {
                    warnings.append(
                        ThemeCompilationWarning(
                            code: .emptyRule,
                            path: path,
                            message: "The component has no enabled declarations."
                        )
                    )
                    continue
                }
                body.append(block)
            }

            for (ruleIndex, rule) in layer.rules.enumerated() where rule.isEnabled {
                let path = "layers[\(layerIndex)].rules[\(ruleIndex)]"
                guard let block = declarationBlock(
                    selectors: [rule.selector],
                    declarations: rule.declarations
                ) else {
                    warnings.append(
                        ThemeCompilationWarning(
                            code: .emptyRule,
                            path: path,
                            message: "The rule has no enabled declarations."
                        )
                    )
                    continue
                }
                body.append(block)
            }

            let rawCSS = layer.rawCSS.trimmingCharacters(in: .whitespacesAndNewlines)
            if !rawCSS.isEmpty {
                advancedCSSOutput.append(
                    conditionedCSS(
                        for: layer,
                        css: """
                        /* Advanced CSS: \(CSSEscaper.escapeComment(layer.name)) */
                        \(rawCSS)
                        """
                    )
                )
            }

            let layerCSS = body.joined(separator: "\n")
            output.append(conditionedCSS(for: layer, css: layerCSS))
        }

        // Image Skin intentionally sits after all structured editor output so its
        // high-level visual controls take effect, but before Raw CSS so expert
        // declarations remain the true final escape hatch.
        if let imageSkin = document.imageSkin, imageSkin.isEnabled {
            output.append(ThemeImageSkinCompiler.compile(imageSkin))
        }
        output.append(contentsOf: advancedCSSOutput)

        let unresolvedCSS = output.joined(separator: "\n\n") + "\n"
        let inlined = try inlineAssets(in: unresolvedCSS, assets: document.assets)

        return CompiledTheme(
            themeID: document.id,
            css: inlined.css,
            warnings: warnings,
            inlinedAssetIDs: inlined.ids
        )
    }

    private func declarationBlock(
        selectors: [String],
        declarations: [ThemeCSSDeclaration]
    ) -> String? {
        let enabled = declarations.filter(\.isEnabled)
        guard !enabled.isEmpty else {
            return nil
        }

        let selectorText = selectors
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: ",\n")
        var lines = ["\(selectorText) {"]
        for declaration in enabled {
            let important = declaration.isImportant ? " !important" : ""
            lines.append("  \(declaration.property): \(declaration.value)\(important);")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func wrapInMedia(_ query: String, css: String) -> String {
        let indented = css
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  \($0)" }
            .joined(separator: "\n")
        return "@media \(query) {\n\(indented)\n}"
    }

    private func conditionedCSS(
        for layer: ThemeLayer,
        css: String
    ) -> String {
        switch layer.condition {
        case .always:
            return css
        case .light:
            return wrapInMedia("(prefers-color-scheme: light)", css: css)
        case .dark:
            return wrapInMedia("(prefers-color-scheme: dark)", css: css)
        case .custom:
            // The validator guarantees this is present and brace-free.
            return wrapInMedia(layer.mediaQuery ?? "all", css: css)
        }
    }

    private func inlineAssets(
        in css: String,
        assets: [ThemeAsset]
    ) throws -> (css: String, ids: Set<UUID>) {
        let assetsByID = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        guard let expression = try? NSRegularExpression(
            pattern: #"(?i)theme-asset\s*\(\s*(["']?)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\1\s*\)"#
        ) else {
            return (css, [])
        }

        var result = css
        let fullRange = NSRange(css.startIndex..<css.endIndex, in: css)
        let matches = expression.matches(in: css, range: fullRange)
        var referencedIDs = Set<UUID>()

        for match in matches.reversed() {
            guard
                match.numberOfRanges > 2,
                let idRange = Range(match.range(at: 2), in: result),
                let fullMatchRange = Range(match.range(at: 0), in: result),
                let id = UUID(uuidString: String(result[idRange]))
            else {
                continue
            }
            guard let asset = assetsByID[id] else {
                throw ThemeCompilationError.missingAsset(id)
            }
            guard asset.decodedData != nil else {
                // Invalid Base64 normally fails validation. Keep a precise error if
                // a custom validator configuration is introduced later.
                throw ThemeCompilationError.malformedAssetReference(id.uuidString)
            }
            let replacement = #"url("data:\#(asset.mediaType);base64,\#(asset.dataBase64)")"#
            result.replaceSubrange(fullMatchRange, with: replacement)
            referencedIDs.insert(id)
        }

        if let malformedRange = result.range(
            of: #"(?i)theme-asset\s*\("#,
            options: .regularExpression
        ) {
            let suffix = result[malformedRange.lowerBound...]
            let preview = String(suffix.prefix(80))
            throw ThemeCompilationError.malformedAssetReference(preview)
        }

        return (result, referencedIDs)
    }
}

public enum CSSEscaper {
    /// Escapes arbitrary text as a CSS identifier.
    public static func escapeIdentifier(_ value: String) -> String {
        if value.isEmpty {
            return "\\0 "
        }

        var result = ""
        for (index, scalar) in value.unicodeScalars.enumerated() {
            let isASCIIUpper = scalar.value >= 65 && scalar.value <= 90
            let isASCIILower = scalar.value >= 97 && scalar.value <= 122
            let isDigit = scalar.value >= 48 && scalar.value <= 57
            let isSafePunctuation = scalar == "-" || scalar == "_"
            let needsLeadingDigitEscape = index == 0 && isDigit

            if (isASCIIUpper || isASCIILower || isDigit || isSafePunctuation)
                && !needsLeadingDigitEscape {
                result.unicodeScalars.append(scalar)
            } else {
                result += "\\\(String(scalar.value, radix: 16)) "
            }
        }
        return result
    }

    /// Escapes text for use inside a double-quoted CSS string.
    public static func escapeString(_ value: String) -> String {
        var result = ""
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22:
                result += "\\\""
            case 0x5C:
                result += "\\\\"
            case 0x0A:
                result += "\\a "
            case 0x0D:
                result += "\\d "
            case 0x0C:
                result += "\\c "
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// Prevents user-provided labels from terminating generated comments.
    public static func escapeComment(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/*", with: "/\\*")
            .replacingOccurrences(of: "*/", with: "*\\/")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
