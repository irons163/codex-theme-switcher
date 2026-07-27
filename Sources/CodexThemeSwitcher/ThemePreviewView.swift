import AppKit
import CodexThemeSwitcherCore
import SwiftUI

enum ThemePreviewSurface: String, CaseIterable {
    case home
    case chat
}

struct ThemePreviewView: View {
    let theme: ThemeDocument
    var appearance: ThemeSkinAppearance?
    var surface: ThemePreviewSurface

    @Environment(\.colorScheme) private var colorScheme

    init(
        theme: ThemeDocument,
        appearance: ThemeSkinAppearance? = nil,
        surface: ThemePreviewSurface = .chat
    ) {
        self.theme = theme
        self.appearance = appearance
        self.surface = surface
    }

    private var resolvedAppearance: ThemeSkinAppearance {
        appearance ?? (colorScheme == .dark ? .dark : .light)
    }

    var body: some View {
        ThemePreviewCanvas(
            visual: ThemeVisualSnapshot(
                theme: theme,
                appearance: resolvedAppearance
            ),
            surface: surface
        )
    }
}

private struct ThemePreviewCanvas: View {
    let visual: ThemeVisualSnapshot
    let surface: ThemePreviewSurface

    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = ThemePreviewLayout.sidebarWidth(
                containerWidth: geometry.size.width
            )

            ZStack(alignment: .top) {
                ThemePreviewBackdropCanvas(
                    visual: visual,
                    canvasSize: geometry.size,
                    sidebarWidth: sidebarWidth
                )

                HStack(alignment: .top, spacing: 0) {
                    previewSidebar(
                        canvasSize: geometry.size,
                        sidebarWidth: sidebarWidth
                    )
                        .frame(width: sidebarWidth)

                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: ThemePreviewLayout.titlebarHeight)

                        Group {
                            switch surface {
                            case .home:
                                homeSurface(
                                    canvasSize: geometry.size,
                                    sidebarWidth: sidebarWidth,
                                    viewportHeight: max(
                                        0,
                                        geometry.size.height
                                            - ThemePreviewLayout.titlebarHeight
                                    )
                                )
                            case .chat:
                                chatSurface(
                                    canvasSize: geometry.size,
                                    sidebarWidth: sidebarWidth,
                                    viewportHeight: max(
                                        0,
                                        geometry.size.height
                                            - ThemePreviewLayout.titlebarHeight
                                    )
                                )
                            }
                        }
                        .frame(
                            height: max(
                                0,
                                geometry.size.height
                                    - ThemePreviewLayout.titlebarHeight
                            )
                        )
                        .clipped()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )

                previewTitlebar
            }
            .coordinateSpace(name: ThemePreviewCoordinateSpace.name)
        }
        .font(visual.uiFont)
        .foregroundStyle(visual.textPrimary)
        .background(visual.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(visual.nativeBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
    }

    private func previewSidebar(
        canvasSize: CGSize,
        sidebarWidth: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Text("Codex")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(visual.textSecondary)
            }
            .padding(.bottom, 10)

            PreviewSidebarRow(icon: "square.and.pencil", title: "New task", visual: visual)
            PreviewSidebarRow(icon: "clock", title: "Scheduled", visual: visual)
            PreviewSidebarRow(icon: "at", title: "Plugins", visual: visual)
            PreviewSidebarRow(icon: "point.3.connected.trianglepath.dotted", title: "Pull requests", visual: visual)

            Text("Projects")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(visual.textSecondary)
                .padding(.top, 11)
                .padding(.bottom, 2)

            PreviewSidebarRow(
                icon: "folder",
                title: "Codex Theme Switcher",
                visual: visual,
                selected: true
            )
            PreviewSidebarRow(
                icon: "circle.fill",
                title: "Image skin studio",
                visual: visual
            )
            PreviewSidebarRow(
                icon: "circle.fill",
                title: "Shareable templates",
                visual: visual
            )

            Spacer()

            HStack {
                Image(systemName: "gearshape")
                Text("Settings")
                    .font(.caption)
                Spacer()
                Image(systemName: "questionmark.circle")
            }
            .foregroundStyle(visual.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .padding(.top, ThemePreviewLayout.titlebarHeight + 12)
        .background {
            if visual.sidebarUsesBackdrop {
                ThemePreviewGlassBackground(
                    visual: visual,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth,
                    tint: visual.sidebarBackground,
                    blurRadius: visual.glassBackdropBlur,
                    saturation: visual.glassBackdropSaturation
                )
            } else {
                visual.sidebarBackground
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(visual.sidebarBorder)
                .frame(width: visual.sidebarBorderWidth)
        }
    }

    private var previewTitlebar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 1, green: 0.37, blue: 0.34))
                Circle()
                    .fill(Color(red: 1, green: 0.75, blue: 0.23))
                Circle()
                    .fill(Color(red: 0.18, green: 0.78, blue: 0.35))
            }
            .frame(width: 42, height: 10)

            Image(systemName: "sidebar.left")
            Image(systemName: "chevron.left")
            Image(systemName: "chevron.right")
                .opacity(0.45)
            Spacer()

            if surface == .chat {
                VStack(spacing: 1) {
                    Text("Codex Theme Switcher")
                        .font(.system(size: 11, weight: .semibold))
                    Text("main")
                        .font(.system(size: 9))
                        .foregroundStyle(visual.textSecondary)
                }
            }

            Spacer()
            Image(systemName: "rectangle.on.rectangle")
        }
        .font(.system(size: 11))
        .foregroundStyle(visual.textSecondary)
        .padding(.horizontal, 18)
        .frame(height: ThemePreviewLayout.titlebarHeight)
        .background(visual.titlebarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(visual.nativeBorder.opacity(0.75))
                .frame(height: 1)
        }
    }

    private func chatSurface(
        canvasSize: CGSize,
        sidebarWidth: CGFloat,
        viewportHeight: CGFloat
    ) -> some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: viewportHeight)

            centerPanel(
                legacyMaximumWidth: 600,
                alignment: .leading,
                canvasSize: canvasSize,
                sidebarWidth: sidebarWidth
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    userMessage
                    assistantMessage
                    if viewportHeight >= 330 {
                        codeBlock(
                            canvasSize: canvasSize,
                            sidebarWidth: sidebarWidth
                        )
                        assistantReply
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .frame(
                height: max(0, viewportHeight - 104),
                alignment: .top
            )
            .frame(maxWidth: .infinity)
            .clipped()

            composer(
                prompt: "Ask Codex anything",
                mode: .chat,
                canvasSize: canvasSize,
                sidebarWidth: sidebarWidth
            )
                .frame(maxWidth: 520)
                .frame(height: ThemePreviewLayout.composerHeight)
                .padding(22)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(2)
                .frame(height: viewportHeight, alignment: .bottom)
        }
        .frame(height: viewportHeight)
    }

    private func homeSurface(
        canvasSize: CGSize,
        sidebarWidth: CGFloat,
        viewportHeight: CGFloat
    ) -> some View {
        let showsSuggestions = viewportHeight >= 330
        let heroMaximumHeight = max(
            92,
            viewportHeight - (showsSuggestions ? 214 : 114)
        )

        return ZStack {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: viewportHeight)

            centerPanel(
                legacyMaximumWidth: 610,
                alignment: .center,
                canvasSize: canvasSize,
                sidebarWidth: sidebarWidth
            ) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(visual.textSecondary)

                    Text("What should we build?")
                        .font(.system(size: 25, weight: .regular))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 24)
            .frame(height: heroMaximumHeight)
            .clipped()
            .padding(.top, 10)
            .frame(height: viewportHeight, alignment: .top)

            VStack(spacing: 10) {
                if showsSuggestions {
                    ViewThatFits(in: .horizontal) {
                        suggestionRow(
                            limit: 4,
                            canvasSize: canvasSize,
                            sidebarWidth: sidebarWidth
                        )
                        .frame(minWidth: 430)

                        suggestionRow(
                            limit: 3,
                            canvasSize: canvasSize,
                            sidebarWidth: sidebarWidth
                        )
                        .frame(minWidth: 320)

                        suggestionRow(
                            limit: 2,
                            canvasSize: canvasSize,
                            sidebarWidth: sidebarWidth
                        )
                    }
                    .frame(maxWidth: 650)
                    .padding(.horizontal, 20)
                }

                composer(
                    prompt: "Do anything",
                    mode: .home,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth
                )
                .frame(maxWidth: 650)
                .frame(height: ThemePreviewLayout.composerHeight)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 14)
            .frame(height: viewportHeight, alignment: .bottom)
        }
        .frame(height: viewportHeight)
    }

    private func suggestionRow(
        limit: Int,
        canvasSize: CGSize,
        sidebarWidth: CGFloat
    ) -> some View {
        let suggestions = [
            ("megaphone", "Explore and understand code"),
            ("hammer", "Build a new feature"),
            ("arrow.triangle.2.circlepath", "Review and suggest changes"),
            ("ladybug", "Fix issues and failures")
        ]

        return HStack(spacing: 10) {
            ForEach(
                Array(suggestions.prefix(limit).enumerated()),
                id: \.offset
            ) { _, suggestion in
                HomeSuggestionCard(
                    icon: suggestion.0,
                    title: suggestion.1,
                    visual: visual,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth
                )
            }
        }
    }

    @ViewBuilder
    private func centerPanel<Content: View>(
        legacyMaximumWidth: CGFloat,
        alignment: Alignment,
        canvasSize: CGSize,
        sidebarWidth: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if visual.centerPanelEnabled {
            content()
                .frame(maxWidth: .infinity, alignment: alignment)
                .padding(
                    .horizontal,
                    visual.centerPanelHorizontalPadding
                )
                .padding(
                    .vertical,
                    visual.centerPanelVerticalPadding
                )
                .frame(
                    maxWidth: visual.centerPanelMaximumWidth,
                    alignment: alignment
                )
                .background {
                    if visual.centerPanelUsesBackdrop {
                        ThemePreviewGlassBackground(
                            visual: visual,
                            canvasSize: canvasSize,
                            sidebarWidth: sidebarWidth,
                            tint: visual.centerPanelBackground,
                            blurRadius: visual.centerPanelBackdropBlur,
                            saturation:
                                visual.centerPanelBackdropSaturation
                        )
                    } else {
                        visual.centerPanelBackground
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: visual.centerPanelCornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: visual.centerPanelCornerRadius,
                        style: .continuous
                    )
                    .stroke(
                        visual.centerPanelBorder,
                        lineWidth: visual.centerPanelBorderWidth
                    )
                }
                .shadow(
                    color: visual.centerPanelShadow.opacity(
                        visual.centerPanelShadowOpacity
                    ),
                    radius: visual.centerPanelShadowRadius,
                    x: visual.centerPanelShadowOffsetX,
                    y: visual.centerPanelShadowOffsetY
                )
        } else {
            content()
                .frame(
                    maxWidth: legacyMaximumWidth,
                    alignment: alignment
                )
        }
    }

    private var assistantMessage: some View {
        Text("I’ll turn this into a menu bar app with live theme switching, a visual skin editor, and portable templates.")
            .font(.system(size: visual.chatFontSize))
            .lineSpacing(visual.chatFontSize * 0.35)
        .shadow(
            color: .black.opacity(visual.textShadowOpacity),
            radius: 2,
            y: 1
        )
    }

    private var userMessage: some View {
        Text("Make the customization as flexible as possible.")
            .font(.system(size: visual.chatFontSize))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(visual.userMessageBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .frame(maxWidth: 440, alignment: .trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func codeBlock(
        canvasSize: CGSize,
        sidebarWidth: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("theme.css")
                    .font(.caption)
                    .foregroundStyle(visual.textSecondary)
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(visual.textPrimary.opacity(0.04))

            (
                Text(":root").foregroundColor(visual.syntaxPurple)
                    + Text(" {\n  --cts-skin-background: ")
                    .foregroundColor(visual.codeText)
                    + Text("theme-asset(…)").foregroundColor(visual.syntaxGreen)
                    + Text(";\n}").foregroundColor(visual.codeText)
            )
            .font(visual.codeFont)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background {
            if visual.codeUsesBackdrop {
                ThemePreviewGlassBackground(
                    visual: visual,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth,
                    tint: visual.codeBackground,
                    blurRadius: visual.glassBackdropBlur,
                    saturation: visual.glassBackdropSaturation,
                    includesCenterPanelBackdrop:
                        visual.centerPanelEnabled
                )
            } else {
                visual.codeBackground
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: visual.codeCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: visual.codeCornerRadius,
                style: .continuous
            )
            .stroke(
                visual.codeBorder,
                lineWidth: visual.codeBorderWidth
            )
        }
        .shadow(
            color: .black.opacity(visual.codeShadowOpacity),
            radius: visual.codeShadowRadius,
            y: visual.codeShadowOffsetY
        )
    }

    private var assistantReply: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(visual.success)
            VStack(alignment: .leading, spacing: 4) {
                Text("Theme applied")
                    .fontWeight(.semibold)
                Text("All open Codex renderer surfaces are synchronized.")
                    .foregroundStyle(visual.textSecondary)
            }
            .font(.system(size: visual.chatFontSize - 1))
        }
    }

    private func composer(
        prompt: String,
        mode: PreviewComposerMode,
        canvasSize: CGSize,
        sidebarWidth: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(prompt)
                .foregroundStyle(visual.textSecondary)
                .padding(.horizontal, 14)
                .padding(.top, 13)
                .frame(
                    maxWidth: .infinity,
                    minHeight: mode == .chat ? 42 : 38,
                    alignment: .topLeading
                )

            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .foregroundStyle(visual.textSecondary)

                HStack(spacing: 5) {
                    Image(systemName: mode == .home ? "folder" : "gearshape")
                    Text(mode == .home ? "Select project" : "Custom")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(visual.textSecondary)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(visual.controlBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                )

                Spacer()

                Text("5.6 Sol")
                    .font(.system(size: 9))
                    .foregroundStyle(visual.textSecondary)
                Circle()
                    .fill(visual.accent)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.caption.bold())
                            .foregroundStyle(visual.accentContrast)
                    }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 9)
            .frame(minHeight: 39)
        }
        .background {
            if visual.composerUsesBackdrop {
                ThemePreviewGlassBackground(
                    visual: visual,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth,
                    tint: visual.composerBackground,
                    blurRadius: visual.glassBackdropBlur,
                    saturation: visual.glassBackdropSaturation
                )
            } else {
                visual.composerBackground
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: visual.resolvedComposerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: visual.resolvedComposerRadius,
                style: .continuous
            )
            .stroke(
                visual.composerBorder,
                lineWidth: visual.composerBorderWidth
            )
        }
        .shadow(
            color: .black.opacity(visual.composerShadowOpacity),
            radius: visual.composerShadowRadius,
            y: visual.composerShadowOffsetY
        )
    }
}

private enum PreviewComposerMode {
    case home
    case chat
}

enum ThemePreviewLayout {
    static let titlebarHeight: CGFloat = 46
    static let composerHeight: CGFloat = 78

    static func sidebarWidth(containerWidth: CGFloat) -> CGFloat {
        min(165, max(124, containerWidth * 0.18))
    }

    static func wallpaperWidth(
        containerWidth: CGFloat,
        sidebarWidth: CGFloat,
        scope: ThemeSkinWallpaperScope
    ) -> CGFloat {
        switch scope {
        case .fullWindow:
            containerWidth
        case .mainContent:
            max(0, containerWidth - sidebarWidth)
        }
    }
}

private enum ThemePreviewCoordinateSpace {
    static let name = "codex-theme-preview-root"
}

struct ThemePreviewBackdropCanvas: View {
    let visual: ThemeVisualSnapshot
    let canvasSize: CGSize
    let sidebarWidth: CGFloat

    private var wallpaperWidth: CGFloat {
        ThemePreviewLayout.wallpaperWidth(
            containerWidth: canvasSize.width,
            sidebarWidth: sidebarWidth,
            scope: visual.wallpaperScope
        )
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            visual.backgroundPrimary

            ThemePreviewWallpaper(visual: visual)
                .frame(
                    width: wallpaperWidth,
                    height: canvasSize.height
                )

            HStack(spacing: 0) {
                Color.clear
                    .frame(width: sidebarWidth)
                visual.contentBackground
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .allowsHitTesting(false)
    }
}

private struct ThemePreviewWallpaper: View {
    let visual: ThemeVisualSnapshot

    var body: some View {
        ZStack {
            visual.backgroundPrimary

            if let image = visual.backgroundImage,
               let variant = visual.skinVariant {
                SkinWallpaperView(image: image, variant: variant)
            }

            if let variant = visual.skinVariant {
                Color(css: variant.overlayColor, fallback: .black)
                    .opacity(variant.overlayOpacity)

                SkinScrimView(variant: variant)
                SkinVignetteView(opacity: variant.vignetteOpacity)
            }
        }
        .clipped()
    }
}

private struct ThemePreviewGlassBackground: View {
    let visual: ThemeVisualSnapshot
    let canvasSize: CGSize
    let sidebarWidth: CGFloat
    let tint: Color
    let blurRadius: CGFloat
    let saturation: Double
    let includesCenterPanelBackdrop: Bool

    init(
        visual: ThemeVisualSnapshot,
        canvasSize: CGSize,
        sidebarWidth: CGFloat,
        tint: Color,
        blurRadius: CGFloat,
        saturation: Double,
        includesCenterPanelBackdrop: Bool = false
    ) {
        self.visual = visual
        self.canvasSize = canvasSize
        self.sidebarWidth = sidebarWidth
        self.tint = tint
        self.blurRadius = blurRadius
        self.saturation = saturation
        self.includesCenterPanelBackdrop =
            includesCenterPanelBackdrop
    }

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(
                in: .named(ThemePreviewCoordinateSpace.name)
            )

            // SwiftUI Material adds its own platform tint and cannot represent an
            // exact CSS blur radius. Repaint the shared backdrop in root
            // coordinates, filter it, then add the configured RGBA tint.
            ZStack(alignment: .topLeading) {
                sampledBackdrop(frame: frame)
                .blur(radius: blurRadius)
                .saturation(saturation)

                tint
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .topLeading
            )
            .clipped()
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func sampledBackdrop(frame: CGRect) -> some View {
        if includesCenterPanelBackdrop {
            ZStack(alignment: .topLeading) {
                alignedRootBackdrop(frame: frame)
                    .blur(radius: visual.centerPanelBackdropBlur)
                    .saturation(
                        visual.centerPanelBackdropSaturation
                    )

                visual.centerPanelBackground
                    .frame(
                        width: canvasSize.width,
                        height: canvasSize.height
                    )
                    .offset(x: -frame.minX, y: -frame.minY)
            }
        } else {
            alignedRootBackdrop(frame: frame)
        }
    }

    private func alignedRootBackdrop(frame: CGRect) -> some View {
        ThemePreviewBackdropCanvas(
            visual: visual,
            canvasSize: canvasSize,
            sidebarWidth: sidebarWidth
        )
        .frame(
            width: canvasSize.width,
            height: canvasSize.height
        )
        .offset(x: -frame.minX, y: -frame.minY)
    }
}

enum SkinWallpaperLayout {
    struct Resolution: Equatable {
        let renderedSize: CGSize
        let offset: CGSize
    }

    static func resolve(
        imageSize: CGSize,
        containerSize: CGSize,
        fit: ThemeSkinImageFit,
        zoom: Double,
        positionX: Double,
        positionY: Double
    ) -> Resolution {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0
        else {
            return Resolution(
                renderedSize: containerSize,
                offset: .zero
            )
        }

        let renderedSize: CGSize
        switch fit {
        case .fill:
            renderedSize = CGSize(
                width: containerSize.width * zoom,
                height: containerSize.height * zoom
            )
        case .cover, .contain, .fitWidth, .fitHeight, .original, .tile:
            let widthScale = containerSize.width / imageSize.width
            let heightScale = containerSize.height / imageSize.height
            let baseScale: Double
            switch fit {
            case .cover:
                baseScale = max(widthScale, heightScale)
            case .contain:
                baseScale = min(widthScale, heightScale)
            case .fitWidth:
                baseScale = widthScale
            case .fitHeight:
                baseScale = heightScale
            case .original, .tile:
                baseScale = 1
            case .fill:
                baseScale = 1
            }
            let scale = baseScale * zoom
            renderedSize = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )
        }

        return Resolution(
            renderedSize: renderedSize,
            offset: CGSize(
                width: (positionX - 0.5)
                    * (containerSize.width - renderedSize.width),
                height: (positionY - 0.5)
                    * (containerSize.height - renderedSize.height)
            )
        )
    }

    static func blurOverscan(
        fit: ThemeSkinImageFit,
        imageBlur: Double
    ) -> CGFloat {
        guard imageBlur > 0,
              fit == .cover || fit == .fill
        else {
            return 0
        }
        return imageBlur * 2 + 4
    }
}

private struct SkinWallpaperView: View {
    let image: NSImage
    let variant: ThemeSkinVariant

    var body: some View {
        GeometryReader { geometry in
            let overscan = SkinWallpaperLayout.blurOverscan(
                fit: variant.imageFit,
                imageBlur: variant.imageBlur
            )
            let renderSize = CGSize(
                width: geometry.size.width + overscan * 2,
                height: geometry.size.height + overscan * 2
            )

            switch variant.imageFit {
            case .tile:
                Rectangle()
                    .fill(
                        ImagePaint(
                            image: Image(nsImage: image),
                            sourceRect: CGRect(
                                x: 0,
                                y: 0,
                                width: 1,
                                height: 1
                            ),
                            scale: max(0.2, variant.zoom)
                        )
                    )
                    .modifier(SkinImageTreatment(variant: variant))
            case .cover, .contain, .fill, .fitWidth, .fitHeight, .original:
                let layout = SkinWallpaperLayout.resolve(
                    imageSize: image.size,
                    containerSize: renderSize,
                    fit: variant.imageFit,
                    zoom: variant.zoom,
                    positionX: variant.positionX,
                    positionY: variant.positionY
                )

                Image(nsImage: image)
                    .resizable()
                    .frame(
                        width: layout.renderedSize.width,
                        height: layout.renderedSize.height
                    )
                    .offset(
                        x: layout.offset.width,
                        y: layout.offset.height
                    )
                    .modifier(SkinImageTreatment(variant: variant))
                    .frame(
                        width: renderSize.width,
                        height: renderSize.height
                    )
                    .clipped()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SkinImageTreatment: ViewModifier {
    let variant: ThemeSkinVariant

    func body(content: Content) -> some View {
        content
            .blur(radius: variant.imageBlur)
            .brightness(max(-1, min(1, variant.brightness - 1)))
            .contrast(variant.contrast)
            .saturation(variant.saturation)
            .opacity(variant.imageOpacity)
            .blendMode(swiftUIBlendMode)
    }

    private var swiftUIBlendMode: BlendMode {
        switch variant.blendMode {
        case .normal: .normal
        case .multiply: .multiply
        case .screen: .screen
        case .overlay: .overlay
        case .softLight: .softLight
        }
    }
}

private struct SkinScrimView: View {
    let variant: ThemeSkinVariant

    @ViewBuilder
    var body: some View {
        if variant.scrimDirection != .none, variant.scrimOpacity > 0 {
            LinearGradient(
                stops: [
                    .init(
                        color: .black.opacity(variant.scrimOpacity),
                        location: 0
                    ),
                    .init(color: .clear, location: 0.58),
                    .init(color: .clear, location: 1)
                ],
                startPoint: startPoint,
                endPoint: endPoint
            )
            .allowsHitTesting(false)
        }
    }

    private var startPoint: UnitPoint {
        switch variant.scrimDirection {
        case .left: .leading
        case .right: .trailing
        case .top: .top
        case .bottom: .bottom
        case .none: .center
        }
    }

    private var endPoint: UnitPoint {
        switch variant.scrimDirection {
        case .left: .trailing
        case .right: .leading
        case .top: .bottom
        case .bottom: .top
        case .none: .center
        }
    }
}

private struct SkinVignetteView: View {
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(
                geometry.size.width,
                geometry.size.height
            )

            RadialGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.34),
                    .init(color: .black.opacity(opacity), location: 1)
                ],
                center: .center,
                startRadius: 0,
                endRadius: diameter / 2
            )
            .frame(width: diameter, height: diameter)
            .scaleEffect(
                x: geometry.size.width / diameter,
                y: geometry.size.height / diameter
            )
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .allowsHitTesting(false)
    }
}

private struct PreviewSidebarRow: View {
    let icon: String
    let title: String
    let visual: ThemeVisualSnapshot
    var selected = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: icon == "circle.fill" ? 5 : 11))
                .frame(width: 14)
            Text(title)
                .lineLimit(1)
            Spacer()
        }
        .font(.system(size: 11))
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(selected ? visual.selectionBackground : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct HomeSuggestionCard: View {
    let icon: String
    let title: String
    let visual: ThemeVisualSnapshot
    let canvasSize: CGSize
    let sidebarWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(visual.accent)
                .frame(width: 24, height: 24, alignment: .leading)

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background {
            if visual.cardUsesBackdrop {
                ThemePreviewGlassBackground(
                    visual: visual,
                    canvasSize: canvasSize,
                    sidebarWidth: sidebarWidth,
                    tint: visual.cardBackground,
                    blurRadius: visual.glassBackdropBlur,
                    saturation: visual.glassBackdropSaturation
                )
            } else {
                visual.cardBackground
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: visual.cardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: visual.cardCornerRadius,
                style: .continuous
            )
            .stroke(
                visual.cardBorder,
                lineWidth: visual.cardBorderWidth
            )
        }
        .shadow(
            color: .black.opacity(visual.cardShadowOpacity),
            radius: visual.cardShadowRadius,
            y: visual.cardShadowOffsetY
        )
    }
}

struct ThemeVisualSnapshot {
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let contentBackground: Color
    let sidebarBackground: Color
    let titlebarBackground: Color
    let composerBackground: Color
    let cardBackground: Color
    let userMessageBackground: Color
    let controlBackground: Color
    let centerPanelBackground: Color
    let centerPanelBorder: Color
    let centerPanelShadow: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let accentContrast: Color
    let border: Color
    let nativeBorder: Color
    let success: Color
    let codeBackground: Color
    let codeText: Color
    let syntaxPurple: Color
    let syntaxGreen: Color
    let selectionBackground: Color
    let cornerRadius: CGFloat
    let composerRadius: CGFloat
    let nativeCornerRadius: CGFloat
    let nativeComposerRadius: CGFloat
    let chatFontSize: CGFloat
    let borderWidth: CGFloat
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let textShadowOpacity: Double
    let glassBackdropBlur: CGFloat
    let glassBackdropSaturation: Double
    let centerPanelEnabled: Bool
    let centerPanelBorderWidth: CGFloat
    let centerPanelCornerRadius: CGFloat
    let centerPanelBackdropBlur: CGFloat
    let centerPanelBackdropSaturation: Double
    let centerPanelShadowOpacity: Double
    let centerPanelShadowRadius: CGFloat
    let centerPanelShadowOffsetX: CGFloat
    let centerPanelShadowOffsetY: CGFloat
    let centerPanelMaximumWidth: CGFloat
    let centerPanelHorizontalPadding: CGFloat
    let centerPanelVerticalPadding: CGFloat
    let uiFont: Font
    let codeFont: Font
    let backgroundImage: NSImage?
    let skinVariant: ThemeSkinVariant?
    let wallpaperScope: ThemeSkinWallpaperScope
    let sidebarTargetEnabled: Bool
    let composerTargetEnabled: Bool
    let cardTargetEnabled: Bool
    let codeTargetEnabled: Bool
    let sidebarUsesBackdrop: Bool
    let composerUsesBackdrop: Bool
    let cardUsesBackdrop: Bool
    let codeUsesBackdrop: Bool
    let centerPanelUsesBackdrop: Bool

    init(
        theme: ThemeDocument,
        appearance: ThemeSkinAppearance
    ) {
        let values = theme.layers
            .filter {
                guard $0.isEnabled else { return false }
                switch $0.condition {
                case .always:
                    return true
                case .light:
                    return appearance == .light
                case .dark:
                    return appearance == .dark
                case .custom:
                    return false
                }
            }
            .flatMap(\.variables)
            .filter(\.isEnabled)

        func semantic(_ role: ThemeSemanticRole, _ fallback: String) -> String {
            values.last(where: { $0.semanticRole == role })?.value ?? fallback
        }

        func token(_ name: String, _ fallback: String) -> String {
            values.last(where: { $0.resolvedName == name })?.value ?? fallback
        }

        let activeSkin = theme.imageSkin.flatMap { $0.isEnabled ? $0 : nil }
        let variant = activeSkin?.variant(for: appearance)
        skinVariant = variant
        wallpaperScope = activeSkin?.wallpaperScope ?? .fullWindow
        sidebarTargetEnabled = activeSkin?.targets.sidebar ?? false
        composerTargetEnabled = activeSkin?.targets.composer ?? false
        cardTargetEnabled = activeSkin?.targets.cards ?? false
        codeTargetEnabled = activeSkin?.targets.codeBlocks ?? false

        nativeBorder = Color(
            css: semantic(.border, "rgba(255,255,255,0.12)"),
            fallback: .white.opacity(0.12)
        )
        nativeCornerRadius = token(
            "--codex-corner-radius-scale",
            "12"
        ).firstCSSNumber ?? 12
        nativeComposerRadius = token(
            "--composer-border-radius",
            "\(nativeCornerRadius)"
        ).firstCSSNumber ?? nativeCornerRadius

        backgroundPrimary = Color(
            css: variant?.backgroundColor
                ?? semantic(.backgroundPrimary, "#151515"),
            fallback: appearance == .dark
                ? .init(white: 0.08)
                : .init(white: 0.96)
        )
        backgroundSecondary = Color(
            css: semantic(.backgroundSecondary, "#1d1d1d"),
            fallback: .init(white: 0.11)
        )

        let sidebarFallback = token(
            "--color-token-side-bar-background",
            semantic(.backgroundSecondary, "#1d1d1d")
        )
        let surfaceFallback = semantic(.surface, "#252525")
        let centerPanel = activeSkin?.centerPanel
            ?? ThemeSkinCenterPanel()

        centerPanelEnabled = activeSkin != nil && centerPanel.isEnabled
        centerPanelBackground = Color(
            css: variant?.centerPanelTint ?? "#000000",
            fallback: .clear
        ).opacity(variant?.centerPanelOpacity ?? 0)
        centerPanelBorder = Color(
            css: variant?.centerPanelBorderColor ?? "#000000",
            fallback: .clear
        ).opacity(variant?.centerPanelBorderOpacity ?? 0)
        centerPanelShadow = Color(
            css: variant?.centerPanelShadowColor ?? "#000000",
            fallback: .black
        )
        centerPanelBorderWidth = centerPanel.borderWidth
        centerPanelCornerRadius = centerPanel.cornerRadius
        centerPanelBackdropBlur = centerPanel.backdropBlur
        centerPanelBackdropSaturation = centerPanel.backdropSaturation
        centerPanelShadowOpacity =
            variant?.centerPanelShadowOpacity ?? 0
        centerPanelShadowRadius = centerPanel.shadowBlur
        centerPanelShadowOffsetX = centerPanel.shadowOffsetX
        centerPanelShadowOffsetY = centerPanel.shadowOffsetY
        centerPanelMaximumWidth = centerPanel.maximumWidth
        centerPanelHorizontalPadding = centerPanel.horizontalPadding
        centerPanelVerticalPadding = centerPanel.verticalPadding
        centerPanelUsesBackdrop =
            centerPanelEnabled
            && (
                centerPanel.backdropBlur > 0
                || abs(centerPanel.backdropSaturation - 1) > 0.001
            )

        if let variant, let activeSkin {
            if activeSkin.targets.content {
                contentBackground = Color(
                    css: variant.contentTint,
                    fallback: .clear
                ).opacity(variant.contentOpacity)
            } else if activeSkin.wallpaperScope == .mainContent {
                contentBackground = .clear
            } else {
                contentBackground = Color(
                    css: semantic(.backgroundPrimary, "#151515"),
                    fallback: backgroundPrimary
                )
            }
            sidebarBackground = Color(
                css: activeSkin.targets.sidebar
                    ? variant.sidebarTint
                    : sidebarFallback,
                fallback: .clear
            ).opacity(
                activeSkin.targets.sidebar ? variant.sidebarOpacity : 1
            )
            titlebarBackground = Color(
                css: activeSkin.targets.titlebar
                    ? variant.contentTint
                    : token("--codex-titlebar-tint", "transparent"),
                fallback: .clear
            ).opacity(
                activeSkin.targets.titlebar ? variant.contentOpacity : 1
            )
            composerBackground = Color(
                css: activeSkin.targets.composer
                    ? variant.composerTint
                    : surfaceFallback,
                fallback: .clear
            ).opacity(
                activeSkin.targets.composer ? variant.composerOpacity : 0.9
            )
            cardBackground = Color(
                css: activeSkin.targets.cards
                    ? variant.cardTint
                    : surfaceFallback,
                fallback: .clear
            ).opacity(
                activeSkin.targets.cards ? variant.cardOpacity : 0.86
            )
            userMessageBackground = Color(
                css: variant.primaryTextColor,
                fallback: .primary
            ).opacity(0.06)
            controlBackground = Color(
                css: activeSkin.targets.composer
                    ? variant.composerTint
                    : surfaceFallback,
                fallback: .clear
            ).opacity(
                activeSkin.targets.composer ? variant.composerOpacity : 0.9
            )
            surface = cardBackground
            textPrimary = Color(
                css: variant.primaryTextColor,
                fallback: .primary
            )
            textSecondary = Color(
                css: variant.secondaryTextColor,
                fallback: .secondary
            )
            accent = Color(
                css: variant.accentColor,
                fallback: .accentColor
            )
            border = Color(
                css: variant.borderColor,
                fallback: .white
            ).opacity(variant.borderOpacity)
            borderWidth = activeSkin.glass.borderWidth
            cornerRadius = activeSkin.glass.cornerRadius
            composerRadius = activeSkin.glass.cornerRadius
            shadowOpacity = activeSkin.glass.shadowOpacity
            shadowRadius = activeSkin.glass.shadowBlur
            textShadowOpacity = activeSkin.glass.textShadowOpacity
            glassBackdropBlur = activeSkin.glass.blurRadius
            glassBackdropSaturation = activeSkin.glass.saturation

            let hasBackdrop =
                activeSkin.glass.blurRadius > 0
                || abs(activeSkin.glass.saturation - 1) > 0.001
            sidebarUsesBackdrop =
                activeSkin.targets.sidebar && hasBackdrop
            composerUsesBackdrop =
                activeSkin.targets.composer && hasBackdrop
            cardUsesBackdrop =
                activeSkin.targets.cards && hasBackdrop
        } else {
            contentBackground = Color(
                css: semantic(.backgroundPrimary, "#151515"),
                fallback: .init(white: 0.08)
            )
            sidebarBackground = Color(
                css: sidebarFallback,
                fallback: .init(white: 0.11)
            )
            titlebarBackground = backgroundPrimary.opacity(0.96)
            surface = Color(
                css: surfaceFallback,
                fallback: .init(white: 0.15)
            )
            composerBackground = surface.opacity(0.9)
            cardBackground = surface.opacity(0.86)
            userMessageBackground = Color.primary.opacity(0.06)
            controlBackground = surface.opacity(0.9)
            textPrimary = Color(
                css: semantic(.textPrimary, "#f5f5f5"),
                fallback: .white
            )
            textSecondary = Color(
                css: semantic(.textSecondary, "#a0a0a0"),
                fallback: .gray
            )
            accent = Color(
                css: semantic(.accent, "#339cff"),
                fallback: .blue
            )
            border = Color(
                css: semantic(.border, "rgba(255,255,255,0.12)"),
                fallback: .white.opacity(0.12)
            )
            borderWidth = 1
            cornerRadius = nativeCornerRadius
            composerRadius = nativeComposerRadius
            shadowOpacity = 0.12
            shadowRadius = 18
            textShadowOpacity = 0
            glassBackdropBlur = 0
            glassBackdropSaturation = 1
            sidebarUsesBackdrop = false
            composerUsesBackdrop = false
            cardUsesBackdrop = false
        }

        accentContrast = Color(
            css: token("--color-token-on-accent", "#ffffff"),
            fallback: .white
        )
        success = Color(
            css: semantic(.success, "#40c977"),
            fallback: .green
        )
        if let activeSkin,
           let variant,
           activeSkin.targets.codeBlocks {
            codeBackground = Color(
                css: variant.cardTint,
                fallback: .black
            ).opacity(variant.cardOpacity)
            codeUsesBackdrop =
                activeSkin.glass.blurRadius > 0
                || abs(activeSkin.glass.saturation - 1) > 0.001
        } else {
            codeBackground = Color(
                css: token(
                    "--color-token-text-code-block-background",
                    "#101010"
                ),
                fallback: .black.opacity(0.7)
            )
            codeUsesBackdrop = false
        }
        codeText = Color(
            css: token(
                "--color-token-editor-foreground",
                semantic(.textPrimary, "#f5f5f5")
            ),
            fallback: .white
        )
        syntaxPurple = Color(
            css: token("--color-token-terminal-ansi-magenta", "#c792ea"),
            fallback: .purple
        )
        syntaxGreen = Color(
            css: token("--color-token-terminal-ansi-green", "#7fdb8a"),
            fallback: .green
        )
        selectionBackground = Color(
            css: token(
                "--color-token-list-active-selection-background",
                variant?.accentColor ?? surfaceFallback
            ),
            fallback: accent.opacity(0.16)
        )
        chatFontSize = token(
            "--codex-chat-font-size",
            "14"
        ).firstCSSNumber ?? 14

        let uiFamily = token("--font-sans", "")
            .cssFontFamilyName
        let monoFamily = token("--font-mono", "")
            .cssFontFamilyName
        uiFont = uiFamily.isEmpty
            ? .system(size: 12)
            : .custom(uiFamily, size: 12)
        codeFont = monoFamily.isEmpty
            ? .system(size: 11, design: .monospaced)
            : .custom(monoFamily, size: 11)

        if let id = variant?.backgroundAssetID,
           let asset = theme.assets.first(where: { $0.id == id }),
           let data = asset.decodedData {
            backgroundImage = NSImage(data: data)
        } else {
            backgroundImage = nil
        }
    }

    var sidebarBorder: Color {
        sidebarTargetEnabled ? border : nativeBorder
    }

    var sidebarBorderWidth: CGFloat {
        sidebarTargetEnabled ? borderWidth : 1
    }

    var resolvedComposerRadius: CGFloat {
        composerTargetEnabled ? composerRadius : nativeComposerRadius
    }

    var composerBorder: Color {
        composerTargetEnabled ? border : nativeBorder
    }

    var composerBorderWidth: CGFloat {
        composerTargetEnabled ? borderWidth : 1
    }

    var composerShadowOpacity: Double {
        composerTargetEnabled ? shadowOpacity : 0.12
    }

    var composerShadowRadius: CGFloat {
        composerTargetEnabled ? shadowRadius : 18
    }

    var composerShadowOffsetY: CGFloat {
        composerTargetEnabled ? 18 : 8
    }

    var cardCornerRadius: CGFloat {
        cardTargetEnabled ? cornerRadius : nativeCornerRadius
    }

    var cardBorder: Color {
        cardTargetEnabled ? border : nativeBorder
    }

    var cardBorderWidth: CGFloat {
        cardTargetEnabled ? borderWidth : 1
    }

    var cardShadowOpacity: Double {
        cardTargetEnabled ? shadowOpacity : 0.08
    }

    var cardShadowRadius: CGFloat {
        cardTargetEnabled ? shadowRadius : 8
    }

    var cardShadowOffsetY: CGFloat {
        cardTargetEnabled ? 18 : 4
    }

    var codeCornerRadius: CGFloat {
        codeTargetEnabled
            ? cornerRadius
            : max(6, nativeCornerRadius - 3)
    }

    var codeBorder: Color {
        codeTargetEnabled ? border : nativeBorder
    }

    var codeBorderWidth: CGFloat {
        codeTargetEnabled ? borderWidth : 1
    }

    var codeShadowOpacity: Double {
        codeTargetEnabled ? shadowOpacity : 0
    }

    var codeShadowRadius: CGFloat {
        codeTargetEnabled ? shadowRadius : 0
    }

    var codeShadowOffsetY: CGFloat {
        codeTargetEnabled ? 18 : 0
    }
}

extension String {
    fileprivate var firstCSSNumber: CGFloat? {
        let allowed = CharacterSet(charactersIn: "-.0123456789")
        let scalarPrefix = unicodeScalars.prefix { allowed.contains($0) }
        guard !scalarPrefix.isEmpty else { return nil }
        return Double(String(String.UnicodeScalarView(scalarPrefix)))
            .map { CGFloat($0) }
    }

    fileprivate var cssFontFamilyName: String {
        split(separator: ",").first.map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
            ?? ""
    }
}

extension Color {
    init(css: String, fallback: Color) {
        if let color = NSColor(css: css) {
            self.init(nsColor: color)
        } else {
            self = fallback
        }
    }
}

extension NSColor {
    convenience init?(css raw: String) {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.caseInsensitiveCompare("transparent") == .orderedSame {
            self.init(
                srgbRed: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
            return
        }

        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard [3, 6, 8].contains(hex.count) else { return nil }
            let expanded = hex.count == 3
                ? hex.map { "\($0)\($0)" }.joined()
                : hex
            guard let number = UInt64(expanded, radix: 16) else { return nil }
            if expanded.count == 8 {
                self.init(
                    srgbRed: CGFloat((number >> 24) & 0xff) / 255,
                    green: CGFloat((number >> 16) & 0xff) / 255,
                    blue: CGFloat((number >> 8) & 0xff) / 255,
                    alpha: CGFloat(number & 0xff) / 255
                )
            } else {
                self.init(
                    srgbRed: CGFloat((number >> 16) & 0xff) / 255,
                    green: CGFloat((number >> 8) & 0xff) / 255,
                    blue: CGFloat(number & 0xff) / 255,
                    alpha: 1
                )
            }
            return
        }

        let pattern = #"rgba?\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: value,
                range: NSRange(value.startIndex..., in: value)
              ),
              let redRange = Range(match.range(at: 1), in: value),
              let greenRange = Range(match.range(at: 2), in: value),
              let blueRange = Range(match.range(at: 3), in: value),
              let red = Double(value[redRange]),
              let green = Double(value[greenRange]),
              let blue = Double(value[blueRange]) else {
            return nil
        }
        var alpha = 1.0
        if match.range(at: 4).location != NSNotFound,
           let alphaRange = Range(match.range(at: 4), in: value),
           let parsed = Double(value[alphaRange]) {
            alpha = parsed
        }
        self.init(
            srgbRed: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: alpha
        )
    }

    var cssHex: String {
        let color = usingColorSpace(.sRGB) ?? self
        let red = Int(round(color.redComponent * 255))
        let green = Int(round(color.greenComponent * 255))
        let blue = Int(round(color.blueComponent * 255))
        let alpha = Int(round(color.alphaComponent * 255))
        if alpha < 255 {
            return String(
                format: "#%02X%02X%02X%02X",
                red,
                green,
                blue,
                alpha
            )
        }
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
