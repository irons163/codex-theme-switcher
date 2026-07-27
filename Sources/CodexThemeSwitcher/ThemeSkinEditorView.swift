import AppKit
import CodexThemeSwitcherCore
import SwiftUI

struct ThemeSkinEditorView: View {
    @ObservedObject var model: ThemeAppModel

    private var appearance: ThemeSkinAppearance {
        model.previewAppearance
    }

    private var previewSurface: ThemePreviewSurface {
        model.previewSurface
    }

    private var skin: ThemeImageSkin {
        model.draft?.imageSkin ?? ThemeImageSkin(isEnabled: false)
    }

    private var variant: ThemeSkinVariant {
        skin.variant(for: appearance)
    }

    private var backgroundAsset: ThemeAsset? {
        guard let id = variant.backgroundAssetID else { return nil }
        return model.draft?.assets.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if skin.isEnabled {
                    preview
                    backgroundSection
                    treatmentSection
                    overlaySection
                    surfacesSection
                    centerPanelSection
                    glassSection
                    targetsSection
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
                    title: L10n.skin,
                    description: L10n.text(
                        "建立全視窗背景、明暗雙版本、焦點裁切、色調遮罩與分區玻璃材質。所有圖片與設定都會跟著 .codextheme 分享。",
                        "Create full-window imagery, independent light/dark treatments, focal cropping, overlays, and per-region glass. Images and settings travel inside the .codextheme."
                    )
                )
                Spacer()
                Toggle(
                    L10n.text("啟用 Image Skin", "Enable image skin"),
                    isOn: skinEnabledBinding
                )
                .toggleStyle(.switch)
            }

            HStack(spacing: 8) {
                Text(L10n.text("快速風格", "Quick styles"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(L10n.text("柔光玻璃", "Soft glass")) {
                    applyPreset(.softGlass)
                }
                Button(L10n.text("哥德金影", "Gothic gold")) {
                    applyPreset(.gothic)
                }
                Button(L10n.text("極透明", "Clear canvas")) {
                    applyPreset(.clear)
                }
                Spacer()
                Button(L10n.text("移除 Skin", "Remove skin"), role: .destructive) {
                    model.removeImageSkin()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var preview: some View {
        EditorSection(
            title: L10n.text("即時預覽", "Live preview"),
            subtitle: L10n.text(
                "切換 Home／Chat 檢查中央面板邊界；玻璃材質為近似顯示，Codex 會使用精確 blur / saturation 數值。",
                "Switch between Home and Chat to inspect the center-panel boundary. Glass is approximated here; Codex uses the exact blur / saturation values."
            )
        ) {
            HStack {
                Picker(
                    L10n.text("預覽畫面", "Preview surface"),
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
                Button {
                    let other: ThemeSkinAppearance =
                        appearance == .light ? .dark : .light
                    model.copySkinVariant(from: appearance, to: other)
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

            if let theme = model.draft {
                ThemePreviewView(
                    theme: theme,
                    appearance: appearance,
                    surface: previewSurface
                )
                .environment(
                    \.colorScheme,
                    appearance == .dark ? .dark : .light
                )
                .frame(height: 330)
            }
        }
    }

    private var backgroundSection: some View {
        EditorSection(
            title: L10n.text("背景圖片與焦點", "Background & focal point"),
            subtitle: L10n.text(
                "背景使用獨立 pseudo-element，不會阻擋 Codex 的點擊或拖曳。",
                "The wallpaper uses a click-through pseudo-element and never blocks Codex controls."
            )
        ) {
            HStack(spacing: 14) {
                assetPreview
                    .frame(width: 170, height: 108)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.quaternary)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        backgroundAsset?.name
                            ?? L10n.text("尚未選擇圖片", "No image selected")
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
                            model.chooseSkinBackground(for: appearance)
                        } label: {
                            Label(
                                L10n.text("選擇圖片", "Choose image"),
                                systemImage: "photo"
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        if !model.availableSkinImageAssets.isEmpty {
                            Menu {
                                ForEach(model.availableSkinImageAssets) { asset in
                                    Button {
                                        model.setSkinBackground(
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
                                    L10n.text("現有素材", "Existing assets"),
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
                                model.clearSkinBackground(for: appearance)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .controlSize(.small)
                }
                Spacer()
                focalGrid
            }

            Toggle(isOn: wallpaperExcludesSidebarBinding) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.text(
                            "壁紙避開左側欄",
                            "Keep wallpaper out of sidebar"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        L10n.text(
                            "開啟後，Fit／Fill、焦點與遮罩只以主內容區計算；側欄保留自己的底色與玻璃材質。",
                            "Fit, fill, focal point, and overlays use only the main content area; the sidebar keeps its own base color and glass."
                        )
                    )
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(10)
            .background(.quaternary.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 9))

            Divider()

            imageSizingControl

            Divider()

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinColorField(
                    title: L10n.text("背景底色", "Background base color"),
                    value: variantBinding(\.backgroundColor)
                )
                pickerRow(
                    L10n.text("混合模式", "Blend mode"),
                    selection: variantBinding(\.blendMode)
                ) {
                    ForEach(ThemeSkinBlendMode.allCases, id: \.self) {
                        Text(blendTitle($0)).tag($0)
                    }
                }
                SkinValueSlider(
                    title: horizontalPositionTitle,
                    value: variantBinding(\.positionX),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: verticalPositionTitle,
                    value: variantBinding(\.positionY),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: L10n.text("圖片縮放", "Image zoom"),
                    value: variantBinding(\.zoom),
                    range: 0.5...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("圖片透明度", "Image opacity"),
                    value: variantBinding(\.imageOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
            }
        }
    }

    private var imageSizingControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(L10n.text("圖片尺寸", "Image sizing"))
                    .font(.caption.weight(.semibold))
                    .frame(width: 82, alignment: .leading)

                imageFitShortcut(
                    fit: .contain,
                    title: L10n.text("完整顯示 Fit", "Fit"),
                    symbol: "arrow.down.right.and.arrow.up.left",
                    help: L10n.text(
                        "完整顯示圖片，空白處使用背景底色。",
                        "Show the whole image; empty space uses the base color."
                    )
                )
                imageFitShortcut(
                    fit: .cover,
                    title: L10n.text("填滿裁切 Fill", "Fill"),
                    symbol: "arrow.up.left.and.arrow.down.right",
                    help: L10n.text(
                        "填滿視窗並裁切邊緣；焦點控制裁切位置。",
                        "Fill the window and crop edges; focal point controls the crop."
                    )
                )

                Spacer(minLength: 4)

                Picker(
                    L10n.text("全部模式", "All modes"),
                    selection: imageFitSelection
                ) {
                    ForEach(imageFitOptions, id: \.self) {
                        Text(imageFitTitle($0)).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 205)
            }

            Text(imageFitDescription(variant.imageFit))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                L10n.text(
                    "切換模式會回到 1.00×；之後仍可用「圖片縮放」微調。",
                    "Changing mode resets to 1.00×; use Image zoom for further adjustment."
                )
            )
            .font(.system(size: 9))
            .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .disabled(backgroundAsset == nil)
        .opacity(backgroundAsset == nil ? 0.55 : 1)
    }

    private func imageFitShortcut(
        fit: ThemeSkinImageFit,
        title: String,
        symbol: String,
        help: String
    ) -> some View {
        let isSelected = variant.imageFit == fit
        return Button {
            setImageFit(fit)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : symbol)
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .frame(width: 116, height: 28)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.13)
                    : Color.secondary.opacity(0.07)
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.6)
                            : Color.secondary.opacity(0.22)
                    )
            }
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var imageFitSelection: Binding<ThemeSkinImageFit> {
        Binding(
            get: { variant.imageFit },
            set: { setImageFit($0) }
        )
    }

    private var imageFitOptions: [ThemeSkinImageFit] {
        [
            .contain,
            .cover,
            .fitWidth,
            .fitHeight,
            .fill,
            .original,
            .tile
        ]
    }

    private func setImageFit(_ fit: ThemeSkinImageFit) {
        model.mutateDraft { document in
            var imageSkin = document.imageSkin ?? ThemeImageSkin()
            var value = imageSkin.variant(for: appearance)
            value.imageFit = fit
            value.zoom = 1
            imageSkin.setVariant(value, for: appearance)
            document.imageSkin = imageSkin
        }
    }

    private var horizontalPositionTitle: String {
        variant.imageFit == .tile
            ? L10n.text("水平起點", "Horizontal tile origin")
            : L10n.text("水平焦點", "Horizontal focal point")
    }

    private var verticalPositionTitle: String {
        variant.imageFit == .tile
            ? L10n.text("垂直起點", "Vertical tile origin")
            : L10n.text("垂直焦點", "Vertical focal point")
    }

    private var treatmentSection: some View {
        EditorSection(
            title: L10n.text("圖片調色", "Image treatment"),
            subtitle: L10n.text(
                "每個明暗版本都有自己的亮度、對比、飽和與柔焦。",
                "Each appearance has independent brightness, contrast, saturation, and blur."
            )
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinValueSlider(
                    title: L10n.text("亮度", "Brightness"),
                    value: variantBinding(\.brightness),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("對比", "Contrast"),
                    value: variantBinding(\.contrast),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("飽和", "Saturation"),
                    value: variantBinding(\.saturation),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("柔焦", "Image blur"),
                    value: variantBinding(\.imageBlur),
                    range: 0...80,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
            }
        }
    }

    private var overlaySection: some View {
        EditorSection(
            title: L10n.text("遮罩與文字對比", "Overlay & legibility"),
            subtitle: L10n.text(
                "左／右 scrim 適合保護側欄文字；vignette 可壓暗邊緣。",
                "Directional scrims protect navigation text; vignette darkens the edges."
            )
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinColorField(
                    title: L10n.text("全域遮罩", "Global overlay"),
                    value: variantBinding(\.overlayColor)
                )
                SkinValueSlider(
                    title: L10n.text("遮罩濃度", "Overlay opacity"),
                    value: variantBinding(\.overlayOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                pickerRow(
                    L10n.text("可讀性漸層", "Readability scrim"),
                    selection: variantBinding(\.scrimDirection)
                ) {
                    ForEach(ThemeSkinScrimDirection.allCases, id: \.self) {
                        Text(scrimTitle($0)).tag($0)
                    }
                }
                SkinValueSlider(
                    title: L10n.text("漸層強度", "Scrim strength"),
                    value: variantBinding(\.scrimOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: L10n.text("邊緣暗角", "Vignette"),
                    value: variantBinding(\.vignetteOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
            }

            Divider()

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinColorField(
                    title: L10n.text("主要文字", "Primary text"),
                    value: variantBinding(\.primaryTextColor)
                )
                SkinColorField(
                    title: L10n.text("次要文字", "Secondary text"),
                    value: variantBinding(\.secondaryTextColor)
                )
                SkinColorField(
                    title: L10n.text("強調色", "Accent"),
                    value: variantBinding(\.accentColor)
                )
            }
        }
    }

    private var surfacesSection: some View {
        EditorSection(
            title: L10n.text("分區玻璃色", "Per-region glass color"),
            subtitle: L10n.text(
                "只調整背景材質透明度，不會讓面板內的文字一起變淡。",
                "Only the material background becomes translucent; child text keeps full opacity."
            )
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                surfaceControl(
                    L10n.text("側欄", "Sidebar"),
                    color: \.sidebarTint,
                    opacity: \.sidebarOpacity
                )
                surfaceControl(
                    L10n.text("主內容", "Main content"),
                    color: \.contentTint,
                    opacity: \.contentOpacity
                )
                surfaceControl(
                    L10n.text("Composer／Project picker", "Composer / project picker"),
                    color: \.composerTint,
                    opacity: \.composerOpacity
                )
                surfaceControl(
                    L10n.text("Cards／選單", "Cards / menus"),
                    color: \.cardTint,
                    opacity: \.cardOpacity
                )
                surfaceControl(
                    L10n.text("邊框／Glow", "Border / glow"),
                    color: \.borderColor,
                    opacity: \.borderOpacity
                )
            }
        }
    }

    private var centerPanelSection: some View {
        EditorSection(
            title: L10n.text("中央內容面板", "Center content panel"),
            subtitle: L10n.text(
                "獨立包住 Home 標題或 Chat 對話文字，不會改到建議 Cards、Composer 或整片主內容背景。",
                "Wraps only the Home heading or Chat transcript, without changing suggestion cards, the Composer, or the full main-content background."
            )
        ) {
            Toggle(isOn: centerPanelBinding(\.isEnabled)) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        L10n.text(
                            "啟用中央內容面板",
                            "Enable center content panel"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    Text(
                        L10n.text(
                            "可替文字加上獨立底色、邊框、留白、模糊與陰影。",
                            "Give the text its own fill, border, spacing, blur, and shadow."
                        )
                    )
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(10)
            .background(.quaternary.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 9))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinColorField(
                    title: L10n.text("面板底色", "Panel fill"),
                    value: variantBinding(\.centerPanelTint)
                )
                SkinValueSlider(
                    title: L10n.text("底色不透明度", "Fill opacity"),
                    value: variantBinding(\.centerPanelOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinColorField(
                    title: L10n.text("面板邊框色", "Panel border"),
                    value: variantBinding(\.centerPanelBorderColor)
                )
                SkinValueSlider(
                    title: L10n.text("邊框不透明度", "Border opacity"),
                    value: variantBinding(\.centerPanelBorderOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: L10n.text("邊框寬度", "Border width"),
                    value: centerPanelBinding(\.borderWidth),
                    range: 0...8,
                    step: 0.25,
                    format: { String(format: "%.2f px", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("面板圓角", "Panel radius"),
                    value: centerPanelBinding(\.cornerRadius),
                    range: 0...64,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("背景模糊", "Backdrop blur"),
                    value: centerPanelBinding(\.backdropBlur),
                    range: 0...80,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("玻璃飽和", "Glass saturation"),
                    value: centerPanelBinding(\.backdropSaturation),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinColorField(
                    title: L10n.text("陰影顏色", "Shadow color"),
                    value: variantBinding(\.centerPanelShadowColor)
                )
                SkinValueSlider(
                    title: L10n.text("陰影不透明度", "Shadow opacity"),
                    value: variantBinding(\.centerPanelShadowOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: L10n.text("陰影擴散", "Shadow blur"),
                    value: centerPanelBinding(\.shadowBlur),
                    range: 0...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("陰影水平位移", "Shadow offset X"),
                    value: centerPanelBinding(\.shadowOffsetX),
                    range: -120...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("陰影垂直位移", "Shadow offset Y"),
                    value: centerPanelBinding(\.shadowOffsetY),
                    range: -120...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("最大寬度", "Maximum width"),
                    value: centerPanelBinding(\.maximumWidth),
                    range: 320...1_600,
                    step: 10,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("水平內距", "Horizontal padding"),
                    value: centerPanelBinding(\.horizontalPadding),
                    range: 0...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("垂直內距", "Vertical padding"),
                    value: centerPanelBinding(\.verticalPadding),
                    range: 0...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
            }
            .disabled(!skin.centerPanel.isEnabled)
            .opacity(skin.centerPanel.isEnabled ? 1 : 0.5)
        }
    }

    private var glassSection: some View {
        EditorSection(
            title: L10n.text("玻璃物理參數", "Glass material"),
            subtitle: L10n.text(
                "共用於已啟用的 Codex 區域。",
                "Shared by the enabled Codex regions."
            )
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 12
            ) {
                SkinValueSlider(
                    title: L10n.text("背景模糊", "Backdrop blur"),
                    value: glassBinding(\.blurRadius),
                    range: 0...80,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("玻璃飽和", "Glass saturation"),
                    value: glassBinding(\.saturation),
                    range: 0...3,
                    step: 0.01,
                    format: { String(format: "%.2f×", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("邊框寬度", "Border width"),
                    value: glassBinding(\.borderWidth),
                    range: 0...8,
                    step: 0.25,
                    format: { String(format: "%.2f px", $0) }
                )
                SkinValueSlider(
                    title: L10n.text("面板圓角", "Panel radius"),
                    value: glassBinding(\.cornerRadius),
                    range: 0...64,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("陰影濃度", "Shadow opacity"),
                    value: glassBinding(\.shadowOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
                SkinValueSlider(
                    title: L10n.text("陰影擴散", "Shadow blur"),
                    value: glassBinding(\.shadowBlur),
                    range: 0...120,
                    step: 1,
                    format: { "\(Int($0)) px" }
                )
                SkinValueSlider(
                    title: L10n.text("文字陰影", "Text shadow"),
                    value: glassBinding(\.textShadowOpacity),
                    range: 0...1,
                    step: 0.01,
                    format: { "\(Int($0 * 100))%" }
                )
            }
        }
    }

    private var targetsSection: some View {
        EditorSection(
            title: L10n.text("套用區域", "Glass targets"),
            subtitle: L10n.text(
                "Selector 已針對目前 Codex 26 的實際 DOM 更新。",
                "Selectors are aligned with the current Codex 26 DOM."
            )
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                alignment: .leading,
                spacing: 10
            ) {
                targetToggle(L10n.text("側欄", "Sidebar"), \.sidebar)
                targetToggle(L10n.text("主內容", "Main content"), \.content)
                targetToggle(L10n.text("標題列", "Titlebar"), \.titlebar)
                targetToggle(L10n.text("輸入框", "Composer"), \.composer)
                targetToggle(L10n.text("首頁 Cards", "Home cards"), \.cards)
                targetToggle(L10n.text("選單／彈出視窗", "Menus / popovers"), \.popovers)
                targetToggle(L10n.text("程式碼區塊", "Code blocks"), \.codeBlocks)
            }
        }
    }

    @ViewBuilder
    private var assetPreview: some View {
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
                    colors: [.secondary.opacity(0.12), .secondary.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var focalGrid: some View {
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
                                model.mutateDraft { document in
                                    var skin = document.imageSkin
                                        ?? ThemeImageSkin()
                                    var value = skin.variant(for: appearance)
                                    value.positionX = x
                                    value.positionY = y
                                    skin.setVariant(value, for: appearance)
                                    document.imageSkin = skin
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        abs(variant.positionX - x) < 0.1
                                            && abs(variant.positionY - y) < 0.1
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.25)
                                    )
                                    .frame(width: 12, height: 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(8)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func surfaceControl(
        _ title: String,
        color: WritableKeyPath<ThemeSkinVariant, String>,
        opacity: WritableKeyPath<ThemeSkinVariant, Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SkinColorField(
                title: title,
                value: variantBinding(color)
            )
            SkinValueSlider(
                title: L10n.text("不透明度", "Opacity"),
                value: variantBinding(opacity),
                range: 0...1,
                step: 0.01,
                format: { "\(Int($0 * 100))%" }
            )
        }
        .padding(11)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func targetToggle(
        _ title: String,
        _ keyPath: WritableKeyPath<ThemeSkinTargets, Bool>
    ) -> some View {
        Toggle(title, isOn: targetBinding(keyPath))
            .toggleStyle(.checkbox)
            .font(.caption)
    }

    private var skinEnabledBinding: Binding<Bool> {
        Binding(
            get: { skin.isEnabled },
            set: { enabled in
                model.mutateDraft { document in
                    var value = document.imageSkin ?? ThemeImageSkin()
                    value.isEnabled = enabled
                    document.imageSkin = value
                }
            }
        )
    }

    private var wallpaperExcludesSidebarBinding: Binding<Bool> {
        Binding(
            get: { skin.wallpaperScope == .mainContent },
            set: { excludesSidebar in
                model.mutateDraft { document in
                    var value = document.imageSkin ?? ThemeImageSkin()
                    value.wallpaperScope = excludesSidebar
                        ? .mainContent
                        : .fullWindow
                    document.imageSkin = value
                }
            }
        )
    }

    private func variantBinding<Value>(
        _ keyPath: WritableKeyPath<ThemeSkinVariant, Value>
    ) -> Binding<Value> {
        Binding(
            get: {
                skin.variant(for: appearance)[keyPath: keyPath]
            },
            set: { value in
                model.mutateDraft(
                    coalescingKey:
                        "image-skin.variant.\(appearance.rawValue)."
                        + String(reflecting: keyPath)
                ) { document in
                    var imageSkin = document.imageSkin ?? ThemeImageSkin()
                    var item = imageSkin.variant(for: appearance)
                    item[keyPath: keyPath] = value
                    imageSkin.setVariant(item, for: appearance)
                    document.imageSkin = imageSkin
                }
            }
        )
    }

    private func glassBinding<Value>(
        _ keyPath: WritableKeyPath<ThemeSkinGlass, Value>
    ) -> Binding<Value> {
        Binding(
            get: { skin.glass[keyPath: keyPath] },
            set: { value in
                model.mutateDraft(
                    coalescingKey:
                        "image-skin.glass." + String(reflecting: keyPath)
                ) { document in
                    var imageSkin = document.imageSkin ?? ThemeImageSkin()
                    imageSkin.glass[keyPath: keyPath] = value
                    document.imageSkin = imageSkin
                }
            }
        )
    }

    private func centerPanelBinding<Value>(
        _ keyPath: WritableKeyPath<ThemeSkinCenterPanel, Value>
    ) -> Binding<Value> {
        Binding(
            get: { skin.centerPanel[keyPath: keyPath] },
            set: { value in
                model.mutateDraft(
                    coalescingKey:
                        "image-skin.center-panel."
                        + String(reflecting: keyPath)
                ) { document in
                    var imageSkin = document.imageSkin ?? ThemeImageSkin()
                    imageSkin.centerPanel[keyPath: keyPath] = value
                    document.imageSkin = imageSkin
                }
            }
        )
    }

    private func targetBinding(
        _ keyPath: WritableKeyPath<ThemeSkinTargets, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { skin.targets[keyPath: keyPath] },
            set: { value in
                model.mutateDraft(
                    coalescingKey:
                        "image-skin.targets." + String(reflecting: keyPath)
                ) { document in
                    var imageSkin = document.imageSkin ?? ThemeImageSkin()
                    imageSkin.targets[keyPath: keyPath] = value
                    document.imageSkin = imageSkin
                }
            }
        )
    }

    private func pickerRow<Value: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Value>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
            Picker(title, selection: selection, content: content)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func applyPreset(_ preset: SkinPreset) {
        model.mutateDraft { document in
            var value = document.imageSkin ?? ThemeImageSkin()
            value.isEnabled = true
            switch preset {
            case .softGlass:
                var light = ThemeSkinVariant.lightDefault
                var dark = ThemeSkinVariant.darkDefault
                light.backgroundAssetID = value.light.backgroundAssetID
                dark.backgroundAssetID = value.dark.backgroundAssetID
                value.light = light
                value.dark = dark
                value.glass = ThemeSkinGlass(
                    blurRadius: 22,
                    saturation: 1.18,
                    borderWidth: 1,
                    cornerRadius: 18,
                    shadowOpacity: 0.18,
                    shadowBlur: 38,
                    textShadowOpacity: 0.12
                )
            case .gothic:
                var dark = ThemeSkinVariant.darkDefault
                dark.backgroundAssetID = value.dark.backgroundAssetID
                    ?? value.light.backgroundAssetID
                dark.brightness = 0.66
                dark.contrast = 1.18
                dark.saturation = 0.72
                dark.overlayOpacity = 0.24
                dark.scrimOpacity = 0.68
                dark.vignetteOpacity = 0.42
                dark.accentColor = "#D6AD62"
                dark.borderColor = "#D6AD62"
                dark.borderOpacity = 0.38
                dark.composerTint = "#1A1510"
                dark.cardTint = "#17130F"
                value.dark = dark
                value.glass = ThemeSkinGlass(
                    blurRadius: 14,
                    saturation: 0.88,
                    borderWidth: 1.25,
                    cornerRadius: 18,
                    shadowOpacity: 0.38,
                    shadowBlur: 46,
                    textShadowOpacity: 0.34
                )
            case .clear:
                value.light.sidebarOpacity = 0.24
                value.light.contentOpacity = 0
                value.light.composerOpacity = 0.5
                value.light.cardOpacity = 0.36
                value.dark.sidebarOpacity = 0.24
                value.dark.contentOpacity = 0
                value.dark.composerOpacity = 0.52
                value.dark.cardOpacity = 0.38
                value.glass.blurRadius = 10
                value.glass.shadowOpacity = 0.1
            }
            document.imageSkin = value
        }
    }

    private func imageFitTitle(_ value: ThemeSkinImageFit) -> String {
        switch value {
        case .cover: L10n.text("填滿裁切（Fill）", "Fill · Crop to Fill")
        case .contain: L10n.text("完整顯示（Fit）", "Fit · Show Whole Image")
        case .fill: L10n.text("拉伸（Stretch）", "Stretch")
        case .fitWidth: L10n.text("符合寬度", "Fit Width")
        case .fitHeight: L10n.text("符合高度", "Fit Height")
        case .original: L10n.text("原始大小", "Original")
        case .tile: L10n.text("平鋪", "Tile")
        }
    }

    private func imageFitDescription(_ value: ThemeSkinImageFit) -> String {
        switch value {
        case .cover:
            L10n.text(
                "保持比例並填滿視窗；超出邊緣的部分會裁切。",
                "Preserve aspect ratio and fill the window; overflow is cropped."
            )
        case .contain:
            L10n.text(
                "保持比例並完整顯示圖片；空白處使用背景底色。",
                "Show the whole image with its aspect ratio; empty space uses the base color."
            )
        case .fill:
            L10n.text(
                "忽略長寬比，將圖片拉伸到整個視窗。",
                "Ignore aspect ratio and stretch the image to the window."
            )
        case .fitWidth:
            L10n.text(
                "寬度貼齊視窗，高度依原比例縮放。",
                "Match the window width and preserve aspect ratio."
            )
        case .fitHeight:
            L10n.text(
                "高度貼齊視窗，寬度依原比例縮放。",
                "Match the window height and preserve aspect ratio."
            )
        case .original:
            L10n.text(
                "使用圖片原始尺寸；焦點決定圖片位置。",
                "Use the image's natural size; focal point controls placement."
            )
        case .tile:
            L10n.text(
                "重複排列圖片；縮放控制每個圖塊大小。",
                "Repeat the image; zoom controls tile size."
            )
        }
    }

    private func blendTitle(_ value: ThemeSkinBlendMode) -> String {
        switch value {
        case .normal: L10n.text("正常", "Normal")
        case .multiply: L10n.text("色彩增值", "Multiply")
        case .screen: L10n.text("濾色", "Screen")
        case .overlay: L10n.text("覆蓋", "Overlay")
        case .softLight: L10n.text("柔光", "Soft Light")
        }
    }

    private func scrimTitle(_ value: ThemeSkinScrimDirection) -> String {
        switch value {
        case .none: L10n.text("無", "None")
        case .left: L10n.text("左側加深", "Darken left")
        case .right: L10n.text("右側加深", "Darken right")
        case .top: L10n.text("上方加深", "Darken top")
        case .bottom: L10n.text("下方加深", "Darken bottom")
        }
    }
}

private enum SkinPreset {
    case softGlass
    case gothic
    case clear
}

private struct SkinValueSlider: View {
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

private struct SkinColorField: View {
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
