import AppKit
import CodexThemeSwitcherCore
import SwiftUI

struct ThemeEditorView: View {
    @ObservedObject var model: ThemeAppModel
    @ObservedObject var updateModel: AppUpdateModel

    var body: some View {
        Group {
            if model.selectedPage == .settings {
                AppSettingsPage(updateModel: updateModel)
            } else if let theme = model.draft {
                VStack(spacing: 0) {
                    if model.isSelectedBuiltIn {
                        builtInBanner(theme)
                        Divider()
                    }
                    page(theme)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text(L10n.text("尚未選擇主題", "No theme selected"))
                        .font(.headline)
                    Text(
                        L10n.text(
                            "從左側選擇或新增一個主題。",
                            "Choose or create a theme from the library."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func page(_ theme: ThemeDocument) -> some View {
        switch model.selectedPage {
        case .preview:
            ThemePreviewPage(theme: theme, model: model)
        case .skin:
            ThemeSkinEditorView(model: model)
        case .colors:
            ColorEditorPage(model: model)
        case .typography:
            TypographyEditorPage(model: model)
        case .components:
            ComponentEditorPage(model: model)
        case .rules:
            RuleEditorPage(model: model)
        case .rawCSS:
            RawCSSEditorPage(model: model)
        case .assets:
            AssetEditorPage(model: model)
        case .info:
            ThemeInfoEditorPage(model: model)
        case .settings:
            AppSettingsPage(updateModel: updateModel)
        }
    }

    private func builtInBanner(_ theme: ThemeDocument) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    L10n.text(
                        "這是內建模板",
                        "This is a built-in template"
                    )
                )
                .font(.caption.bold())
                Text(
                    L10n.text(
                        "可以直接套用或導出；先製作副本即可自由修改。",
                        "Apply or export it as-is, or make a copy to customize it."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Button(L10n.duplicate) {
                model.duplicateSelected()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color.accentColor.opacity(0.07))
    }
}

private struct ThemePreviewPage: View {
    let theme: ThemeDocument
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.metadata.name)
                        .font(.title2.bold())
                    Text(
                        theme.metadata.description.isEmpty
                            ? L10n.text(
                                "即時模擬 Codex 的側欄、對話、程式碼與輸入框。",
                                "Live simulation of Codex surfaces, conversation, code, and composer."
                            )
                            : theme.metadata.description
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                }
                Spacer()
                if model.appliedThemeID == theme.id {
                    Label(
                        L10n.text("使用中", "ACTIVE"),
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                }
            }

            HStack(spacing: 10) {
                Picker(
                    L10n.text("畫面", "Surface"),
                    selection: $model.previewSurface
                ) {
                    Text(L10n.text("首頁", "Home"))
                        .tag(ThemePreviewSurface.home)
                    Text(L10n.text("對話", "Chat"))
                        .tag(ThemePreviewSurface.chat)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)

                Picker(
                    L10n.text("外觀", "Appearance"),
                    selection: $model.previewAppearance
                ) {
                    Label(
                        L10n.text("淺色", "Light"),
                        systemImage: "sun.max"
                    )
                    .tag(ThemeSkinAppearance.light)
                    Label(
                        L10n.text("深色", "Dark"),
                        systemImage: "moon.stars"
                    )
                    .tag(ThemeSkinAppearance.dark)
                }
                .pickerStyle(.segmented)
                .frame(width: 210)

                Spacer()
            }

            ThemePreviewView(
                theme: theme,
                appearance: model.previewAppearance,
                surface: model.previewSurface
            )
            .environment(
                \.colorScheme,
                model.previewAppearance == .dark ? .dark : .light
            )

            HStack {
                Label(
                    L10n.text(
                        "預覽使用與真實 Codex 相同的 theme 資料；selector 規則請在真實 Codex 驗證。",
                        "The preview uses the same theme data; verify expert selector rules in Codex."
                    ),
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(18)
    }
}

private struct ColorEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    private let semanticColors: [(ThemeSemanticRole, String, String)] = [
        (.backgroundPrimary, L10n.text("主背景", "App background"), "#151515"),
        (.backgroundSecondary, L10n.text("次背景", "Secondary background"), "#1D1D1D"),
        (.surface, L10n.text("浮層／對話框", "Surface / bubble"), "#252525"),
        (.textPrimary, L10n.text("主要文字", "Primary text"), "#F5F5F5"),
        (.textSecondary, L10n.text("次要文字", "Secondary text"), "#A0A0A0"),
        (.accent, L10n.text("強調色", "Accent"), "#339CFF"),
        (.border, L10n.text("邊框", "Border"), "#FFFFFF1F"),
        (.success, L10n.text("成功", "Success"), "#40C977"),
        (.warning, L10n.text("警告", "Warning"), "#FFB020"),
        (.error, L10n.text("錯誤／刪除", "Error / delete"), "#FA423E")
    ]

    private let surfaceTokens: [(String, String, String)] = [
        ("--color-token-side-bar-background", L10n.text("側欄", "Sidebar"), "#1D1D1D"),
        ("--color-token-input-background", L10n.text("輸入框", "Input"), "#242424"),
        ("--color-token-dropdown-background", L10n.text("下拉選單", "Dropdown"), "#242424"),
        ("--color-token-menu-background", L10n.text("選單", "Menu"), "#242424"),
        ("--color-token-editor-background", L10n.text("編輯器", "Editor"), "#111111"),
        ("--color-token-text-code-block-background", L10n.text("程式碼區塊", "Code block"), "#111111"),
        ("--color-token-terminal-background", L10n.text("Terminal 背景", "Terminal background"), "#111111"),
        ("--color-token-terminal-foreground", L10n.text("Terminal 文字", "Terminal text"), "#E7E7E7")
    ]

    private let interactionTokens: [(String, String, String)] = [
        ("--color-token-list-hover-background", L10n.text("滑過項目", "List hover"), "#FFFFFF0D"),
        ("--color-token-list-active-selection-background", L10n.text("選中項目", "Active selection"), "#339CFF26"),
        ("--color-token-editor-selection-background", L10n.text("文字選取", "Text selection"), "#339CFF40"),
        ("--color-token-focus-border", L10n.text("焦點框", "Focus ring"), "#339CFF"),
        ("--color-token-text-link-foreground", L10n.text("連結", "Link"), "#62B0FF"),
        ("--color-token-scrollbar-slider-background", L10n.text("捲軸", "Scrollbar"), "#FFFFFF29"),
        ("--color-token-diff-editor-inserted-line-background", L10n.text("Diff 新增", "Diff added"), "#40C97724"),
        ("--color-token-diff-editor-removed-line-background", L10n.text("Diff 刪除", "Diff removed"), "#FA423E24")
    ]

    private let syntaxTokens: [(String, String, String)] = [
        ("--color-token-terminal-ansi-red", "ANSI Red", "#F14C4C"),
        ("--color-token-terminal-ansi-green", "ANSI Green", "#23D18B"),
        ("--color-token-terminal-ansi-yellow", "ANSI Yellow", "#F5F543"),
        ("--color-token-terminal-ansi-blue", "ANSI Blue", "#3B8EEA"),
        ("--color-token-terminal-ansi-magenta", "ANSI Magenta", "#D670D6"),
        ("--color-token-terminal-ansi-cyan", "ANSI Cyan", "#29B8DB"),
        ("--color-token-terminal-ansi-white", "ANSI White", "#E5E5E5"),
        ("--color-token-terminal-ansi-black", "ANSI Black", "#181818")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.text("色彩系統", "Color system"),
                    description: L10n.text(
                        "基礎色會編譯成 Codex 的穩定 token；進階色可精準覆寫特定介面。所有欄位都接受 HEX、Display-P3、rgba、漸層或 color-mix。",
                        "Foundation colors compile to stable Codex tokens. Advanced colors target individual surfaces. Fields accept HEX, Display-P3, rgba, gradients, and color-mix."
                    )
                )

                EditorSection(
                    title: L10n.text("基礎色", "Foundation"),
                    subtitle: L10n.text(
                        "分享主題時相容性最高的一層",
                        "The most portable layer for shared themes"
                    )
                ) {
                    colorGrid(
                        semanticColors.map { role, title, fallback in
                            CSSColorDefinition(
                                id: role.rawValue,
                                title: title,
                                token: role.cssVariableName,
                                fallback: fallback,
                                value: Binding(
                                    get: {
                                        model.semanticValue(
                                            role,
                                            fallback: fallback
                                        )
                                    },
                                    set: {
                                        model.setSemanticValue(role, value: $0)
                                    }
                                )
                            )
                        }
                    )
                }

                tokenSection(
                    L10n.text("介面表面", "Surfaces"),
                    subtitle: L10n.text(
                        "側欄、輸入、選單、程式碼與 Terminal",
                        "Sidebar, inputs, menus, code, and terminal"
                    ),
                    tokens: surfaceTokens
                )

                tokenSection(
                    L10n.text("互動與 Diff", "Interaction & diff"),
                    subtitle: L10n.text(
                        "滑過、選中、焦點、連結與變更標記",
                        "Hover, selection, focus, links, and changes"
                    ),
                    tokens: interactionTokens
                )

                tokenSection(
                    L10n.text("Terminal / Syntax Palette", "Terminal / Syntax Palette"),
                    subtitle: L10n.text(
                        "完整 ANSI 基礎色，可再到進階 token 增加 bright 色",
                        "Complete ANSI base palette; add bright variants under advanced tokens"
                    ),
                    tokens: syntaxTokens
                )
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }

    private func tokenSection(
        _ title: String,
        subtitle: String,
        tokens: [(String, String, String)]
    ) -> some View {
        EditorSection(title: title, subtitle: subtitle) {
            colorGrid(
                tokens.map { token, title, fallback in
                    CSSColorDefinition(
                        id: token,
                        title: title,
                        token: token,
                        fallback: fallback,
                        value: Binding(
                            get: {
                                model.tokenValue(token, fallback: fallback)
                            },
                            set: {
                                model.setTokenValue(token, value: $0)
                            }
                        )
                    )
                }
            )
        }
    }

    private func colorGrid(
        _ definitions: [CSSColorDefinition]
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 10
        ) {
            ForEach(definitions) { definition in
                CSSColorField(definition: definition)
            }
        }
    }
}

private struct CSSColorDefinition: Identifiable {
    let id: String
    let title: String
    let token: String
    let fallback: String
    let value: Binding<String>
}

private struct CSSColorField: View {
    let definition: CSSColorDefinition

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                Color(
                    css: definition.value.wrappedValue,
                    fallback: Color(css: definition.fallback, fallback: .gray)
                )
            },
            set: { color in
                definition.value.wrappedValue = NSColor(color).cssHex
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(definition.title)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(definition.token)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            HStack(spacing: 7) {
                ColorPicker(
                    "",
                    selection: colorBinding,
                    supportsOpacity: true
                )
                .labelsHidden()
                .frame(width: 30)
                TextField(
                    L10n.text("CSS 值", "CSS value"),
                    text: definition.value
                )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct TypographyEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    private let typeTokens: [CSSTokenDefinition] = [
        .init("--font-sans", L10n.text("UI 字型", "UI font"), "system-ui, -apple-system"),
        .init("--font-mono", L10n.text("程式碼字型", "Code font"), "ui-monospace, SFMono-Regular"),
        .init("--codex-chat-font-size", L10n.text("對話字級", "Chat font size"), "14px"),
        .init("--codex-chat-code-font-size", L10n.text("程式碼字級", "Code font size"), "13px"),
        .init("--markdown-font-size", L10n.text("Markdown 字級", "Markdown font size"), "14px"),
        .init("--markdown-line-height", L10n.text("Markdown 行高", "Markdown line height"), "1.65"),
        .init("--text-base", L10n.text("基準字級", "Base type scale"), "14px"),
        .init("--letter-spacing", L10n.text("全域字距", "Global tracking"), "0em")
    ]

    private let geometryTokens: [CSSTokenDefinition] = [
        .init("--codex-corner-radius-scale", L10n.text("全域圓角", "Global radius"), "12px"),
        .init("--composer-border-radius", L10n.text("輸入框圓角", "Composer radius"), "18px"),
        .init("--radius-lg", L10n.text("大型元件圓角", "Large radius"), "12px"),
        .init("--radius-2xl", L10n.text("超大型圓角", "2XL radius"), "16px"),
        .init("--spacing", L10n.text("間距倍率", "Spacing scale"), "0.25rem"),
        .init("--padding-row-x", L10n.text("列水平內距", "Row horizontal padding"), "12px"),
        .init("--padding-row-y", L10n.text("列垂直內距", "Row vertical padding"), "8px"),
        .init("--height-toolbar", L10n.text("工具列高度", "Toolbar height"), "40px"),
        .init("--thread-content-max-width", L10n.text("對話最大寬度", "Thread max width"), "48rem"),
        .init("--markdown-wide-block-max-width", L10n.text("寬內容最大寬度", "Wide block max width"), "72rem")
    ]

    private let effectTokens: [CSSTokenDefinition] = [
        .init("--codex-titlebar-tint", L10n.text("標題列色調", "Titlebar tint"), "transparent"),
        .init("--composer-top-tray-background", L10n.text("Composer tray 背景", "Composer tray background"), "transparent"),
        .init("--shadow-2xl", L10n.text("大型陰影", "Large shadow"), "0 24px 48px rgba(0,0,0,.24)"),
        .init("--blur-lg", L10n.text("大型模糊", "Large blur"), "16px"),
        .init("--transition-duration-basic", L10n.text("基本動畫時間", "Basic motion duration"), "150ms"),
        .init("--transition-duration-relaxed", L10n.text("舒緩動畫時間", "Relaxed motion duration"), "240ms"),
        .init("--codex-window-zoom", L10n.text("介面縮放", "Interface zoom"), "1")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.typography,
                    description: L10n.text(
                        "值直接寫入 Codex token，所以可以使用任何合法 CSS：變數字型、clamp()、calc()、自訂陰影與動畫都可以。",
                        "Values map directly to Codex tokens, so variable fonts, clamp(), calc(), custom shadows, and motion are all supported."
                    )
                )
                tokenEditorSection(
                    L10n.text("Typography", "Typography"),
                    L10n.text("字型家族、字級、行高與字距", "Families, scale, line height, and tracking"),
                    typeTokens
                )
                tokenEditorSection(
                    L10n.text("Geometry & Density", "Geometry & Density"),
                    L10n.text("圓角、間距、密度與內容寬度", "Radius, spacing, density, and content width"),
                    geometryTokens
                )
                tokenEditorSection(
                    L10n.text("Effects & Motion", "Effects & Motion"),
                    L10n.text("色調、陰影、模糊、縮放與動畫", "Tint, shadow, blur, zoom, and motion"),
                    effectTokens
                )
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }

    private func tokenEditorSection(
        _ title: String,
        _ subtitle: String,
        _ tokens: [CSSTokenDefinition]
    ) -> some View {
        EditorSection(title: title, subtitle: subtitle) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 10
            ) {
                ForEach(tokens) { definition in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(definition.title)
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text(definition.token)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        TextField(
                            definition.fallback,
                            text: Binding(
                                get: {
                                    model.tokenValue(
                                        definition.token,
                                        fallback: definition.fallback
                                    )
                                },
                                set: {
                                    model.setTokenValue(
                                        definition.token,
                                        value: $0
                                    )
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.35))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                    )
                }
            }
        }
    }
}

private struct CSSTokenDefinition: Identifiable {
    var id: String { token }
    let token: String
    let title: String
    let fallback: String

    init(_ token: String, _ title: String, _ fallback: String) {
        self.token = token
        self.title = title
        self.fallback = fallback
    }
}

private struct ComponentEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.components,
                    description: L10n.text(
                        "元件可使用內建 catalog（app、sidebar、composer、codeBlock…），也可以填任意 selectors。property/value 完全不受限制。",
                        "Use catalog components (app, sidebar, composer, codeBlock…) or supply any selectors. Property/value pairs are unrestricted."
                    )
                )

                if let draft = model.draft {
                    ForEach(
                        Array(draft.layers.enumerated()),
                        id: \.element.id
                    ) { layerIndex, layer in
                        let componentTemplate =
                            layer.components.count == 1
                                ? "{0} component override"
                                : "{0} component overrides"
                        EditorSection(
                            title: layer.name,
                            subtitle: L10n.format(
                                "{0} 個元件覆寫",
                                componentTemplate,
                                String(layer.components.count)
                            )
                        ) {
                            VStack(spacing: 12) {
                                ForEach(
                                    Array(layer.components.enumerated()),
                                    id: \.element.id
                                ) { componentIndex, _ in
                                    ComponentOverrideCard(
                                        model: model,
                                        layerIndex: layerIndex,
                                        componentIndex: componentIndex
                                    )
                                }
                                Button {
                                    model.mutateDraft { document in
                                        document.layers[layerIndex]
                                            .components.append(
                                                ThemeComponentOverride(
                                                    componentID: "custom",
                                                    selectors: [".your-selector"],
                                                    declarations: [
                                                        ThemeCSSDeclaration(
                                                            property: "background",
                                                            value: "var(--codex-theme-surface)"
                                                        )
                                                    ]
                                                )
                                            )
                                    }
                                } label: {
                                    Label(
                                        L10n.text("新增元件覆寫", "Add component override"),
                                        systemImage: "plus"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }
}

private struct ComponentOverrideCard: View {
    @ObservedObject var model: ThemeAppModel
    let layerIndex: Int
    let componentIndex: Int

    private var component: ThemeComponentOverride? {
        guard let draft = model.draft,
              draft.layers.indices.contains(layerIndex),
              draft.layers[layerIndex].components.indices.contains(
                componentIndex
              ) else {
            return nil
        }
        return draft.layers[layerIndex].components[componentIndex]
    }

    var body: some View {
        if let component {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Toggle(
                        "",
                        isOn: binding(
                            get: { $0.isEnabled },
                            set: { $0.isEnabled = $1 }
                        )
                    )
                    .labelsHidden()
                    TextField(
                        "componentID",
                        text: binding(
                            get: { $0.componentID },
                            set: { $0.componentID = $1 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    TextField(
                        L10n.text(
                            "selectors，以逗號分隔",
                            "selectors, comma-separated"
                        ),
                        text: Binding(
                            get: { component.selectors.joined(separator: ", ") },
                            set: { value in
                                update { item in
                                    item.selectors = value
                                        .split(separator: ",")
                                        .map {
                                            $0.trimmingCharacters(
                                                in: .whitespacesAndNewlines
                                            )
                                        }
                                        .filter { !$0.isEmpty }
                                }
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 10, design: .monospaced))
                    Button(role: .destructive) {
                        model.mutateDraft { document in
                            document.layers[layerIndex]
                                .components.remove(at: componentIndex)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }

                VStack(spacing: 6) {
                    ForEach(
                        Array(component.declarations.enumerated()),
                        id: \.element.id
                    ) { declarationIndex, declaration in
                        HStack(spacing: 6) {
                            Toggle(
                                "",
                                isOn: declarationBinding(
                                    declarationIndex,
                                    get: { $0.isEnabled },
                                    set: { $0.isEnabled = $1 }
                                )
                            )
                            .labelsHidden()
                            TextField(
                                L10n.text("屬性", "Property"),
                                text: declarationBinding(
                                    declarationIndex,
                                    get: { $0.property },
                                    set: { $0.property = $1 }
                                )
                            )
                            .frame(width: 145)
                            TextField(
                                L10n.text("CSS 值", "CSS value"),
                                text: declarationBinding(
                                    declarationIndex,
                                    get: { $0.value },
                                    set: { $0.value = $1 }
                                )
                            )
                            Toggle(
                                "!important",
                                isOn: declarationBinding(
                                    declarationIndex,
                                    get: { $0.isImportant },
                                    set: { $0.isImportant = $1 }
                                )
                            )
                            .font(.system(size: 9, design: .monospaced))
                            Button {
                                update { item in
                                    item.declarations.remove(
                                        at: declarationIndex
                                    )
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                        .font(.system(size: 10, design: .monospaced))
                    }
                }

                Button {
                    update {
                        $0.declarations.append(
                            ThemeCSSDeclaration(
                                property: "color",
                                value: "var(--codex-theme-text-primary)"
                            )
                        )
                    }
                } label: {
                    Label(
                        L10n.text("新增 declaration", "Add declaration"),
                        systemImage: "plus.circle"
                    )
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(12)
            .background(.quaternary.opacity(0.32))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func update(
        _ mutation: @escaping (inout ThemeComponentOverride) -> Void
    ) {
        model.mutateDraft { document in
            guard document.layers.indices.contains(layerIndex),
                  document.layers[layerIndex].components.indices.contains(
                    componentIndex
                  ) else {
                return
            }
            mutation(&document.layers[layerIndex].components[componentIndex])
        }
    }

    private func binding<Value>(
        get: @escaping (ThemeComponentOverride) -> Value,
        set: @escaping (inout ThemeComponentOverride, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(component!) },
            set: { newValue in update { set(&$0, newValue) } }
        )
    }

    private func declarationBinding<Value>(
        _ index: Int,
        get: @escaping (ThemeCSSDeclaration) -> Value,
        set: @escaping (inout ThemeCSSDeclaration, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(component!.declarations[index]) },
            set: { value in
                update { item in
                    guard item.declarations.indices.contains(index) else {
                        return
                    }
                    set(&item.declarations[index], value)
                }
            }
        )
    }
}

private struct RuleEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.rules,
                    description: L10n.text(
                        "任意 selector 規則是高自由度的第二層 escape hatch。Codex 更新後 selector 可能改變，因此分享時請寫清楚適用版本。",
                        "Arbitrary selector rules are the second escape hatch. Selectors may change across Codex updates, so document compatible versions when sharing."
                    )
                )

                if let draft = model.draft {
                    ForEach(
                        Array(draft.layers.enumerated()),
                        id: \.element.id
                    ) { layerIndex, layer in
                        let condition = localizedLayerCondition(
                            layer.condition
                        )
                        let ruleTemplate = layer.rules.count == 1
                            ? "{0} · {1} rule"
                            : "{0} · {1} rules"
                        EditorSection(
                            title: layer.name,
                            subtitle: L10n.format(
                                "{0} · {1} 條規則",
                                ruleTemplate,
                                condition,
                                String(layer.rules.count)
                            )
                        ) {
                            VStack(spacing: 12) {
                                ForEach(
                                    Array(layer.rules.enumerated()),
                                    id: \.element.id
                                ) { ruleIndex, _ in
                                    RuleCard(
                                        model: model,
                                        layerIndex: layerIndex,
                                        ruleIndex: ruleIndex
                                    )
                                }
                                Button {
                                    model.mutateDraft { document in
                                        document.layers[layerIndex].rules.append(
                                            ThemeCSSRule(
                                                name: L10n.text(
                                                    "自訂規則",
                                                    "Custom rule"
                                                ),
                                                selector: ".your-selector",
                                                declarations: [
                                                    ThemeCSSDeclaration(
                                                        property: "background",
                                                        value: "transparent"
                                                    )
                                                ]
                                            )
                                        )
                                    }
                                } label: {
                                    Label(
                                        L10n.text("新增 CSS 規則", "Add CSS rule"),
                                        systemImage: "plus"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }
}

private struct RuleCard: View {
    @ObservedObject var model: ThemeAppModel
    let layerIndex: Int
    let ruleIndex: Int

    private var rule: ThemeCSSRule? {
        guard let draft = model.draft,
              draft.layers.indices.contains(layerIndex),
              draft.layers[layerIndex].rules.indices.contains(ruleIndex) else {
            return nil
        }
        return draft.layers[layerIndex].rules[ruleIndex]
    }

    var body: some View {
        if let rule {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Toggle(
                        "",
                        isOn: binding(
                            get: { $0.isEnabled },
                            set: { $0.isEnabled = $1 }
                        )
                    )
                    .labelsHidden()
                    TextField(
                        L10n.text("規則名稱", "Rule name"),
                        text: binding(
                            get: { $0.name },
                            set: { $0.name = $1 }
                        )
                    )
                    .frame(width: 160)
                    TextField(
                        "selector",
                        text: binding(
                            get: { $0.selector },
                            set: { $0.selector = $1 }
                        )
                    )
                    .font(.system(size: 10, design: .monospaced))
                    Button(role: .destructive) {
                        model.mutateDraft {
                            $0.layers[layerIndex].rules.remove(at: ruleIndex)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }

                ForEach(
                    Array(rule.declarations.enumerated()),
                    id: \.element.id
                ) { index, _ in
                    HStack {
                        TextField(
                            "property",
                            text: declarationBinding(
                                index,
                                get: { $0.property },
                                set: { $0.property = $1 }
                            )
                        )
                        .frame(width: 160)
                        TextField(
                            "value",
                            text: declarationBinding(
                                index,
                                get: { $0.value },
                                set: { $0.value = $1 }
                            )
                        )
                        Toggle(
                            "!important",
                            isOn: declarationBinding(
                                index,
                                get: { $0.isImportant },
                                set: { $0.isImportant = $1 }
                            )
                        )
                        .font(.system(size: 9, design: .monospaced))
                        Button {
                            update {
                                $0.declarations.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.system(size: 10, design: .monospaced))
                }
                Button {
                    update {
                        $0.declarations.append(
                            ThemeCSSDeclaration(
                                property: "color",
                                value: "inherit"
                            )
                        )
                    }
                } label: {
                    Label(
                        L10n.text("新增 declaration", "Add declaration"),
                        systemImage: "plus.circle"
                    )
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(12)
            .background(.quaternary.opacity(0.32))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func update(
        _ mutation: @escaping (inout ThemeCSSRule) -> Void
    ) {
        model.mutateDraft { document in
            guard document.layers.indices.contains(layerIndex),
                  document.layers[layerIndex].rules.indices.contains(ruleIndex)
            else { return }
            mutation(&document.layers[layerIndex].rules[ruleIndex])
        }
    }

    private func binding<Value>(
        get: @escaping (ThemeCSSRule) -> Value,
        set: @escaping (inout ThemeCSSRule, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(rule!) },
            set: { value in update { set(&$0, value) } }
        )
    }

    private func declarationBinding<Value>(
        _ index: Int,
        get: @escaping (ThemeCSSDeclaration) -> Value,
        set: @escaping (inout ThemeCSSDeclaration, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(rule!.declarations[index]) },
            set: { value in
                update { item in
                    guard item.declarations.indices.contains(index) else {
                        return
                    }
                    set(&item.declarations[index], value)
                }
            }
        )
    }
}

private struct RawCSSEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.rawCSS,
                    description: L10n.text(
                        "最後套用的完整 CSS，提供最高自由度。為了模板分享安全，@import、http(s) 與 file URL 會被拒絕；可用內嵌素材 macro。",
                        "Final CSS with maximum freedom. For share safety, @import and http(s)/file URLs are rejected; embedded asset macros remain available."
                    )
                )

                if let draft = model.draft {
                    ForEach(
                        Array(draft.layers.enumerated()),
                        id: \.element.id
                    ) { layerIndex, layer in
                        EditorSection(
                            title: layer.name,
                            subtitle: layerSubtitle(layer)
                        ) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Toggle(
                                        L10n.text("啟用", "Enabled"),
                                        isOn: Binding(
                                            get: { layer.isEnabled },
                                            set: { enabled in
                                                model.mutateDraft {
                                                    $0.layers[layerIndex]
                                                        .isEnabled = enabled
                                                }
                                            }
                                        )
                                    )
                                    TextField(
                                        L10n.text("Layer 名稱", "Layer name"),
                                        text: Binding(
                                            get: { layer.name },
                                            set: { name in
                                                model.mutateDraft {
                                                    $0.layers[layerIndex]
                                                        .name = name
                                                }
                                            }
                                        )
                                    )
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)
                                    Picker(
                                        L10n.text("條件", "Condition"),
                                        selection: Binding(
                                            get: { layer.condition },
                                            set: { condition in
                                                model.mutateDraft {
                                                    $0.layers[layerIndex]
                                                        .condition = condition
                                                }
                                            }
                                        )
                                    ) {
                                        ForEach(
                                            ThemeLayerCondition.allCases,
                                            id: \.self
                                        ) {
                                            Text(localizedLayerCondition($0))
                                                .tag($0)
                                        }
                                    }
                                    .frame(width: 145)
                                    if layer.condition == .custom {
                                        TextField(
                                            "(prefers-contrast: more)",
                                            text: Binding(
                                                get: {
                                                    layer.mediaQuery ?? ""
                                                },
                                                set: { value in
                                                    model.mutateDraft {
                                                        $0.layers[layerIndex]
                                                            .mediaQuery = value
                                                    }
                                                }
                                            )
                                        )
                                        .textFieldStyle(.roundedBorder)
                                    }
                                    Spacer()
                                    Button {
                                        model.mutateDraft {
                                            $0.layers.swapAt(
                                                layerIndex,
                                                layerIndex - 1
                                            )
                                        }
                                    } label: {
                                        Image(systemName: "arrow.up")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(layerIndex == 0)
                                    .help(
                                        L10n.text(
                                            "提早套用（降低 cascade 優先序）",
                                            "Apply earlier (lower cascade priority)"
                                        )
                                    )

                                    Button {
                                        model.mutateDraft {
                                            $0.layers.swapAt(
                                                layerIndex,
                                                layerIndex + 1
                                            )
                                        }
                                    } label: {
                                        Image(systemName: "arrow.down")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(
                                        layerIndex == draft.layers.count - 1
                                    )
                                    .help(
                                        L10n.text(
                                            "延後套用（提高 cascade 優先序）",
                                            "Apply later (higher cascade priority)"
                                        )
                                    )

                                    if draft.layers.count > 1 {
                                        Button(role: .destructive) {
                                            model.mutateDraft {
                                                $0.layers.remove(
                                                    at: layerIndex
                                                )
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }

                                TextEditor(
                                    text: Binding(
                                        get: { layer.rawCSS },
                                        set: { value in
                                            model.mutateDraft {
                                                $0.layers[layerIndex].rawCSS =
                                                    value
                                            }
                                        }
                                    )
                                )
                                .font(.system(size: 11, design: .monospaced))
                                .frame(minHeight: 180)
                                .scrollContentBackground(.hidden)
                                .padding(9)
                                .background(Color.black.opacity(0.18))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 8,
                                        style: .continuous
                                    )
                                )
                            }
                        }
                    }

                    EditorSection(
                        title: L10n.text("Advanced Tokens", "Advanced Tokens"),
                        subtitle: L10n.text(
                            "增加任何 --color-token-*、--vscode-* 或自訂 CSS variable",
                            "Add any --color-token-*, --vscode-*, or custom CSS variable"
                        )
                    ) {
                        AdvancedVariableList(model: model)
                    }

                    Button {
                        model.mutateDraft { document in
                            document.layers.append(
                                ThemeLayer(
                                    name: L10n.text(
                                        "新條件層",
                                        "New conditional layer"
                                    ),
                                    condition: .dark
                                )
                            )
                        }
                    } label: {
                        Label(
                            L10n.text("新增條件 Layer", "Add conditional layer"),
                            systemImage: "square.stack.3d.up.badge.a"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }

    private func layerSubtitle(_ layer: ThemeLayer) -> String {
        switch layer.condition {
        case .always:
            return L10n.text("永遠套用", "Always applied")
        case .light:
            return "@media (prefers-color-scheme: light)"
        case .dark:
            return "@media (prefers-color-scheme: dark)"
        case .custom:
            return "@media \(layer.mediaQuery ?? "")"
        }
    }
}

private struct AdvancedVariableList: View {
    @ObservedObject var model: ThemeAppModel

    private var variables: [(layer: Int, index: Int, value: ThemeVariable)] {
        guard let draft = model.draft else { return [] }
        return draft.layers.enumerated().flatMap { layerIndex, layer in
            layer.variables.enumerated().compactMap { index, variable in
                variable.semanticRole == nil
                    ? (layerIndex, index, variable)
                    : nil
            }
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(variables, id: \.value.id) { item in
                HStack(spacing: 7) {
                    Toggle(
                        "",
                        isOn: binding(
                            item,
                            get: { $0.isEnabled },
                            set: { $0.isEnabled = $1 }
                        )
                    )
                    .labelsHidden()
                    TextField(
                        "--custom-variable",
                        text: binding(
                            item,
                            get: { $0.name },
                            set: { $0.name = $1 }
                        )
                    )
                    .frame(width: 260)
                    TextField(
                        L10n.text("CSS 值", "CSS value"),
                        text: binding(
                            item,
                            get: { $0.value },
                            set: { $0.value = $1 }
                        )
                    )
                    Button {
                        model.mutateDraft {
                            $0.layers[item.layer].variables.remove(
                                at: item.index
                            )
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .font(.system(size: 10, design: .monospaced))
            }
            Button {
                model.addVariable()
            } label: {
                Label(
                    L10n.text("新增 token", "Add token"),
                    systemImage: "plus.circle"
                )
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func binding<Value>(
        _ item: (layer: Int, index: Int, value: ThemeVariable),
        get: @escaping (ThemeVariable) -> Value,
        set: @escaping (inout ThemeVariable, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(item.value) },
            set: { value in
                model.mutateDraft { document in
                    guard document.layers.indices.contains(item.layer),
                          document.layers[item.layer].variables.indices
                            .contains(item.index) else {
                        return
                    }
                    set(
                        &document.layers[item.layer].variables[item.index],
                        value
                    )
                }
            }
        )
    }
}

private func localizedLayerCondition(
    _ condition: ThemeLayerCondition
) -> String {
    switch condition {
    case .always:
        L10n.text("永遠", "Always")
    case .light:
        L10n.text("淺色", "Light")
    case .dark:
        L10n.text("深色", "Dark")
    case .custom:
        L10n.text("自訂", "Custom")
    }
}

private struct AssetEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.assets,
                    description: L10n.text(
                        "背景圖、紋理、GIF 與字型會以 base64 嵌入單一 .codextheme 檔，導入後不會遺失。CSS 使用 theme-asset(\"UUID\")。",
                        "Images, textures, GIFs, and fonts are base64-embedded in one .codextheme file. Reference them with theme-asset(\"UUID\")."
                    )
                )

                EditorSection(
                    title: L10n.text("Embedded Assets", "Embedded Assets"),
                    subtitle: L10n.text(
                        "每個素材上限 16 MB；素材總量 32 MB；模板檔上限 48 MB",
                        "16 MB per asset; 32 MB total assets; 48 MB per template"
                    )
                ) {
                    VStack(spacing: 10) {
                        if let assets = model.draft?.assets, !assets.isEmpty {
                            ForEach(assets) { asset in
                                AssetRow(asset: asset) {
                                    model.removeAsset(asset.id)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text(
                                    L10n.text(
                                        "尚未加入素材",
                                        "No embedded assets"
                                    )
                                )
                                .font(.headline)
                                Text(
                                    L10n.text(
                                        "加入背景圖或字型，導出時會一起打包。",
                                        "Add a background or font and it will travel with the export."
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 26)
                        }

                        Button {
                            model.addAsset()
                        } label: {
                            Label(
                                L10n.text("加入素材", "Add asset"),
                                systemImage: "plus"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                }

                EditorSection(
                    title: L10n.text("範例", "Examples"),
                    subtitle: L10n.text(
                        "將 UUID 換成素材列顯示的值",
                        "Replace the UUID with the value shown above"
                    )
                ) {
                    Text(
                        """
                        body {
                          background-image: theme-asset("ASSET-UUID");
                          background-size: cover;
                          background-attachment: fixed;
                        }

                        @font-face {
                          font-family: "My Theme Font";
                          src: theme-asset("FONT-UUID") format("woff2");
                        }
                        """
                    )
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.black.opacity(0.18))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                }
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }
}

private struct AssetRow: View {
    let asset: ThemeAsset
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            assetThumbnail
                .frame(width: 52, height: 42)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name)
                    .font(.caption.weight(.medium))
                Text(
                    "\(asset.mediaType) · \(ByteCountFormatter.string(fromByteCount: Int64(asset.decodedData?.count ?? 0), countStyle: .file))"
                )
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                Text("theme-asset(\"\(asset.id.uuidString)\")")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tint)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    "theme-asset(\"\(asset.id.uuidString)\")",
                    forType: .string
                )
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(9)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    @ViewBuilder
    private var assetThumbnail: some View {
        if asset.mediaType.hasPrefix("image/"),
           let data = asset.decodedData,
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Image(systemName: "textformat")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ThemeInfoEditorPage: View {
    @ObservedObject var model: ThemeAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                EditorIntro(
                    title: L10n.info,
                    description: L10n.text(
                        "完整 metadata 會隨模板導出，方便作者署名、版本管理與相容性說明。",
                        "Metadata travels with exports for attribution, versioning, and compatibility notes."
                    )
                )

                if let theme = model.draft {
                    EditorSection(
                        title: L10n.text("主題資料", "Theme metadata"),
                        subtitle: "schema v\(theme.schemaVersion) · \(theme.id.uuidString)"
                    ) {
                        Grid(
                            alignment: .leading,
                            horizontalSpacing: 14,
                            verticalSpacing: 12
                        ) {
                            infoRow(
                                L10n.text("名稱", "Name"),
                                \.metadata.name
                            )
                            infoRow(
                                L10n.text("作者", "Author"),
                                \.metadata.author
                            )
                            infoRow(
                                L10n.text("版本", "Version"),
                                \.metadata.version
                            )
                            GridRow {
                                Text(L10n.text("標籤", "Tags"))
                                    .foregroundStyle(.secondary)
                                TextField(
                                    L10n.text(
                                        "dark, glass, neon",
                                        "dark, glass, neon"
                                    ),
                                    text: Binding(
                                        get: {
                                            theme.metadata.tags.joined(
                                                separator: ", "
                                            )
                                        },
                                        set: { value in
                                            model.mutateDraft {
                                                $0.metadata.tags = value
                                                    .split(separator: ",")
                                                    .map {
                                                        $0.trimmingCharacters(
                                                            in: .whitespacesAndNewlines
                                                        )
                                                    }
                                                    .filter { !$0.isEmpty }
                                            }
                                        }
                                    )
                                )
                                .textFieldStyle(.roundedBorder)
                            }
                            infoRow(
                                L10n.text("授權", "License"),
                                \.metadata.license,
                                fallback: ""
                            )
                            GridRow {
                                Text(L10n.text("說明", "Description"))
                                    .foregroundStyle(.secondary)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                TextEditor(
                                    text: Binding(
                                        get: {
                                            theme.metadata.description
                                        },
                                        set: { value in
                                            model.mutateDraft {
                                                $0.metadata.description = value
                                            }
                                        }
                                    )
                                )
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(7)
                                .background(.quaternary.opacity(0.35))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 7)
                                )
                            }
                        }
                        .font(.caption)
                    }
                    .disabled(model.isSelectedBuiltIn)

                    EditorSection(
                        title: L10n.text("分享模板", "Share template"),
                        subtitle: L10n.text(
                            "單一檔案包含 theme、CSS 與所有素材",
                            "One file contains the theme, CSS, and every asset"
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(".codextheme")
                                    .font(.system(.headline, design: .monospaced))
                                Text(
                                    L10n.text(
                                        "導入時會驗證 schema、安全 CSS、容量與 ID 衝突；不會自動套用。",
                                        "Imports validate schema, CSS safety, size, and ID collisions, and never auto-apply."
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(L10n.exportTheme) {
                                model.exportSelected()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if !model.isSelectedBuiltIn {
                        Button(
                            L10n.text("刪除這個主題", "Delete this theme"),
                            role: .destructive
                        ) {
                            model.deleteSelected()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(18)
        }
    }

    private func infoRow(
        _ title: String,
        _ keyPath: WritableKeyPath<ThemeDocument, String>
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(
                title,
                text: Binding(
                    get: { model.draft?[keyPath: keyPath] ?? "" },
                    set: { value in
                        model.mutateDraft { $0[keyPath: keyPath] = value }
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }

    private func infoRow(
        _ title: String,
        _ keyPath: WritableKeyPath<ThemeDocument, String?>,
        fallback: String
    ) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            TextField(
                title,
                text: Binding(
                    get: { model.draft?[keyPath: keyPath] ?? fallback },
                    set: { value in
                        model.mutateDraft {
                            $0[keyPath: keyPath] = value.isEmpty ? nil : value
                        }
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
        }
    }
}

struct EditorIntro: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EditorSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}
