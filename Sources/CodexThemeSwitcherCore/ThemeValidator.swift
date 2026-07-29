import Foundation

public enum ThemeValidationSeverity: String, Codable, Equatable, Sendable {
    case warning
    case error
}

public enum ThemeValidationCode: String, Codable, Equatable, Sendable {
    case unsupportedSchema
    case emptyThemeName
    case emptyLayerName
    case duplicateIdentifier
    case invalidVariableName
    case emptyVariableValue
    case emptyComponentIdentifier
    case missingComponentSelector
    case invalidSelector
    case invalidDeclarationProperty
    case emptyDeclarationValue
    case invalidMediaQuery
    case unsafeImport
    case unsafeURL
    case invalidAssetName
    case invalidAssetMediaType
    case invalidAssetData
    case assetTooLarge
    case totalAssetsTooLarge
    case cssTooLarge
    case missingSkinAsset
    case invalidSkinAssetType
    case invalidSkinNumber
    case invalidSkinCSSValue
}

public struct ThemeValidationIssue: Codable, Equatable, Sendable, Identifiable {
    public var id: String {
        "\(severity.rawValue):\(code.rawValue):\(path):\(message)"
    }

    public var severity: ThemeValidationSeverity
    public var code: ThemeValidationCode
    public var path: String
    public var message: String

    public init(
        severity: ThemeValidationSeverity,
        code: ThemeValidationCode,
        path: String,
        message: String
    ) {
        self.severity = severity
        self.code = code
        self.path = path
        self.message = message
    }
}

public struct ThemeValidationResult: Codable, Equatable, Sendable {
    public var issues: [ThemeValidationIssue]

    public init(issues: [ThemeValidationIssue] = []) {
        self.issues = issues
    }

    public var errors: [ThemeValidationIssue] {
        issues.filter { $0.severity == .error }
    }

    public var warnings: [ThemeValidationIssue] {
        issues.filter { $0.severity == .warning }
    }

    public var isValid: Bool {
        errors.isEmpty
    }
}

public struct ThemeValidationError: LocalizedError, Equatable, Sendable {
    public var issues: [ThemeValidationIssue]

    public init(issues: [ThemeValidationIssue]) {
        self.issues = issues
    }

    public var errorDescription: String? {
        let summary = issues
            .filter { $0.severity == .error }
            .prefix(3)
            .map { "\($0.path): \($0.message)" }
            .joined(separator: "\n")
        return summary.isEmpty ? "Theme validation failed." : summary
    }
}

public struct ThemeValidator: Sendable {
    public struct Configuration: Codable, Equatable, Sendable {
        public var maximumAssetBytes: Int
        public var maximumTotalAssetBytes: Int
        public var maximumCSSCharacters: Int

        public init(
            maximumAssetBytes: Int = 16 * 1_024 * 1_024,
            maximumTotalAssetBytes: Int = 32 * 1_024 * 1_024,
            maximumCSSCharacters: Int = 1_000_000
        ) {
            self.maximumAssetBytes = maximumAssetBytes
            self.maximumTotalAssetBytes = maximumTotalAssetBytes
            self.maximumCSSCharacters = maximumCSSCharacters
        }

        public static let `default` = Configuration()
    }

    public var configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    public func validate(_ document: ThemeDocument) -> ThemeValidationResult {
        var issues: [ThemeValidationIssue] = []
        var identifiers = Set<UUID>()

        func add(
            _ code: ThemeValidationCode,
            path: String,
            message: String,
            severity: ThemeValidationSeverity = .error
        ) {
            issues.append(
                ThemeValidationIssue(
                    severity: severity,
                    code: code,
                    path: path,
                    message: message
                )
            )
        }

        func register(_ id: UUID, path: String) {
            if !identifiers.insert(id).inserted {
                add(
                    .duplicateIdentifier,
                    path: path,
                    message: "Identifier \(id.uuidString) is used more than once."
                )
            }
        }

        if document.schemaVersion != ThemeDocument.currentSchemaVersion {
            add(
                .unsupportedSchema,
                path: "schemaVersion",
                message: "Schema \(document.schemaVersion) is unsupported; expected \(ThemeDocument.currentSchemaVersion)."
            )
        }

        if document.metadata.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            add(.emptyThemeName, path: "metadata.name", message: "A theme name is required.")
        }

        var totalCSSCharacters = 0

        for (layerIndex, layer) in document.layers.enumerated() {
            let layerPath = "layers[\(layerIndex)]"
            register(layer.id, path: "\(layerPath).id")

            if layer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                add(.emptyLayerName, path: "\(layerPath).name", message: "A layer name is required.")
            }

            switch layer.condition {
            case .custom:
                let query = layer.mediaQuery?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if query.isEmpty || query.contains("{") || query.contains("}") {
                    add(
                        .invalidMediaQuery,
                        path: "\(layerPath).mediaQuery",
                        message: "A custom condition requires a media query without braces."
                    )
                }
            case .always, .light, .dark:
                break
            }

            if let mediaQuery = layer.mediaQuery {
                appendSecurityIssues(
                    in: mediaQuery,
                    path: "\(layerPath).mediaQuery",
                    to: &issues
                )
            }

            for (variableIndex, variable) in layer.variables.enumerated() {
                let path = "\(layerPath).variables[\(variableIndex)]"
                register(variable.id, path: "\(path).id")
                if !Self.isValidVariableName(variable.resolvedName) {
                    add(
                        .invalidVariableName,
                        path: "\(path).name",
                        message: "CSS variable names must begin with -- and contain only letters, digits, _ or -."
                    )
                }
                if variable.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    add(.emptyVariableValue, path: "\(path).value", message: "A variable value is required.")
                }
                totalCSSCharacters += variable.value.count
                appendSecurityIssues(in: variable.value, path: "\(path).value", to: &issues)
            }

            for (componentIndex, component) in layer.components.enumerated() {
                let path = "\(layerPath).components[\(componentIndex)]"
                register(component.id, path: "\(path).id")
                if component.componentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    add(
                        .emptyComponentIdentifier,
                        path: "\(path).componentID",
                        message: "A component identifier is required."
                    )
                }
                for (selectorIndex, selector) in component.selectors.enumerated() {
                    if !Self.isValidSelector(selector) {
                        add(
                            .invalidSelector,
                            path: "\(path).selectors[\(selectorIndex)]",
                            message: "A selector must not be empty or contain declaration braces."
                        )
                    }
                    appendSecurityIssues(
                        in: selector,
                        path: "\(path).selectors[\(selectorIndex)]",
                        to: &issues
                    )
                    totalCSSCharacters += selector.count
                }
                validateDeclarations(
                    component.declarations,
                    at: "\(path).declarations",
                    identifiers: &identifiers,
                    issues: &issues,
                    totalCSSCharacters: &totalCSSCharacters
                )
            }

            for (ruleIndex, rule) in layer.rules.enumerated() {
                let path = "\(layerPath).rules[\(ruleIndex)]"
                register(rule.id, path: "\(path).id")
                if !Self.isValidSelector(rule.selector) {
                    add(
                        .invalidSelector,
                        path: "\(path).selector",
                        message: "A selector must not be empty or contain declaration braces."
                    )
                }
                appendSecurityIssues(
                    in: rule.selector,
                    path: "\(path).selector",
                    to: &issues
                )
                totalCSSCharacters += rule.selector.count
                validateDeclarations(
                    rule.declarations,
                    at: "\(path).declarations",
                    identifiers: &identifiers,
                    issues: &issues,
                    totalCSSCharacters: &totalCSSCharacters
                )
            }

            totalCSSCharacters += layer.rawCSS.count
            appendSecurityIssues(in: layer.rawCSS, path: "\(layerPath).rawCSS", to: &issues)
        }

        if let skin = document.imageSkin {
            let appearances: [
                (name: String, value: ThemeSkinVariant)
            ] = [
                ("light", skin.light),
                ("dark", skin.dark)
            ]
            let allowedImageTypes: Set<String> = [
                "image/png",
                "image/jpeg",
                "image/webp",
                "image/gif",
                "image/avif"
            ]

            for appearance in appearances {
                let path = "imageSkin.\(appearance.name)"
                let variant = appearance.value
                if let assetID = variant.backgroundAssetID {
                    if let asset = document.assets.first(
                        where: { $0.id == assetID }
                    ) {
                        if !allowedImageTypes.contains(
                            asset.mediaType.lowercased()
                        ) {
                            add(
                                .invalidSkinAssetType,
                                path: "\(path).backgroundAssetID",
                                message: "Image skins require a supported raster image asset."
                            )
                        }
                    } else {
                        add(
                            .missingSkinAsset,
                            path: "\(path).backgroundAssetID",
                            message: "Image skin references missing asset \(assetID.uuidString)."
                        )
                    }
                }

                var cssValues: [(String, String)] = [
                    ("backgroundColor", variant.backgroundColor),
                    ("overlayColor", variant.overlayColor),
                    ("primaryTextColor", variant.primaryTextColor),
                    ("secondaryTextColor", variant.secondaryTextColor),
                    ("accentColor", variant.accentColor),
                    ("sidebarTint", variant.sidebarTint),
                    ("contentTint", variant.contentTint),
                    ("composerTint", variant.composerTint),
                    ("cardTint", variant.cardTint),
                    ("borderColor", variant.borderColor),
                    ("centerPanelTint", variant.centerPanelTint),
                    ("centerPanelBorderColor", variant.centerPanelBorderColor),
                    ("centerPanelShadowColor", variant.centerPanelShadowColor)
                ]
                if let value = variant.composerActionBackgroundColor {
                    cssValues.append(
                        ("composerActionBackgroundColor", value)
                    )
                }
                if let value = variant.composerActionIconColor {
                    cssValues.append(
                        ("composerActionIconColor", value)
                    )
                }
                for (name, value) in cssValues {
                    totalCSSCharacters += value.count
                    let valuePath = "\(path).\(name)"
                    if value.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                        || value.contains(";")
                        || value.contains("{")
                        || value.contains("}")
                        || value.localizedCaseInsensitiveContains("!important")
                        || value.contains("/*")
                        || value.contains("*/")
                        || value.contains("@")
                        || value.unicodeScalars.contains(where: {
                            $0.value < 0x20 || $0.value == 0x7F
                        }) {
                        add(
                            .invalidSkinCSSValue,
                            path: valuePath,
                            message: "Skin colors must be one CSS color value without declaration delimiters."
                        )
                    }
                    appendSecurityIssues(
                        in: value,
                        path: valuePath,
                        to: &issues
                    )
                }

                let unitValues: [(String, Double)] = [
                    ("positionX", variant.positionX),
                    ("positionY", variant.positionY),
                    ("imageOpacity", variant.imageOpacity),
                    ("overlayOpacity", variant.overlayOpacity),
                    ("scrimOpacity", variant.scrimOpacity),
                    ("vignetteOpacity", variant.vignetteOpacity),
                    ("sidebarOpacity", variant.sidebarOpacity),
                    ("contentOpacity", variant.contentOpacity),
                    ("composerOpacity", variant.composerOpacity),
                    ("cardOpacity", variant.cardOpacity),
                    ("borderOpacity", variant.borderOpacity),
                    ("centerPanelOpacity", variant.centerPanelOpacity),
                    ("centerPanelBorderOpacity", variant.centerPanelBorderOpacity),
                    ("centerPanelShadowOpacity", variant.centerPanelShadowOpacity)
                ]
                for (name, value) in unitValues
                where !value.isFinite || !(0...1).contains(value) {
                    add(
                        .invalidSkinNumber,
                        path: "\(path).\(name)",
                        message: "Skin value must be finite and between 0 and 1."
                    )
                }

                let ranges: [(String, Double, ClosedRange<Double>)] = [
                    ("zoom", variant.zoom, 0.5...3),
                    ("imageBlur", variant.imageBlur, 0...80),
                    ("brightness", variant.brightness, 0...3),
                    ("contrast", variant.contrast, 0...3),
                    ("saturation", variant.saturation, 0...3)
                ]
                for (name, value, range) in ranges
                where !value.isFinite || !range.contains(value) {
                    add(
                        .invalidSkinNumber,
                        path: "\(path).\(name)",
                        message: "Skin value is outside the supported range."
                    )
                }
            }

            let glassValues: [
                (name: String, value: Double, range: ClosedRange<Double>)
            ] = [
                ("blurRadius", skin.glass.blurRadius, 0...80),
                ("saturation", skin.glass.saturation, 0...3),
                ("borderWidth", skin.glass.borderWidth, 0...8),
                ("cornerRadius", skin.glass.cornerRadius, 0...64),
                ("shadowOpacity", skin.glass.shadowOpacity, 0...1),
                ("shadowBlur", skin.glass.shadowBlur, 0...120),
                ("textShadowOpacity", skin.glass.textShadowOpacity, 0...1)
            ]
            for item in glassValues
            where !item.value.isFinite || !item.range.contains(item.value) {
                add(
                    .invalidSkinNumber,
                    path: "imageSkin.glass.\(item.name)",
                    message: "Glass value is outside the supported range."
                )
            }

            let centerPanelValues: [
                (name: String, value: Double, range: ClosedRange<Double>)
            ] = [
                ("backdropBlur", skin.centerPanel.backdropBlur, 0...80),
                (
                    "backdropSaturation",
                    skin.centerPanel.backdropSaturation,
                    0...3
                ),
                ("borderWidth", skin.centerPanel.borderWidth, 0...8),
                ("cornerRadius", skin.centerPanel.cornerRadius, 0...64),
                ("shadowBlur", skin.centerPanel.shadowBlur, 0...120),
                ("shadowOffsetX", skin.centerPanel.shadowOffsetX, -120...120),
                ("shadowOffsetY", skin.centerPanel.shadowOffsetY, -120...120),
                ("maximumWidth", skin.centerPanel.maximumWidth, 320...1_600),
                (
                    "horizontalPadding",
                    skin.centerPanel.horizontalPadding,
                    0...120
                ),
                (
                    "verticalPadding",
                    skin.centerPanel.verticalPadding,
                    0...120
                )
            ]
            for item in centerPanelValues
            where !item.value.isFinite || !item.range.contains(item.value) {
                add(
                    .invalidSkinNumber,
                    path: "imageSkin.centerPanel.\(item.name)",
                    message: "Center panel value is outside the supported range."
                )
            }
        }

        if let voice = document.voiceStyle {
            let appearances: [
                (name: String, value: ThemeVoiceVariant)
            ] = [
                ("light", voice.light),
                ("dark", voice.dark)
            ]
            for appearance in appearances {
                let path = "voiceStyle.\(appearance.name)"
                let variant = appearance.value
                let colorValues = [
                    ("glowColor", variant.glowColor),
                    ("backdropColor", variant.backdropColor)
                ]
                for (name, value) in colorValues {
                    totalCSSCharacters += value.count
                    let valuePath = "\(path).\(name)"
                    if value.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                        || value.contains(";")
                        || value.contains("{")
                        || value.contains("}")
                        || value.localizedCaseInsensitiveContains("!important")
                        || value.contains("/*")
                        || value.contains("*/")
                        || value.contains("@")
                        || value.unicodeScalars.contains(where: {
                            $0.value < 0x20 || $0.value == 0x7F
                        }) {
                        add(
                            .invalidSkinCSSValue,
                            path: valuePath,
                            message: "Voice colors must be one CSS color value without declaration delimiters."
                        )
                    }
                    appendSecurityIssues(
                        in: value,
                        path: valuePath,
                        to: &issues
                    )
                }

                let unitValues = [
                    ("orbOpacity", variant.orbOpacity),
                    ("glowOpacity", variant.glowOpacity),
                    ("backdropOpacity", variant.backdropOpacity)
                ]
                for (name, value) in unitValues
                where !value.isFinite || !(0...1).contains(value) {
                    add(
                        .invalidSkinNumber,
                        path: "\(path).\(name)",
                        message: "Voice value must be finite and between 0 and 1."
                    )
                }

                let ranges: [
                    (String, Double, ClosedRange<Double>)
                ] = [
                    ("orbScale", variant.orbScale, 0.5...2),
                    ("brightness", variant.brightness, 0...3),
                    ("contrast", variant.contrast, 0...3),
                    ("saturation", variant.saturation, 0...3),
                    ("hueRotation", variant.hueRotation, -180...180),
                    ("blur", variant.blur, 0...40),
                    ("glowBlur", variant.glowBlur, 0...120)
                ]
                for (name, value, range) in ranges
                where !value.isFinite || !range.contains(value) {
                    add(
                        .invalidSkinNumber,
                        path: "\(path).\(name)",
                        message: "Voice value is outside the supported range."
                    )
                }
            }

            totalCSSCharacters += voice.rawCSS.count
            appendSecurityIssues(
                in: voice.rawCSS,
                path: "voiceStyle.rawCSS",
                to: &issues
            )
        }

        if totalCSSCharacters > configuration.maximumCSSCharacters {
            add(
                .cssTooLarge,
                path: "layers",
                message: "Theme CSS contains \(totalCSSCharacters) characters; the maximum is \(configuration.maximumCSSCharacters)."
            )
        }

        var totalAssetBytes = 0
        for (assetIndex, asset) in document.assets.enumerated() {
            let path = "assets[\(assetIndex)]"
            register(asset.id, path: "\(path).id")

            if asset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                add(.invalidAssetName, path: "\(path).name", message: "An asset name is required.")
            }
            if !Self.isValidMediaType(asset.mediaType) {
                add(
                    .invalidAssetMediaType,
                    path: "\(path).mediaType",
                    message: "The media type must use a value such as image/png or font/woff2."
                )
            }
            guard let data = asset.decodedData else {
                add(
                    .invalidAssetData,
                    path: "\(path).dataBase64",
                    message: "Asset data is not valid Base64."
                )
                continue
            }
            totalAssetBytes += data.count
            if data.count > configuration.maximumAssetBytes {
                add(
                    .assetTooLarge,
                    path: "\(path).dataBase64",
                    message: "Asset contains \(data.count) bytes; the maximum is \(configuration.maximumAssetBytes)."
                )
            }
        }

        if totalAssetBytes > configuration.maximumTotalAssetBytes {
            add(
                .totalAssetsTooLarge,
                path: "assets",
                message: "Assets contain \(totalAssetBytes) bytes; the maximum is \(configuration.maximumTotalAssetBytes)."
            )
        }

        return ThemeValidationResult(issues: issues)
    }

    public func validateOrThrow(_ document: ThemeDocument) throws {
        let result = validate(document)
        guard result.isValid else {
            throw ThemeValidationError(issues: result.issues)
        }
    }

    private func validateDeclarations(
        _ declarations: [ThemeCSSDeclaration],
        at path: String,
        identifiers: inout Set<UUID>,
        issues: inout [ThemeValidationIssue],
        totalCSSCharacters: inout Int
    ) {
        for (index, declaration) in declarations.enumerated() {
            let declarationPath = "\(path)[\(index)]"
            if !identifiers.insert(declaration.id).inserted {
                issues.append(
                    ThemeValidationIssue(
                        severity: .error,
                        code: .duplicateIdentifier,
                        path: "\(declarationPath).id",
                        message: "Identifier \(declaration.id.uuidString) is used more than once."
                    )
                )
            }
            if !Self.isValidPropertyName(declaration.property) {
                issues.append(
                    ThemeValidationIssue(
                        severity: .error,
                        code: .invalidDeclarationProperty,
                        path: "\(declarationPath).property",
                        message: "The CSS property name is invalid."
                    )
                )
            }
            if declaration.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(
                    ThemeValidationIssue(
                        severity: .error,
                        code: .emptyDeclarationValue,
                        path: "\(declarationPath).value",
                        message: "A declaration value is required."
                    )
                )
            }
            totalCSSCharacters += declaration.property.count + declaration.value.count
            appendSecurityIssues(
                in: declaration.value,
                path: "\(declarationPath).value",
                to: &issues
            )
        }
    }

    private func appendSecurityIssues(
        in css: String,
        path: String,
        to issues: inout [ThemeValidationIssue]
    ) {
        for violation in CSSSecurityScanner.violations(in: css) {
            switch violation {
            case .importRule:
                issues.append(
                    ThemeValidationIssue(
                        severity: .error,
                        code: .unsafeImport,
                        path: path,
                        message: "@import is not allowed in a shareable theme."
                    )
                )
            case let .unsafeURL(url):
                issues.append(
                    ThemeValidationIssue(
                        severity: .error,
                        code: .unsafeURL,
                        path: path,
                        message: "External or file URL is not allowed: \(url)"
                    )
                )
            }
        }
    }

    private static func isValidVariableName(_ value: String) -> Bool {
        matches(#"^--[A-Za-z0-9_-]+$"#, value)
    }

    private static func isValidPropertyName(_ value: String) -> Bool {
        matches(#"^(--[A-Za-z0-9_-]+|-?[A-Za-z][A-Za-z0-9-]*)$"#, value)
    }

    private static func isValidSelector(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains("{") && !trimmed.contains("}")
    }

    private static func isValidMediaType(_ value: String) -> Bool {
        matches(#"^[A-Za-z0-9.+-]+/[A-Za-z0-9.+-]+$"#, value)
    }

    private static func matches(_ pattern: String, _ value: String) -> Bool {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.firstMatch(in: value, range: range)?.range == range
    }
}

private enum CSSSecurityViolation: Hashable {
    case importRule
    case unsafeURL(String)
}

private enum CSSSecurityScanner {
    static func violations(in source: String) -> [CSSSecurityViolation] {
        let normalized = decodeEscapes(in: removingComments(from: source))
        var violations: [CSSSecurityViolation] = []

        if containsImport(in: normalized) {
            violations.append(.importRule)
        }

        guard let expression = try? NSRegularExpression(
            pattern: #"(?is)\burl\s*\((.*?)\)"#
        ) else {
            return violations
        }

        let fullRange = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        for match in expression.matches(in: normalized, range: fullRange) {
            guard
                match.numberOfRanges > 1,
                let valueRange = Range(match.range(at: 1), in: normalized)
            else {
                continue
            }
            var value = String(normalized[valueRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if value.count >= 2,
               let first = value.first,
               let last = value.last,
               (first == "\"" || first == "'"),
               first == last {
                value.removeFirst()
                value.removeLast()
                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if isUnsafeURL(value) {
                violations.append(.unsafeURL(value))
            }
        }

        var seen = Set<CSSSecurityViolation>()
        return violations.filter { seen.insert($0).inserted }
    }

    private static func containsImport(in source: String) -> Bool {
        guard let expression = try? NSRegularExpression(
            pattern: #"(?i)@\s*import\b"#
        ) else {
            return false
        }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return expression.firstMatch(in: source, range: range) != nil
    }

    private static func isUnsafeURL(_ value: String) -> Bool {
        let lowered = value.lowercased()
        if lowered.isEmpty || lowered.hasPrefix("#") {
            return false
        }
        if lowered.hasPrefix("//") {
            return true
        }
        guard let colon = lowered.firstIndex(of: ":") else {
            // Relative/root-relative paths stay within the current local document.
            return false
        }

        let scheme = String(lowered[..<colon])
        guard scheme.range(of: #"^[a-z][a-z0-9+.-]*$"#, options: .regularExpression) != nil else {
            return false
        }
        return scheme != "data"
            && scheme != "theme-asset"
            && scheme != "codex-theme-asset"
    }

    private static func removingComments(from source: String) -> String {
        let characters = Array(source)
        var result = ""
        var index = 0
        var quote: Character?
        var escaped = false

        while index < characters.count {
            let character = characters[index]
            if let activeQuote = quote {
                result.append(character)
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == activeQuote {
                    quote = nil
                }
                index += 1
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
                result.append(character)
                index += 1
                continue
            }

            if character == "/",
               index + 1 < characters.count,
               characters[index + 1] == "*" {
                index += 2
                while index + 1 < characters.count {
                    if characters[index] == "*", characters[index + 1] == "/" {
                        index += 2
                        break
                    }
                    index += 1
                }
                continue
            }

            result.append(character)
            index += 1
        }
        return result
    }

    /// Decodes CSS escapes so strings such as `u\72l` and `h\74tps` cannot bypass
    /// the simple security policy.
    private static func decodeEscapes(in source: String) -> String {
        let characters = Array(source)
        var result = ""
        var index = 0

        while index < characters.count {
            guard characters[index] == "\\" else {
                result.append(characters[index])
                index += 1
                continue
            }

            index += 1
            guard index < characters.count else {
                result.append("\\")
                break
            }

            var hex = ""
            while index < characters.count, hex.count < 6,
                  characters[index].isHexadecimalDigit {
                hex.append(characters[index])
                index += 1
            }
            if !hex.isEmpty {
                if index < characters.count, characters[index].isWhitespace {
                    index += 1
                }
                if let value = UInt32(hex, radix: 16),
                   let scalar = Unicode.Scalar(value) {
                    result.unicodeScalars.append(scalar)
                }
                continue
            }

            let escaped = characters[index]
            if escaped != "\n" && escaped != "\r" {
                result.append(escaped)
            }
            index += 1
        }
        return result
    }
}

private extension Character {
    var isHexadecimalDigit: Bool {
        guard unicodeScalars.count == 1 else { return false }
        return String(self).range(of: #"^[0-9A-Fa-f]$"#, options: .regularExpression) != nil
    }
}
