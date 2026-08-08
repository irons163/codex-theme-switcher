import Foundation

/// The complete, shareable representation of a Codex theme.
///
/// The model deliberately stores CSS values as strings. CSS supports substantially
/// more values than a native color or length type can represent (gradients, `calc`,
/// Display-P3 colors, filters, and so on), so string values preserve round trips and
/// leave room for an advanced editor.
public struct ThemeDocument: Codable, Equatable, Sendable, Identifiable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var metadata: ThemeMetadata
    public var layers: [ThemeLayer]
    public var assets: [ThemeAsset]
    public var imageSkin: ThemeImageSkin?
    /// Optional ChatGPT Voice styling. Safe orb-only rules are also compiled
    /// into the main renderer for the initial embedded Voice orb, while the
    /// full background and advanced CSS remain isolated to avatar-overlay.
    public var voiceStyle: ThemeVoiceStyle?

    public init(
        schemaVersion: Int = ThemeDocument.currentSchemaVersion,
        id: UUID = UUID(),
        metadata: ThemeMetadata,
        layers: [ThemeLayer] = [],
        assets: [ThemeAsset] = [],
        imageSkin: ThemeImageSkin? = nil,
        voiceStyle: ThemeVoiceStyle? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.metadata = metadata
        self.layers = layers
        self.assets = assets
        self.imageSkin = imageSkin
        self.voiceStyle = voiceStyle
    }
}

public struct ThemeMetadata: Codable, Equatable, Sendable {
    public var name: String
    public var author: String
    public var description: String
    public var version: String
    public var tags: [String]
    public var homepage: URL?
    public var license: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        name: String,
        author: String = "",
        description: String = "",
        version: String = "1.0.0",
        tags: [String] = [],
        homepage: URL? = nil,
        license: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.author = author
        self.description = description
        self.version = version
        self.tags = tags
        self.homepage = homepage
        self.license = license
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ThemeLayerCondition: String, Codable, CaseIterable, Equatable, Sendable {
    case always
    case light
    case dark
    case custom
}

/// One ordered CSS layer in a theme.
///
/// Later layers win according to normal CSS cascade rules. A custom layer uses
/// `mediaQuery`, without the leading `@media`.
public struct ThemeLayer: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var condition: ThemeLayerCondition
    public var mediaQuery: String?
    public var isEnabled: Bool
    public var variables: [ThemeVariable]
    public var components: [ThemeComponentOverride]
    public var rules: [ThemeCSSRule]
    public var rawCSS: String

    public init(
        id: UUID = UUID(),
        name: String,
        condition: ThemeLayerCondition = .always,
        mediaQuery: String? = nil,
        isEnabled: Bool = true,
        variables: [ThemeVariable] = [],
        components: [ThemeComponentOverride] = [],
        rules: [ThemeCSSRule] = [],
        rawCSS: String = ""
    ) {
        self.id = id
        self.name = name
        self.condition = condition
        self.mediaQuery = mediaQuery
        self.isEnabled = isEnabled
        self.variables = variables
        self.components = components
        self.rules = rules
        self.rawCSS = rawCSS
    }
}

/// Semantic variables have stable names that generated component styles can use.
public enum ThemeSemanticRole: String, Codable, CaseIterable, Equatable, Sendable {
    case backgroundPrimary
    case backgroundSecondary
    case surface
    case textPrimary
    case textSecondary
    case accent
    case border
    case success
    case warning
    case error

    public var cssVariableName: String {
        switch self {
        case .backgroundPrimary:
            return "--codex-theme-background-primary"
        case .backgroundSecondary:
            return "--codex-theme-background-secondary"
        case .surface:
            return "--codex-theme-surface"
        case .textPrimary:
            return "--codex-theme-text-primary"
        case .textSecondary:
            return "--codex-theme-text-secondary"
        case .accent:
            return "--codex-theme-accent"
        case .border:
            return "--codex-theme-border"
        case .success:
            return "--codex-theme-success"
        case .warning:
            return "--codex-theme-warning"
        case .error:
            return "--codex-theme-error"
        }
    }

    /// CSS variables used by the Codex 26 design-system and editor surfaces.
    ///
    /// The compiler emits these as aliases of `cssVariableName`. Keeping this
    /// mapping in Core lets the visual editor operate on ten semantic roles while
    /// still reaching Codex, legacy ChatGPT tokens, and embedded editor/diff UI.
    public var codexStableTokenAliases: [String] {
        switch self {
        case .backgroundPrimary:
            return [
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
            ]
        case .backgroundSecondary:
            return [
                "--color-background-secondary",
                "--color-background-panel",
                "--color-token-bg-secondary",
                "--color-token-side-bar-background",
                "--main-surface-secondary",
                "--color-surface-secondary",
                "--oai-wb-surface-secondary",
                "--vscode-sideBar-background"
            ]
        case .surface:
            return [
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
            ]
        case .textPrimary:
            return [
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
            ]
        case .textSecondary:
            return [
                "--muted-foreground",
                "--color-text-foreground-secondary",
                "--color-text-secondary",
                "--color-icon-secondary",
                "--color-token-text-secondary",
                "--color-token-description-foreground",
                "--color-token-input-placeholder-foreground",
                "--oai-wb-text-secondary",
                "--vscode-descriptionForeground"
            ]
        case .accent:
            return [
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
            ]
        case .border:
            return [
                "--border",
                "--color-border",
                "--color-border-primary",
                "--color-token-border",
                "--color-token-border-default",
                "--color-token-input-border",
                "--color-token-menu-border",
                "--oai-wb-border",
                "--vscode-panel-border"
            ]
        case .success:
            return [
                "--color-text-success",
                "--color-icon-success",
                "--color-border-success",
                "--color-background-status-success",
                "--color-token-git-decoration-added-resource-foreground",
                "--diffs-addition-color",
                "--diffs-addition-color-override",
                "--codex-diffs-addition-number",
                "--state-success"
            ]
        case .warning:
            return [
                "--color-text-warning",
                "--color-icon-warning",
                "--color-border-warning",
                "--color-background-status-warning",
                "--color-token-editor-warning-foreground",
                "--color-token-git-decoration-modified-resource-foreground",
                "--diffs-modified-color",
                "--diffs-modified-color-override",
                "--viz-warning"
            ]
        case .error:
            return [
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
        }
    }
}

public struct ThemeVariable: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var value: String
    public var semanticRole: ThemeSemanticRole?
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String = "",
        value: String,
        semanticRole: ThemeSemanticRole? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.semanticRole = semanticRole
        self.isEnabled = isEnabled
    }

    /// The name emitted by the compiler. A semantic role intentionally takes
    /// precedence over a manually supplied name.
    public var resolvedName: String {
        semanticRole?.cssVariableName ?? name
    }
}

public struct ThemeCSSDeclaration: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var property: String
    public var value: String
    public var isImportant: Bool
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        property: String,
        value: String,
        isImportant: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.property = property
        self.value = value
        self.isImportant = isImportant
        self.isEnabled = isEnabled
    }
}

/// A style for a known component, or for custom selectors supplied by a theme.
///
/// If `selectors` is empty the compiler consults `ThemeComponentCatalog` using
/// `componentID`. Supplying selectors is the escape hatch for future Codex UI.
public struct ThemeComponentOverride: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var componentID: String
    public var selectors: [String]
    public var declarations: [ThemeCSSDeclaration]
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        componentID: String,
        selectors: [String] = [],
        declarations: [ThemeCSSDeclaration] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.componentID = componentID
        self.selectors = selectors
        self.declarations = declarations
        self.isEnabled = isEnabled
    }
}

public struct ThemeCSSRule: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var selector: String
    public var declarations: [ThemeCSSDeclaration]
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        selector: String,
        declarations: [ThemeCSSDeclaration] = [],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.selector = selector
        self.declarations = declarations
        self.isEnabled = isEnabled
    }
}

/// A theme asset embedded directly in the `.codextheme` JSON document.
public struct ThemeAsset: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var mediaType: String
    public var dataBase64: String

    public init(
        id: UUID = UUID(),
        name: String,
        mediaType: String,
        dataBase64: String
    ) {
        self.id = id
        self.name = name
        self.mediaType = mediaType
        self.dataBase64 = dataBase64
    }

    public init(
        id: UUID = UUID(),
        name: String,
        mediaType: String,
        data: Data
    ) {
        self.init(
            id: id,
            name: name,
            mediaType: mediaType,
            dataBase64: data.base64EncodedString()
        )
    }

    public var decodedData: Data? {
        Data(base64Encoded: dataBase64)
    }
}

public struct ThemeSummary: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var author: String
    public var updatedAt: Date
    public var isBuiltIn: Bool

    public init(
        id: UUID,
        name: String,
        author: String,
        updatedAt: Date,
        isBuiltIn: Bool
    ) {
        self.id = id
        self.name = name
        self.author = author
        self.updatedAt = updatedAt
        self.isBuiltIn = isBuiltIn
    }

    public init(document: ThemeDocument, isBuiltIn: Bool) {
        self.init(
            id: document.id,
            name: document.metadata.name,
            author: document.metadata.author,
            updatedAt: document.metadata.updatedAt,
            isBuiltIn: isBuiltIn
        )
    }
}

public enum ThemeCollisionPolicy: String, Codable, CaseIterable, Equatable, Sendable {
    case fail
    case replace
    case clone
}
