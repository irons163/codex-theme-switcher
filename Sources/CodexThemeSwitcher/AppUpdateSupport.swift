import AppKit
import Foundation
import Sparkle

enum AppUpdateConfiguration {
    static let repositorySlug = "irons163/codex-theme-switcher"
    static let releasesPageURL = URL(
        string: "https://github.com/\(repositorySlug)/releases"
    )!
    static let latestReleaseAPIURL = URL(
        string: "https://api.github.com/repos/\(repositorySlug)/releases/latest"
    )!
    static let fallbackVersion = "0.3.0-beta.1"
    static let fallbackBuild = "15"

    static func feedURL(
        channel: AppUpdateChannel,
        architecture: AppUpdateArchitecture
    ) -> URL {
        let assetName = channel.feedAssetName(for: architecture)
        return URL(
            string: "https://github.com/\(repositorySlug)/releases/latest/download/\(assetName)"
        )!
    }
}

enum AppUpdateChannel: String, CaseIterable, Identifiable, Sendable {
    case stable
    case beta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stable:
            L10n.text("穩定版", "Stable")
        case .beta:
            L10n.text("Beta", "Beta")
        }
    }

    var detail: String {
        switch self {
        case .stable:
            L10n.text("建議使用的正式版本。", "Recommended releases.")
        case .beta:
            L10n.text(
                "可提早取得測試功能，但穩定性可能較低。",
                "Prerelease builds may be less stable."
            )
        }
    }

    func feedAssetName(
        for architecture: AppUpdateArchitecture
    ) -> String {
        let prefix = self == .beta ? "appcast-beta" : "appcast"
        return switch architecture {
        case .appleSilicon, .unknown:
            "\(prefix)-arm64.xml"
        case .intel:
            "\(prefix)-x86_64.xml"
        }
    }
}

enum AppUpdateArchitecture: Equatable, Sendable {
    case appleSilicon
    case intel
    case unknown

    static var current: AppUpdateArchitecture {
        #if arch(arm64)
        .appleSilicon
        #elseif arch(x86_64)
        .intel
        #else
        .unknown
        #endif
    }
}

enum AppUpdateError: LocalizedError, Equatable {
    case invalidResponse
    case decodingFailed
    case noReleaseAvailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            L10n.text(
                "更新伺服器回應無效。",
                "Invalid update response."
            )
        case .decodingFailed:
            L10n.text(
                "無法解析更新資訊。",
                "Failed to decode update metadata."
            )
        case .noReleaseAvailable:
            L10n.text(
                "這個更新頻道目前沒有可用版本。",
                "No update is available on this channel."
            )
        }
    }
}

struct AppVersionInfo: Equatable, Sendable {
    let version: String
    let build: String

    static var current: AppVersionInfo {
        let dictionary = Bundle.main.infoDictionary
        return AppVersionInfo(
            version: dictionary?["CFBundleShortVersionString"] as? String
                ?? AppUpdateConfiguration.fallbackVersion,
            build: dictionary?["CFBundleVersion"] as? String
                ?? AppUpdateConfiguration.fallbackBuild
        )
    }

    var versionID: String {
        let normalized = AppUpdateVersioning.normalizedVersion(from: version)
        let normalizedBuild = build.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return normalizedBuild.isEmpty
            ? normalized
            : "\(normalized)+\(normalizedBuild)"
    }
}

struct AppUpdateAsset: Equatable, Sendable {
    let name: String
    let downloadURL: URL
}

struct AppUpdateRelease: Equatable, Identifiable, Sendable {
    let tagName: String
    let name: String
    let htmlURL: URL
    let publishedAt: Date?
    let body: String?
    let assets: [AppUpdateAsset]
    let notesLanguageCode: String?

    var id: String { normalizedVersion }

    var normalizedVersion: String {
        AppUpdateVersioning.normalizedVersion(from: tagName)
    }

    var displayTitle: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? tagName : trimmed
    }

    var releaseNotesText: String? {
        guard let body else { return nil }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func replacingReleaseNotes(
        _ text: String,
        languageCode: String
    ) -> AppUpdateRelease {
        AppUpdateRelease(
            tagName: tagName,
            name: name,
            htmlURL: htmlURL,
            publishedAt: publishedAt,
            body: text,
            assets: assets,
            notesLanguageCode: languageCode
        )
    }

    func preferredInstallerURL(
        for architecture: AppUpdateArchitecture
    ) -> URL? {
        let diskImages = assets.filter {
            $0.name.lowercased().hasSuffix(".dmg")
        }
        guard !diskImages.isEmpty else { return nil }

        switch architecture {
        case .appleSilicon:
            if let match = diskImages.first(where: {
                let name = $0.name.lowercased()
                return name.contains("apple-silicon")
                    || name.contains("arm64")
                    || name.contains("aarch64")
            }) {
                return match.downloadURL
            }
        case .intel:
            if let match = diskImages.first(where: {
                let name = $0.name.lowercased()
                return name.contains("intel") || name.contains("x86_64")
            }) {
                return match.downloadURL
            }
        case .unknown:
            break
        }

        return diskImages.first?.downloadURL
    }

    func localizedReleaseNotesAsset(
        candidates: [String]
    ) -> (asset: AppUpdateAsset, languageCode: String)? {
        let noteAssets = assets.filter {
            let name = $0.name.lowercased()
            return name.hasSuffix(".md") || name.hasSuffix(".txt")
        }

        for candidate in candidates {
            if let asset = noteAssets.first(where: {
                Self.assetName($0.name, matchesLanguageCode: candidate)
            }) {
                return (asset, candidate)
            }
        }
        return nil
    }

    private static func assetName(
        _ name: String,
        matchesLanguageCode languageCode: String
    ) -> Bool {
        let nameTokens = normalizedTokens(name)
        let languageTokens = normalizedTokens(languageCode)
        guard !languageTokens.isEmpty,
              nameTokens.count >= languageTokens.count else {
            return false
        }

        for start in 0...(nameTokens.count - languageTokens.count) {
            if Array(
                nameTokens[start..<(start + languageTokens.count)]
            ) == languageTokens {
                return true
            }
        }
        return false
    }

    private static func normalizedTokens(_ value: String) -> [String] {
        value
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }
}

enum AppUpdateVersioning {
    static func normalizedVersion(from rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else { return "0" }
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }

    static func isRemoteNewer(
        current: String,
        remote: String
    ) -> Bool {
        compare(current, remote) == .orderedAscending
    }

    static func compare(
        _ lhsRaw: String,
        _ rhsRaw: String
    ) -> ComparisonResult {
        let lhs = SemanticVersion(normalizedVersion(from: lhsRaw))
        let rhs = SemanticVersion(normalizedVersion(from: rhsRaw))
        return lhs.compare(to: rhs)
    }

    private struct SemanticVersion {
        enum Identifier {
            case numeric(Int)
            case text(String)
        }

        let core: [Int]
        let prerelease: [Identifier]?

        init(_ rawValue: String) {
            let withoutBuild = rawValue.split(
                separator: "+",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )[0]
            let pieces = withoutBuild.split(
                separator: "-",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            core = pieces[0]
                .split(separator: ".", omittingEmptySubsequences: false)
                .map { Int($0) ?? 0 }
            if pieces.count > 1, !pieces[1].isEmpty {
                prerelease = pieces[1].split(separator: ".").map {
                    if let value = Int($0) {
                        return .numeric(value)
                    }
                    return .text($0.lowercased())
                }
            } else {
                prerelease = nil
            }
        }

        func compare(to other: SemanticVersion) -> ComparisonResult {
            let coreCount = max(core.count, other.core.count)
            for index in 0..<coreCount {
                let lhs = index < core.count ? core[index] : 0
                let rhs = index < other.core.count ? other.core[index] : 0
                if lhs < rhs { return .orderedAscending }
                if lhs > rhs { return .orderedDescending }
            }

            switch (prerelease, other.prerelease) {
            case (nil, nil):
                return .orderedSame
            case (nil, .some):
                return .orderedDescending
            case (.some, nil):
                return .orderedAscending
            case let (.some(lhs), .some(rhs)):
                let count = max(lhs.count, rhs.count)
                for index in 0..<count {
                    guard index < lhs.count else {
                        return .orderedAscending
                    }
                    guard index < rhs.count else {
                        return .orderedDescending
                    }
                    let result = Self.compare(lhs[index], rhs[index])
                    if result != .orderedSame { return result }
                }
                return .orderedSame
            }
        }

        private static func compare(
            _ lhs: Identifier,
            _ rhs: Identifier
        ) -> ComparisonResult {
            switch (lhs, rhs) {
            case let (.numeric(lhs), .numeric(rhs)):
                if lhs < rhs { return .orderedAscending }
                if lhs > rhs { return .orderedDescending }
                return .orderedSame
            case (.numeric, .text):
                return .orderedAscending
            case (.text, .numeric):
                return .orderedDescending
            case let (.text(lhs), .text(rhs)):
                return lhs.compare(rhs)
            }
        }
    }
}

enum AppUpdateAutoCheckPolicy {
    static let interval: TimeInterval = 30 * 60

    static func shouldRun(
        lastCheckedAt: TimeInterval,
        now: Date
    ) -> Bool {
        guard lastCheckedAt > 0 else { return true }
        return now.timeIntervalSince1970 - lastCheckedAt >= interval
    }
}

struct AppUpdateService: @unchecked Sendable {
    var latestEndpoint = AppUpdateConfiguration.latestReleaseAPIURL
    var session: URLSession = .shared

    func fetchLatestRelease(
        channel: AppUpdateChannel,
        language: AppLanguage
    ) async throws -> AppUpdateRelease {
        let requestURL = channel == .beta
            ? releasesListEndpoint(from: latestEndpoint)
            : latestEndpoint
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "CodexThemeSwitcher/\(AppVersionInfo.current.version)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppUpdateError.invalidResponse
        }

        let payload: AppUpdateReleasePayload
        do {
            if channel == .beta {
                let releases = try JSONDecoder().decode(
                    [AppUpdateReleasePayload].self,
                    from: data
                )
                guard let latest = releases
                    .filter(\.isVisible)
                    .max(by: {
                        AppUpdateVersioning.compare(
                            $0.tagName,
                            $1.tagName
                        ) == .orderedAscending
                    }) else {
                    throw AppUpdateError.noReleaseAvailable
                }
                payload = latest
            } else {
                payload = try JSONDecoder().decode(
                    AppUpdateReleasePayload.self,
                    from: data
                )
            }
        } catch let error as AppUpdateError {
            throw error
        } catch {
            throw AppUpdateError.decodingFailed
        }

        let release = payload.release
        guard let localizedNotes = release.localizedReleaseNotesAsset(
            candidates: language.releaseNotesCandidates
        ) else {
            return release
        }

        var notesRequest = URLRequest(
            url: localizedNotes.asset.downloadURL
        )
        notesRequest.setValue(
            "CodexThemeSwitcher/\(AppVersionInfo.current.version)",
            forHTTPHeaderField: "User-Agent"
        )
        guard let (notesData, notesResponse) = try? await session.data(
            for: notesRequest
        ),
              let notesHTTPResponse = notesResponse as? HTTPURLResponse,
              (200..<300).contains(notesHTTPResponse.statusCode),
              let notes = String(data: notesData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !notes.isEmpty else {
            return release
        }
        return release.replacingReleaseNotes(
            notes,
            languageCode: localizedNotes.languageCode
        )
    }

    private func releasesListEndpoint(from endpoint: URL) -> URL {
        guard var components = URLComponents(
            url: endpoint,
            resolvingAgainstBaseURL: false
        ) else {
            return endpoint
        }
        components.path = components.path.replacingOccurrences(
            of: "/releases/latest",
            with: "/releases"
        )
        components.queryItems = [
            URLQueryItem(name: "per_page", value: "30")
        ]
        return components.url ?? endpoint
    }
}

private extension AppLanguage {
    var releaseNotesCandidates: [String] {
        switch self {
        case .traditionalChinese:
            ["zh-hant", "zh", "en"]
        case .simplifiedChinese:
            ["zh-hans", "zh", "en"]
        default:
            [rawValue.lowercased(), "en"]
        }
    }
}

private struct AppUpdateReleasePayload: Decodable {
    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let name: String?
    let htmlURL: URL
    let publishedAt: String?
    let body: String?
    let draft: Bool?
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case body
        case draft
        case assets
    }

    var isVisible: Bool {
        draft != true
    }

    var release: AppUpdateRelease {
        let publishedDate = publishedAt.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return AppUpdateRelease(
            tagName: tagName,
            name: name ?? "",
            htmlURL: htmlURL,
            publishedAt: publishedDate,
            body: body,
            assets: assets.map {
                AppUpdateAsset(
                    name: $0.name,
                    downloadURL: $0.browserDownloadURL
                )
            },
            notesLanguageCode: nil
        )
    }
}

@MainActor
protocol AppUpdateInstalling: AnyObject {
    var isAvailable: Bool { get }
    func configure(channel: AppUpdateChannel)
    func startUserInitiatedUpdate() -> Bool
}

@MainActor
final class SparkleUpdateDriver: NSObject, AppUpdateInstalling {
    static let shared = SparkleUpdateDriver()

    private var channel: AppUpdateChannel = .stable
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
    )

    var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    func configure(channel: AppUpdateChannel) {
        self.channel = channel
        guard isAvailable else { return }
        updaterController.updater.automaticallyChecksForUpdates = false
    }

    func startUserInitiatedUpdate() -> Bool {
        guard isAvailable,
              updaterController.updater.canCheckForUpdates else {
            return false
        }
        updaterController.checkForUpdates(nil)
        return true
    }

    private override init() {
        super.init()
    }
}

extension SparkleUpdateDriver: SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        AppUpdateConfiguration.feedURL(
            channel: channel,
            architecture: .current
        ).absoluteString
    }
}

enum AppUpdateSheet: Identifiable, Equatable {
    case update(AppUpdateRelease)
    case whatsNew(String)

    var id: String {
        switch self {
        case let .update(release):
            "update-\(release.id)"
        case let .whatsNew(versionID):
            "whats-new-\(versionID)"
        }
    }
}

@MainActor
final class AppUpdateModel: ObservableObject {
    private enum DefaultsKey {
        static let automaticChecks =
            "codex_theme_switcher.updates.automatic_checks"
        static let channel = "codex_theme_switcher.updates.channel"
        static let lastCheckedAt =
            "codex_theme_switcher.updates.last_checked_at"
        static let skippedVersion =
            "codex_theme_switcher.updates.skipped_version"
        static let lastSeenWhatsNew =
            "codex_theme_switcher.whats_new.last_seen"
    }

    @Published var automaticChecksEnabled: Bool {
        didSet {
            defaults.set(
                automaticChecksEnabled,
                forKey: DefaultsKey.automaticChecks
            )
            if !automaticChecksEnabled {
                cancelCurrentCheck()
                statusMessage = L10n.text(
                    "已關閉自動檢查。",
                    "Automatic checks are off."
                )
            }
            restartAutomaticChecks()
        }
    }
    @Published var channel: AppUpdateChannel {
        didSet {
            defaults.set(channel.rawValue, forKey: DefaultsKey.channel)
            defaults.removeObject(forKey: DefaultsKey.skippedVersion)
            cancelCurrentCheck()
            availableRelease = nil
            statusMessage = nil
            installer.configure(channel: channel)
            if isStarted {
                restartAutomaticChecks()
            }
        }
    }
    @Published private(set) var isChecking = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var availableRelease: AppUpdateRelease?
    @Published var sheet: AppUpdateSheet?

    let versionInfo: AppVersionInfo

    private let defaults: UserDefaults
    private let service: AppUpdateService
    private let installer: AppUpdateInstalling
    private var automaticTask: Task<Void, Never>?
    private var checkTask: Task<Void, Never>?
    private var checkGeneration: UInt = 0
    private var isStarted = false
    private var didPresentLaunchAnnouncement = false

    init(
        defaults: UserDefaults = .standard,
        service: AppUpdateService = AppUpdateService(),
        installer: AppUpdateInstalling = SparkleUpdateDriver.shared,
        versionInfo: AppVersionInfo = .current
    ) {
        self.defaults = defaults
        self.service = service
        self.installer = installer
        self.versionInfo = versionInfo

        if defaults.object(
            forKey: DefaultsKey.automaticChecks
        ) == nil {
            automaticChecksEnabled = true
        } else {
            automaticChecksEnabled = defaults.bool(
                forKey: DefaultsKey.automaticChecks
            )
        }
        channel = AppUpdateChannel(
            rawValue: defaults.string(forKey: DefaultsKey.channel) ?? ""
        ) ?? (versionInfo.version.contains("-") ? .beta : .stable)
    }

    deinit {
        automaticTask?.cancel()
        checkTask?.cancel()
    }

    var sparkleIsAvailable: Bool {
        installer.isAvailable
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        installer.configure(channel: channel)
        restartAutomaticChecks()
    }

    func presentLaunchAnnouncements() {
        guard !didPresentLaunchAnnouncement else { return }
        didPresentLaunchAnnouncement = true
        guard sheet == nil else { return }
        showWhatsNewIfNeeded()
    }

    func checkForUpdates(
        userInitiated: Bool = true,
        bypassCadence: Bool = true
    ) {
        guard !isChecking else { return }
        if !userInitiated && !automaticChecksEnabled { return }

        let lastCheckedAt = defaults.double(
            forKey: DefaultsKey.lastCheckedAt
        )
        if !userInitiated,
           !bypassCadence,
           !AppUpdateAutoCheckPolicy.shouldRun(
               lastCheckedAt: lastCheckedAt,
               now: .now
           ) {
            return
        }

        isChecking = true
        if userInitiated {
            statusMessage = L10n.text(
                "正在檢查更新…",
                "Checking for updates…"
            )
        }
        let selectedChannel = channel

        checkGeneration &+= 1
        let generation = checkGeneration
        checkTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if generation == checkGeneration {
                    isChecking = false
                    checkTask = nil
                }
            }
            defaults.set(
                Date.now.timeIntervalSince1970,
                forKey: DefaultsKey.lastCheckedAt
            )
            do {
                let release = try await service.fetchLatestRelease(
                    channel: selectedChannel,
                    language: L10n.language
                )
                guard !Task.isCancelled,
                      generation == checkGeneration,
                      selectedChannel == channel else {
                    return
                }
                let latestVersion = release.normalizedVersion
                guard AppUpdateVersioning.isRemoteNewer(
                    current: versionInfo.version,
                    remote: latestVersion
                ) else {
                    availableRelease = nil
                    statusMessage = L10n.format(
                        "已是最新版本（{0}）。",
                        "You're up to date ({0}).",
                        versionInfo.version
                    )
                    return
                }

                availableRelease = release
                statusMessage = L10n.format(
                    "有新版本 {0} 可用。",
                    "Version {0} is available.",
                    latestVersion
                )
                let skipped = defaults.string(
                    forKey: DefaultsKey.skippedVersion
                )
                if userInitiated
                    || (skipped != latestVersion && sheet == nil) {
                    sheet = .update(release)
                }
            } catch {
                guard !Task.isCancelled,
                      generation == checkGeneration else {
                    return
                }
                if userInitiated {
                    statusMessage = L10n.format(
                        "檢查更新失敗：{0}",
                        "Update check failed: {0}",
                        error.localizedDescription
                    )
                }
            }
        }
    }

    func presentAvailableUpdate() {
        guard let availableRelease else { return }
        sheet = .update(availableRelease)
    }

    func install(_ release: AppUpdateRelease) {
        sheet = nil
        if installer.startUserInitiatedUpdate() {
            return
        }
        statusMessage = L10n.text(
            "無法啟動 Sparkle，已改為開啟下載頁面。",
            "Unable to start Sparkle. Open the download page instead."
        )
        openManualDownload(release)
    }

    func openManualDownload(_ release: AppUpdateRelease) {
        let url = release.preferredInstallerURL(for: .current)
            ?? release.htmlURL
        NSWorkspace.shared.open(url)
    }

    func openReleasesPage() {
        NSWorkspace.shared.open(AppUpdateConfiguration.releasesPageURL)
    }

    func skip(_ release: AppUpdateRelease) {
        defaults.set(
            release.normalizedVersion,
            forKey: DefaultsKey.skippedVersion
        )
        sheet = nil
    }

    func dismissSheet() {
        sheet = nil
    }

    func showWhatsNew() {
        sheet = .whatsNew(versionInfo.versionID)
    }

    func dismissWhatsNew(markSeen: Bool) {
        if markSeen {
            defaults.set(
                versionInfo.versionID,
                forKey: DefaultsKey.lastSeenWhatsNew
            )
        }
        sheet = nil
        if let availableRelease {
            let skipped = defaults.string(
                forKey: DefaultsKey.skippedVersion
            )
            if skipped != availableRelease.normalizedVersion {
                sheet = .update(availableRelease)
            }
        }
    }

    private func showWhatsNewIfNeeded() {
        let lastSeen = defaults.string(
            forKey: DefaultsKey.lastSeenWhatsNew
        ) ?? ""
        guard lastSeen != versionInfo.versionID else { return }
        sheet = .whatsNew(versionInfo.versionID)
    }

    private func restartAutomaticChecks() {
        automaticTask?.cancel()
        guard isStarted, automaticChecksEnabled else { return }

        automaticTask = Task { [weak self] in
            self?.checkForUpdates(
                userInitiated: false,
                bypassCadence: true
            )
            while !Task.isCancelled {
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        AppUpdateAutoCheckPolicy.interval * 1_000_000_000
                    )
                )
                guard !Task.isCancelled else { return }
                self?.checkForUpdates(
                    userInitiated: false,
                    bypassCadence: true
                )
            }
        }
    }

    private func cancelCurrentCheck() {
        checkTask?.cancel()
        checkTask = nil
        checkGeneration &+= 1
        isChecking = false
    }
}
