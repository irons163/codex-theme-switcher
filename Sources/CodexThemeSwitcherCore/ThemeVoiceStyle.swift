import Foundation

public enum ThemeVoiceAvatarMode: String, Codable, CaseIterable, Equatable, Sendable {
    /// Keep ChatGPT's original animated Voice orb.
    case native
    /// Use the existing flat portrait, mouth-frame, and blink-image renderer.
    case image
    /// Render an imported Cubism `.model3.json` package with WebGL.
    case live2D
}

public struct ThemeLive2DResource: Codable, Equatable, Sendable, Identifiable {
    public var path: String
    public var assetID: UUID

    public var id: String { path }

    public init(path: String, assetID: UUID) {
        self.path = path
        self.assetID = assetID
    }
}

public struct ThemeLive2DModel: Codable, Equatable, Sendable {
    /// Path of the `.model3.json` file relative to the imported model folder.
    public var modelSettingsPath: String
    /// Every Cubism file required by the settings file, including the settings
    /// file itself. Paths remain relative so the Web loader can resolve them.
    public var resources: [ThemeLive2DResource]
    public var scale: Double
    public var positionX: Double
    public var positionY: Double
    public var mouthParameterID: String
    public var angleXParameterID: String
    public var angleYParameterID: String
    public var angleZParameterID: String
    public var bodyAngleXParameterID: String

    public init(
        modelSettingsPath: String,
        resources: [ThemeLive2DResource],
        scale: Double = 1,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        mouthParameterID: String = "ParamMouthOpenY",
        angleXParameterID: String = "ParamAngleX",
        angleYParameterID: String = "ParamAngleY",
        angleZParameterID: String = "ParamAngleZ",
        bodyAngleXParameterID: String = "ParamBodyAngleX"
    ) {
        self.modelSettingsPath = modelSettingsPath
        self.resources = resources
        self.scale = scale
        self.positionX = positionX
        self.positionY = positionY
        self.mouthParameterID = mouthParameterID
        self.angleXParameterID = angleXParameterID
        self.angleYParameterID = angleYParameterID
        self.angleZParameterID = angleZParameterID
        self.bodyAngleXParameterID = bodyAngleXParameterID
    }
}

/// Best-effort styling for ChatGPT Voice's dedicated avatar-overlay renderer.
///
/// The renderer can contain ordinary DOM, SVG, Canvas, WebGL, and native
/// Core Animation surfaces depending on the installed Codex version. These
/// settings affect CSS-addressable surfaces and the renderer container only;
/// they deliberately make no promise about native layers.
public struct ThemeVoiceStyle: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var light: ThemeVoiceVariant
    public var dark: ThemeVoiceVariant
    /// Advanced CSS delivered only to the avatar-overlay renderer.
    public var rawCSS: String

    public init(
        isEnabled: Bool = false,
        light: ThemeVoiceVariant = .lightDefault,
        dark: ThemeVoiceVariant = .darkDefault,
        rawCSS: String = ""
    ) {
        self.isEnabled = isEnabled
        self.light = light
        self.dark = dark
        self.rawCSS = rawCSS
    }

    public func variant(for appearance: ThemeSkinAppearance) -> ThemeVoiceVariant {
        appearance == .light ? light : dark
    }

    public mutating func setVariant(
        _ variant: ThemeVoiceVariant,
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
        case light
        case dark
        case rawCSS
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .isEnabled
        ) ?? false
        if values.contains(.light), try !values.decodeNil(forKey: .light) {
            light = try ThemeVoiceVariant(
                from: values.superDecoder(forKey: .light),
                defaults: .lightDefault
            )
        } else {
            light = .lightDefault
        }
        if values.contains(.dark), try !values.decodeNil(forKey: .dark) {
            dark = try ThemeVoiceVariant(
                from: values.superDecoder(forKey: .dark),
                defaults: .darkDefault
            )
        } else {
            dark = .darkDefault
        }
        rawCSS = try values.decodeIfPresent(
            String.self,
            forKey: .rawCSS
        ) ?? ""
    }
}

public struct ThemeVoiceVariant: Codable, Equatable, Sendable {
    /// Selects the renderer without removing data owned by the other modes.
    /// This lets users switch back to a flat portrait without reimporting it.
    public var avatarMode: ThemeVoiceAvatarMode
    public var live2DModel: ThemeLive2DModel?
    public var backgroundAssetID: UUID?
    public var backgroundImageFit: ThemeSkinImageFit
    public var backgroundPositionX: Double
    public var backgroundPositionY: Double
    public var backgroundZoom: Double
    public var backgroundImageOpacity: Double
    public var backgroundImageBlur: Double
    /// Width, in CSS pixels, of ChatGPT's measured Voice mascot area.
    ///
    /// ChatGPT derives the native overlay window height from this measurement,
    /// so increasing it gives large portraits and Live2D models more room.
    public var overlayMascotWidth: Double
    /// Keeps the draggable Voice mascot anchored to the overlay center.
    ///
    /// When disabled, ChatGPT's native positioning can move the orb to screen
    /// edges regardless of whether an overlay background image is configured.
    public var orbLocksToOverlayCenter: Bool
    public var orbBackgroundAssetID: UUID?
    public var orbBackgroundImageFit: ThemeSkinImageFit
    public var orbBackgroundPositionX: Double
    public var orbBackgroundPositionY: Double
    public var orbBackgroundImageOpacity: Double
    public var orbBackgroundImageBlur: Double
    public var orbBackgroundInset: Double
    public var orbBackgroundFollowsVoicePulse: Bool
    public var orbBackgroundPulseStrength: Double
    /// Additional mouth poses ordered from least to most open.
    ///
    /// `orbBackgroundAssetID` remains the closed-mouth frame so existing
    /// single-image themes continue to work without migration.
    public var orbMouthFrameAssetIDs: [UUID]
    public var orbMouthSensitivity: Double
    /// How quickly the mouth opens when output energy rises.
    public var orbMouthAttackMilliseconds: Double
    /// How quickly the mouth closes after output energy falls.
    public var orbMouthReleaseMilliseconds: Double
    /// Output energy below this value is treated as silence.
    public var orbMouthNoiseGate: Double
    /// Shapes the amplitude-to-mouth-opening response.
    public var orbMouthResponseCurve: Double
    /// Legacy discrete-frame controls retained for theme compatibility.
    public var orbMouthSmoothing: Double
    public var orbMouthFrameHoldMilliseconds: Double
    /// Enables subtle portrait movement while Voice output is silent.
    public var orbIdleMotionEnabled: Bool
    /// Multiplier for the idle translation and rotation amplitude.
    public var orbIdleMotionStrength: Double
    /// Duration of one full idle sway cycle.
    public var orbIdleMotionPeriodSeconds: Double
    /// Optional matching portrait with closed eyes for idle blinking.
    public var orbBlinkAssetID: UUID?
    /// Average delay between idle blinks.
    public var orbBlinkIntervalSeconds: Double
    /// Duration of one complete close-and-open blink.
    public var orbBlinkDurationMilliseconds: Double
    public var orbScale: Double
    public var orbOpacity: Double
    public var brightness: Double
    public var contrast: Double
    public var saturation: Double
    public var hueRotation: Double
    public var blur: Double
    public var glowColor: String
    public var glowOpacity: Double
    public var glowBlur: Double
    public var backdropColor: String
    public var backdropOpacity: Double

    public init(
        avatarMode: ThemeVoiceAvatarMode = .image,
        live2DModel: ThemeLive2DModel? = nil,
        backgroundAssetID: UUID? = nil,
        backgroundImageFit: ThemeSkinImageFit = .cover,
        backgroundPositionX: Double = 0.5,
        backgroundPositionY: Double = 0.5,
        backgroundZoom: Double = 1,
        backgroundImageOpacity: Double = 1,
        backgroundImageBlur: Double = 0,
        overlayMascotWidth: Double = 113,
        orbLocksToOverlayCenter: Bool = true,
        orbBackgroundAssetID: UUID? = nil,
        orbBackgroundImageFit: ThemeSkinImageFit = .cover,
        orbBackgroundPositionX: Double = 0.5,
        orbBackgroundPositionY: Double = 0.5,
        orbBackgroundImageOpacity: Double = 1,
        orbBackgroundImageBlur: Double = 0,
        orbBackgroundInset: Double = 4,
        orbBackgroundFollowsVoicePulse: Bool = true,
        orbBackgroundPulseStrength: Double = 1,
        orbMouthFrameAssetIDs: [UUID] = [],
        orbMouthSensitivity: Double = 1,
        orbMouthAttackMilliseconds: Double = 18,
        orbMouthReleaseMilliseconds: Double = 72,
        orbMouthNoiseGate: Double = 0.05,
        orbMouthResponseCurve: Double = 0.9,
        orbMouthSmoothing: Double = 0.72,
        orbMouthFrameHoldMilliseconds: Double = 80,
        orbIdleMotionEnabled: Bool = false,
        orbIdleMotionStrength: Double = 0.35,
        orbIdleMotionPeriodSeconds: Double = 4.8,
        orbBlinkAssetID: UUID? = nil,
        orbBlinkIntervalSeconds: Double = 4.2,
        orbBlinkDurationMilliseconds: Double = 140,
        orbScale: Double = 1,
        orbOpacity: Double = 1,
        brightness: Double = 1,
        contrast: Double = 1,
        saturation: Double = 1,
        hueRotation: Double = 0,
        blur: Double = 0,
        glowColor: String = "#66D9FF",
        glowOpacity: Double = 0.55,
        glowBlur: Double = 28,
        backdropColor: String = "#000000",
        backdropOpacity: Double = 0
    ) {
        self.avatarMode = avatarMode
        self.live2DModel = live2DModel
        self.backgroundAssetID = backgroundAssetID
        self.backgroundImageFit = backgroundImageFit
        self.backgroundPositionX = backgroundPositionX
        self.backgroundPositionY = backgroundPositionY
        self.backgroundZoom = backgroundZoom
        self.backgroundImageOpacity = backgroundImageOpacity
        self.backgroundImageBlur = backgroundImageBlur
        self.overlayMascotWidth = overlayMascotWidth
        self.orbLocksToOverlayCenter = orbLocksToOverlayCenter
        self.orbBackgroundAssetID = orbBackgroundAssetID
        self.orbBackgroundImageFit = orbBackgroundImageFit
        self.orbBackgroundPositionX = orbBackgroundPositionX
        self.orbBackgroundPositionY = orbBackgroundPositionY
        self.orbBackgroundImageOpacity = orbBackgroundImageOpacity
        self.orbBackgroundImageBlur = orbBackgroundImageBlur
        self.orbBackgroundInset = orbBackgroundInset
        self.orbBackgroundFollowsVoicePulse = orbBackgroundFollowsVoicePulse
        self.orbBackgroundPulseStrength = orbBackgroundPulseStrength
        self.orbMouthFrameAssetIDs = orbMouthFrameAssetIDs
        self.orbMouthSensitivity = orbMouthSensitivity
        self.orbMouthAttackMilliseconds = orbMouthAttackMilliseconds
        self.orbMouthReleaseMilliseconds = orbMouthReleaseMilliseconds
        self.orbMouthNoiseGate = orbMouthNoiseGate
        self.orbMouthResponseCurve = orbMouthResponseCurve
        self.orbMouthSmoothing = orbMouthSmoothing
        self.orbMouthFrameHoldMilliseconds = orbMouthFrameHoldMilliseconds
        self.orbIdleMotionEnabled = orbIdleMotionEnabled
        self.orbIdleMotionStrength = orbIdleMotionStrength
        self.orbIdleMotionPeriodSeconds = orbIdleMotionPeriodSeconds
        self.orbBlinkAssetID = orbBlinkAssetID
        self.orbBlinkIntervalSeconds = orbBlinkIntervalSeconds
        self.orbBlinkDurationMilliseconds = orbBlinkDurationMilliseconds
        self.orbScale = orbScale
        self.orbOpacity = orbOpacity
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.hueRotation = hueRotation
        self.blur = blur
        self.glowColor = glowColor
        self.glowOpacity = glowOpacity
        self.glowBlur = glowBlur
        self.backdropColor = backdropColor
        self.backdropOpacity = backdropOpacity
    }

    public static let lightDefault = ThemeVoiceVariant(
        glowColor: "#2F80ED",
        glowOpacity: 0.42,
        backdropColor: "#FFFFFF"
    )

    public static let darkDefault = ThemeVoiceVariant()

    /// Tuned animated-portrait defaults used when Voice styling is enabled
    /// for the first time. Asset references are attached by the app because
    /// portable theme assets require document-specific UUIDs.
    public static let animatedPortraitDefault = ThemeVoiceVariant(
        backgroundImageFit: .contain,
        backgroundPositionX: 0.5,
        backgroundPositionY: 0.5,
        backgroundZoom: 1.72,
        backgroundImageOpacity: 0.44,
        backgroundImageBlur: 0,
        orbBackgroundImageFit: .cover,
        orbBackgroundPositionX: 0.5,
        orbBackgroundPositionY: 0.5,
        orbBackgroundImageOpacity: 1,
        orbBackgroundImageBlur: 0,
        orbBackgroundInset: 0,
        orbBackgroundFollowsVoicePulse: true,
        orbBackgroundPulseStrength: 2,
        orbMouthSensitivity: 0.8,
        orbMouthAttackMilliseconds: 8,
        orbMouthReleaseMilliseconds: 40,
        orbMouthNoiseGate: 0.045,
        orbMouthResponseCurve: 1.45,
        orbMouthSmoothing: 0.9,
        orbMouthFrameHoldMilliseconds: 80,
        orbIdleMotionEnabled: true,
        orbIdleMotionStrength: 1.4,
        orbIdleMotionPeriodSeconds: 5.8,
        orbBlinkIntervalSeconds: 3,
        orbBlinkDurationMilliseconds: 200,
        orbScale: 3,
        orbOpacity: 0,
        brightness: 1,
        contrast: 1,
        saturation: 1,
        hueRotation: 0,
        blur: 0,
        glowColor: "#66D9FF",
        glowOpacity: 0,
        glowBlur: 39,
        backdropColor: "#000000",
        backdropOpacity: 0
    )

    private enum CodingKeys: String, CodingKey {
        case avatarMode
        case live2DModel
        case backgroundAssetID
        case backgroundImageFit
        case backgroundPositionX
        case backgroundPositionY
        case backgroundZoom
        case backgroundImageOpacity
        case backgroundImageBlur
        case overlayMascotWidth
        case orbLocksToOverlayCenter
        case orbBackgroundAssetID
        case orbBackgroundImageFit
        case orbBackgroundPositionX
        case orbBackgroundPositionY
        case orbBackgroundImageOpacity
        case orbBackgroundImageBlur
        case orbBackgroundInset
        case orbBackgroundFollowsVoicePulse
        case orbBackgroundPulseStrength
        case orbMouthFrameAssetIDs
        case orbMouthSensitivity
        case orbMouthAttackMilliseconds
        case orbMouthReleaseMilliseconds
        case orbMouthNoiseGate
        case orbMouthResponseCurve
        case orbMouthSmoothing
        case orbMouthFrameHoldMilliseconds
        case orbIdleMotionEnabled
        case orbIdleMotionStrength
        case orbIdleMotionPeriodSeconds
        case orbBlinkAssetID
        case orbBlinkIntervalSeconds
        case orbBlinkDurationMilliseconds
        case orbScale
        case orbOpacity
        case brightness
        case contrast
        case saturation
        case hueRotation
        case blur
        case glowColor
        case glowOpacity
        case glowBlur
        case backdropColor
        case backdropOpacity
    }

    public init(from decoder: Decoder) throws {
        try self.init(from: decoder, defaults: .darkDefault)
    }

    init(
        from decoder: Decoder,
        defaults: ThemeVoiceVariant
    ) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        live2DModel = try values.decodeIfPresent(
            ThemeLive2DModel.self,
            forKey: .live2DModel
        )
        backgroundAssetID = try values.decodeIfPresent(
            UUID.self,
            forKey: .backgroundAssetID
        )
        if let rawImageFit = try values.decodeIfPresent(
            String.self,
            forKey: .backgroundImageFit
        ) {
            backgroundImageFit = ThemeSkinImageFit(rawValue: rawImageFit)
                ?? defaults.backgroundImageFit
        } else {
            backgroundImageFit = defaults.backgroundImageFit
        }
        backgroundPositionX = try values.decodeIfPresent(
            Double.self,
            forKey: .backgroundPositionX
        ) ?? defaults.backgroundPositionX
        backgroundPositionY = try values.decodeIfPresent(
            Double.self,
            forKey: .backgroundPositionY
        ) ?? defaults.backgroundPositionY
        backgroundZoom = try values.decodeIfPresent(
            Double.self,
            forKey: .backgroundZoom
        ) ?? defaults.backgroundZoom
        backgroundImageOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .backgroundImageOpacity
        ) ?? defaults.backgroundImageOpacity
        backgroundImageBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .backgroundImageBlur
        ) ?? defaults.backgroundImageBlur
        overlayMascotWidth = try values.decodeIfPresent(
            Double.self,
            forKey: .overlayMascotWidth
        ) ?? defaults.overlayMascotWidth
        orbLocksToOverlayCenter = try values.decodeIfPresent(
            Bool.self,
            forKey: .orbLocksToOverlayCenter
        ) ?? defaults.orbLocksToOverlayCenter
        orbBackgroundAssetID = try values.decodeIfPresent(
            UUID.self,
            forKey: .orbBackgroundAssetID
        )
        if let rawMode = try values.decodeIfPresent(
            String.self,
            forKey: .avatarMode
        ) {
            avatarMode = ThemeVoiceAvatarMode(rawValue: rawMode)
                ?? defaults.avatarMode
        } else if live2DModel != nil {
            avatarMode = .live2D
        } else if orbBackgroundAssetID != nil {
            // Themes created before avatarMode existed used the image renderer.
            avatarMode = .image
        } else {
            avatarMode = defaults.avatarMode
        }
        if let rawImageFit = try values.decodeIfPresent(
            String.self,
            forKey: .orbBackgroundImageFit
        ) {
            orbBackgroundImageFit = ThemeSkinImageFit(rawValue: rawImageFit)
                ?? defaults.orbBackgroundImageFit
        } else {
            orbBackgroundImageFit = defaults.orbBackgroundImageFit
        }
        orbBackgroundPositionX = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundPositionX
        ) ?? defaults.orbBackgroundPositionX
        orbBackgroundPositionY = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundPositionY
        ) ?? defaults.orbBackgroundPositionY
        orbBackgroundImageOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundImageOpacity
        ) ?? defaults.orbBackgroundImageOpacity
        orbBackgroundImageBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundImageBlur
        ) ?? defaults.orbBackgroundImageBlur
        orbBackgroundInset = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundInset
        ) ?? defaults.orbBackgroundInset
        orbBackgroundFollowsVoicePulse = try values.decodeIfPresent(
            Bool.self,
            forKey: .orbBackgroundFollowsVoicePulse
        ) ?? defaults.orbBackgroundFollowsVoicePulse
        orbBackgroundPulseStrength = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBackgroundPulseStrength
        ) ?? defaults.orbBackgroundPulseStrength
        orbMouthFrameAssetIDs = try values.decodeIfPresent(
            [UUID].self,
            forKey: .orbMouthFrameAssetIDs
        ) ?? defaults.orbMouthFrameAssetIDs
        orbMouthSensitivity = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthSensitivity
        ) ?? defaults.orbMouthSensitivity
        orbMouthAttackMilliseconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthAttackMilliseconds
        ) ?? defaults.orbMouthAttackMilliseconds
        orbMouthReleaseMilliseconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthReleaseMilliseconds
        ) ?? defaults.orbMouthReleaseMilliseconds
        orbMouthNoiseGate = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthNoiseGate
        ) ?? defaults.orbMouthNoiseGate
        orbMouthResponseCurve = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthResponseCurve
        ) ?? defaults.orbMouthResponseCurve
        orbMouthSmoothing = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthSmoothing
        ) ?? defaults.orbMouthSmoothing
        orbMouthFrameHoldMilliseconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbMouthFrameHoldMilliseconds
        ) ?? defaults.orbMouthFrameHoldMilliseconds
        orbIdleMotionEnabled = try values.decodeIfPresent(
            Bool.self,
            forKey: .orbIdleMotionEnabled
        ) ?? defaults.orbIdleMotionEnabled
        orbIdleMotionStrength = try values.decodeIfPresent(
            Double.self,
            forKey: .orbIdleMotionStrength
        ) ?? defaults.orbIdleMotionStrength
        orbIdleMotionPeriodSeconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbIdleMotionPeriodSeconds
        ) ?? defaults.orbIdleMotionPeriodSeconds
        orbBlinkAssetID = try values.decodeIfPresent(
            UUID.self,
            forKey: .orbBlinkAssetID
        )
        orbBlinkIntervalSeconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBlinkIntervalSeconds
        ) ?? defaults.orbBlinkIntervalSeconds
        orbBlinkDurationMilliseconds = try values.decodeIfPresent(
            Double.self,
            forKey: .orbBlinkDurationMilliseconds
        ) ?? defaults.orbBlinkDurationMilliseconds
        orbScale = try values.decodeIfPresent(
            Double.self,
            forKey: .orbScale
        ) ?? defaults.orbScale
        orbOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .orbOpacity
        ) ?? defaults.orbOpacity
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
        hueRotation = try values.decodeIfPresent(
            Double.self,
            forKey: .hueRotation
        ) ?? defaults.hueRotation
        blur = try values.decodeIfPresent(
            Double.self,
            forKey: .blur
        ) ?? defaults.blur
        glowColor = try values.decodeIfPresent(
            String.self,
            forKey: .glowColor
        ) ?? defaults.glowColor
        glowOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .glowOpacity
        ) ?? defaults.glowOpacity
        glowBlur = try values.decodeIfPresent(
            Double.self,
            forKey: .glowBlur
        ) ?? defaults.glowBlur
        backdropColor = try values.decodeIfPresent(
            String.self,
            forKey: .backdropColor
        ) ?? defaults.backdropColor
        backdropOpacity = try values.decodeIfPresent(
            Double.self,
            forKey: .backdropOpacity
        ) ?? defaults.backdropOpacity
    }
}
