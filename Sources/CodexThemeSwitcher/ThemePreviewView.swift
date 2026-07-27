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

    private var visual: ThemeVisualSnapshot {
        ThemeVisualSnapshot(
            theme: theme,
            appearance: resolvedAppearance
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = ThemePreviewLayout.sidebarWidth(
                containerWidth: geometry.size.width
            )
            let wallpaperWidth = ThemePreviewLayout.wallpaperWidth(
                containerWidth: geometry.size.width,
                sidebarWidth: sidebarWidth,
                scope: visual.wallpaperScope
            )

            ZStack(alignment: .trailing) {
                wallpaper
                    .frame(
                        width: wallpaperWidth,
                        height: geometry.size.height
                    )

                HStack(spacing: 0) {
                    previewSidebar
                        .frame(width: sidebarWidth)

                    VStack(spacing: 0) {
                        previewTitlebar
                        switch surface {
                        case .home:
                            homeSurface
                        case .chat:
                            chatSurface
                        }
                    }
                    .background(visual.contentBackground)
                    .background {
                        if visual.contentUsesMaterial {
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    }
                }
            }
        }
        .font(visual.uiFont)
        .foregroundStyle(visual.textPrimary)
        .background(visual.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(visual.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
    }

    private var wallpaper: some View {
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

    private var previewSidebar: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(visual.accent)
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

            Text("PROJECTS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
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
        .padding(14)
        .background(visual.sidebarBackground)
        .background {
            if visual.sidebarUsesMaterial {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(visual.border)
                .frame(width: visual.borderWidth)
        }
        .shadow(
            color: .black.opacity(visual.shadowOpacity * 0.55),
            radius: visual.shadowRadius * 0.45
        )
    }

    private var previewTitlebar: some View {
        HStack(spacing: 10) {
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
        .frame(height: 46)
        .background(visual.titlebarBackground)
        .background {
            if visual.titlebarUsesMaterial {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(visual.border.opacity(0.75))
                .frame(height: visual.borderWidth)
        }
    }

    private var chatSurface: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                assistantMessage
                userMessage
                codeBlock
                assistantReply
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .bottom) {
            composer(prompt: "Ask Codex anything", expanded: false)
                .padding(22)
        }
    }

    private var homeSurface: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 5) {
                Text("What should we build?")
                    .font(.system(size: 25, weight: .bold))
                Text("Bring your workspace into a look that feels entirely yours.")
                    .font(.system(size: 11))
                    .foregroundStyle(visual.textSecondary)
            }
            .frame(maxWidth: 610, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                HomeSuggestionCard(
                    icon: "megaphone",
                    title: "Explore and understand code",
                    visual: visual
                )
                HomeSuggestionCard(
                    icon: "hammer",
                    title: "Build a new feature",
                    visual: visual
                )
                HomeSuggestionCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Review and suggest changes",
                    visual: visual
                )
                HomeSuggestionCard(
                    icon: "ladybug",
                    title: "Fix issues and failures",
                    visual: visual
                )
            }
            .frame(maxWidth: 650)
            .padding(.horizontal, 20)

            Spacer(minLength: 18)

            composer(prompt: "Do anything", expanded: true)
                .frame(maxWidth: 650)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
    }

    private var assistantMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Codex")
                .font(.caption.bold())
                .foregroundStyle(visual.accent)
            Text("I’ll turn this into a menu bar app with live theme switching, a visual skin editor, and portable templates.")
                .font(.system(size: visual.chatFontSize))
                .lineSpacing(visual.chatFontSize * 0.35)
        }
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
            .background(visual.cardBackground)
            .background {
                if visual.cardUsesMaterial {
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: visual.cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: visual.cornerRadius,
                    style: .continuous
                )
                .stroke(visual.border, lineWidth: visual.borderWidth)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var codeBlock: some View {
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
            .background(visual.codeBackground.opacity(0.86))

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
            .background(visual.codeBackground)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: max(6, visual.cornerRadius - 3),
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: max(6, visual.cornerRadius - 3),
                style: .continuous
            )
            .stroke(visual.border, lineWidth: visual.borderWidth)
        }
    }

    private var assistantReply: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.circle.fill")
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

    private func composer(prompt: String, expanded: Bool) -> some View {
        VStack(spacing: 0) {
            if expanded {
                HStack(spacing: 7) {
                    Image(systemName: "folder")
                    Text("Select project")
                    Spacer()
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(visual.textSecondary)
                .padding(.horizontal, 14)
                .frame(height: 31)

                Divider()
                    .overlay(visual.border)
            }

            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .foregroundStyle(visual.textSecondary)
                Text(prompt)
                    .foregroundStyle(visual.textSecondary)
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
            .frame(height: expanded ? 47 : 50)
        }
        .background(visual.composerBackground)
        .background {
            if visual.composerUsesMaterial {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: visual.composerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: visual.composerRadius,
                style: .continuous
            )
            .stroke(visual.border, lineWidth: visual.borderWidth)
        }
        .shadow(
            color: .black.opacity(visual.shadowOpacity),
            radius: visual.shadowRadius,
            y: 8
        )
    }
}

enum ThemePreviewLayout {
    static func sidebarWidth(containerWidth: CGFloat) -> CGFloat {
        min(185, containerWidth * 0.28)
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
}

private struct SkinWallpaperView: View {
    let image: NSImage
    let variant: ThemeSkinVariant

    var body: some View {
        GeometryReader { geometry in
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
                    containerSize: geometry.size,
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
                colors: [
                    .black.opacity(variant.scrimOpacity),
                    .clear
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
        case .left: UnitPoint(x: 0.62, y: 0.5)
        case .right: UnitPoint(x: 0.38, y: 0.5)
        case .top: UnitPoint(x: 0.5, y: 0.62)
        case .bottom: UnitPoint(x: 0.5, y: 0.38)
        case .none: .center
        }
    }
}

private struct SkinVignetteView: View {
    let opacity: Double

    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(opacity)],
            center: .center,
            startRadius: 60,
            endRadius: 520
        )
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

    var body: some View {
        VStack(spacing: 9) {
            Circle()
                .fill(visual.accent.opacity(0.12))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(visual.accent)
                }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .padding(.horizontal, 7)
        .background(visual.cardBackground)
        .background {
            if visual.cardUsesMaterial {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: visual.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: visual.cornerRadius,
                style: .continuous
            )
            .stroke(visual.border, lineWidth: visual.borderWidth)
        }
        .shadow(
            color: .black.opacity(visual.shadowOpacity * 0.7),
            radius: visual.shadowRadius * 0.6,
            y: 5
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
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let accentContrast: Color
    let border: Color
    let success: Color
    let codeBackground: Color
    let codeText: Color
    let syntaxPurple: Color
    let syntaxGreen: Color
    let selectionBackground: Color
    let cornerRadius: CGFloat
    let composerRadius: CGFloat
    let chatFontSize: CGFloat
    let borderWidth: CGFloat
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let textShadowOpacity: Double
    let uiFont: Font
    let codeFont: Font
    let backgroundImage: NSImage?
    let skinVariant: ThemeSkinVariant?
    let wallpaperScope: ThemeSkinWallpaperScope
    let contentUsesMaterial: Bool
    let sidebarUsesMaterial: Bool
    let titlebarUsesMaterial: Bool
    let composerUsesMaterial: Bool
    let cardUsesMaterial: Bool

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

        if let variant, let activeSkin {
            contentBackground = Color(
                css: activeSkin.targets.content
                    ? variant.contentTint
                    : semantic(.backgroundPrimary, "#151515"),
                fallback: .clear
            ).opacity(
                activeSkin.targets.content ? variant.contentOpacity : 1
            )
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
                    : semantic(.backgroundPrimary, "#151515"),
                fallback: .clear
            ).opacity(
                activeSkin.targets.titlebar ? variant.contentOpacity : 0.96
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

            let hasBlur = activeSkin.glass.blurRadius > 0
            contentUsesMaterial = false
            sidebarUsesMaterial = activeSkin.targets.sidebar && hasBlur
            titlebarUsesMaterial = false
            composerUsesMaterial = activeSkin.targets.composer && hasBlur
            cardUsesMaterial = activeSkin.targets.cards && hasBlur
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
            cornerRadius = token(
                "--codex-corner-radius-scale",
                "12"
            ).firstCSSNumber ?? 12
            composerRadius = token(
                "--composer-border-radius",
                "\(cornerRadius)"
            ).firstCSSNumber ?? cornerRadius
            shadowOpacity = 0.12
            shadowRadius = 18
            textShadowOpacity = 0
            contentUsesMaterial = false
            sidebarUsesMaterial = false
            titlebarUsesMaterial = false
            composerUsesMaterial = true
            cardUsesMaterial = false
        }

        accentContrast = Color(
            css: token("--color-token-on-accent", "#ffffff"),
            fallback: .white
        )
        success = Color(
            css: semantic(.success, "#40c977"),
            fallback: .green
        )
        codeBackground = Color(
            css: token("--color-token-text-code-block-background", "#101010"),
            fallback: .black.opacity(0.7)
        )
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
