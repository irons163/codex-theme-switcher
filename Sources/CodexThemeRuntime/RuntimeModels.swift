import Foundation

public struct ThemeRuntimeStatus: Codable, Equatable, Sendable {
    public let codexPath: String?
    public let codexVersion: String?
    public let mode: String?
    public let isInjected: Bool?
    public let bridgeRunning: Bool?
    public let debugPort: Int?
    public let bridgePort: Int?
    public let isRunning: Bool?
    public let isDebugPortReady: Bool?
    public let hasCodexTarget: Bool?
    public let activeThemeID: String?
    public let activeThemeName: String?
    public let injectedRendererCount: Int?
    public let lastError: String?

    public init(
        codexPath: String? = nil,
        codexVersion: String? = nil,
        mode: String? = nil,
        isInjected: Bool? = nil,
        bridgeRunning: Bool? = nil,
        debugPort: Int? = nil,
        bridgePort: Int? = nil,
        isRunning: Bool? = nil,
        isDebugPortReady: Bool? = nil,
        hasCodexTarget: Bool? = nil,
        activeThemeID: String? = nil,
        activeThemeName: String? = nil,
        injectedRendererCount: Int? = nil,
        lastError: String? = nil
    ) {
        self.codexPath = codexPath
        self.codexVersion = codexVersion
        self.mode = mode
        self.isInjected = isInjected
        self.bridgeRunning = bridgeRunning
        self.debugPort = debugPort
        self.bridgePort = bridgePort
        self.isRunning = isRunning
        self.isDebugPortReady = isDebugPortReady
        self.hasCodexTarget = hasCodexTarget
        self.activeThemeID = activeThemeID
        self.activeThemeName = activeThemeName
        self.injectedRendererCount = injectedRendererCount
        self.lastError = lastError
    }
}

public struct ThemeRuntimeErrorPayload: Codable, Equatable, Sendable {
    public let message: String
    public let code: String?

    public init(message: String, code: String? = nil) {
        self.message = message
        self.code = code
    }
}

public struct ThemeRuntimeResult: Codable, Equatable, Sendable {
    public let ok: Bool
    public let status: ThemeRuntimeStatus?
    public let error: ThemeRuntimeErrorPayload?
    public let rawOutput: String?

    public init(
        ok: Bool,
        status: ThemeRuntimeStatus?,
        error: ThemeRuntimeErrorPayload?,
        rawOutput: String? = nil
    ) {
        self.ok = ok
        self.status = status
        self.error = error
        self.rawOutput = rawOutput
    }

    public func requiringSuccess() throws -> ThemeRuntimeResult {
        guard ok else {
            throw ThemeRuntimeFailure(
                message: error?.message ?? rawOutput ?? "Codex Theme runtime command failed."
            )
        }
        return self
    }
}

public struct ThemeRuntimeFailure: LocalizedError, Equatable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}

public struct ThemeRuntimeAsset: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let mediaType: String
    public let dataBase64: String

    public init(
        id: String,
        mediaType: String,
        dataBase64: String
    ) {
        self.id = id
        self.mediaType = mediaType
        self.dataBase64 = dataBase64
    }
}

struct RuntimeThemePayload: Encodable, Sendable {
    let themeID: String
    let themeName: String
    let css: String
    let assets: [ThemeRuntimeAsset]

    init(
        themeID: String,
        themeName: String,
        css: String,
        assets: [ThemeRuntimeAsset] = []
    ) {
        self.themeID = themeID
        self.themeName = themeName
        self.css = css
        self.assets = assets
    }

    enum CodingKeys: String, CodingKey {
        case themeID
        case themeName
        case css
        case assets
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(themeID, forKey: .themeID)
        try container.encode(themeName, forKey: .themeName)
        try container.encode(css, forKey: .css)
        if !assets.isEmpty {
            try container.encode(assets, forKey: .assets)
        }
    }
}
