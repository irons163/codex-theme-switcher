import AppKit
import CodexThemeSwitcherCore
import SwiftUI

struct ThemeSwitcherRootView: View {
    @ObservedObject var model: ThemeAppModel
    @ObservedObject var updateModel: AppUpdateModel
    @ObservedObject var languageSettings: AppLanguageSettings
    @State private var renamingThemeID: UUID?
    @State private var proposedThemeName = ""

    var body: some View {
        HStack(spacing: 0) {
            themeLibrary
                .frame(width: 238)

            Divider()

            VStack(spacing: 0) {
                runtimeToolbar
                Divider()
                editorNavigation
                Divider()
                ThemeEditorView(
                    model: model,
                    updateModel: updateModel,
                    languageSettings: languageSettings
                )
            }
        }
        .id(languageSettings.selection)
        .environment(\.locale, languageSettings.locale)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            if let notice = model.notice {
                NoticeView(notice: notice)
                    .padding(14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            model.start()
            updateModel.start()
            updateModel.presentLaunchAnnouncements()
        }
        .overlay {
            if let sheet = updateModel.sheet {
                updateModal(sheet)
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.97)
                        )
                    )
                    .zIndex(100)
            }
        }
        .animation(
            .easeInOut(duration: 0.18),
            value: updateModel.sheet
        )
        .animation(.easeInOut(duration: 0.18), value: model.notice?.id)
    }

    private func updateModal(_ sheet: AppUpdateSheet) -> some View {
        ZStack {
            Color.black.opacity(0.52)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Keep the modal open and consume clicks inside the
                    // transient MenuBarExtra window.
                }

            Group {
                switch sheet {
                case .about:
                    AboutAppSheetView(updateModel: updateModel)
                case let .update(release):
                    AppUpdateSheetView(
                        release: release,
                        updateModel: updateModel
                    )
                case .whatsNew:
                    WhatsNewSheetView(updateModel: updateModel)
                }
            }
            .background(
                .regularMaterial,
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.42), radius: 28, y: 12)
            .padding(32)
        }
        .contentShape(Rectangle())
        .onExitCommand {
            dismissUpdateModal(sheet)
        }
    }

    private func dismissUpdateModal(_ sheet: AppUpdateSheet) {
        switch sheet {
        case .whatsNew:
            updateModel.dismissWhatsNew(markSeen: false)
        case .about, .update:
            updateModel.dismissSheet()
        }
    }

    private var themeLibrary: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    AppBrandIcon(height: 26)
                        .accessibilityLabel(L10n.appName)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L10n.appName)
                            .font(.headline)
                        Text(L10n.text("MENU BAR STUDIO", "MENU BAR STUDIO"))
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(
                        L10n.text("搜尋主題", "Search themes"),
                        text: $model.searchText
                    )
                    .textFieldStyle(.plain)
                }
                .padding(.horizontal, 9)
                .frame(height: 30)
                .background(.quaternary.opacity(0.55))
                .clipShape(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .padding(14)

            Divider()

            if model.isLoaded {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(model.filteredThemes) { theme in
                            ThemeLibraryRow(
                                theme: theme,
                                isSelected: model.selectedThemeID == theme.id,
                                isActive: model.appliedThemeID == theme.id,
                                isBuiltIn: BuiltInThemes.theme(id: theme.id) != nil,
                                isDirty: model.hasUnsavedChanges(for: theme.id),
                                isRenaming: renamingThemeID == theme.id,
                                proposedName: $proposedThemeName,
                                onCommitRename: commitThemeRename,
                                onCancelRename: cancelThemeRename
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if renamingThemeID != nil,
                                   renamingThemeID != theme.id {
                                    commitThemeRename()
                                }
                                model.selectTheme(theme.id)
                            }
                            .onTapGesture(count: 2) {
                                beginThemeRename(theme)
                            }
                            .contextMenu {
                                Button(L10n.apply) {
                                    model.applyTheme(theme.id)
                                }
                                Button(L10n.duplicate) {
                                    model.selectTheme(theme.id)
                                    model.duplicateSelected()
                                }
                                Button(L10n.exportTheme) {
                                    model.selectTheme(theme.id)
                                    model.exportSelected()
                                }
                                if BuiltInThemes.theme(id: theme.id) == nil {
                                    Divider()
                                    Button(
                                        L10n.text(
                                            "重新命名",
                                            "Rename"
                                        )
                                    ) {
                                        beginThemeRename(theme)
                                    }
                                    Button(
                                        L10n.text("刪除", "Delete"),
                                        role: .destructive
                                    ) {
                                        model.selectTheme(theme.id)
                                        model.deleteSelected()
                                    }
                                }
                            }
                        }
                    }
                    .padding(9)
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }

            Divider()

            HStack(spacing: 7) {
                Button {
                    model.createTheme()
                } label: {
                    Label(L10n.newTheme, systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    model.importTheme()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.borderless)
                .help(L10n.importTheme)

                Button {
                    model.exportSelected()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .help(L10n.exportTheme)
                .disabled(model.draft == nil)
            }
            .padding(.horizontal, 13)
            .frame(height: 44)
        }
        .background(.thinMaterial)
    }

    private func beginThemeRename(_ theme: ThemeDocument) {
        guard BuiltInThemes.theme(id: theme.id) == nil else { return }
        if renamingThemeID != nil, renamingThemeID != theme.id {
            commitThemeRename()
        }
        model.selectTheme(theme.id)
        proposedThemeName = theme.metadata.name
        renamingThemeID = theme.id
    }

    private func commitThemeRename() {
        guard let id = renamingThemeID else { return }
        let originalName = model.themes.first {
            $0.id == id
        }?.metadata.name ?? ""
        if !model.renameTheme(id, to: proposedThemeName) {
            proposedThemeName = originalName
        }
        renamingThemeID = nil
    }

    private func cancelThemeRename() {
        renamingThemeID = nil
        proposedThemeName = ""
    }

    private var runtimeToolbar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(model.isAttached ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(
                    color: (model.isAttached ? Color.green : Color.orange)
                        .opacity(0.5),
                    radius: 4
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(model.runtimeSummary)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let version = model.runtimeStatus?.codexVersion {
                    Text("Codex \(version)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            }

            HStack(spacing: 2) {
                Button {
                    model.undoDraftChange()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .help(
                    model.undoDraftActionName.map {
                        L10n.format(
                            "復原：{0}（⌘Z）",
                            "Undo: {0} (⌘Z)",
                            $0
                        )
                    } ?? L10n.text("沒有可復原的動作", "Nothing to undo")
                )
                .disabled(!model.canUndoDraft || model.isBusy)

                Button {
                    model.redoDraftChange()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .buttonStyle(.borderless)
                .help(
                    model.redoDraftActionName.map {
                        L10n.format(
                            "重做：{0}（⇧⌘Z）",
                            "Redo: {0} (⇧⌘Z)",
                            $0
                        )
                    } ?? L10n.text("沒有可重做的動作", "Nothing to redo")
                )
                .disabled(!model.canRedoDraft || model.isBusy)
            }
            .controlSize(.small)

            if !model.isAttached {
                Button {
                    model.launchAndAttach()
                } label: {
                    Label(L10n.attach, systemImage: "bolt.horizontal.fill")
                }
                .buttonStyle(.bordered)
                .help(model.launchAndAttachHelp)
            }

            Button {
                model.applyDraft()
            } label: {
                Label(L10n.apply, systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.draft == nil || !model.isAttached || model.isBusy)

            Button {
                model.saveDraft()
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .help(L10n.save)
            .disabled(
                model.draft == nil
                    || model.isSelectedBuiltIn
                    || !model.isDraftDirty
                    || model.isBusy
            )

            Menu {
                Button {
                    updateModel.showAbout()
                } label: {
                    Label(
                        L10n.format(
                            "關於 {0}",
                            "About {0}",
                            L10n.appName
                        ),
                        systemImage: "info.circle"
                    )
                }
                Button {
                    model.selectedPage = .settings
                } label: {
                    Label(
                        L10n.text("設定", "Settings"),
                        systemImage: "gearshape"
                    )
                }
                Divider()
                Button(
                    L10n.text(
                        "檢查更新…",
                        "Check for Updates…"
                    )
                ) {
                    updateModel.checkForUpdates()
                }
                Divider()
                Button(L10n.importTheme) { model.importTheme() }
                Button(L10n.exportTheme) { model.exportSelected() }
                Divider()
                Button(L10n.clear) { model.restoreCodexStyle() }
                Button(
                    L10n.text("停止 Theme Runtime", "Stop theme runtime")
                ) {
                    model.stopRuntime()
                }
                Divider()
                Button(L10n.quit) {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26)
        }
        .padding(.horizontal, 14)
        .frame(height: 55)
        .background(.bar)
    }

    private var editorNavigation: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(
                        ThemeAppModel.EditorPage.allCases.filter {
                            $0 != .settings
                        }
                    ) { page in
                        editorNavigationButton(page)
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, 6)
            }

            Divider()
                .frame(height: 24)

            editorNavigationButton(.settings)
                .padding(.horizontal, 8)
        }
        .frame(height: 43)
        .background(.bar)
    }

    private func editorNavigationButton(
        _ page: ThemeAppModel.EditorPage
    ) -> some View {
        Button {
            model.selectedPage = page
        } label: {
            Label(page.title, systemImage: page.symbol)
                .font(.caption)
                .padding(.horizontal, 9)
                .frame(height: 30)
                .background(
                    model.selectedPage == page
                        ? Color.accentColor.opacity(0.14)
                        : .clear
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 7,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            model.selectedPage == page
                ? Color.accentColor
                : Color.secondary
        )
    }
}

private struct ThemeLibraryRow: View {
    let theme: ThemeDocument
    let isSelected: Bool
    let isActive: Bool
    let isBuiltIn: Bool
    let isDirty: Bool
    let isRenaming: Bool
    @Binding var proposedName: String
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void

    private var swatches: [Color] {
        let roles: [ThemeSemanticRole] = [
            .backgroundPrimary,
            .surface,
            .accent,
            .textPrimary
        ]
        let variables = theme.layers.flatMap(\.variables)
        return roles.map { role in
            let value = variables.last {
                $0.semanticRole == role && $0.isEnabled
            }?.value ?? "#777777"
            return Color(css: value, fallback: .gray)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: -3) {
                ForEach(Array(swatches.enumerated()), id: \.offset) {
                    _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 15, height: 15)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.22), lineWidth: 0.5)
                        }
                }
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                if isRenaming {
                    ThemeNameEditor(
                        name: $proposedName,
                        onCommit: onCommitRename,
                        onCancel: onCancelRename
                    )
                } else {
                    HStack(spacing: 4) {
                        Text(theme.metadata.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        if isBuiltIn {
                            Text(L10n.text("內建", "BUILT-IN"))
                                .font(.system(size: 6.5, weight: .bold))
                                .tracking(0.4)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                        if isDirty {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                                .help(
                                    L10n.text(
                                        "有尚未儲存的變更",
                                        "Has unsaved changes"
                                    )
                                )
                        }
                    }
                }
                Text(
                    theme.metadata.author.isEmpty
                        ? L10n.text("未署名", "Unknown author")
                        : theme.metadata.author
                )
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 2)

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 48)
        .background(
            isSelected ? Color.accentColor.opacity(0.12) : .clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
            }
        }
    }
}

private struct ThemeNameEditor: View {
    @Binding var name: String
    let onCommit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    @State private var hasFinished = false

    var body: some View {
        TextField(L10n.text("主題名稱", "Theme name"), text: $name)
            .font(.system(size: 12, weight: .medium))
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .onSubmit {
                finish(onCommit)
            }
            .onExitCommand {
                finish(onCancel)
            }
            .onChange(of: isFocused) { focused in
                if !focused {
                    finish(onCommit)
                }
            }
            .task {
                isFocused = true
            }
    }

    private func finish(_ action: () -> Void) {
        guard !hasFinished else { return }
        hasFinished = true
        action()
    }
}

private struct NoticeView: View {
    let notice: ThemeAppModel.Notice

    var color: Color {
        switch notice.style {
        case .info: .blue
        case .success: .green
        case .error: .red
        }
    }

    var symbol: String {
        switch notice.style {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(notice.text)
                .font(.caption)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThickMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}
