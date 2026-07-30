import Foundation

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
    public var backgroundAssetID: UUID?
    public var backgroundImageFit: ThemeSkinImageFit
    public var backgroundPositionX: Double
    public var backgroundPositionY: Double
    public var backgroundZoom: Double
    public var backgroundImageOpacity: Double
    public var backgroundImageBlur: Double
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
        backgroundAssetID: UUID? = nil,
        backgroundImageFit: ThemeSkinImageFit = .cover,
        backgroundPositionX: Double = 0.5,
        backgroundPositionY: Double = 0.5,
        backgroundZoom: Double = 1,
        backgroundImageOpacity: Double = 1,
        backgroundImageBlur: Double = 0,
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
        self.backgroundAssetID = backgroundAssetID
        self.backgroundImageFit = backgroundImageFit
        self.backgroundPositionX = backgroundPositionX
        self.backgroundPositionY = backgroundPositionY
        self.backgroundZoom = backgroundZoom
        self.backgroundImageOpacity = backgroundImageOpacity
        self.backgroundImageBlur = backgroundImageBlur
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

    private enum CodingKeys: String, CodingKey {
        case backgroundAssetID
        case backgroundImageFit
        case backgroundPositionX
        case backgroundPositionY
        case backgroundZoom
        case backgroundImageOpacity
        case backgroundImageBlur
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
        orbBackgroundAssetID = try values.decodeIfPresent(
            UUID.self,
            forKey: .orbBackgroundAssetID
        )
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
