import SwiftUI

struct AppSettingsPage: View {
    @ObservedObject var model: ThemeAppModel
    @ObservedObject var updateModel: AppUpdateModel
    @ObservedObject var languageSettings: AppLanguageSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.text("App 更新", "App updates"),
                    description: L10n.text(
                        "透過具簽章的 Sparkle 更新，讓 Codex 主題切換器保持最新。",
                        "Keep Codex Theme Switcher current with signed Sparkle updates."
                    )
                )

                EditorSection(
                    title: L10n.text(
                        "介面語言",
                        "Interface language"
                    ),
                    subtitle: L10n.text(
                        "自動跟隨 Mac，或為此 App 選擇語言。",
                        "Follow your Mac automatically or choose a language for this app."
                    )
                ) {
                    HStack(spacing: 12) {
                        Label(
                            L10n.text(
                                "介面語言",
                                "Interface language"
                            ),
                            systemImage: "globe"
                        )
                        .font(.subheadline.weight(.semibold))

                        Spacer()

                        Picker(
                            L10n.text(
                                "介面語言",
                                "Interface language"
                            ),
                            selection: $languageSettings.selection
                        ) {
                            ForEach(
                                AppLanguagePreference.allCases
                            ) { preference in
                                Text(preference.title)
                                    .tag(preference)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }

                    Label(
                        L10n.text(
                            "語言變更會立即生效。",
                            "Language changes take effect immediately."
                        ),
                        systemImage: "checkmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                EditorSection(
                    title: L10n.text(
                        "Codex App 位置",
                        "Codex application"
                    ),
                    subtitle: L10n.text(
                        "自動尋找正在執行或已安裝的 Codex，也可指定其他位置。",
                        "Automatically finds a running or installed Codex, or lets you choose another location."
                    )
                ) {
                    HStack(spacing: 10) {
                        Image(
                            systemName: model.codexAppIsAvailable
                                ? "checkmark.circle.fill"
                                : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(
                            model.codexAppIsAvailable
                                ? Color.green
                                : Color.orange
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(
                                model.codexAppIsAvailable
                                    ? (
                                        model.hasCustomCodexApp
                                            ? L10n.text(
                                                "使用自訂位置",
                                                "Using a custom location"
                                            )
                                            : L10n.text(
                                                "已自動找到 Codex",
                                                "Codex detected automatically"
                                            )
                                    )
                                    : L10n.text(
                                        "找不到 Codex App",
                                        "Codex application not found"
                                    )
                            )
                            .font(.subheadline.weight(.semibold))

                            Text(model.codexAppURL.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }

                        Spacer()

                        Button(L10n.text("選擇…", "Choose…")) {
                            model.chooseCodexApplication()
                        }
                        .buttonStyle(.borderedProminent)

                        if model.hasCustomCodexApp {
                            Button(
                                L10n.text(
                                    "改用自動偵測",
                                    "Use Automatic"
                                )
                            ) {
                                model.useAutomaticCodexApplication()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                EditorSection(
                    title: L10n.text("目前版本", "Current version"),
                    subtitle: L10n.format(
                        "版本 {0}（{1}）",
                        "Version {0} ({1})",
                        updateModel.versionInfo.version,
                        updateModel.versionInfo.build
                    )
                ) {
                    HStack(spacing: 10) {
                        AppBrandIcon(height: 38)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.appName)
                                .font(.headline)
                            Text(
                                updateModel.sparkleIsAvailable
                                    ? L10n.text(
                                        "Sparkle 已可在此 App 使用。",
                                        "Sparkle is available in the packaged app."
                                    )
                                    : L10n.text(
                                        "從 SwiftPM 執行時無法使用 Sparkle。",
                                        "Sparkle is unavailable when running from SwiftPM."
                                    )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if updateModel.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Button(
                            L10n.text(
                                "檢查更新…",
                                "Check for Updates…"
                            )
                        ) {
                            updateModel.checkForUpdates()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(updateModel.isChecking)
                    }

                    if let status = updateModel.statusMessage {
                        Label(
                            status,
                            systemImage: updateModel.availableRelease == nil
                                ? "info.circle"
                                : "arrow.down.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            updateModel.availableRelease == nil
                                ? Color.secondary
                                : Color.accentColor
                        )
                    }

                    if updateModel.availableRelease != nil {
                        Button(
                            L10n.text(
                                "顯示可用更新",
                                "Update available"
                            )
                        ) {
                            updateModel.presentAvailableUpdate()
                        }
                        .buttonStyle(.link)
                    }
                }

                EditorSection(
                    title: L10n.text("自動更新", "Automatic update checks"),
                    subtitle: L10n.text(
                        "啟動時檢查，之後每 30 分鐘檢查一次。",
                        "Checks at launch and every 30 minutes."
                    )
                ) {
                    Toggle(
                        L10n.text(
                            "自動檢查更新",
                            "Automatic update checks"
                        ),
                        isOn: $updateModel.automaticChecksEnabled
                    )
                    .toggleStyle(.switch)
                }

                EditorSection(
                    title: L10n.text("更新頻道", "Update channel"),
                    subtitle: updateModel.channel.detail
                ) {
                    Picker(
                        L10n.text("更新頻道", "Update channel"),
                        selection: $updateModel.channel
                    ) {
                        ForEach(AppUpdateChannel.allCases) { channel in
                            Text(channel.title)
                                .tag(channel)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(alignment: .top, spacing: 8) {
                        Image(
                            systemName: updateModel.channel == .stable
                                ? "checkmark.shield.fill"
                                : "flask.fill"
                        )
                        .foregroundStyle(
                            updateModel.channel == .stable
                                ? Color.green
                                : Color.orange
                        )
                        Text(updateModel.channel.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                EditorSection(
                    title: L10n.text("關於更新", "Powered by Sparkle"),
                    subtitle: L10n.text(
                        "Sparkle 會驗證並安裝具簽章的 App 更新。",
                        "Sparkle verifies and installs signed app updates."
                    )
                ) {
                    HStack {
                        Button(
                            L10n.text(
                                "顯示新功能",
                                "Show What's New"
                            )
                        ) {
                            updateModel.showWhatsNew()
                        }
                        .buttonStyle(.bordered)

                        Button(
                            L10n.text(
                                "開啟 Releases",
                                "Open Releases"
                            )
                        ) {
                            updateModel.openReleasesPage()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Label(
                            L10n.text(
                                "由 Sparkle 提供",
                                "Powered by Sparkle"
                            ),
                            systemImage: "sparkles"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
    }
}

struct AppUpdateSheetView: View {
    let release: AppUpdateRelease
    @ObservedObject var updateModel: AppUpdateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.format(
                            "有新版本 {0}",
                            "What's New in {0}",
                            release.normalizedVersion
                        )
                    )
                    .font(.title2.bold())
                    Text(release.displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let publishedAt = release.publishedAt {
                    Text(
                        L10n.format(
                            "發布於 {0}",
                            "Published {0}",
                            publishedAt.formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("版本說明", "Release notes"))
                    .font(.headline)
                ScrollView {
                    Text(
                        release.releaseNotesText
                            ?? L10n.text(
                                "沒有提供版本說明。",
                                "No release notes were provided."
                            )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                }
                .frame(minHeight: 170, maxHeight: 320)
                .padding(12)
                .background(.quaternary.opacity(0.35))
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            }

            HStack {
                Button(
                    L10n.text(
                        "略過這個版本",
                        "Skip this version"
                    )
                ) {
                    updateModel.skip(release)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(
                    L10n.text(
                        "手動下載",
                        "Download manually"
                    )
                ) {
                    updateModel.openManualDownload(release)
                }
                .buttonStyle(.bordered)

                Button(
                    L10n.text(
                        "安裝更新",
                        "Install update"
                    )
                ) {
                    updateModel.install(release)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 620)
    }
}

struct WhatsNewSheetView: View {
    @ObservedObject var updateModel: AppUpdateModel

    private var improvements: [(String, String)] {
        [
            (
                "globe",
                L10n.text(
                    "可自動跟隨 Mac，或手動選擇七種介面語言。",
                    "Follow your Mac automatically or choose from seven interface languages."
                )
            ),
            (
                "point.3.connected.trianglepath.dotted",
                L10n.text(
                    "可在設定中選擇穩定版或 Beta 更新。",
                    "Choose Stable or Beta updates from Settings."
                )
            ),
            (
                "checkmark.shield",
                L10n.text(
                    "Sparkle 會驗證並安裝具簽章的 App 更新。",
                    "Sparkle verifies and installs signed app updates."
                )
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                AppBrandIcon(height: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.format(
                            "{0} 的新功能",
                            "What's New in {0}",
                            updateModel.versionInfo.version
                        )
                    )
                    .font(.title2.bold())
                    Text(
                        L10n.text(
                            "主題與更新，都由你決定。",
                            "Theme updates, your way."
                        )
                    )
                    .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                ForEach(
                    Array(improvements.enumerated()),
                    id: \.offset
                ) { _, improvement in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: improvement.0)
                            .frame(width: 24)
                            .foregroundStyle(.tint)
                        Text(improvement.1)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                }
            }

            HStack {
                Button(L10n.text("稍後", "Later")) {
                    updateModel.dismissWhatsNew(markSeen: false)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(L10n.text("完成", "Done")) {
                    updateModel.dismissWhatsNew(markSeen: true)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 540)
    }
}
