import Foundation

public enum ThemeSkinAppearance: String, Codable, CaseIterable, Sendable {
    case light
    case dark
}

public enum ThemeSkinImageFit: String, Codable, CaseIterable, Sendable {
    /// Aspect-fill the window; crops whichever axis overflows.
    case cover
    /// Aspect-fit the whole image inside the window.
    case contain
    /// Stretch independently on both axes.
    case fill
    /// Preserve aspect ratio and match the window width.
    case fitWidth
    /// Preserve aspect ratio and match the window height.
    case fitHeight
    /// Use the image's intrinsic dimensions.
    case original
    /// Repeat the image at its intrinsic dimensions.
    case tile
}

public enum ThemeSkinWallpaperScope: String, Codable, CaseIterable, Sendable {
    /// Size and position the wallpaper against the entire Codex window.
    case fullWindow
    /// Size and position the wallpaper inside Codex's main content pane.
    case mainContent
}

public enum ThemeSkinScrimDirection: String, Codable, CaseIterable, Sendable {
    case none
    case left
    case right
    case top
    case bottom
}

public enum ThemeSkinBlendMode: String, Codable, CaseIterable, Sendable {
    case normal
    case multiply
    case screen
    case overlay
    case softLight
}

/// A high-level, shareable image skin.
///
/// This remains optional on `ThemeDocument`, so schema-v1 themes produced before
/// image skins existed still decode without a migration.
public struct ThemeImageSkin: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var wallpaperScope: ThemeSkinWallpaperScope
    public var light: ThemeSkinVariant
    public var dark: ThemeSkinVariant
    public var centerPanel: ThemeSkinCenterPanel
    public var glass: ThemeSkinGlass
    public var targets: ThemeSkinTargets

    public init(
        isEnabled: Bool = true,
        wallpaperScope: ThemeSkinWallpaperScope = .fullWindow,
        light: ThemeSkinVariant = .lightDefault,
        dark: ThemeSkinVariant = .darkDefault,
        centerPanel: ThemeSkinCenterPanel = ThemeSkinCenterPanel(),
        glass: ThemeSkinGlass = ThemeSkinGlass(),
        targets: ThemeSkinTargets = ThemeSkinTargets()
    ) {
        self.isEnabled = isEnabled
        self.wallpaperScope = wallpaperScope
        self.light = light
        self.dark = dark
        self.centerPanel = centerPanel
        self.glass = glass
        self.targets = targets
    }

    public func variant(for appearance: ThemeSkinAppearance) -> ThemeSkinVariant {
        appearance == .light ? light : dark
    }

    public mutating func setVariant(
        _ variant: ThemeSkinVariant,
        for appearance: ThemeSkinAppearance
    ) {
        switch appearance {
        case .light:
            light = variant
        case .dark:
            dark = variant
        }
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case wallpaperScope
        case light
        case dark
        case centerPanel
        case glass
        case targets
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .isEnabled
        ) ?? true
        if let rawWallpaperScope = try values.decodeIfPresent(
            String.self,
            forKey: .wallpaperScope
        ) {
            wallpaperScope = ThemeSkinWallpaperScope(
                rawValue: rawWallpaperScope
            ) ?? .fullWindow
        } else {
            wallpaperScope = .fullWindow
        }
        if values.contains(.light),
           try !values.decodeNil(forKey: .light) {
            light = try ThemeSkinVariant(
                from: values.superDecoder(forKey: .light),
                defaults: .lightDefault
            )
        } else {
            light = .lightDefault
        }
        if values.contains(.dark),
           try !values.decodeNil(forKey: .dark) {
            dark = try ThemeSkinVariant(
                from: values.superDecoder(forKey: .dark),
                defaults: .darkDefault
            )
        } else {
            dark = .darkDefault
        }
        centerPanel = try values.decodeIfPresent(
            ThemeSkinCenterPanel.self,
            forKey: .centerPanel
        ) ?? ThemeSkinCenterPanel()
        glass = try values.decodeIfPresent(
            ThemeSkinGlass.self,
            forKey: .glass
        ) ?? ThemeSkinGlass()
        targets = try values.decodeIfPresent(
            ThemeSkinTargets.self,
            forKey: .targets
        ) ?? ThemeSkinTargets()
    }
}

public struct ThemeSkinVariant: Codable, Equatable, Sendable {
    public var backgroundAssetID: UUID?
    public var backgroundColor: String
    public var imageFit: ThemeSkinImageFit
    public var positionX: Double
    public var positionY: Double
    public var zoom: Double
    public var imageOpacity: Double
    public var imageBlur: Double
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    public var blendMode: ThemeSkinBlendMode
    public var overlayColor: String
    public var overlayOpacity: Double
    public var scrimDirection: ThemeSkinScrimDirection
    public var scrimOpacity: Double
    public var vignetteOpacity: Double
    public var primaryTextColor: String
    public var secondaryTextColor: String
    public var accentColor: String
    public var sidebarTint: String
    public var sidebarOpacity: Double
    public var contentTint: String
    public var contentOpacity: Double
    public var composerTint: String
    public var composerOpacity: Double
    /// Overrides the Composer's primary voice/send/stop button background.
    ///
    /// `nil` preserves the legacy semantic behavior by following
    /// `primaryTextColor` at compile time.
    public var composerActionBackgroundColor: String?
    /// Overrides the icon inside the Composer's primary action button.
    ///
    /// `nil` preserves the legacy semantic behavior by following the complete
    /// card surface, including `cardOpacity`, at compile time.
    public var composerActionIconColor: String?
    public var cardTint: String
    public var cardOpacity: Double
    public var borderColor: String
    public var borderOpacity: Double
    public var centerPanelTint: String
    public var centerPanelOpacity: Double
    public var centerPanelBorderColor: String
    public var centerPanelBorderOpacity: Double
    public var centerPanelShadowColor: String
    public var centerPanelShadowOpacity: Double

    public init(
        backgroundAssetID: UUID? = nil,
        backgroundColor: String = "#0B0B0D",
        imageFit: ThemeSkinImageFit = .cover,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        zoom: Double = 1,
        imageOpacity: Double = 1,
        imageBlur: Double = 0,
        brightness: Double = 0.82,
        contrast: Double = 1.05,
        saturation: Double = 0.9,
        blendMode: ThemeSkinBlendMode = .normal,
        overlayColor: String = "#08090C",
        overlayOpacity: Double = 0.22,
        scrimDirection: ThemeSkinScrimDirection = .left,
        scrimOpacity: Double = 0.42,
        vignetteOpacity: Double = 0.2,
        primaryTextColor: String = "#F7F2EA",
        secondaryTextColor: String = "#C7BCAE",
        accentColor: String = "#D8B06C",
        sidebarTint: String = "#08090C",
        sidebarOpacity: Double = 0.42,
        contentTint: String = "#08090C",
        contentOpacity: Double = 0.08,
        composerTint: String = "#15130F",
        composerOpacity: Double = 0.78,
        composerActionBackgroundColor: String? = nil,
        composerActionIconColor: String? = nil,
        cardTint: String = "#15130F",
        cardOpacity: Double = 0.58,
        borderColor: String = "#D8B06C",
        borderOpacity: Double = 0.24,
        centerPanelTint: String = "#08090C",
        centerPanelOpacity: Double = 0.38,
        centerPanelBorderColor: String = "#D8B06C",
        centerPanelBorderOpacity: Double = 0.24,
        centerPanelShadowColor: String = "#000000",
        centerPanelShadowOpacity: Double = 0.24
    ) {
        self.backgroundAssetID = backgroundAssetID
        self.backgroundColor = backgroundColor
        self.imageFit = imageFit
        self.positionX = positionX
        self.positionY = positionY
        self.zoom = zoom
        self.imageOpacity = imageOpacity
        self.imageBlur = imageBlur
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.blendMode = blendMode
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.scrimDirection = scrimDirection
        self.scrimOpacity = scrimOpacity
        self.vignetteOpacity = vignetteOpacity
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.accentColor = accentColor
        self.sidebarTint = sidebarTint
        self.sidebarOpacity = sidebarOpacity
        self.contentTint = contentTint
        self.contentOpacity = contentOpacity
        self.composerTint = composerTint
        self.composerOpacity = composerOpacity
        self.composerActionBackgroundColor = composerActionBackgroundColor
        self.composerActionIconColor = composerActionIconColor
        self.cardTint = cardTint
        self.cardOpacity = cardOpacity
        self.borderColor = borderColor
        self.borderOpacity = borderOpacity
        self.centerPanelTint = centerPanelTint
        self.centerPanelOpacity = centerPanelOpacity
        self.centerPanelBorderColor = centerPanelBorderColor
        self.centerPanelBorderOpacity = centerPanelBorderOpacity
        self.centerPanelShadowColor = centerPanelShadowColor
        self.centerPanelShadowOpacity = centerPanelShadowOpacity
    }

    public static let darkDefault = ThemeSkinVariant()

    public static let lightDefault = ThemeSkinVariant(
        backgroundColor: "#F6F0EA",
        imageOpacity: 1,
        brightness: 1.04,
        contrast: 0.96,
        saturation: 0.88,
        overlayColor: "#FFF8F3",
        overlayOpacity: 0.13,
        scrimDirection: .left,
        scrimOpacity: 0.18,
        vignetteOpacity: 0.04,
        primaryTextColor: "#211B18",
        secondaryTextColor: "#655B55",
        accentColor: "#B86438",
        sidebarTint: "#FFF9F5",
        sidebarOpacity: 0.46,
        contentTint: "#FFF9F5",
        contentOpacity: 0.08,
        composerTint: "#FFFCFA",
        composerOpacity: 0.76,
        cardTint: "#FFFCFA",
        cardOpacity: 0.58,
        borderColor: "#FFFFFF",
        borderOpacity: 0.48,
        centerPanelTint: "#FFF9F5",
        centerPanelOpacity: 0.56,
        centerPanelBorderColor: "#FFFFFF",
        centerPanelBorderOpacity: 0.48,
        centerPanelShadowColor: "#5A4638",
        centerPanelShadowOpacity: 0.14
    )

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case backgroundAssetID
        case backgroundColor
        case imageFit
        case positionX
        case positionY
        case zoom
        case imageOpacity
        case imageBlur
        case brightness
        case contrast
        case saturation
        case blendMode
        case overlayColor
        case overlayOpacity
        case scrimDirection
        case scrimOpacity
        case vignetteOpacity
        case primaryTextColor
        case secondaryTextColor
        case accentColor
        case sidebarTint
        case sidebarOpacity
        case contentTint
        case contentOpacity
        case composerTint
        case composerOpacity
        case composerActionBackgroundColor
        case composerActionIconColor
        case cardTint
        case cardOpacity
        case borderColor
        case borderOpacity
        case centerPanelTint
        case centerPanelOpacity
        case centerPanelBorderColor
        case centerPanelBorderOpacity
        case centerPanelShadowColor
        case centerPanelShadowOpacity
    }

    public init(from decoder: Decoder) throws {
        try self.init(from: decoder, defaults: .darkDefault)
    }

    fileprivate init(
        from decoder: Decoder,
        defaults: ThemeSkinVariant
    ) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        backgroundAssetID = try values.decodeIfPresent(
            UUID.self,
            forKey: .backgroundAssetID
        )
        backgroundColor = try values.decodeIfPresent(
            String.self,
            forKey: .backgroundColor
        ) ?? defaults.backgroundColor
        if let rawImageFit = try values.decodeIfPresent(
            String.self,
            forKey: .imageFit
        ) {
            imageFit = ThemeSkinImageFit(rawValue: rawImageFit)
                ?? defaults.imageFit
        } else {
            imageFit = defaults.imageFit
        }
        positionX = try values.decodeIfPresent(
            Double.self,
            forKey: .positionX
        ) ?? defaults.positionX
        positionY = try values.decodeIfPresent(
            Double.self,
            forKey: .positionY
        ) ?? defaults.positionY
        zoom = try values.decodeIfPresent(
            Double.self,
            forKey: .zoom
        ) ?? defaults.zoom
        imageOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .imageOpacity
        ) ?? defaults.imageOpacity
        imageBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .imageBlur
        ) ?? defaults.imageBlur
        brightness = try values.decodeIfPresent(
            Double.self,
            forKey: .brightness
        ) ?? defaults.brightness
        contrast = try values.decodeIfPresent(
            Double.self,
            forKey: .contrast
        ) ?? defaults.contrast
        saturation = try values.decodeIfPresent(
            Double.self,
            forKey: .saturation
        ) ?? defaults.saturation
        blendMode = try values.decodeIfPresent(
            ThemeSkinBlendMode.self,
            forKey: .blendMode
        ) ?? defaults.blendMode
        overlayColor = try values.decodeIfPresent(
            String.self,
            forKey: .overlayColor
        ) ?? defaults.overlayColor
        overlayOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .overlayOpacity
        ) ?? defaults.overlayOpacity
        scrimDirection = try values.decodeIfPresent(
            ThemeSkinScrimDirection.self,
            forKey: .scrimDirection
        ) ?? defaults.scrimDirection
        scrimOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .scrimOpacity
        ) ?? defaults.scrimOpacity
        vignetteOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .vignetteOpacity
        ) ?? defaults.vignetteOpacity
        primaryTextColor = try values.decodeIfPresent(
            String.self,
            forKey: .primaryTextColor
        ) ?? defaults.primaryTextColor
        secondaryTextColor = try values.decodeIfPresent(
            String.self,
            forKey: .secondaryTextColor
        ) ?? defaults.secondaryTextColor
        accentColor = try values.decodeIfPresent(
            String.self,
            forKey: .accentColor
        ) ?? defaults.accentColor
        sidebarTint = try values.decodeIfPresent(
            String.self,
            forKey: .sidebarTint
        ) ?? defaults.sidebarTint
        sidebarOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .sidebarOpacity
        ) ?? defaults.sidebarOpacity
        contentTint = try values.decodeIfPresent(
            String.self,
            forKey: .contentTint
        ) ?? defaults.contentTint
        contentOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .contentOpacity
        ) ?? defaults.contentOpacity
        composerTint = try values.decodeIfPresent(
            String.self,
            forKey: .composerTint
        ) ?? defaults.composerTint
        composerOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .composerOpacity
        ) ?? defaults.composerOpacity
        composerActionBackgroundColor = try values.decodeIfPresent(
            String.self,
            forKey: .composerActionBackgroundColor
        ) ?? defaults.composerActionBackgroundColor
        composerActionIconColor = try values.decodeIfPresent(
            String.self,
            forKey: .composerActionIconColor
        ) ?? defaults.composerActionIconColor
        cardTint = try values.decodeIfPresent(
            String.self,
            forKey: .cardTint
        ) ?? defaults.cardTint
        cardOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .cardOpacity
        ) ?? defaults.cardOpacity
        borderColor = try values.decodeIfPresent(
            String.self,
            forKey: .borderColor
        ) ?? defaults.borderColor
        borderOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .borderOpacity
        ) ?? defaults.borderOpacity
        centerPanelTint = try values.decodeIfPresent(
            String.self,
            forKey: .centerPanelTint
        ) ?? defaults.centerPanelTint
        centerPanelOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .centerPanelOpacity
        ) ?? defaults.centerPanelOpacity
        centerPanelBorderColor = try values.decodeIfPresent(
            String.self,
            forKey: .centerPanelBorderColor
        ) ?? defaults.centerPanelBorderColor
        centerPanelBorderOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .centerPanelBorderOpacity
        ) ?? defaults.centerPanelBorderOpacity
        centerPanelShadowColor = try values.decodeIfPresent(
            String.self,
            forKey: .centerPanelShadowColor
        ) ?? defaults.centerPanelShadowColor
        centerPanelShadowOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .centerPanelShadowOpacity
        ) ?? defaults.centerPanelShadowOpacity
    }
}

public struct ThemeSkinCenterPanel: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var backdropBlur: Double
    public var backdropSaturation: Double
    public var borderWidth: Double
    public var cornerRadius: Double
    public var shadowBlur: Double
    public var shadowOffsetX: Double
    public var shadowOffsetY: Double
    public var maximumWidth: Double
    public var horizontalPadding: Double
    public var verticalPadding: Double

    public init(
        isEnabled: Bool = false,
        backdropBlur: Double = 18,
        backdropSaturation: Double = 1.12,
        borderWidth: Double = 1,
        cornerRadius: Double = 20,
        shadowBlur: Double = 32,
        shadowOffsetX: Double = 0,
        shadowOffsetY: Double = 18,
        maximumWidth: Double = 768,
        horizontalPadding: Double = 24,
        verticalPadding: Double = 20
    ) {
        self.isEnabled = isEnabled
        self.backdropBlur = backdropBlur
        self.backdropSaturation = backdropSaturation
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadowBlur = shadowBlur
        self.shadowOffsetX = shadowOffsetX
        self.shadowOffsetY = shadowOffsetY
        self.maximumWidth = maximumWidth
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case backdropBlur
        case backdropSaturation
        case borderWidth
        case cornerRadius
        case shadowBlur
        case shadowOffsetX
        case shadowOffsetY
        case maximumWidth
        case horizontalPadding
        case verticalPadding
    }

    public init(from decoder: Decoder) throws {
        let defaults = ThemeSkinCenterPanel()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .isEnabled
        ) ?? defaults.isEnabled
        backdropBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .backdropBlur
        ) ?? defaults.backdropBlur
        backdropSaturation = try values.decodeIfPresent(
            Double.self,
            forKey: .backdropSaturation
        ) ?? defaults.backdropSaturation
        borderWidth = try values.decodeIfPresent(
            Double.self,
            forKey: .borderWidth
        ) ?? defaults.borderWidth
        cornerRadius = try values.decodeIfPresent(
            Double.self,
            forKey: .cornerRadius
        ) ?? defaults.cornerRadius
        shadowBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .shadowBlur
        ) ?? defaults.shadowBlur
        shadowOffsetX = try values.decodeIfPresent(
            Double.self,
            forKey: .shadowOffsetX
        ) ?? defaults.shadowOffsetX
        shadowOffsetY = try values.decodeIfPresent(
            Double.self,
            forKey: .shadowOffsetY
        ) ?? defaults.shadowOffsetY
        maximumWidth = try values.decodeIfPresent(
            Double.self,
            forKey: .maximumWidth
        ) ?? defaults.maximumWidth
        horizontalPadding = try values.decodeIfPresent(
            Double.self,
            forKey: .horizontalPadding
        ) ?? defaults.horizontalPadding
        verticalPadding = try values.decodeIfPresent(
            Double.self,
            forKey: .verticalPadding
        ) ?? defaults.verticalPadding
    }
}

public struct ThemeSkinGlass: Codable, Equatable, Sendable {
    public var blurRadius: Double
    public var saturation: Double
    public var borderWidth: Double
    public var cornerRadius: Double
    public var shadowOpacity: Double
    public var shadowBlur: Double
    public var textShadowOpacity: Double

    public init(
        blurRadius: Double = 18,
        saturation: Double = 1.12,
        borderWidth: Double = 1,
        cornerRadius: Double = 16,
        shadowOpacity: Double = 0.24,
        shadowBlur: Double = 36,
        textShadowOpacity: Double = 0.16
    ) {
        self.blurRadius = blurRadius
        self.saturation = saturation
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadowOpacity = shadowOpacity
        self.shadowBlur = shadowBlur
        self.textShadowOpacity = textShadowOpacity
    }

    private enum CodingKeys: String, CodingKey {
        case blurRadius
        case saturation
        case borderWidth
        case cornerRadius
        case shadowOpacity
        case shadowBlur
        case textShadowOpacity
    }

    public init(from decoder: Decoder) throws {
        let defaults = ThemeSkinGlass()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        blurRadius = try values.decodeIfPresent(
            Double.self,
            forKey: .blurRadius
        ) ?? defaults.blurRadius
        saturation = try values.decodeIfPresent(
            Double.self,
            forKey: .saturation
        ) ?? defaults.saturation
        borderWidth = try values.decodeIfPresent(
            Double.self,
            forKey: .borderWidth
        ) ?? defaults.borderWidth
        cornerRadius = try values.decodeIfPresent(
            Double.self,
            forKey: .cornerRadius
        ) ?? defaults.cornerRadius
        shadowOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .shadowOpacity
        ) ?? defaults.shadowOpacity
        shadowBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .shadowBlur
        ) ?? defaults.shadowBlur
        textShadowOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .textShadowOpacity
        ) ?? defaults.textShadowOpacity
    }
}

public struct ThemeSkinTargets: Codable, Equatable, Sendable {
    public var sidebar: Bool
    public var content: Bool
    public var titlebar: Bool
    public var composer: Bool
    public var cards: Bool
    public var popovers: Bool
    public var codeBlocks: Bool

    public init(
        sidebar: Bool = true,
        content: Bool = true,
        titlebar: Bool = true,
        composer: Bool = true,
        cards: Bool = true,
        popovers: Bool = true,
        codeBlocks: Bool = false
    ) {
        self.sidebar = sidebar
        self.content = content
        self.titlebar = titlebar
        self.composer = composer
        self.cards = cards
        self.popovers = popovers
        self.codeBlocks = codeBlocks
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case sidebar
        case content
        case titlebar
        case composer
        case cards
        case popovers
        case codeBlocks
    }

    public init(from decoder: Decoder) throws {
        let defaults = ThemeSkinTargets()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sidebar = try values.decodeIfPresent(
            Bool.self,
            forKey: .sidebar
        ) ?? defaults.sidebar
        content = try values.decodeIfPresent(
            Bool.self,
            forKey: .content
        ) ?? defaults.content
        titlebar = try values.decodeIfPresent(
            Bool.self,
            forKey: .titlebar
        ) ?? defaults.titlebar
        composer = try values.decodeIfPresent(
            Bool.self,
            forKey: .composer
        ) ?? defaults.composer
        cards = try values.decodeIfPresent(
            Bool.self,
            forKey: .cards
        ) ?? defaults.cards
        popovers = try values.decodeIfPresent(
            Bool.self,
            forKey: .popovers
        ) ?? defaults.popovers
        codeBlocks = try values.decodeIfPresent(
            Bool.self,
            forKey: .codeBlocks
        ) ?? defaults.codeBlocks
    }
}
