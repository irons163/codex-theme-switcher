import AppKit
import CodexThemeRuntime
import CodexThemeSwitcherCore
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ThemeAppModel: ObservableObject {
    private static let supportedSkinImageTypes: Set<String> = [
        "image/png",
        "image/jpeg",
        "image/webp",
        "image/gif",
        "image/avif"
    ]
    private static let draftHistoryLimit = 100
    private static let draftHistoryCoalescingInterval: TimeInterval = 1

    private struct DraftHistoryEntry {
        let document: ThemeDocument
        let actionName: String
    }

    private struct DraftHistoryState {
        var undoEntries: [DraftHistoryEntry] = []
        var redoEntries: [DraftHistoryEntry] = []
        var lastCoalescingKey: String?
        var lastMutationDate: Date?
    }

    enum EditorPage: String, CaseIterable, Identifiable {
        case preview
        case skin
        case colors
        case typography
        case components
        case rules
        case rawCSS
        case assets
        case info
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .preview: L10n.preview
            case .skin: L10n.skin
            case .colors: L10n.colors
            case .typography: L10n.typography
            case .components: L10n.components
            case .rules: L10n.rules
            case .rawCSS: L10n.rawCSS
            case .assets: L10n.assets
            case .info: L10n.info
            case .settings: L10n.text("設定", "Settings")
            }
        }

        var symbol: String {
            switch self {
            case .preview: "rectangle.on.rectangle"
            case .skin: "photo.artframe"
            case .colors: "paintpalette"
            case .typography: "textformat"
            case .components: "square.grid.2x2"
            case .rules: "list.bullet.rectangle"
            case .rawCSS: "chevron.left.forwardslash.chevron.right"
            case .assets: "photo.on.rectangle.angled"
            case .info: "info.circle"
            case .settings: "gearshape"
            }
        }
    }

    enum NoticeStyle {
        case info
        case success
        case error
    }

    struct Notice: Identifiable {
        let id = UUID()
        let text: String
        let style: NoticeStyle
    }

    @Published private(set) var themes: [ThemeDocument] = []
    @Published var selectedThemeID: UUID?
    @Published var draft: ThemeDocument?
    @Published private(set) var activeThemeID: UUID?
    @Published private(set) var runtimeStatus: ThemeRuntimeStatus?
    @Published private(set) var isBusy = false
    @Published private(set) var isLoaded = false
    @Published private(set) var isDraftDirty = false
    @Published private(set) var undoDraftActionName: String?
    @Published private(set) var redoDraftActionName: String?
    @Published private(set) var codexAppURL: URL
    @Published private(set) var hasCustomCodexApp: Bool
    @Published var selectedPage: EditorPage = .preview
    @Published var previewAppearance: ThemeSkinAppearance = .dark
    @Published var previewSurface: ThemePreviewSurface = .home
    @Published var notice: Notice?
    @Published var searchText = ""

    private let repository: FileThemeRepository
    private let archiveService: ThemeArchiveService
    private let compiler: ThemeCompiler
    private var runtime: ThemeRuntimeController?
    private var monitorTask: Task<Void, Never>?
    private var unsavedDrafts: [UUID: ThemeDocument] = [:]
    private var persistedDocuments: [UUID: ThemeDocument] = [:]
    private var draftHistories: [UUID: DraftHistoryState] = [:]
    private var runtimeMutationGeneration: UInt = 0

    init() {
        let resolvedCodexApp = RuntimeLocator.defaultCodexApp
        codexAppURL = resolvedCodexApp
        hasCustomCodexApp = RuntimeLocator.persistedCodexApp() != nil
        repository = FileThemeRepository()
        archiveService = ThemeArchiveService()
        compiler = ThemeCompiler()
        runtime = try? ThemeRuntimeController.standard(
            codexApp: resolvedCodexApp
        )
    }

    init(
        repository: FileThemeRepository,
        archiveService: ThemeArchiveService = ThemeArchiveService(),
        compiler: ThemeCompiler = ThemeCompiler(),
        codexAppURL: URL = RuntimeLocator.defaultCodexApp,
        hasCustomCodexApp: Bool = false,
        runtime: ThemeRuntimeController?
    ) {
        self.codexAppURL = codexAppURL
        self.hasCustomCodexApp = hasCustomCodexApp
        self.repository = repository
        self.archiveService = archiveService
        self.compiler = compiler
        self.runtime = runtime
    }

    deinit {
        monitorTask?.cancel()
    }

    var filteredThemes: [ThemeDocument] {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return themes }
        return themes.filter {
            $0.metadata.name.localizedCaseInsensitiveContains(query)
                || $0.metadata.author.localizedCaseInsensitiveContains(query)
                || $0.metadata.tags.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
        }
    }

    var activeThemeName: String? {
        runtimeStatus?.activeThemeName
    }

    var appliedThemeID: UUID? {
        runtimeStatus?.activeThemeID.flatMap(UUID.init(uuidString:))
    }

    var selectedTheme: ThemeDocument? {
        guard let selectedThemeID else { return nil }
        return themes.first { $0.id == selectedThemeID }
    }

    var availableSkinImageAssets: [ThemeAsset] {
        draft?.assets.filter {
            Self.supportedSkinImageTypes.contains(
                $0.mediaType.lowercased()
            ) && $0.decodedData != nil
        } ?? []
    }

    var isSelectedBuiltIn: Bool {
        guard let selectedThemeID else { return false }
        return BuiltInThemes.theme(id: selectedThemeID) != nil
    }

    var isAttached: Bool {
        runtimeStatus?.bridgeRunning == true
            && runtimeStatus?.hasCodexTarget == true
            && runtimeStatus?.isInjected == true
    }

    var codexAppIsAvailable: Bool {
        RuntimeLocator.isCodexDesktopApp(codexAppURL)
    }

    var canUndoDraft: Bool {
        undoDraftActionName != nil
    }

    var canRedoDraft: Bool {
        redoDraftActionName != nil
    }

    var runtimeSummary: String {
        if runtime == nil {
            return L10n.text("找不到 runtime", "Runtime unavailable")
        }
        if isAttached {
            if let activeThemeName {
                return L10n.format(
                    "已連接 ·「{0}」使用中",
                    "Attached · “{0}” active",
                    activeThemeName
                )
            }
            return L10n.text(
                "已連接 · 尚未套用主題",
                "Attached · No theme applied"
            )
        }
        if runtimeStatus?.isRunning == true {
            return L10n.text(
                "Codex 執行中，尚未連接",
                "Codex is running, not attached"
            )
        }
        return L10n.text("Codex 尚未連接", "Codex is not attached")
    }

    var launchAndAttachHelp: String {
        if let activeThemeName {
            return L10n.format(
                "連接後會恢復「{0}」。若尚未啟用 CDP，Codex 可能會重新啟動。",
                "Attaching will restore “{0}”. Codex may restart if CDP is not enabled.",
                activeThemeName
            )
        }
        return L10n.text(
            "連接後不會自動套用主題；選好後按「套用」。若尚未啟用 CDP，Codex 可能會重新啟動。",
            "No theme will be applied automatically. Choose one and click Apply after attaching. Codex may restart if CDP is not enabled."
        )
    }

    func start() {
        guard !isLoaded, !isBusy else { return }
        Task {
            await reloadThemes()
            await refreshRuntime()
            startMonitoring()
        }
    }

    func startMonitoring() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                await self?.refreshRuntime(silently: true)
            }
        }
    }

    func chooseCodexApplication() {
        let panel = NSOpenPanel()
        panel.title = L10n.text(
            "選擇 Codex App",
            "Choose Codex application"
        )
        panel.prompt = L10n.text("選擇", "Choose")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.applicationBundle]
        if codexAppIsAvailable {
            panel.directoryURL = codexAppURL.deletingLastPathComponent()
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard RuntimeLocator.isCodexDesktopApp(url) else {
            show(
                ThemeAppError.invalidCodexApplication(
                    url.lastPathComponent
                ).localizedDescription,
                style: .error
            )
            return
        }
        Task {
            await configureCodexApplication(url, persist: true)
        }
    }

    func useAutomaticCodexApplication() {
        Task {
            await configureCodexApplication(nil, persist: false)
        }
    }

    func selectTheme(_ id: UUID) {
        guard selectedThemeID != id,
              let theme = themes.first(where: { $0.id == id }) else {
            return
        }
        selectedThemeID = id
        draft = unsavedDrafts[id] ?? theme
        isDraftDirty = unsavedDrafts[id] != nil
        refreshDraftHistoryAvailability()
    }

    func hasUnsavedChanges(for id: UUID) -> Bool {
        unsavedDrafts[id] != nil
    }

    func createTheme() {
        var theme = BuiltInThemes.midnight
        let now = Date()
        theme.id = UUID()
        theme.metadata.name = L10n.text("未命名主題", "Untitled Theme")
        theme.metadata.author = NSFullUserName()
        theme.metadata.description = ""
        theme.metadata.version = "1.0.0"
        theme.metadata.tags = []
        theme.metadata.createdAt = now
        theme.metadata.updatedAt = now

        Task {
            await perform {
                let saved = try await self.repository.save(
                    theme,
                    collisionPolicy: .fail
                )
                await self.reloadThemes(selecting: saved.id)
                self.selectedPage = .colors
                self.show(
                    L10n.text("已建立新主題", "New theme created"),
                    style: .success
                )
            }
        }
    }

    func duplicateSelected() {
        guard var theme = draft ?? selectedTheme else { return }
        let now = Date()
        theme.id = UUID()
        theme.metadata.name += L10n.text(" 副本", " Copy")
        theme.metadata.createdAt = now
        theme.metadata.updatedAt = now

        Task {
            await perform {
                let saved = try await self.repository.save(
                    theme,
                    collisionPolicy: .fail
                )
                await self.reloadThemes(selecting: saved.id)
                self.show(
                    L10n.text(
                        "副本已建立，可以自由編輯",
                        "Editable copy created"
                    ),
                    style: .success
                )
            }
        }
    }

    @discardableResult
    func renameTheme(_ id: UUID, to proposedName: String) -> Bool {
        let name = proposedName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !name.isEmpty,
              BuiltInThemes.theme(id: id) == nil,
              themes.contains(where: { $0.id == id }) else {
            return false
        }

        selectTheme(id)
        mutateDraft(
            actionName: L10n.text("重新命名主題", "Rename theme"),
            coalesces: false
        ) {
            $0.metadata.name = name
        }
        return draft?.metadata.name == name
    }

    func saveDraft() {
        guard var draft, !isSelectedBuiltIn else { return }
        draft.metadata.updatedAt = Date()
        Task {
            await perform {
                let saved = try await self.repository.save(
                    draft,
                    collisionPolicy: .replace
                )
                self.unsavedDrafts.removeValue(forKey: saved.id)
                await self.reloadThemes(selecting: saved.id)
                self.show(
                    L10n.text("主題已儲存", "Theme saved"),
                    style: .success
                )
            }
        }
    }

    func deleteSelected() {
        guard let id = selectedThemeID, !isSelectedBuiltIn else { return }
        Task {
            await perform {
                let wasApplied = self.appliedThemeID == id
                let wasRepositoryActive = self.activeThemeID == id
                if wasApplied, let runtime = self.runtime {
                    self.runtimeMutationGeneration &+= 1
                    let result = try await runtime.clear().requiringSuccess()
                    self.runtimeStatus = result.status
                }
                if wasRepositoryActive {
                    try await self.repository.setActiveThemeID(nil)
                    self.activeThemeID = nil
                }
                try await self.repository.delete(id: id)
                self.unsavedDrafts.removeValue(forKey: id)
                self.persistedDocuments.removeValue(forKey: id)
                self.draftHistories.removeValue(forKey: id)
                await self.reloadThemes()
                self.show(
                    L10n.text("主題已刪除", "Theme deleted"),
                    style: .success
                )
            }
        }
    }

    func launchAndAttach() {
        Task {
            await perform {
                guard let runtime = self.runtime else {
                    throw RuntimeLocationError.missingHelper
                }
                self.runtimeMutationGeneration &+= 1
                let result = try await runtime.launch().requiringSuccess()
                self.runtimeStatus = result.status
                if let restoredThemeName = result.status?.activeThemeName {
                    self.show(
                        L10n.format(
                            "已連接 Codex，並恢復「{0}」",
                            "Codex attached. Restored “{0}”.",
                            restoredThemeName
                        ),
                        style: .success
                    )
                } else {
                    self.show(
                        L10n.text(
                            "已連接 Codex；選好主題後按「套用」",
                            "Codex attached. Choose a theme, then click Apply."
                        ),
                        style: .success
                    )
                }
            }
        }
    }

    func applyDraft() {
        guard let draft else { return }
        Task {
            await perform {
                guard let runtime = self.runtime else {
                    throw RuntimeLocationError.missingHelper
                }
                guard self.isAttached else {
                    throw ThemeAppError.codexNotAttached
                }
                self.runtimeMutationGeneration &+= 1

                var document = draft
                if !self.isSelectedBuiltIn {
                    document.metadata.updatedAt = Date()
                    document = try await self.repository.save(
                        document,
                        collisionPolicy: .replace
                    )
                    self.unsavedDrafts.removeValue(forKey: document.id)
                    self.isDraftDirty = false
                    if let index = self.themes.firstIndex(
                        where: { $0.id == document.id }
                    ) {
                        self.themes[index] = document
                    }
                }
                let compiled = try self.compiler.compile(document)
                let result = try await runtime.apply(
                    css: compiled.css,
                    themeID: document.id.uuidString,
                    themeName: document.metadata.name,
                    assets: compiled.runtimeAssets.map {
                        ThemeRuntimeAsset(
                            id: $0.id.uuidString.lowercased(),
                            mediaType: $0.mediaType,
                            dataBase64: $0.dataBase64
                        )
                    }
                ).requiringSuccess()

                self.runtimeStatus = result.status
                try await self.repository.setActiveThemeID(document.id)
                self.activeThemeID = document.id
                self.isDraftDirty = false
                await self.reloadThemes(selecting: document.id)
                self.show(
                    L10n.format(
                        "已套用「{0}」",
                        "Applied “{0}”",
                        document.metadata.name
                    ),
                    style: .success
                )
            }
        }
    }

    func applyTheme(_ id: UUID) {
        selectTheme(id)
        applyDraft()
    }

    func restoreCodexStyle() {
        Task {
            await perform {
                if let runtime = self.runtime {
                    self.runtimeMutationGeneration &+= 1
                    let result = try await runtime.clear().requiringSuccess()
                    self.runtimeStatus = result.status
                }
                try await self.repository.setActiveThemeID(nil)
                self.activeThemeID = nil
                self.show(
                    L10n.text(
                        "已恢復 Codex 原始樣式",
                        "Restored the original Codex style"
                    ),
                    style: .success
                )
            }
        }
    }

    func stopRuntime() {
        Task {
            await perform {
                if let runtime = self.runtime {
                    self.runtimeMutationGeneration &+= 1
                    let result = try await runtime.stop().requiringSuccess()
                    self.runtimeStatus = result.status
                }
            }
        }
    }

    func refreshRuntime(silently: Bool = false) async {
        guard let runtime, !isBusy else { return }
        let generation = runtimeMutationGeneration
        do {
            let result = try await runtime.status()
            guard generation == runtimeMutationGeneration, !isBusy else {
                return
            }
            runtimeStatus = result.status
            if !result.ok, !silently {
                show(
                    AppErrorLocalization.runtimeMessage(
                        code: result.error?.code,
                        fallback: result.error?.message
                    ),
                    style: .error
                )
            }
        } catch {
            if !silently {
                show(
                    AppErrorLocalization.message(for: error),
                    style: .error
                )
            }
        }
    }

    private func configureCodexApplication(
        _ selectedURL: URL?,
        persist: Bool
    ) async {
        await perform {
            let resolvedURL: URL
            if let selectedURL {
                resolvedURL = selectedURL.standardizedFileURL
                    .resolvingSymlinksInPath()
                guard RuntimeLocator.isCodexDesktopApp(resolvedURL) else {
                    throw ThemeAppError.invalidCodexApplication(
                        selectedURL.lastPathComponent
                    )
                }
            } else {
                resolvedURL = RuntimeLocator.automaticCodexApp()
                    ?? URL(fileURLWithPath: "/Applications/Codex.app")
            }

            let nextRuntime = try ThemeRuntimeController.standard(
                codexApp: resolvedURL
            )
            if persist {
                try RuntimeLocator.persistCodexApp(resolvedURL)
            } else {
                try RuntimeLocator.clearPersistedCodexApp()
            }

            self.runtimeMutationGeneration &+= 1
            if let runtime = self.runtime {
                _ = try? await runtime.stop()
            }
            self.runtime = nextRuntime
            self.codexAppURL = resolvedURL
            self.hasCustomCodexApp = persist
            self.runtimeStatus = nil

            let result = try await nextRuntime.status()
            self.runtimeStatus = result.status
            self.show(
                persist
                    ? L10n.text(
                        "已保存 Codex App 位置",
                        "Codex application location saved"
                    )
                    : L10n.text(
                        "已改用自動偵測 Codex",
                        "Automatic Codex discovery enabled"
                    ),
                style: .success
            )
        }
    }

    func mutateDraft(
        actionName: String = L10n.text("編輯主題", "Edit theme"),
        coalescingKey: String? = nil,
        coalesces: Bool = true,
        fileID: StaticString = #fileID,
        line: UInt = #line,
        _ mutation: (inout ThemeDocument) -> Void
    ) {
        guard let current = draft, !isSelectedBuiltIn else { return }
        var updated = current
        mutation(&updated)
        guard updated != current else { return }

        let resolvedCoalescingKey: String?
        if coalesces {
            resolvedCoalescingKey = coalescingKey
                ?? "\(String(describing: fileID)):\(line)"
        } else {
            resolvedCoalescingKey = nil
        }
        recordDraftHistory(
            previous: current,
            actionName: actionName,
            coalescingKey: resolvedCoalescingKey
        )

        updated.metadata.updatedAt = Date()
        publishDraft(updated)
    }

    func undoDraftChange() {
        guard let current = draft,
              !isSelectedBuiltIn,
              var history = draftHistories[current.id],
              let entry = history.undoEntries.popLast() else {
            return
        }

        history.redoEntries.append(
            DraftHistoryEntry(
                document: current,
                actionName: entry.actionName
            )
        )
        history.lastCoalescingKey = nil
        history.lastMutationDate = nil
        draftHistories[current.id] = history
        publishDraft(entry.document)
    }

    func redoDraftChange() {
        guard let current = draft,
              !isSelectedBuiltIn,
              var history = draftHistories[current.id],
              let entry = history.redoEntries.popLast() else {
            return
        }

        history.undoEntries.append(
            DraftHistoryEntry(
                document: current,
                actionName: entry.actionName
            )
        )
        trimDraftHistory(&history.undoEntries)
        history.lastCoalescingKey = nil
        history.lastMutationDate = nil
        draftHistories[current.id] = history
        publishDraft(entry.document)
    }

    func semanticValue(
        _ role: ThemeSemanticRole,
        fallback: String = ""
    ) -> String {
        (draft?.layers
            .filter(\.isEnabled)
            .flatMap(\.variables)
            .last(where: { $0.semanticRole == role && $0.isEnabled }))?.value
            ?? fallback
    }

    func setSemanticValue(_ role: ThemeSemanticRole, value: String) {
        mutateDraft { document in
            if document.layers.isEmpty {
                document.layers = [
                    ThemeLayer(name: L10n.text("基礎", "Base"))
                ]
            }
            for layerIndex in document.layers.indices.reversed() {
                if let variableIndex = document.layers[layerIndex].variables
                    .lastIndex(where: { $0.semanticRole == role }) {
                    document.layers[layerIndex]
                        .variables[variableIndex].value = value
                    document.layers[layerIndex]
                        .variables[variableIndex].isEnabled = true
                    return
                }
            }
            document.layers[0].variables.append(
                ThemeVariable(value: value, semanticRole: role)
            )
        }
    }

    func tokenValue(_ name: String, fallback: String = "") -> String {
        (draft?.layers
            .filter(\.isEnabled)
            .flatMap(\.variables)
            .last(where: {
                $0.semanticRole == nil
                    && $0.resolvedName == name
                    && $0.isEnabled
            }))?.value
            ?? fallback
    }

    func setTokenValue(_ name: String, value: String) {
        mutateDraft { document in
            if document.layers.isEmpty {
                document.layers = [
                    ThemeLayer(name: L10n.text("基礎", "Base"))
                ]
            }
            for layerIndex in document.layers.indices.reversed() {
                if let variableIndex = document.layers[layerIndex].variables
                    .lastIndex(where: {
                        $0.semanticRole == nil && $0.name == name
                    }) {
                    document.layers[layerIndex]
                        .variables[variableIndex].value = value
                    document.layers[layerIndex]
                        .variables[variableIndex].isEnabled = true
                    return
                }
            }
            document.layers[0].variables.append(
                ThemeVariable(name: name, value: value)
            )
        }
    }

    func addVariable() {
        mutateDraft { document in
            if document.layers.isEmpty {
                document.layers = [
                    ThemeLayer(name: L10n.text("基礎", "Base"))
                ]
            }
            document.layers[0].variables.append(
                ThemeVariable(name: "--my-custom-token", value: "#339CFF")
            )
        }
    }

    func importTheme() {
        let panel = NSOpenPanel()
        panel.title = L10n.importTheme
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "codextheme") ?? .json,
            .json
        ]
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            await perform {
                let imported = try await self.archiveService.importTheme(
                    from: url,
                    into: self.repository,
                    collisionPolicy: .clone
                )
                await self.reloadThemes(selecting: imported.id)
                self.show(
                    L10n.format(
                        "已導入「{0}」",
                        "Imported “{0}”",
                        imported.metadata.name
                    ),
                    style: .success
                )
            }
        }
    }

    func exportSelected() {
        guard let theme = draft ?? selectedTheme else { return }
        let panel = NSSavePanel()
        panel.title = L10n.exportTheme
        panel.nameFieldStringValue = sanitizedFilename(
            theme.metadata.name
        ) + ".codextheme"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "codextheme") ?? .json
        ]
        panel.canCreateDirectories = true
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            await perform {
                try self.archiveService.export(theme, to: url)
                self.show(
                    L10n.text("主題模板已導出", "Theme template exported"),
                    style: .success
                )
            }
        }
    }

    func addAsset() {
        let panel = NSOpenPanel()
        panel.title = L10n.text("加入背景、圖像或字型", "Add image or font")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [
            .png,
            .jpeg,
            .gif,
            .webP,
            .font,
            .data
        ]
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }

        do {
            let assets = try panel.urls.map { url -> ThemeAsset in
                let data = try Data(contentsOf: url)
                guard data.count <= 16 * 1024 * 1024 else {
                    throw ThemeAppError.assetTooLarge(url.lastPathComponent)
                }
                let type = UTType(filenameExtension: url.pathExtension)
                return ThemeAsset(
                    name: url.lastPathComponent,
                    mediaType: type?.preferredMIMEType
                        ?? "application/octet-stream",
                    data: data
                )
            }
            let currentBytes = draft?.assets.reduce(0) {
                $0 + ($1.decodedData?.count ?? 0)
            } ?? 0
            let addedBytes = assets.reduce(0) {
                $0 + ($1.decodedData?.count ?? 0)
            }
            guard currentBytes + addedBytes <= 32 * 1024 * 1024 else {
                throw ThemeAppError.totalAssetsTooLarge(
                    currentBytes + addedBytes
                )
            }
            mutateDraft { $0.assets.append(contentsOf: assets) }
            let englishMessage = assets.count == 1
                ? "Added {0} asset"
                : "Added {0} assets"
            show(
                L10n.format(
                    "已加入 {0} 個素材",
                    englishMessage,
                    String(assets.count)
                ),
                style: .success
            )
        } catch {
            show(
                AppErrorLocalization.message(for: error),
                style: .error
            )
        }
    }

    func chooseSkinBackground(for appearance: ThemeSkinAppearance) {
        let panel = NSOpenPanel()
        panel.title = L10n.text(
            appearance == .light
                ? "選擇淺色模式背景"
                : "選擇深色模式背景",
            appearance == .light
                ? "Choose light background"
                : "Choose dark background"
        )
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        var contentTypes: [UTType] = [
            .png,
            .jpeg,
            .gif,
            .webP
        ]
        if let avif = UTType(filenameExtension: "avif") {
            contentTypes.append(avif)
        }
        panel.allowedContentTypes = contentTypes
        NSApplication.shared.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            guard data.count <= 16 * 1024 * 1024 else {
                throw ThemeAppError.assetTooLarge(url.lastPathComponent)
            }
            guard let source = CGImageSourceCreateWithData(
                data as CFData,
                nil
            ),
            CGImageSourceGetCount(source) > 0,
            let typeIdentifier = CGImageSourceGetType(source),
            let type = UTType(typeIdentifier as String),
            let mediaType = type.preferredMIMEType,
            Self.supportedSkinImageTypes.contains(mediaType.lowercased())
            else {
                throw ThemeAppError.invalidSkinImage(url.lastPathComponent)
            }
            let asset = ThemeAsset(
                name: url.lastPathComponent,
                mediaType: mediaType,
                data: data
            )
            guard var candidate = draft else { return }
            var skin = candidate.imageSkin ?? ThemeImageSkin()
            skin.isEnabled = true
            var variant = skin.variant(for: appearance)
            let replacedAssetID = variant.backgroundAssetID
            variant.backgroundAssetID = asset.id
            skin.setVariant(variant, for: appearance)
            candidate.imageSkin = skin
            candidate.assets.append(asset)
            if let replacedAssetID {
                pruneAssetIfUnreferenced(
                    replacedAssetID,
                    from: &candidate
                )
            }
            let totalBytes = candidate.assets.reduce(0) {
                $0 + ($1.decodedData?.count ?? 0)
            }
            guard totalBytes <= 32 * 1024 * 1024 else {
                throw ThemeAppError.totalAssetsTooLarge(totalBytes)
            }
            mutateDraft { document in
                document = candidate
            }
            let appearanceName = appearance == .light
                ? L10n.text("淺色", "Light")
                : L10n.text("深色", "Dark")
            show(
                L10n.format(
                    "已設定{0}背景",
                    "{0} background set",
                    appearanceName
                ),
                style: .success
            )
        } catch {
            show(
                AppErrorLocalization.message(for: error),
                style: .error
            )
        }
    }

    func clearSkinBackground(for appearance: ThemeSkinAppearance) {
        mutateDraft { document in
            guard var skin = document.imageSkin else { return }
            var variant = skin.variant(for: appearance)
            let removedAssetID = variant.backgroundAssetID
            variant.backgroundAssetID = nil
            skin.setVariant(variant, for: appearance)
            document.imageSkin = skin
            if let removedAssetID {
                pruneAssetIfUnreferenced(removedAssetID, from: &document)
            }
        }
    }

    func setSkinBackground(
        _ assetID: UUID,
        for appearance: ThemeSkinAppearance
    ) {
        guard availableSkinImageAssets.contains(where: {
            $0.id == assetID
        }) else {
            return
        }
        mutateDraft { document in
            var skin = document.imageSkin ?? ThemeImageSkin()
            skin.isEnabled = true
            var variant = skin.variant(for: appearance)
            let replacedAssetID = variant.backgroundAssetID
            variant.backgroundAssetID = assetID
            skin.setVariant(variant, for: appearance)
            document.imageSkin = skin
            if let replacedAssetID, replacedAssetID != assetID {
                pruneAssetIfUnreferenced(
                    replacedAssetID,
                    from: &document
                )
            }
        }
    }

    func removeImageSkin() {
        mutateDraft { document in
            let assetIDs = [
                document.imageSkin?.light.backgroundAssetID,
                document.imageSkin?.dark.backgroundAssetID
            ].compactMap { $0 }
            document.imageSkin = nil
            for id in Set(assetIDs) {
                pruneAssetIfUnreferenced(id, from: &document)
            }
        }
    }

    func copySkinVariant(
        from source: ThemeSkinAppearance,
        to destination: ThemeSkinAppearance
    ) {
        let sourceName = source == .light
            ? L10n.text("淺色", "Light")
            : L10n.text("深色", "Dark")
        let destinationName = destination == .light
            ? L10n.text("淺色", "Light")
            : L10n.text("深色", "Dark")
        mutateDraft(
            actionName: L10n.format(
                "複製{0}到{1}",
                "Copy {0} to {1}",
                sourceName,
                destinationName
            ),
            coalesces: false
        ) { document in
            var skin = document.imageSkin ?? ThemeImageSkin()
            skin.setVariant(
                skin.variant(for: source),
                for: destination
            )
            document.imageSkin = skin
        }
    }

    func removeAsset(_ id: UUID) {
        mutateDraft { document in
            if var skin = document.imageSkin {
                if skin.light.backgroundAssetID == id {
                    skin.light.backgroundAssetID = nil
                }
                if skin.dark.backgroundAssetID == id {
                    skin.dark.backgroundAssetID = nil
                }
                document.imageSkin = skin
            }
            document.assets.removeAll { $0.id == id }
        }
    }

    func reloadThemes(selecting preferredID: UUID? = nil) async {
        do {
            let summaries = try await repository.list()
            var loaded: [ThemeDocument] = []
            for summary in summaries {
                loaded.append(try await repository.load(id: summary.id))
            }
            let loadedIDs = Set(loaded.map(\.id))
            persistedDocuments = Dictionary(
                uniqueKeysWithValues: loaded.map { ($0.id, $0) }
            )
            unsavedDrafts = unsavedDrafts.filter {
                loadedIDs.contains($0.key)
            }
            draftHistories = draftHistories.filter {
                loadedIDs.contains($0.key)
            }
            for index in loaded.indices {
                if let unsaved = unsavedDrafts[loaded[index].id] {
                    loaded[index] = unsaved
                }
            }
            themes = loaded.sorted {
                if BuiltInThemes.theme(id: $0.id) != nil,
                   BuiltInThemes.theme(id: $1.id) == nil {
                    return true
                }
                if BuiltInThemes.theme(id: $0.id) == nil,
                   BuiltInThemes.theme(id: $1.id) != nil {
                    return false
                }
                return $0.metadata.name.localizedCaseInsensitiveCompare(
                    $1.metadata.name
                ) == .orderedAscending
            }
            activeThemeID = try await repository.activeThemeID()

            let selected = preferredID
                ?? selectedThemeID
                ?? activeThemeID
                ?? themes.first?.id
            if let selected,
               let document = themes.first(where: { $0.id == selected }) {
                selectedThemeID = selected
                draft = unsavedDrafts[selected] ?? document
                isDraftDirty = unsavedDrafts[selected] != nil
            } else {
                selectedThemeID = nil
                draft = nil
                isDraftDirty = false
            }
            refreshDraftHistoryAvailability()
            isLoaded = true
        } catch {
            isLoaded = true
            show(
                AppErrorLocalization.message(for: error),
                style: .error
            )
        }
    }

    private func perform(_ operation: @escaping () async throws -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            show(
                AppErrorLocalization.message(for: error),
                style: .error
            )
        }
    }

    private func show(_ text: String, style: NoticeStyle) {
        let next = Notice(text: text, style: style)
        notice = next
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard self?.notice?.id == next.id else { return }
            self?.notice = nil
        }
    }

    private func recordDraftHistory(
        previous: ThemeDocument,
        actionName: String,
        coalescingKey: String?
    ) {
        var history = draftHistories[previous.id] ?? DraftHistoryState()
        let now = Date()
        let shouldCoalesce =
            coalescingKey != nil
            && history.lastCoalescingKey == coalescingKey
            && history.lastMutationDate.map {
                now.timeIntervalSince($0)
                    <= Self.draftHistoryCoalescingInterval
            } == true
            && !history.undoEntries.isEmpty

        if !shouldCoalesce {
            history.undoEntries.append(
                DraftHistoryEntry(
                    document: previous,
                    actionName: actionName
                )
            )
            trimDraftHistory(&history.undoEntries)
        }
        history.redoEntries.removeAll(keepingCapacity: true)
        history.lastCoalescingKey = coalescingKey
        history.lastMutationDate = now
        draftHistories[previous.id] = history
        refreshDraftHistoryAvailability()
    }

    private func trimDraftHistory(
        _ entries: inout [DraftHistoryEntry]
    ) {
        let overflow = entries.count - Self.draftHistoryLimit
        if overflow > 0 {
            entries.removeFirst(overflow)
        }
    }

    private func publishDraft(_ document: ThemeDocument) {
        draft = document
        let isDirty = persistedDocuments[document.id] != document
        if isDirty {
            unsavedDrafts[document.id] = document
        } else {
            unsavedDrafts.removeValue(forKey: document.id)
        }
        isDraftDirty = isDirty
        if let index = themes.firstIndex(where: { $0.id == document.id }) {
            themes[index] = document
        }
        refreshDraftHistoryAvailability()
    }

    private func refreshDraftHistoryAvailability() {
        guard let selectedThemeID,
              !isSelectedBuiltIn,
              let history = draftHistories[selectedThemeID] else {
            undoDraftActionName = nil
            redoDraftActionName = nil
            return
        }
        undoDraftActionName = history.undoEntries.last?.actionName
        redoDraftActionName = history.redoEntries.last?.actionName
    }

    private func sanitizedFilename(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\")
        let pieces = value.components(separatedBy: invalid)
        let result = pieces.joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "Codex Theme" : result
    }

    private func pruneAssetIfUnreferenced(
        _ id: UUID,
        from document: inout ThemeDocument
    ) {
        guard !isAssetReferenced(id, in: document) else { return }
        document.assets.removeAll { $0.id == id }
    }

    private func isAssetReferenced(
        _ id: UUID,
        in document: ThemeDocument
    ) -> Bool {
        if document.imageSkin?.light.backgroundAssetID == id
            || document.imageSkin?.dark.backgroundAssetID == id {
            return true
        }

        let reference = id.uuidString
        func containsReference(_ text: String) -> Bool {
            text.range(
                of: reference,
                options: .caseInsensitive
            ) != nil
        }

        for layer in document.layers {
            if containsReference(layer.rawCSS)
                || containsReference(layer.mediaQuery ?? "") {
                return true
            }
            if layer.variables.contains(where: {
                containsReference($0.value)
            }) {
                return true
            }
            if layer.components.contains(where: { component in
                component.selectors.contains(where: containsReference)
                    || component.declarations.contains(where: {
                        containsReference($0.value)
                    })
            }) {
                return true
            }
            if layer.rules.contains(where: { rule in
                containsReference(rule.selector)
                    || rule.declarations.contains(where: {
                        containsReference($0.value)
                    })
            }) {
                return true
            }
        }
        return false
    }
}

enum ThemeAppError: LocalizedError {
    case codexNotAttached
    case assetTooLarge(String)
    case totalAssetsTooLarge(Int)
    case invalidSkinImage(String)
    case invalidCodexApplication(String)

    var errorDescription: String? {
        switch self {
        case .codexNotAttached:
            return L10n.text(
                "請先按「啟動並連接 Codex」。第一次連接可能會重新啟動 Codex。",
                "Choose Launch + Attach Codex first. The first attachment may restart Codex."
            )
        case .assetTooLarge(let name):
            return L10n.format(
                "素材「{0}」超過 16 MB。",
                "Asset “{0}” is larger than 16 MB.",
                name
            )
        case .totalAssetsTooLarge(let bytes):
            let size = ByteCountFormatter.string(
                fromByteCount: Int64(bytes),
                countStyle: .file
            )
            return L10n.format(
                "加入後素材合計為 {0}，超過 32 MB 上限。",
                "Assets would total {0}, above the 32 MB limit.",
                size
            )
        case .invalidSkinImage(let name):
            return L10n.format(
                "「{0}」不是可解碼的 PNG、JPEG、WebP、GIF 或 AVIF 圖片。",
                "“{0}” is not a decodable PNG, JPEG, WebP, GIF, or AVIF image.",
                name
            )
        case .invalidCodexApplication(let name):
            return L10n.format(
                "「{0}」不是有效的 Codex App。",
                "“{0}” is not a valid Codex application.",
                name
            )
        }
    }
}
