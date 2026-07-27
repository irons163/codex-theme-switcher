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
    @Published var selectedPage: EditorPage = .preview
    @Published var previewAppearance: ThemeSkinAppearance = .dark
    @Published var previewSurface: ThemePreviewSurface = .home
    @Published var notice: Notice?
    @Published var searchText = ""

    private let repository: FileThemeRepository
    private let archiveService: ThemeArchiveService
    private let compiler: ThemeCompiler
    private let runtime: ThemeRuntimeController?
    private var monitorTask: Task<Void, Never>?
    private var unsavedDrafts: [UUID: ThemeDocument] = [:]

    init() {
        repository = FileThemeRepository()
        archiveService = ThemeArchiveService()
        compiler = ThemeCompiler()
        runtime = try? ThemeRuntimeController.standard()
    }

    init(
        repository: FileThemeRepository,
        archiveService: ThemeArchiveService = ThemeArchiveService(),
        compiler: ThemeCompiler = ThemeCompiler(),
        runtime: ThemeRuntimeController?
    ) {
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
        activeThemeID.flatMap {
            id in themes.first(where: { $0.id == id })
        }?.metadata.name
            ?? runtimeStatus?.activeThemeName
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

    var menuBarSymbol: String {
        if isBusy { return "paintpalette.fill" }
        if isAttached && activeThemeID != nil {
            return "paintpalette.fill"
        }
        return "paintpalette"
    }

    var runtimeSummary: String {
        if runtime == nil {
            return L10n.text("找不到 runtime", "Runtime unavailable")
        }
        if isAttached {
            let count = runtimeStatus?.injectedRendererCount ?? 0
            return L10n.text(
                "已連接 \(count) 個 Codex 畫面",
                "Attached to \(count) Codex surface\(count == 1 ? "" : "s")"
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

    func selectTheme(_ id: UUID) {
        guard selectedThemeID != id,
              let theme = themes.first(where: { $0.id == id }) else {
            return
        }
        selectedThemeID = id
        draft = unsavedDrafts[id] ?? theme
        isDraftDirty = unsavedDrafts[id] != nil
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
                if self.activeThemeID == id {
                    if let runtime = self.runtime {
                        _ = try await runtime.clear().requiringSuccess()
                    }
                    try await self.repository.setActiveThemeID(nil)
                    self.activeThemeID = nil
                }
                try await self.repository.delete(id: id)
                self.unsavedDrafts.removeValue(forKey: id)
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
                let result = try await runtime.launch().requiringSuccess()
                self.runtimeStatus = result.status
                if let id = self.activeThemeID,
                   let active = self.themes.first(where: { $0.id == id }) {
                    let compiled = try self.compiler.compile(active)
                    let applied = try await runtime.apply(
                        css: compiled.css,
                        themeID: active.id.uuidString,
                        themeName: active.metadata.name,
                        assets: compiled.runtimeAssets.map {
                            ThemeRuntimeAsset(
                                id: $0.id.uuidString.lowercased(),
                                mediaType: $0.mediaType,
                                dataBase64: $0.dataBase64
                            )
                        }
                    ).requiringSuccess()
                    self.runtimeStatus = applied.status
                }
                self.show(
                    L10n.text("已連接 Codex", "Codex attached"),
                    style: .success
                )
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

                try await self.repository.setActiveThemeID(document.id)
                self.activeThemeID = document.id
                self.runtimeStatus = result.status
                self.isDraftDirty = false
                await self.reloadThemes(selecting: document.id)
                self.show(
                    L10n.text(
                        "已套用「\(document.metadata.name)」",
                        "Applied “\(document.metadata.name)”"
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
                    _ = try await runtime.stop().requiringSuccess()
                }
                await self.refreshRuntime(silently: true)
            }
        }
    }

    func refreshRuntime(silently: Bool = false) async {
        guard let runtime else { return }
        do {
            let result = try await runtime.status()
            runtimeStatus = result.status
            if !result.ok, !silently {
                show(
                    result.error?.message
                        ?? L10n.text("無法讀取 runtime", "Runtime unavailable"),
                    style: .error
                )
            }
        } catch {
            if !silently {
                show(error.localizedDescription, style: .error)
            }
        }
    }

    func mutateDraft(_ mutation: (inout ThemeDocument) -> Void) {
        guard var draft, !isSelectedBuiltIn else { return }
        mutation(&draft)
        draft.metadata.updatedAt = Date()
        self.draft = draft
        unsavedDrafts[draft.id] = draft
        isDraftDirty = true
        if let index = themes.firstIndex(where: { $0.id == draft.id }) {
            themes[index] = draft
        }
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
                document.layers = [ThemeLayer(name: "Base")]
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
                document.layers = [ThemeLayer(name: "Base")]
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
                document.layers = [ThemeLayer(name: "Base")]
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
                    L10n.text(
                        "已導入「\(imported.metadata.name)」",
                        "Imported “\(imported.metadata.name)”"
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
            show(
                L10n.text(
                    "已加入 \(assets.count) 個素材",
                    "Added \(assets.count) asset\(assets.count == 1 ? "" : "s")"
                ),
                style: .success
            )
        } catch {
            show(error.localizedDescription, style: .error)
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
            show(
                L10n.text(
                    "已設定\(appearance == .light ? "淺色" : "深色")背景",
                    "\(appearance == .light ? "Light" : "Dark") background set"
                ),
                style: .success
            )
        } catch {
            show(error.localizedDescription, style: .error)
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
        mutateDraft { document in
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
            unsavedDrafts = unsavedDrafts.filter {
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
            isLoaded = true
        } catch {
            isLoaded = true
            show(error.localizedDescription, style: .error)
        }
    }

    private func perform(_ operation: @escaping () async throws -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            show(error.localizedDescription, style: .error)
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

    var errorDescription: String? {
        switch self {
        case .codexNotAttached:
            return L10n.text(
                "請先按「啟動並連接 Codex」。第一次連接可能會重新啟動 Codex。",
                "Choose Launch + Attach Codex first. The first attachment may restart Codex."
            )
        case .assetTooLarge(let name):
            return L10n.text(
                "素材「\(name)」超過 16 MB。",
                "Asset “\(name)” is larger than 16 MB."
            )
        case .totalAssetsTooLarge(let bytes):
            let size = ByteCountFormatter.string(
                fromByteCount: Int64(bytes),
                countStyle: .file
            )
            return L10n.text(
                "加入後素材合計為 \(size)，超過 32 MB 上限。",
                "Assets would total \(size), above the 32 MB limit."
            )
        case .invalidSkinImage(let name):
            return L10n.text(
                "「\(name)」不是可解碼的 PNG、JPEG、WebP、GIF 或 AVIF 圖片。",
                "“\(name)” is not a decodable PNG, JPEG, WebP, GIF, or AVIF image."
            )
        }
    }
}
