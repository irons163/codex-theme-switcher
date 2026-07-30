import AppKit
import CodexThemeSwitcherCore
import SwiftUI

struct ThemeVoiceEditorView: View {
    @ObservedObject var model: ThemeAppModel
    @State private var previewSpeechLevel = 0.35

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

    private var orbBackgroundAsset: ThemeAsset? {
        guard let id = variant.orbBackgroundAssetID else { return nil }
        return model.draft?.assets.first { $0.id == id }
    }

    private var blinkAsset: ThemeAsset? {
        guard let id = variant.orbBlinkAssetID else { return nil }
        return model.draft?.assets.first { $0.id == id }
    }

    private var mouthFrameAssets: [ThemeAsset] {
        variant.orbMouthFrameAssetIDs.compactMap { id in
            model.draft?.assets.first { $0.id == id }
        }
    }

    private var previewOrbAsset: ThemeAsset? {
        let frames = [orbBackgroundAsset].compactMap { $0 }
            + mouthFrameAssets
        guard !frames.isEmpty else { return nil }
        let normalizedGate = min(
            max(variant.orbMouthNoiseGate / 0.46, 0),
            0.95
        )
        let gatedLevel = min(
            max(
                (previewSpeechLevel - normalizedGate)
                    / max(1 - normalizedGate, 0.05),
                0
            ),
            1
        )
        let level = pow(
            min(max(gatedLevel * variant.orbMouthSensitivity, 0), 1),
            variant.orbMouthResponseCurve
        )
        let scaled = level * Double(frames.count - 1)
        let index = min(Int(scaled.rounded()), frames.count - 1)
        return frames[index]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if style.isEnabled {
                    previewSection
                    backgroundSection
                    orbBackgroundSection
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
                        "自訂 ChatGPT Voice 圓球與周圍效果。人物圓球會同時套用於主視窗及獨立 Voice 畫面；全頁背景仍只套用於獨立畫面。",
                        "Customize the ChatGPT Voice orb and surrounding effects. The custom orb appears both in the main window and the isolated Voice overlay; full-page backgrounds remain isolated."
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
                        "Codex versions may use DOM, Canvas, WebGL, or native layers. The embedded image works on the current DOM orb, while native or Canvas orbs may not expose their inside to CSS."
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
                "預覽使用目前 Voice overlay 的實測比例與圓球起始位置；拖動圓球後，實際位置可能不同。",
                "The preview uses the measured Voice overlay ratio and initial orb position. Its runtime position can differ after you drag the orb."
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
                backgroundAsset: backgroundAsset,
                orbBackgroundAsset: previewOrbAsset,
                blinkAsset: blinkAsset,
                speechLevel: previewSpeechLevel
            )
            .frame(width: 408, height: 400)
            .frame(maxWidth: .infinity)

            if !variant.orbMouthFrameAssetIDs.isEmpty
                || variant.orbIdleMotionEnabled
                || blinkAsset != nil {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        Label(
                            L10n.text(
                                "測試說話強度",
                                "Test speech intensity"
                            ),
                            systemImage: "waveform"
                        )
                        .font(.caption.weight(.semibold))
                        Slider(value: $previewSpeechLevel, in: 0...1)
                        Text(Self.percent(previewSpeechLevel))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                    Text(
                        L10n.text(
                            "將說話強度調到 0，可預覽待機搖晃與眨眼。",
                            "Set speech intensity to 0 to preview idle sway and blinking."
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
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

    private var orbBackgroundSection: some View {
        EditorSection(
            title: L10n.text(
                "圓球內部圖片",
                "Image inside orb"
            ),
            subtitle: L10n.text(
                "使用獨立圖片覆蓋在目前的 DOM 圓球內；降低圖片不透明度可讓原本的動畫圓球透出。",
                "Places a separate image inside the current DOM orb. Lower the image opacity to let the original animated orb show through."
            )
        ) {
            HStack(spacing: 14) {
                assetPreview(orbBackgroundAsset)
                    .frame(width: 108, height: 108)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.quaternary)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        orbBackgroundAsset?.name
                            ?? L10n.text(
                                "尚未選擇圖片",
                                "No image selected"
                            )
                    )
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                    if let orbBackgroundAsset {
                        Text(
                            "\(orbBackgroundAsset.mediaType) · "
                                + ByteCountFormatter.string(
                                    fromByteCount: Int64(
                                        orbBackgroundAsset.decodedData?.count
                                            ?? 0
                                    ),
                                    countStyle: .file
                                )
                        )
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button {
                            model.chooseVoiceOrbBackground(for: appearance)
                        } label: {
                            Label(
                                L10n.text("選擇圖片", "Choose image"),
                                systemImage: "circle.inset.filled"
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        if !model.availableSkinImageAssets.isEmpty {
                            Menu {
                                ForEach(
                                    model.availableSkinImageAssets
                                ) { asset in
                                    Button {
                                        model.setVoiceOrbBackground(
                                            asset.id,
                                            for: appearance
                                        )
                                    } label: {
                                        if asset.id
                                            == orbBackgroundAsset?.id {
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

                        if orbBackgroundAsset != nil {
                            Button(
                                L10n.text("清除", "Clear"),
                                role: .destructive
                            ) {
                                model.clearVoiceOrbBackground(
                                    for: appearance
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.small)
                }

                Spacer()
                orbFocalGrid
            }

            Divider()

            mouthFramesSection

            Divider()

            idleAnimationSection

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.text("圖片尺寸", "Image sizing"))
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Picker(
                        L10n.text("圖片尺寸", "Image sizing"),
                        selection: variantBinding(
                            \.orbBackgroundImageFit
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
                    orbImageFitShortcut(
                        .contain,
                        title: L10n.text(
                            "完整顯示 Fit",
                            "Fit · Show Whole Image"
                        )
                    )
                    orbImageFitShortcut(
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
            .disabled(orbBackgroundAsset == nil)
            .opacity(orbBackgroundAsset == nil ? 0.55 : 1)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.text(
                            "跟隨語音脈動",
                            "Follow Voice pulse"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        L10n.text(
                            "讓圓球圖片跟著原生 Voice 動畫同步縮放。",
                            "Synchronizes the orb image scale with the native Voice animation."
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle(
                    L10n.text(
                        "跟隨語音脈動",
                        "Follow Voice pulse"
                    ),
                    isOn: variantBinding(
                        \.orbBackgroundFollowsVoicePulse
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }
            .padding(10)
            .background(.quaternary.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .disabled(orbBackgroundAsset == nil)
            .opacity(orbBackgroundAsset == nil ? 0.55 : 1)

            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text(
                        "水平焦點",
                        "Horizontal focal point"
                    ),
                    value: variantBinding(\.orbBackgroundPositionX),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "垂直焦點",
                        "Vertical focal point"
                    ),
                    value: variantBinding(\.orbBackgroundPositionY),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "圓球圖片不透明度",
                        "Orb image opacity"
                    ),
                    value: variantBinding(\.orbBackgroundImageOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "圓球圖片模糊",
                        "Orb image blur"
                    ),
                    value: variantBinding(\.orbBackgroundImageBlur),
                    range: 0...40,
                    step: 0.5,
                    format: { String(format: "%.1f px", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "圓球圖片內縮",
                        "Orb image inset"
                    ),
                    value: variantBinding(\.orbBackgroundInset),
                    range: 0...24,
                    step: 0.5,
                    format: { String(format: "%.1f px", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "脈動強度",
                        "Pulse strength"
                    ),
                    value: variantBinding(
                        \.orbBackgroundPulseStrength
                    ),
                    range: 0...2,
                    step: 0.05,
                    format: { String(format: "%.2f×", $0) }
                )
                .disabled(!variant.orbBackgroundFollowsVoicePulse)
            }
            .disabled(orbBackgroundAsset == nil)
            .opacity(orbBackgroundAsset == nil ? 0.55 : 1)
        }
    }

    private var mouthFramesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.text(
                            "說話嘴型",
                            "Talking mouth frames"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        L10n.text(
                            "第 1 張是閉嘴，其餘依嘴巴由小到大排列；實際 Voice 會快速張嘴、平滑閉嘴並直接切換最接近的嘴型。",
                            "Frame 1 is closed. Order the rest from least to most open; Voice opens quickly, closes smoothly, and directly selects the nearest pose."
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()

                Button {
                    model.chooseVoiceMouthSpriteSheet(
                        for: appearance,
                        gridSize: 2
                    )
                } label: {
                    Label(
                        L10n.text(
                            "匯入 2×2 嘴型圖",
                            "Import 2×2 sheet"
                        ),
                        systemImage: "square.grid.2x2"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    model.chooseVoiceMouthSpriteSheet(
                        for: appearance,
                        gridSize: 3
                    )
                } label: {
                    Label(
                        L10n.text(
                            "匯入 3×3 嘴型圖",
                            "Import 3×3 sheet"
                        ),
                        systemImage: "square.grid.3x3"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    model.chooseVoiceMouthFrames(for: appearance)
                } label: {
                    Label(
                        L10n.text("加入多張圖片", "Add images"),
                        systemImage: "photo.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(variant.orbMouthFrameAssetIDs.count >= 8)

                if !model.availableSkinImageAssets.isEmpty {
                    Menu {
                        ForEach(
                            model.availableSkinImageAssets.filter { asset in
                                asset.id != variant.orbBackgroundAssetID
                                    && !variant.orbMouthFrameAssetIDs
                                        .contains(asset.id)
                            }
                        ) { asset in
                            Button(asset.name) {
                                model.addVoiceMouthFrame(
                                    asset.id,
                                    for: appearance
                                )
                            }
                        }
                    } label: {
                        Label(
                            L10n.text("現有素材", "Existing assets"),
                            systemImage: "photo.stack"
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .controlSize(.small)
                    .disabled(variant.orbMouthFrameAssetIDs.count >= 8)
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    mouthFrameTile(
                        asset: orbBackgroundAsset,
                        title: L10n.text("1 · 閉嘴", "1 · Closed"),
                        index: nil
                    )
                    ForEach(
                        Array(mouthFrameAssets.enumerated()),
                        id: \.element.id
                    ) { index, asset in
                        mouthFrameTile(
                            asset: asset,
                            title: "\(index + 2)",
                            index: index
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text(
                        "嘴型靈敏度",
                        "Mouth sensitivity"
                    ),
                    value: variantBinding(\.orbMouthSensitivity),
                    range: 0.25...3,
                    step: 0.05,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "張嘴速度",
                        "Mouth attack"
                    ),
                    value: variantBinding(
                        \.orbMouthAttackMilliseconds
                    ),
                    range: 8...120,
                    step: 2,
                    format: { "\(Int($0)) ms" }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "閉嘴速度",
                        "Mouth release"
                    ),
                    value: variantBinding(
                        \.orbMouthReleaseMilliseconds
                    ),
                    range: 5...300,
                    step: 1,
                    format: { "\(Int($0)) ms" }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "靜音門檻",
                        "Noise gate"
                    ),
                    value: variantBinding(\.orbMouthNoiseGate),
                    range: 0...0.2,
                    step: 0.005,
                    format: Self.percent
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "嘴型反應曲線",
                        "Mouth response curve"
                    ),
                    value: variantBinding(\.orbMouthResponseCurve),
                    range: 0.35...1.5,
                    step: 0.05,
                    format: { String(format: "%.2f", $0) }
                )
            }
            .disabled(variant.orbMouthFrameAssetIDs.isEmpty)
            .opacity(variant.orbMouthFrameAssetIDs.isEmpty ? 0.55 : 1)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var idleAnimationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.text(
                            "待機動畫",
                            "Idle animation"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        L10n.text(
                            "沒有說話時輕微搖晃人物；開始說話後會平滑停止。",
                            "Gently sways the portrait during silence and smoothly stops when speech begins."
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle(
                    L10n.text(
                        "啟用待機搖晃",
                        "Enable idle sway"
                    ),
                    isOn: variantBinding(\.orbIdleMotionEnabled)
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }

            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text(
                        "搖晃幅度",
                        "Sway strength"
                    ),
                    value: variantBinding(\.orbIdleMotionStrength),
                    range: 0...2,
                    step: 0.05,
                    format: { String(format: "%.2f×", $0) }
                )
                .disabled(!variant.orbIdleMotionEnabled)
                VoiceValueSlider(
                    title: L10n.text(
                        "搖晃週期",
                        "Sway period"
                    ),
                    value: variantBinding(\.orbIdleMotionPeriodSeconds),
                    range: 1.5...12,
                    step: 0.1,
                    format: { String(format: "%.1f s", $0) }
                )
                .disabled(!variant.orbIdleMotionEnabled)
            }

            Divider()

            HStack(spacing: 12) {
                assetPreview(blinkAsset)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.quaternary)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(
                        L10n.text(
                            "閉眼圖片",
                            "Closed-eye image"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        blinkAsset?.name
                            ?? L10n.text(
                                "選擇與閉嘴圖片構圖一致、只有眼睛閉上的圖片。",
                                "Choose a matching closed-eye portrait with the same framing as the closed-mouth image."
                            )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                    HStack {
                        Button {
                            model.chooseVoiceBlinkImage(for: appearance)
                        } label: {
                            Label(
                                L10n.text("選擇圖片", "Choose image"),
                                systemImage: "eye.slash"
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        if !model.availableSkinImageAssets.isEmpty {
                            Menu {
                                ForEach(
                                    model.availableSkinImageAssets
                                ) { asset in
                                    Button {
                                        model.setVoiceBlinkImage(
                                            asset.id,
                                            for: appearance
                                        )
                                    } label: {
                                        if asset.id == blinkAsset?.id {
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

                        if blinkAsset != nil {
                            Button(
                                L10n.text("清除", "Clear"),
                                role: .destructive
                            ) {
                                model.clearVoiceBlinkImage(
                                    for: appearance
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.small)
                }
                Spacer()
            }

            settingsGrid {
                VoiceValueSlider(
                    title: L10n.text(
                        "平均眨眼間隔",
                        "Average blink interval"
                    ),
                    value: variantBinding(\.orbBlinkIntervalSeconds),
                    range: 1...15,
                    step: 0.1,
                    format: { String(format: "%.1f s", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "眨眼時間",
                        "Blink duration"
                    ),
                    value: variantBinding(
                        \.orbBlinkDurationMilliseconds
                    ),
                    range: 60...400,
                    step: 10,
                    format: { "\(Int($0)) ms" }
                )
            }
            .disabled(blinkAsset == nil)
            .opacity(blinkAsset == nil ? 0.55 : 1)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .disabled(orbBackgroundAsset == nil)
        .opacity(orbBackgroundAsset == nil ? 0.55 : 1)
    }

    private func mouthFrameTile(
        asset: ThemeAsset?,
        title: String,
        index: Int?
    ) -> some View {
        VStack(spacing: 5) {
            assetPreview(asset)
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(.quaternary)
                }
            Text(title)
                .font(.caption2.weight(.semibold))
            if let index {
                HStack(spacing: 2) {
                    Button {
                        model.moveVoiceMouthFrame(
                            from: index,
                            to: index - 1,
                            for: appearance
                        )
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(index == 0)
                    Button {
                        model.moveVoiceMouthFrame(
                            from: index,
                            to: index + 1,
                            for: appearance
                        )
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(index == mouthFrameAssets.count - 1)
                    Button(role: .destructive) {
                        model.removeVoiceMouthFrame(
                            at: index,
                            for: appearance
                        )
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .buttonStyle(.borderless)
                .controlSize(.mini)
            } else {
                Text(L10n.text("基準", "Base"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(height: 16)
            }
        }
        .frame(width: 84)
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
                    range: 0.5...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                VoiceValueSlider(
                    title: L10n.text(
                        "原生圓球不透明度",
                        "Native orb opacity"
                    ),
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
                model.setVoiceStyleEnabled(enabled)
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
        assetPreview(backgroundAsset)
    }

    @ViewBuilder
    private func assetPreview(_ asset: ThemeAsset?) -> some View {
        if let asset,
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

    private var orbFocalGrid: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text("圖片焦點", "Image focal point"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Grid(horizontalSpacing: 5, verticalSpacing: 5) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { column in
                            let x = Double(column) / 2
                            let y = Double(row) / 2
                            Button {
                                setOrbFocalPoint(x: x, y: y)
                            } label: {
                                Circle()
                                    .fill(
                                        abs(
                                            variant.orbBackgroundPositionX - x
                                        ) < 0.01
                                            && abs(
                                                variant
                                                    .orbBackgroundPositionY - y
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
        .disabled(orbBackgroundAsset == nil)
        .opacity(orbBackgroundAsset == nil ? 0.55 : 1)
    }

    private func setOrbFocalPoint(x: Double, y: Double) {
        model.mutateDraft(
            actionName: L10n.text(
                "調整圓球圖片焦點",
                "Adjust orb image focal point"
            )
        ) { document in
            var voice = document.voiceStyle
                ?? ThemeVoiceStyle(isEnabled: true)
            var value = voice.variant(for: appearance)
            value.orbBackgroundPositionX = x
            value.orbBackgroundPositionY = y
            voice.setVariant(value, for: appearance)
            document.voiceStyle = voice
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

    private func orbImageFitShortcut(
        _ fit: ThemeSkinImageFit,
        title: String
    ) -> some View {
        Button {
            variantBinding(\.orbBackgroundImageFit).wrappedValue = fit
        } label: {
            Label(
                title,
                systemImage: variant.orbBackgroundImageFit == fit
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
    let orbBackgroundAsset: ThemeAsset?
    let blinkAsset: ThemeAsset?
    let speechLevel: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            GeometryReader { proxy in
                ZStack(alignment: .top) {
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

                    let orbDiameter = min(
                        proxy.size.width * (112 / 408),
                        proxy.size.height * 0.32
                    )
                    let orbCenter = clampedOrbCenter(
                        in: proxy.size,
                        orbDiameter: orbDiameter
                    )
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        Color(
                                            red: 0.12,
                                            green: 0.78,
                                            blue: 1
                                        ),
                                        Color(
                                            red: 0.58,
                                            green: 0.25,
                                            blue: 1
                                        ),
                                        Color(
                                            red: 1,
                                            green: 0.25,
                                            blue: 0.65
                                        ),
                                        Color(
                                            red: 0.12,
                                            green: 0.78,
                                            blue: 1
                                        )
                                    ],
                                    center: .center
                                )
                            )
                            .opacity(variant.orbOpacity)
                            .overlay {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .padding(orbDiameter * 0.14)
                                    .opacity(variant.orbOpacity)
                            }

                        ZStack {
                            if let orbBackgroundAsset,
                               let data = orbBackgroundAsset.decodedData,
                               let image = NSImage(data: data) {
                                VoiceOrbImagePreview(
                                    image: image,
                                    variant: variant
                                )
                                .padding(
                                    variant.orbBackgroundInset
                                        * orbDiameter / 112
                                )
                                .clipShape(Circle())
                            }

                            if let blinkAsset,
                               let data = blinkAsset.decodedData,
                               let image = NSImage(data: data) {
                                VoiceOrbImagePreview(
                                    image: image,
                                    variant: variant
                                )
                                .padding(
                                    variant.orbBackgroundInset
                                        * orbDiameter / 112
                                )
                                .clipShape(Circle())
                                .opacity(
                                    blinkOpacity(at: timeline.date)
                                )
                            }
                        }
                        .offset(
                            x: idleMotion(at: timeline.date).x,
                            y: idleMotion(at: timeline.date).y
                        )
                        .rotationEffect(
                            .degrees(
                                idleMotion(at: timeline.date).rotation
                            )
                        )
                    }
                    .frame(width: orbDiameter, height: orbDiameter)
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
                    .position(orbCenter)
                }
            }
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

    private var isIdle: Bool {
        speechLevel <= max(variant.orbMouthNoiseGate, 0.01)
    }

    private func clampedOrbCenter(
        in size: CGSize,
        orbDiameter: CGFloat
    ) -> CGPoint {
        let margin: CGFloat = 4
        let scaledDiameter =
            orbDiameter * CGFloat(variant.orbScale)

        func coordinate(
            fallback: CGFloat,
            visualLength: CGFloat,
            viewportLength: CGFloat
        ) -> CGFloat {
            guard visualLength + margin * 2 < viewportLength else {
                return viewportLength / 2
            }
            let half = visualLength / 2
            return min(
                max(fallback, margin + half),
                viewportLength - margin - half
            )
        }

        return CGPoint(
            x: coordinate(
                fallback: size.width / 2,
                visualLength: scaledDiameter,
                viewportLength: size.width
            ),
            y: coordinate(
                fallback: size.height * (8 / 400) + orbDiameter / 2,
                visualLength: scaledDiameter,
                viewportLength: size.height
            )
        )
    }

    private func idleMotion(
        at date: Date
    ) -> (x: Double, y: Double, rotation: Double) {
        guard isIdle, variant.orbIdleMotionEnabled else {
            return (0, 0, 0)
        }
        let period = max(variant.orbIdleMotionPeriodSeconds, 0.1)
        let phase = (
            date.timeIntervalSinceReferenceDate / period
        ) * .pi * 2
        let strength = variant.orbIdleMotionStrength
        return (
            sin(phase) * 3.2 * strength,
            sin(phase * 0.61 + 1.2) * 1.8 * strength,
            sin(phase * 0.83 - 0.7) * 1.05 * strength
        )
    }

    private func blinkOpacity(at date: Date) -> Double {
        guard isIdle, blinkAsset != nil else { return 0 }
        let interval = max(variant.orbBlinkIntervalSeconds, 0.1)
        let duration = max(
            variant.orbBlinkDurationMilliseconds / 1_000,
            0.01
        )
        let cycle = interval + duration
        let time = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: cycle)
        guard time >= interval else { return 0 }
        let progress = min(max((time - interval) / duration, 0), 1)
        return pow(sin(progress * .pi), 2)
    }
}

private struct VoiceOrbImagePreview: View {
    let image: NSImage
    let variant: ThemeVoiceVariant

    var body: some View {
        GeometryReader { proxy in
            fittedImage(in: proxy.size)
                .offset(
                    x: (0.5 - variant.orbBackgroundPositionX)
                        * proxy.size.width * 0.45,
                    y: (0.5 - variant.orbBackgroundPositionY)
                        * proxy.size.height * 0.45
                )
                .blur(radius: variant.orbBackgroundImageBlur)
                .opacity(variant.orbBackgroundImageOpacity)
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func fittedImage(in size: CGSize) -> some View {
        switch variant.orbBackgroundImageFit {
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
                        scale: 1
                    )
                )
                .frame(width: size.width, height: size.height)
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
