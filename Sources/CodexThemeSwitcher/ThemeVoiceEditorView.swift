import AppKit
import CodexThemeSwitcherCore
import SwiftUI

struct ThemeVoiceEditorView: View {
    @ObservedObject var model: ThemeAppModel

    private var appearance: ThemeSkinAppearance {
        model.previewAppearance
    }

    private var style: ThemeVoiceStyle {
        model.draft?.voiceStyle ?? ThemeVoiceStyle()
    }

    private var variant: ThemeVoiceVariant {
        style.variant(for: appearance)
    }

    private var backgroundAsset: ThemeAsset? {
        guard let id = variant.backgroundAssetID else { return nil }
        return model.draft?.assets.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if style.isEnabled {
                    previewSection
                    backgroundSection
                    orbSection
                    glowSection
                    backdropSection
                    advancedSection
                }
            }
            .padding(18)
        }
        .disabled(model.isSelectedBuiltIn)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                EditorIntro(
                    title: L10n.voice,
                    description: L10n.text(
                        "自訂 ChatGPT Voice 圓球可由 CSS 控制的表面與周圍效果。Voice 使用獨立 renderer，不會套用主畫面的壁紙與元件規則。",
                        "Customize CSS-addressable ChatGPT Voice orb surfaces and surrounding effects. Voice uses an isolated renderer and never receives the main window wallpaper or component rules."
                    )
                )
                Spacer()
                Toggle(
                    L10n.text("啟用 Voice 樣式", "Enable Voice styling"),
                    isOn: enabledBinding
                )
                .toggleStyle(.switch)
            }

            HStack(spacing: 8) {
                Label(
                    L10n.text("實驗功能", "Experimental"),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.orange)
                Text(
                    L10n.text(
                        "不同 Codex 版本可能使用 DOM、Canvas、WebGL 或原生圖層；原生圓球內部不受 CSS 控制。",
                        "Codex versions may use DOM, Canvas, WebGL, or native layers. CSS cannot alter the inside of a native orb."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                if style.isEnabled {
                    Button(L10n.text("重設目前版本", "Reset current appearance")) {
                        resetCurrentVariant()
                    }
                    Button(L10n.text("移除 Voice 樣式", "Remove Voice style"), role: .destructive) {
                        model.removeVoiceStyle()
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var previewSection: some View {
        EditorSection(
            title: L10n.text("效果預覽", "Effect preview"),
            subtitle: L10n.text(
                "預覽呈現 CSS 濾鏡；實際圓球是否能完整套用，取決於目前 Codex Voice renderer。",
                "This previews the CSS filters. How much reaches the real orb depends on the current Codex Voice renderer."
            )
        ) {
            HStack {
                Picker(
                    L10n.text("編輯版本", "Editing"),
                    selection: $model.previewAppearance
                ) {
                    Label(L10n.text("淺色", "Light"), systemImage: "sun.max")
                        .tag(ThemeSkinAppearance.light)
                    Label(L10n.text("深色", "Dark"), systemImage: "moon.stars")
                        .tag(ThemeSkinAppearance.dark)
                }
                .pickerStyle(.segmented)
                .frame(width: 230)

                Spacer()

                if model.appliedThemeID == model.draft?.id,
                   model.runtimeStatus?.voiceStyleEnabled == true {
                    Label(
                        (model.runtimeStatus?.avatarOverlayRendererCount ?? 0) > 0
                            ? L10n.text(
                                "Voice renderer 已連接",
                                "Voice renderer connected"
                            )
                            : L10n.text(
                                "等待開啟 Voice 對話",
                                "Waiting for a Voice conversation"
                            ),
                        systemImage:
                            (model.runtimeStatus?.avatarOverlayRendererCount ?? 0) > 0
                            ? "checkmark.circle.fill"
                            : "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        (model.runtimeStatus?.avatarOverlayRendererCount ?? 0) > 0
                            ? Color.green
                            : Color.secondary
                    )
                }

                Button {
                    copyToOtherAppearance()
                } label: {
                    Label(
                        L10n.format(
                            "複製到{0}",
                            "Copy to {0}",
                            appearance == .light
                                ? L10n.text("深色", "Dark")
                                : L10n.text("淺色", "Light")
                        ),
                        systemImage: "square.on.square"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VoiceOrbPreview(
                variant: variant,
                appearance: appearance,
                backgroundAsset: backgroundAsset
            )
            .frame(height: 250)
        }
    }

    private var backgroundSection: some View {
        EditorSection(
            title: L10n.text(
                "Voice 背景圖片",
                "Voice background image"
            ),
            subtitle: L10n.text(
                "Light／Dark 可使用不同圖片；圖片會嵌入 .codextheme，且只送到 Voice overlay。",
                "Light and Dark can use different images. The image is embedded in the .codextheme and sent only to the Voice overlay."
            )
        ) {
            HStack(spacing: 14) {
                backgroundAssetPreview
                    .frame(width: 170, height: 108)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.quaternary)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        backgroundAsset?.name
                            ?? L10n.text(
                                "尚未選擇圖片",
                                "No image selected"
                            )
                    )
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                    if let backgroundAsset {
                        Text(
                            "\(backgroundAsset.mediaType) · "
                                + ByteCountFormatter.string(
                                    fromByteCount: Int64(
                                        backgroundAsset.decodedData?.count ?? 0
                                    ),
                                    countStyle: .file
                                )
                        )
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button {
                            model.chooseVoiceBackground(for: appearance)
                        } label: {
                            Label(
                                L10n.text("選擇圖片", "Choose image"),
                                systemImage: "photo"
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        if !model.availableSkinImageAssets.isEmpty {
                            Menu {
                                ForEach(
                                    model.availableSkinImageAssets
                                ) { asset in
                                    Button {
                                        model.setVoiceBackground(
                                            asset.id,
                                            for: appearance
                                        )
                                    } label: {
                                        if asset.id == backgroundAsset?.id {
                                            Label(
                                                asset.name,
                                                systemImage: "checkmark"
                                            )
                                        } else {
                                            Text(asset.name)
                                        }
                                    }
                                }
                            } label: {
                                Label(
                                    L10n.text(
                                        "現有素材",
                                        "Existing assets"
                                    ),
                                    systemImage: "photo.stack"
                                )
                            }
                            .menuStyle(.borderlessButton)
                        }

                        if backgroundAsset != nil {
                            Button(
                                L10n.text("清除", "Clear"),
                                role: .destructive
                            ) {
                                model.clearVoiceBackground(
                                    for: appearance
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.small)
                }

                Spacer()
                voiceFocalGrid
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.text("圖片尺寸", "Image sizing"))
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Picker(
                        L10n.text("圖片尺寸", "Image sizing"),
                        selection: variantBinding(
                            \.backgroundImageFit
                        )
                    ) {
                        ForEach(
                            ThemeSkinImageFit.allCases,
                            id: \.self
                        ) { fit in
                            Text(imageFitTitle(fit)).tag(fit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 230)
                }

                HStack(spacing: 8) {
                    imageFitShortcut(
                        .contain,
                        title: L10n.text(
                            "完整顯示 Fit",
                            "Fit · Show Whole Image"
                        )
                    )
                    imageFitShortcut(
                        .cover,
                        title: L10n.text(
                            "填滿裁切 Fill",
                            "Fill · Crop to Fill"
                        )
                    )
                    Spacer()
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .disabled(backgroundAsset == nil)
            .opacity(backgroundAsset == nil ? 0.55 : 1)

            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text(
                        "水平焦點",
                        "Horizontal focal point"
                    ),
                    value: variantBinding(\.backgroundPositionX),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "垂直焦點",
                        "Vertical focal point"
                    ),
                    value: variantBinding(\.backgroundPositionY),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text("圖片縮放", "Image zoom"),
                    value: variantBinding(\.backgroundZoom),
                    range: 0.5...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "圖片不透明度",
                        "Image opacity"
                    ),
                    value: variantBinding(\.backgroundImageOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text("圖片模糊", "Image blur"),
                    value: variantBinding(\.backgroundImageBlur),
                    range: 0...40,
                    step: 0.5,
                    format: { String(format: "%.1f px", $0) }
                )
            }
            .disabled(backgroundAsset == nil)
            .opacity(backgroundAsset == nil ? 0.55 : 1)
        }
    }

    private var orbSection: some View {
        EditorSection(
            title: L10n.text("圓球表面", "Orb surface"),
            subtitle: L10n.text(
                "套用在 Voice overlay 裡可定位到的 Canvas 或圓球容器。",
                "Applied to Canvas and recognizable orb containers inside the Voice overlay."
            )
        ) {
            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text("縮放", "Scale"),
                    value: variantBinding(\.orbScale),
                    range: 0.5...2,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text("不透明度", "Opacity"),
                    value: variantBinding(\.orbOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text("亮度", "Brightness"),
                    value: variantBinding(\.brightness),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text("對比", "Contrast"),
                    value: variantBinding(\.contrast),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text("彩度", "Saturation"),
                    value: variantBinding(\.saturation),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text("色相旋轉", "Hue rotation"),
                    value: variantBinding(\.hueRotation),
                    range: -180...180,
                    step: 1,
                    format: { "\(Int($0))°" }
                )
                VoiceValueSlider(
                    title: L10n.text("模糊", "Blur"),
                    value: variantBinding(\.blur),
                    range: 0...40,
                    step: 0.5,
                    format: { String(format: "%.1f px", $0) }
                )
            }
        }
    }

    private var glowSection: some View {
        EditorSection(
            title: L10n.text("外圍光暈", "Outer glow")
        ) {
            settingsGrid {
                VoiceColorField(
                    title: L10n.text("光暈顏色", "Glow color"),
                    value: variantBinding(\.glowColor)
                )
                VoiceValueSlider(
                    title: L10n.text("光暈不透明度", "Glow opacity"),
                    value: variantBinding(\.glowOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text("光暈範圍", "Glow spread"),
                    value: variantBinding(\.glowBlur),
                    range: 0...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
            }
        }
    }

    private var backdropSection: some View {
        EditorSection(
            title: L10n.text("Voice 背景", "Voice backdrop"),
            subtitle: L10n.text(
                "預設完全透明。提高不透明度會為 Voice overlay 加上底色。",
                "Transparent by default. Raising opacity adds a tint behind the Voice overlay."
            )
        ) {
            settingsGrid {
                VoiceColorField(
                    title: L10n.text("背景顏色", "Backdrop color"),
                    value: variantBinding(\.backdropColor)
                )
                VoiceValueSlider(
                    title: L10n.text("背景不透明度", "Backdrop opacity"),
                    value: variantBinding(\.backdropOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
            }
        }
    }

    private var advancedSection: some View {
        EditorSection(
            title: L10n.text("Voice 進階 CSS", "Voice Advanced CSS"),
            subtitle: L10n.text(
                "只會送到 avatar-overlay，不會進入 Codex 主畫面。可使用 theme-asset(\"UUID\")；匯入、外部網址與 file URL 仍會被拒絕。",
                "Delivered only to avatar-overlay, never the main Codex window. theme-asset(\"UUID\") is supported; imports, external URLs, and file URLs remain blocked."
            )
        ) {
            TextEditor(text: rawCSSBinding)
                .font(.system(size: 11, design: .monospaced))
                .frame(minHeight: 180)
                .padding(6)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func settingsGrid<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12,
            content: content
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { style.isEnabled },
            set: { enabled in
                model.mutateDraft(
                    actionName: L10n.text(
                        enabled ? "啟用 Voice 樣式" : "停用 Voice 樣式",
                        enabled ? "Enable Voice styling" : "Disable Voice styling"
                    )
                ) { document in
                    var value = document.voiceStyle ?? ThemeVoiceStyle()
                    value.isEnabled = enabled
                    document.voiceStyle = value
                }
            }
        )
    }

    private func variantBinding<Value>(
        _ keyPath: WritableKeyPath<ThemeVoiceVariant, Value>
    ) -> Binding<Value> {
        Binding(
            get: { style.variant(for: appearance)[keyPath: keyPath] },
            set: { value in
                model.mutateDraft(
                    coalescingKey:
                        "voice-style.\(appearance.rawValue)."
                        + String(reflecting: keyPath)
                ) { document in
                    var voice = document.voiceStyle
                        ?? ThemeVoiceStyle(isEnabled: true)
                    var item = voice.variant(for: appearance)
                    item[keyPath: keyPath] = value
                    voice.setVariant(item, for: appearance)
                    document.voiceStyle = voice
                }
            }
        )
    }

    private var rawCSSBinding: Binding<String> {
        Binding(
            get: { style.rawCSS },
            set: { value in
                model.mutateDraft(
                    coalescingKey: "voice-style.raw-css"
                ) { document in
                    var voice = document.voiceStyle
                        ?? ThemeVoiceStyle(isEnabled: true)
                    voice.rawCSS = value
                    document.voiceStyle = voice
                }
            }
        )
    }

    private func copyToOtherAppearance() {
        let source = appearance
        let destination: ThemeSkinAppearance =
            source == .light ? .dark : .light
        model.mutateDraft(
            actionName: L10n.text(
                "複製 Voice 外觀",
                "Copy Voice appearance"
            )
        ) { document in
            var voice = document.voiceStyle
                ?? ThemeVoiceStyle(isEnabled: true)
            voice.setVariant(
                voice.variant(for: source),
                for: destination
            )
            document.voiceStyle = voice
        }
    }

    private func resetCurrentVariant() {
        model.resetVoiceVariant(for: appearance)
    }

    @ViewBuilder
    private var backgroundAssetPreview: some View {
        if let asset = backgroundAsset,
           let data = asset.decodedData,
           let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        .secondary.opacity(0.12),
                        .secondary.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var voiceFocalGrid: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text("快速焦點", "Quick focal point"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Grid(horizontalSpacing: 5, verticalSpacing: 5) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { column in
                            let x = Double(column) / 2
                            let y = Double(row) / 2
                            Button {
                                setVoiceFocalPoint(x: x, y: y)
                            } label: {
                                Circle()
                                    .fill(
                                        abs(variant.backgroundPositionX - x)
                                            < 0.01
                                            && abs(
                                                variant.backgroundPositionY
                                                    - y
                                            ) < 0.01
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.24)
                                    )
                                    .frame(width: 8, height: 8)
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .disabled(backgroundAsset == nil)
        .opacity(backgroundAsset == nil ? 0.55 : 1)
    }

    private func setVoiceFocalPoint(x: Double, y: Double) {
        model.mutateDraft(
            actionName: L10n.text(
                "調整 Voice 背景焦點",
                "Adjust Voice background focal point"
            )
        ) { document in
            var voice = document.voiceStyle
                ?? ThemeVoiceStyle(isEnabled: true)
            var value = voice.variant(for: appearance)
            value.backgroundPositionX = x
            value.backgroundPositionY = y
            voice.setVariant(value, for: appearance)
            document.voiceStyle = voice
        }
    }

    private func imageFitShortcut(
        _ fit: ThemeSkinImageFit,
        title: String
    ) -> some View {
        Button {
            variantBinding(\.backgroundImageFit).wrappedValue = fit
        } label: {
            Label(
                title,
                systemImage: variant.backgroundImageFit == fit
                    ? "checkmark.circle.fill"
                    : "photo"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func imageFitTitle(_ fit: ThemeSkinImageFit) -> String {
        switch fit {
        case .cover:
            L10n.text("填滿裁切（Fill）", "Fill · Crop to Fill")
        case .contain:
            L10n.text("完整顯示（Fit）", "Fit · Show Whole Image")
        case .fill:
            L10n.text("拉伸（Stretch）", "Stretch")
        case .fitWidth:
            L10n.text("符合寬度", "Fit Width")
        case .fitHeight:
            L10n.text("符合高度", "Fit Height")
        case .original:
            L10n.text("原始大小", "Original")
        case .tile:
            L10n.text("平鋪", "Tile")
        }
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct VoiceOrbPreview: View {
    let variant: ThemeVoiceVariant
    let appearance: ThemeSkinAppearance
    let backgroundAsset: ThemeAsset?

    var body: some View {
        ZStack {
            Color(
                css: variant.backdropColor,
                fallback: appearance == .dark ? .black : .white
            )
            .opacity(variant.backdropOpacity)

            if let backgroundAsset,
               let data = backgroundAsset.decodedData,
               let image = NSImage(data: data) {
                VoiceBackgroundImagePreview(
                    image: image,
                    variant: variant
                )
            }

            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.12, green: 0.78, blue: 1),
                            Color(red: 0.58, green: 0.25, blue: 1),
                            Color(red: 1, green: 0.25, blue: 0.65),
                            Color(red: 0.12, green: 0.78, blue: 1)
                        ],
                        center: .center
                    )
                )
                .overlay {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .padding(18)
                }
                .frame(width: 132, height: 132)
                .hueRotation(.degrees(variant.hueRotation))
                .saturation(variant.saturation)
                .contrast(variant.contrast)
                .brightness(variant.brightness - 1)
                .blur(radius: variant.blur)
                .shadow(
                    color: Color(
                        css: variant.glowColor,
                        fallback: .cyan
                    ).opacity(variant.glowOpacity),
                    radius: variant.glowBlur
                )
                .scaleEffect(variant.orbScale)
                .opacity(variant.orbOpacity)
        }
        .background(
            appearance == .dark
                ? Color.black.opacity(0.72)
                : Color.white.opacity(0.72)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
    }
}

private struct VoiceBackgroundImagePreview: View {
    let image: NSImage
    let variant: ThemeVoiceVariant

    var body: some View {
        GeometryReader { proxy in
            fittedImage(in: proxy.size)
                .scaleEffect(
                    variant.backgroundImageFit == .tile
                        ? 1
                        : variant.backgroundZoom,
                    anchor: UnitPoint(
                        x: variant.backgroundPositionX,
                        y: variant.backgroundPositionY
                    )
                )
                .offset(
                    x: (0.5 - variant.backgroundPositionX)
                        * proxy.size.width * 0.45,
                    y: (0.5 - variant.backgroundPositionY)
                        * proxy.size.height * 0.45
                )
                .blur(radius: variant.backgroundImageBlur)
                .opacity(variant.backgroundImageOpacity)
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func fittedImage(in size: CGSize) -> some View {
        switch variant.backgroundImageFit {
        case .cover:
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
        case .contain:
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
        case .fill:
            Image(nsImage: image)
                .resizable()
                .frame(width: size.width, height: size.height)
        case .fitWidth:
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size.width)
                .frame(width: size.width, height: size.height)
        case .fitHeight:
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: size.height)
                .frame(width: size.width, height: size.height)
        case .original:
            Image(nsImage: image)
                .frame(width: size.width, height: size.height)
        case .tile:
            Rectangle()
                .fill(
                    ImagePaint(
                        image: Image(nsImage: image),
                        scale: variant.backgroundZoom
                    )
                )
                .frame(width: size.width, height: size.height)
        }
    }
}

private struct VoiceValueSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(format(value))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

private struct VoiceColorField: View {
    let title: String
    @Binding var value: String

    init(title: String, value: Binding<String>) {
        self.title = title
        _value = value
    }

    private var color: Binding<Color> {
        Binding(
            get: { Color(css: value, fallback: .gray) },
            set: { value = NSColor($0).cssHex }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
            HStack(spacing: 7) {
                ColorPicker("", selection: color, supportsOpacity: true)
                    .labelsHidden()
                    .frame(width: 28)
                TextField(
                    L10n.text("CSS 色彩", "CSS color"),
                    text: $value
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 10, design: .monospaced))
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
