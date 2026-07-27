import AppKit
import CodexThemeSwitcherCore
import Foundation
import ImageIO
import SwiftUI

/// The color scheme used by a native agent preview.
public enum AgentPreviewAppearance: String, Codable, CaseIterable, Sendable {
    case light
    case dark

    fileprivate var skinAppearance: ThemeSkinAppearance {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    fileprivate var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// The representative Codex screen rendered into the preview.
public enum AgentPreviewSurface: String, Codable, CaseIterable, Sendable {
    case home
    case chat
}

/// Pixel dimensions for a preview rendered at the renderer's fixed 1x scale.
public struct AgentPreviewSize: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    fileprivate var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}

/// A stable warning identifier suitable for programmatic agent decisions.
public enum AgentPreviewWarningCode: String, Codable, Sendable {
    case rawCSSNotRendered = "raw_css_not_rendered"
    case customSelectorsNotRendered = "custom_selectors_not_rendered"
    case customMediaConditionNotRendered = "custom_media_condition_not_rendered"
    case componentDeclarationsApproximated =
        "component_declarations_approximated"
    case wallpaperAssetMissing = "wallpaper_asset_missing"
    case wallpaperAssetInvalid = "wallpaper_asset_invalid"
    case wallpaperAssetTooLarge = "wallpaper_asset_too_large"
    case unsupportedCSSColor = "unsupported_css_color"
}

public enum AgentPreviewWarningSeverity: String, Codable, Sendable {
    case info
    case warning
}

/// A machine-readable limitation encountered while producing a native preview.
public struct AgentPreviewWarning: Codable, Equatable, Sendable {
    public var code: AgentPreviewWarningCode
    public var severity: AgentPreviewWarningSeverity
    public var message: String
    public var details: [String: String]

    public init(
        code: AgentPreviewWarningCode,
        severity: AgentPreviewWarningSeverity = .warning,
        message: String,
        details: [String: String] = [:]
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.details = details
    }
}

/// Metadata returned after a successful render.
public struct AgentPreviewRenderResult: Codable, Equatable, Sendable {
    public var outputURL: URL
    public var byteCount: Int
    public var themeID: UUID
    public var appearance: AgentPreviewAppearance
    public var surface: AgentPreviewSurface
    public var size: AgentPreviewSize
    public var isApproximation: Bool
    public var warnings: [AgentPreviewWarning]

    public init(
        outputURL: URL,
        byteCount: Int,
        themeID: UUID,
        appearance: AgentPreviewAppearance,
        surface: AgentPreviewSurface,
        size: AgentPreviewSize,
        isApproximation: Bool = true,
        warnings: [AgentPreviewWarning]
    ) {
        self.outputURL = outputURL
        self.byteCount = byteCount
        self.themeID = themeID
        self.appearance = appearance
        self.surface = surface
        self.size = size
        self.isApproximation = isApproximation
        self.warnings = warnings
    }
}

public enum AgentPreviewRendererError: Error, LocalizedError, Sendable {
    case invalidSize(width: Int, height: Int)
    case outputMustBeFileURL
    case imageRendererFailed
    case pngEncodingFailed

    public var errorDescription: String? {
        switch self {
        case let .invalidSize(width, height):
            return """
            Preview size \(width)x\(height) is invalid. Each dimension must be \
            240...8192 and the image may contain at most 40 million pixels.
            """
        case .outputMustBeFileURL:
            return "The preview output URL must be a local file URL."
        case .imageRendererFailed:
            return "SwiftUI ImageRenderer did not produce an AppKit image."
        case .pngEncodingFailed:
            return "The rendered AppKit image could not be encoded as PNG."
        }
    }
}

/// Renders deterministic, representative Codex home/chat surfaces without
/// launching or reading the real Codex application.
///
/// The renderer intentionally does not execute CSS. It understands semantic
/// variables and `ThemeImageSkin`, then reports any CSS-only behavior through
/// `warnings` so an agent can decide whether a browser-level verification pass
/// is still required.
@MainActor
public struct AgentPreviewRenderer {
    public init() {}

    public func render(
        theme: ThemeDocument,
        appearance: AgentPreviewAppearance,
        surface: AgentPreviewSurface,
        size: AgentPreviewSize,
        outputURL: URL
    ) async throws -> AgentPreviewRenderResult {
        try Self.validate(size: size)
        guard outputURL.isFileURL else {
            throw AgentPreviewRendererError.outputMustBeFileURL
        }
        try Task.checkCancellation()

        let snapshot = AgentPreviewVisualSnapshot(
            theme: theme,
            appearance: appearance,
            maximumWallpaperPixelDimension: max(size.width, size.height)
        )
        let content = AgentPreviewCanvas(
            visual: snapshot,
            surface: surface
        )
        .environment(\.colorScheme, appearance.colorScheme)
        .frame(
            width: size.cgSize.width,
            height: size.cgSize.height
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(size.cgSize)

        guard let image = renderer.nsImage else {
            throw AgentPreviewRendererError.imageRendererFailed
        }
        guard let cgImage = image.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            throw AgentPreviewRendererError.pngEncodingFailed
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let png = bitmap.representation(
            using: .png,
            properties: [:]
        ) else {
            throw AgentPreviewRendererError.pngEncodingFailed
        }

        let destination = outputURL.standardizedFileURL
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try png.write(to: destination, options: .atomic)

        return AgentPreviewRenderResult(
            outputURL: destination,
            byteCount: png.count,
            themeID: theme.id,
            appearance: appearance,
            surface: surface,
            size: size,
            warnings: Self.warnings(
                for: theme,
                appearance: appearance,
                snapshot: snapshot
            )
        )
    }

    /// Convenience overload for callers already using Core's appearance enum.
    public func render(
        theme: ThemeDocument,
        skinAppearance: ThemeSkinAppearance,
        surface: AgentPreviewSurface,
        size: AgentPreviewSize,
        outputURL: URL
    ) async throws -> AgentPreviewRenderResult {
        try await render(
            theme: theme,
            appearance: skinAppearance == .light
                ? AgentPreviewAppearance.light
                : AgentPreviewAppearance.dark,
            surface: surface,
            size: size,
            outputURL: outputURL
        )
    }

    /// Convenience overload for flag-based CLIs that already parsed dimensions.
    public func render(
        theme: ThemeDocument,
        appearance: AgentPreviewAppearance,
        surface: AgentPreviewSurface,
        width: Int,
        height: Int,
        outputURL: URL
    ) async throws -> AgentPreviewRenderResult {
        try await render(
            theme: theme,
            appearance: appearance,
            surface: surface,
            size: AgentPreviewSize(width: width, height: height),
            outputURL: outputURL
        )
    }

    private static func validate(size: AgentPreviewSize) throws {
        let allowed = 240...8192
        guard allowed.contains(size.width),
              allowed.contains(size.height)
        else {
            throw AgentPreviewRendererError.invalidSize(
                width: size.width,
                height: size.height
            )
        }
        let pixels = Int64(size.width) * Int64(size.height)
        guard pixels <= 40_000_000 else {
            throw AgentPreviewRendererError.invalidSize(
                width: size.width,
                height: size.height
            )
        }
    }

    private static func warnings(
        for theme: ThemeDocument,
        appearance: AgentPreviewAppearance,
        snapshot: AgentPreviewVisualSnapshot
    ) -> [AgentPreviewWarning] {
        let applicableLayers = theme.layers.filter { layer in
            guard layer.isEnabled else { return false }
            switch layer.condition {
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
        var warnings: [AgentPreviewWarning] = []

        let rawCSSLayers = applicableLayers.filter {
            !$0.rawCSS.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if !rawCSSLayers.isEmpty {
            warnings.append(
                AgentPreviewWarning(
                    code: .rawCSSNotRendered,
                    message: """
                    rawCSS is not executed by the native preview, so selectors, \
                    effects, and layout declared there may differ in Codex.
                    """,
                    details: [
                        "layerCount": String(rawCSSLayers.count),
                        "layers": rawCSSLayers.map(\.name).joined(separator: ", ")
                    ]
                )
            )
        }

        let customRuleCount = applicableLayers.reduce(into: 0) { count, layer in
            count += layer.rules.filter(\.isEnabled).count
            count += layer.components.filter {
                $0.isEnabled && !$0.selectors.isEmpty
            }.count
        }
        if customRuleCount > 0 {
            warnings.append(
                AgentPreviewWarning(
                    code: .customSelectorsNotRendered,
                    message: """
                    Custom selector rules are not matched against a browser DOM; \
                    their appearance may be inaccurate or absent in this preview.
                    """,
                    details: ["ruleCount": String(customRuleCount)]
                )
            )
        }

        let customLayerCount = theme.layers.filter {
            $0.isEnabled && $0.condition == .custom
        }.count
        if customLayerCount > 0 {
            warnings.append(
                AgentPreviewWarning(
                    code: .customMediaConditionNotRendered,
                    message: """
                    Custom media-query layers are not evaluated by the native \
                    renderer and are omitted from this preview.
                    """,
                    details: ["layerCount": String(customLayerCount)]
                )
            )
        }

        let componentCount = applicableLayers.reduce(into: 0) { count, layer in
            count += layer.components.filter {
                $0.isEnabled && !$0.declarations.isEmpty
            }.count
        }
        if componentCount > 0 {
            warnings.append(
                AgentPreviewWarning(
                    code: .componentDeclarationsApproximated,
                    severity: .info,
                    message: """
                    Known component declarations are represented by the native \
                    mock surface, not by executing their exact CSS.
                    """,
                    details: ["componentCount": String(componentCount)]
                )
            )
        }

        if snapshot.requestedWallpaperAssetID != nil {
            if snapshot.wallpaperAssetWasMissing {
                warnings.append(
                    AgentPreviewWarning(
                        code: .wallpaperAssetMissing,
                        message: """
                        The selected appearance references a wallpaper asset that \
                        is not embedded in this theme.
                        """,
                        details: [
                            "assetID":
                                snapshot.requestedWallpaperAssetID?.uuidString
                                ?? ""
                        ]
                    )
                )
            } else if snapshot.wallpaperAssetWasInvalid {
                warnings.append(
                    AgentPreviewWarning(
                        code: .wallpaperAssetInvalid,
                        message: """
                        The selected wallpaper asset could not be decoded as an \
                        image and was omitted.
                        """,
                        details: [
                            "assetID":
                                snapshot.requestedWallpaperAssetID?.uuidString
                                ?? ""
                        ]
                    )
                )
            } else if let size = snapshot.wallpaperAssetRejectedSize {
                warnings.append(
                    AgentPreviewWarning(
                        code: .wallpaperAssetTooLarge,
                        message: """
                        The selected wallpaper has unsafe decoded dimensions and \
                        was omitted from the native preview.
                        """,
                        details: [
                            "assetID":
                                snapshot.requestedWallpaperAssetID?.uuidString
                                ?? "",
                            "height": String(size.height),
                            "maximumPixels": String(
                                AgentPreviewVisualSnapshot
                                    .maximumWallpaperSourcePixels
                            ),
                            "width": String(size.width)
                        ]
                    )
                )
            }
        }

        if !snapshot.unsupportedColorValues.isEmpty {
            warnings.append(
                AgentPreviewWarning(
                    code: .unsupportedCSSColor,
                    severity: .info,
                    message: """
                    Some CSS color expressions are not understood by the native \
                    parser and use appearance-aware fallback colors.
                    """,
                    details: [
                        "count": String(snapshot.unsupportedColorValues.count),
                        "values":
                            snapshot.unsupportedColorValues.joined(separator: ", ")
                    ]
                )
            )
        }

        return warnings
    }
}

private struct AgentPreviewCanvas: View {
    let visual: AgentPreviewVisualSnapshot
    let surface: AgentPreviewSurface

    private let titlebarHeight: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = min(
                180,
                max(124, geometry.size.width * 0.2)
            )

            ZStack(alignment: .topLeading) {
                visual.background
                wallpaperLayer(
                    size: geometry.size,
                    sidebarWidth: sidebarWidth
                )

                HStack(spacing: 0) {
                    sidebar
                        .frame(width: sidebarWidth)

                    ZStack {
                        visual.contentBackground
                        mainSurface
                            .padding(.top, titlebarHeight)
                    }
                }

                titlebar
                    .frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .font(.system(size: 12))
        .foregroundStyle(visual.textPrimary)
        .background(visual.background)
    }

    @ViewBuilder
    private func wallpaperLayer(
        size: CGSize,
        sidebarWidth: CGFloat
    ) -> some View {
        if visual.wallpaperScope == .mainContent {
            HStack(spacing: 0) {
                Color.clear.frame(width: sidebarWidth)
                AgentWallpaperView(visual: visual)
            }
            .frame(width: size.width, height: size.height)
        } else {
            AgentWallpaperView(visual: visual)
                .frame(width: size.width, height: size.height)
        }
    }

    private var titlebar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.34))
                Circle().fill(Color(red: 1, green: 0.75, blue: 0.23))
                Circle().fill(Color(red: 0.18, green: 0.78, blue: 0.35))
            }
            .frame(width: 42, height: 10)

            Image(systemName: "sidebar.left")
            Image(systemName: "chevron.left")
            Image(systemName: "chevron.right").opacity(0.4)
            Spacer()

            if surface == .chat {
                VStack(spacing: 1) {
                    Text(visual.themeName)
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
        .frame(height: titlebarHeight)
        .background(visual.titlebarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(visual.border.opacity(0.8))
                .frame(height: 1)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Codex").fontWeight(.semibold)
                Spacer()
                Image(systemName: "magnifyingglass")
            }
            .padding(.bottom, 10)

            sidebarRow("square.and.pencil", "New task")
            sidebarRow("clock", "Scheduled")
            sidebarRow("at", "Plugins")
            sidebarRow("arrow.triangle.pull", "Pull requests")

            Text("PROJECTS")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(visual.textSecondary)
                .padding(.top, 12)

            sidebarRow("folder", visual.themeName, selected: true)
            sidebarRow("circle.fill", "Theme design", smallIcon: true)
            sidebarRow("circle.fill", "Preview iterations", smallIcon: true)

            Spacer()
            sidebarRow("gearshape", "Settings")
        }
        .foregroundStyle(visual.textPrimary)
        .padding(.horizontal, 14)
        .padding(.top, titlebarHeight + 12)
        .padding(.bottom, 14)
        .background(visual.sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle().fill(visual.border).frame(width: visual.borderWidth)
        }
    }

    private func sidebarRow(
        _ icon: String,
        _ text: String,
        selected: Bool = false,
        smallIcon: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: smallIcon ? 5 : 11))
                .frame(width: 14)
            Text(text).lineLimit(1)
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(
            selected ? visual.textPrimary : visual.textSecondary
        )
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(selected ? visual.selection : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var mainSurface: some View {
        switch surface {
        case .home:
            homeSurface
        case .chat:
            chatSurface
        }
    }

    private var homeSurface: some View {
        GeometryReader { geometry in
            VStack(spacing: 18) {
                Spacer(minLength: 18)

                centerPanel {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundStyle(visual.accent)
                        Text("What should we build?")
                            .font(.system(size: 26, weight: .regular))
                        Text("Designing “\(visual.themeName)”")
                            .font(.system(size: 11))
                            .foregroundStyle(visual.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: min(680, geometry.size.width - 40))

                Spacer()

                if geometry.size.height > 330 {
                    HStack(spacing: 10) {
                        suggestion("sparkles", "Explore code")
                        suggestion("hammer", "Build a feature")
                        suggestion("paintpalette", "Refine theme")
                    }
                    .frame(maxWidth: min(680, geometry.size.width - 40))
                }

                composer(prompt: "Do anything")
                    .frame(maxWidth: min(680, geometry.size.width - 40))
                    .padding(.bottom, 16)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var chatSurface: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    centerPanel {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(
                                "Make the customization as flexible as possible."
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(visual.textPrimary.opacity(0.07))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .trailing
                            )

                            Text(
                                "I’ll design the theme, render both appearances, "
                                    + "and iterate on contrast and hierarchy."
                            )
                            .lineSpacing(4)

                            codeCard

                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(visual.success)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Preview rendered")
                                        .fontWeight(.semibold)
                                    Text("Ready for visual evaluation")
                                        .foregroundStyle(
                                            visual.textSecondary
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(
                        width: min(
                            680,
                            max(240, geometry.size.width - 54)
                        )
                    )
                    .padding(.top, 28)

                    Spacer(minLength: 126)
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )

                composer(prompt: "Ask Codex anything")
                    .frame(maxWidth: min(600, geometry.size.width - 44))
                    .padding(.bottom, 22)
            }
        }
    }

    private func suggestion(_ icon: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(visual.accent)
                .font(.system(size: 15))
            Spacer(minLength: 0)
            Text(title)
                .font(.system(size: 10, weight: .medium))
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(11)
        .background(visual.cardBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: visual.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: visual.cornerRadius)
                .stroke(visual.border, lineWidth: visual.borderWidth)
        }
        .shadow(
            color: .black.opacity(visual.shadowOpacity * 0.65),
            radius: visual.shadowRadius * 0.45,
            y: 4
        )
    }

    private var codeCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("theme.json")
                    .font(.caption)
                    .foregroundStyle(visual.textSecondary)
                Spacer()
                Image(systemName: "doc.on.doc")
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(visual.textPrimary.opacity(0.04))

            VStack(alignment: .leading, spacing: 2) {
                Text("{").foregroundStyle(visual.codeText)
                HStack(spacing: 0) {
                    Text("  \"appearance\"").foregroundStyle(visual.accent)
                    Text(": ").foregroundStyle(visual.codeText)
                    Text("\"preview\"").foregroundStyle(visual.success)
                }
                Text("}").foregroundStyle(visual.codeText)
            }
            .font(.system(size: 11, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(visual.codeBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: max(7, visual.cornerRadius - 3))
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: max(7, visual.cornerRadius - 3)
            )
            .stroke(visual.border, lineWidth: visual.borderWidth)
        }
    }

    private func composer(prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(prompt)
                .foregroundStyle(visual.textSecondary)
                .padding(.horizontal, 14)
                .padding(.top, 13)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)

            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text("Theme workspace")
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(visual.controlBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Spacer()
                Text("5.6")
                    .font(.system(size: 9))
                Circle()
                    .fill(visual.actionBackground)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.caption.bold())
                            .foregroundStyle(visual.actionForeground)
                    }
            }
            .foregroundStyle(visual.textSecondary)
            .padding(.horizontal, 14)
            .padding(.bottom, 9)
        }
        .frame(height: 78)
        .background(visual.composerBackground)
        .clipShape(RoundedRectangle(cornerRadius: visual.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: visual.cornerRadius)
                .stroke(visual.border, lineWidth: visual.borderWidth)
        }
        .shadow(
            color: .black.opacity(visual.shadowOpacity),
            radius: visual.shadowRadius,
            y: 8
        )
    }

    @ViewBuilder
    private func centerPanel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if visual.centerPanelEnabled {
            content()
                .padding(
                    .horizontal,
                    visual.centerPanelHorizontalPadding
                )
                .padding(.vertical, visual.centerPanelVerticalPadding)
                .background(visual.centerPanelBackground)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: visual.centerPanelCornerRadius
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: visual.centerPanelCornerRadius
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
        }
    }
}

private struct AgentWallpaperView: View {
    let visual: AgentPreviewVisualSnapshot

    var body: some View {
        ZStack {
            visual.background

            if let image = visual.wallpaperImage,
               let variant = visual.skinVariant {
                wallpaper(image: image, variant: variant)
            }

            if let variant = visual.skinVariant {
                AgentCSSColor.color(
                    variant.overlayColor,
                    fallback: .clear
                )
                .opacity(clamp(variant.overlayOpacity))

                scrim(variant)
                vignette(variant)
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func wallpaper(
        image: NSImage,
        variant: ThemeSkinVariant
    ) -> some View {
        GeometryReader { geometry in
            switch variant.imageFit {
            case .tile:
                Rectangle()
                    .fill(
                        ImagePaint(
                            image: Image(nsImage: image),
                            sourceRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                            scale: max(0.2, variant.zoom)
                        )
                    )
                    .modifier(AgentImageTreatment(variant: variant))

            case .cover, .contain, .fill, .fitWidth, .fitHeight, .original:
                let overscan =
                    variant.imageBlur > 0
                    && (variant.imageFit == .cover || variant.imageFit == .fill)
                    ? CGFloat(variant.imageBlur * 2 + 4)
                    : 0
                let renderSize = CGSize(
                    width: geometry.size.width + overscan * 2,
                    height: geometry.size.height + overscan * 2
                )
                let layout = AgentWallpaperLayout.resolve(
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
                    .modifier(AgentImageTreatment(variant: variant))
                    .frame(width: renderSize.width, height: renderSize.height)
                    .clipped()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
            }
        }
    }

    @ViewBuilder
    private func scrim(_ variant: ThemeSkinVariant) -> some View {
        if variant.scrimDirection != .none, variant.scrimOpacity > 0 {
            LinearGradient(
                stops: [
                    .init(
                        color: .black.opacity(clamp(variant.scrimOpacity)),
                        location: 0
                    ),
                    .init(color: .clear, location: 0.62),
                    .init(color: .clear, location: 1)
                ],
                startPoint: scrimStart(variant.scrimDirection),
                endPoint: scrimEnd(variant.scrimDirection)
            )
        }
    }

    private func vignette(_ variant: ThemeSkinVariant) -> some View {
        RadialGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.35),
                .init(
                    color: .black.opacity(clamp(variant.vignetteOpacity)),
                    location: 1
                )
            ],
            center: .center,
            startRadius: 0,
            endRadius: 520
        )
    }

    private func scrimStart(
        _ direction: ThemeSkinScrimDirection
    ) -> UnitPoint {
        switch direction {
        case .left: return .leading
        case .right: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        case .none: return .center
        }
    }

    private func scrimEnd(
        _ direction: ThemeSkinScrimDirection
    ) -> UnitPoint {
        switch direction {
        case .left: return .trailing
        case .right: return .leading
        case .top: return .bottom
        case .bottom: return .top
        case .none: return .center
        }
    }
}

private struct AgentImageTreatment: ViewModifier {
    let variant: ThemeSkinVariant

    func body(content: Content) -> some View {
        content
            .blur(radius: max(0, variant.imageBlur))
            .brightness(max(-1, min(1, variant.brightness - 1)))
            .contrast(max(0, variant.contrast))
            .saturation(max(0, variant.saturation))
            .opacity(clamp(variant.imageOpacity))
            .blendMode(blendMode)
    }

    private var blendMode: BlendMode {
        switch variant.blendMode {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .softLight: return .softLight
        }
    }
}

private enum AgentWallpaperLayout {
    struct Resolution {
        var renderedSize: CGSize
        var offset: CGSize
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
            return Resolution(renderedSize: containerSize, offset: .zero)
        }

        let safeZoom = max(0.01, zoom)
        let renderedSize: CGSize
        switch fit {
        case .fill:
            renderedSize = CGSize(
                width: containerSize.width * safeZoom,
                height: containerSize.height * safeZoom
            )
        case .cover, .contain, .fitWidth, .fitHeight, .original, .tile:
            let widthScale = containerSize.width / imageSize.width
            let heightScale = containerSize.height / imageSize.height
            let baseScale: CGFloat
            switch fit {
            case .cover: baseScale = max(widthScale, heightScale)
            case .contain: baseScale = min(widthScale, heightScale)
            case .fitWidth: baseScale = widthScale
            case .fitHeight: baseScale = heightScale
            case .original, .tile: baseScale = 1
            case .fill: baseScale = 1
            }
            renderedSize = CGSize(
                width: imageSize.width * baseScale * safeZoom,
                height: imageSize.height * baseScale * safeZoom
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

private struct AgentPreviewVisualSnapshot {
    var themeName: String
    var background: Color
    var contentBackground: Color
    var sidebarBackground: Color
    var titlebarBackground: Color
    var composerBackground: Color
    var cardBackground: Color
    var controlBackground: Color
    var codeBackground: Color
    var codeText: Color
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    var success: Color
    var border: Color
    var selection: Color
    var actionBackground: Color
    var actionForeground: Color
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var shadowOpacity: Double
    var shadowRadius: CGFloat

    var centerPanelEnabled: Bool
    var centerPanelBackground: Color
    var centerPanelBorder: Color
    var centerPanelShadow: Color
    var centerPanelBorderWidth: CGFloat
    var centerPanelCornerRadius: CGFloat
    var centerPanelShadowOpacity: Double
    var centerPanelShadowRadius: CGFloat
    var centerPanelShadowOffsetX: CGFloat
    var centerPanelShadowOffsetY: CGFloat
    var centerPanelHorizontalPadding: CGFloat
    var centerPanelVerticalPadding: CGFloat

    var skinVariant: ThemeSkinVariant?
    var wallpaperScope: ThemeSkinWallpaperScope
    var wallpaperImage: NSImage?
    var requestedWallpaperAssetID: UUID?
    var wallpaperAssetWasMissing: Bool
    var wallpaperAssetWasInvalid: Bool
    var wallpaperAssetRejectedSize: (width: Int, height: Int)?
    var unsupportedColorValues: [String]

    static let maximumWallpaperSourcePixels = 100_000_000
    private static let maximumWallpaperSourceDimension = 32_768

    init(
        theme: ThemeDocument,
        appearance: AgentPreviewAppearance,
        maximumWallpaperPixelDimension: Int
    ) {
        themeName = theme.metadata.name
        let applicableVariables = theme.layers
            .filter { layer in
                guard layer.isEnabled else { return false }
                switch layer.condition {
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

        func semantic(
            _ role: ThemeSemanticRole,
            fallback: String
        ) -> String {
            applicableVariables.last {
                $0.semanticRole == role
            }?.value ?? fallback
        }

        func token(_ name: String, fallback: String) -> String {
            applicableVariables.last {
                $0.resolvedName == name
            }?.value ?? fallback
        }

        let isDark = appearance == .dark
        let baseBackground = semantic(
            .backgroundPrimary,
            fallback: isDark ? "#111214" : "#F5F5F3"
        )
        let baseSidebar = semantic(
            .backgroundSecondary,
            fallback: isDark ? "#1A1B1E" : "#EAEAE7"
        )
        let baseSurface = semantic(
            .surface,
            fallback: isDark ? "#25262A" : "#FFFFFF"
        )
        let baseText = semantic(
            .textPrimary,
            fallback: isDark ? "#F5F5F4" : "#1C1C1B"
        )
        let baseSecondaryText = semantic(
            .textSecondary,
            fallback: isDark ? "#A8A8A4" : "#676762"
        )
        let baseAccent = semantic(
            .accent,
            fallback: isDark ? "#6CA9FF" : "#1769D2"
        )
        let baseBorder = semantic(
            .border,
            fallback: isDark
                ? "rgba(255,255,255,0.14)"
                : "rgba(0,0,0,0.14)"
        )
        let baseSuccess = semantic(
            .success,
            fallback: isDark ? "#56D385" : "#168447"
        )

        let activeSkin = theme.imageSkin.flatMap { $0.isEnabled ? $0 : nil }
        let variant = activeSkin?.variant(for: appearance.skinAppearance)
        skinVariant = variant
        wallpaperScope = activeSkin?.wallpaperScope ?? .fullWindow
        let requestedCodeBackground = token(
            "--color-token-text-code-block-background",
            fallback: isDark ? "#0C0D0F" : "#ECECE8"
        )
        let requestedCodeText = token(
            "--color-token-editor-foreground",
            fallback: baseText
        )

        var requestedColors: [String] = [
            baseBackground,
            baseSidebar,
            baseSurface,
            baseText,
            baseSecondaryText,
            baseAccent,
            baseBorder,
            baseSuccess,
            requestedCodeBackground,
            requestedCodeText
        ]
        if let variant {
            requestedColors += [
                variant.backgroundColor,
                variant.overlayColor,
                variant.primaryTextColor,
                variant.secondaryTextColor,
                variant.accentColor,
                variant.sidebarTint,
                variant.contentTint,
                variant.composerTint,
                variant.cardTint,
                variant.borderColor,
                variant.centerPanelTint,
                variant.centerPanelBorderColor,
                variant.centerPanelShadowColor
            ]
            if let value = variant.composerActionBackgroundColor {
                requestedColors.append(value)
            }
            if let value = variant.composerActionIconColor {
                requestedColors.append(value)
            }
        }
        unsupportedColorValues = Array(
            Set(
                requestedColors.filter {
                    AgentCSSColor.nsColor($0) == nil
                }
            )
        ).sorted()

        let fallbackBackground: Color = isDark
            ? Color(white: 0.07)
            : Color(white: 0.96)
        background = AgentCSSColor.color(
            variant?.backgroundColor ?? baseBackground,
            fallback: fallbackBackground
        )

        let semanticText = AgentCSSColor.color(
            baseText,
            fallback: isDark ? .white : .black
        )
        let semanticSecondaryText = AgentCSSColor.color(
            baseSecondaryText,
            fallback: .gray
        )
        let semanticAccent = AgentCSSColor.color(
            baseAccent,
            fallback: .blue
        )
        let semanticSurface = AgentCSSColor.color(
            baseSurface,
            fallback: isDark
                ? Color(white: 0.15)
                : .white
        )

        if let variant, let activeSkin {
            textPrimary = AgentCSSColor.color(
                variant.primaryTextColor,
                fallback: semanticText
            )
            textSecondary = AgentCSSColor.color(
                variant.secondaryTextColor,
                fallback: semanticSecondaryText
            )
            accent = AgentCSSColor.color(
                variant.accentColor,
                fallback: semanticAccent
            )
            contentBackground = activeSkin.targets.content
                ? AgentCSSColor.color(
                    variant.contentTint,
                    fallback: .clear
                ).opacity(clamp(variant.contentOpacity))
                : (activeSkin.wallpaperScope == .mainContent
                    ? .clear
                    : AgentCSSColor.color(
                        baseBackground,
                        fallback: background
                    ))
            sidebarBackground = activeSkin.targets.sidebar
                ? AgentCSSColor.color(
                    variant.sidebarTint,
                    fallback: .clear
                ).opacity(clamp(variant.sidebarOpacity))
                : AgentCSSColor.color(
                    baseSidebar,
                    fallback: background.opacity(0.94)
                )
            titlebarBackground = activeSkin.targets.titlebar
                ? AgentCSSColor.color(
                    variant.contentTint,
                    fallback: .clear
                ).opacity(clamp(variant.contentOpacity))
                : background.opacity(0.94)
            composerBackground = activeSkin.targets.composer
                ? AgentCSSColor.color(
                    variant.composerTint,
                    fallback: semanticSurface
                ).opacity(clamp(variant.composerOpacity))
                : semanticSurface.opacity(0.92)
            cardBackground = activeSkin.targets.cards
                ? AgentCSSColor.color(
                    variant.cardTint,
                    fallback: semanticSurface
                ).opacity(clamp(variant.cardOpacity))
                : semanticSurface.opacity(0.88)
            border = AgentCSSColor.color(
                variant.borderColor,
                fallback: textPrimary
            ).opacity(clamp(variant.borderOpacity))
            borderWidth = max(0, activeSkin.glass.borderWidth)
            cornerRadius = max(0, activeSkin.glass.cornerRadius)
            shadowOpacity = clamp(activeSkin.glass.shadowOpacity)
            shadowRadius = max(0, activeSkin.glass.shadowBlur)
            controlBackground = composerBackground.opacity(0.82)
            selection = accent.opacity(0.17)

            actionBackground = AgentCSSColor.color(
                variant.composerActionBackgroundColor
                    ?? variant.primaryTextColor,
                fallback: textPrimary
            )
            actionForeground = AgentCSSColor.color(
                variant.composerActionIconColor
                    ?? variant.cardTint,
                fallback: cardBackground
            ).opacity(clamp(variant.cardOpacity))
        } else {
            textPrimary = semanticText
            textSecondary = semanticSecondaryText
            accent = semanticAccent
            contentBackground = AgentCSSColor.color(
                baseBackground,
                fallback: background
            )
            sidebarBackground = AgentCSSColor.color(
                baseSidebar,
                fallback: background.opacity(0.94)
            )
            titlebarBackground = background.opacity(0.96)
            composerBackground = semanticSurface.opacity(0.92)
            cardBackground = semanticSurface.opacity(0.88)
            controlBackground = semanticSurface.opacity(0.82)
            border = AgentCSSColor.color(
                baseBorder,
                fallback: textPrimary.opacity(0.14)
            )
            selection = accent.opacity(0.16)
            actionBackground = accent
            actionForeground = .white
            borderWidth = 1
            cornerRadius = max(
                0,
                token(
                    "--codex-corner-radius-scale",
                    fallback: "12"
                ).agentFirstCSSNumber ?? 12
            )
            shadowOpacity = 0.14
            shadowRadius = 16
        }

        success = AgentCSSColor.color(
            baseSuccess,
            fallback: .green
        )
        codeBackground = AgentCSSColor.color(
            requestedCodeBackground,
            fallback: isDark ? .black.opacity(0.72) : .white.opacity(0.78)
        )
        codeText = AgentCSSColor.color(
            requestedCodeText,
            fallback: textPrimary
        )

        let centerPanel = activeSkin?.centerPanel ?? ThemeSkinCenterPanel()
        centerPanelEnabled = activeSkin != nil && centerPanel.isEnabled
        centerPanelBackground = AgentCSSColor.color(
            variant?.centerPanelTint ?? "#000000",
            fallback: .clear
        ).opacity(clamp(variant?.centerPanelOpacity ?? 0))
        centerPanelBorder = AgentCSSColor.color(
            variant?.centerPanelBorderColor ?? "#000000",
            fallback: .clear
        ).opacity(clamp(variant?.centerPanelBorderOpacity ?? 0))
        centerPanelShadow = AgentCSSColor.color(
            variant?.centerPanelShadowColor ?? "#000000",
            fallback: .black
        )
        centerPanelBorderWidth = max(0, centerPanel.borderWidth)
        centerPanelCornerRadius = max(0, centerPanel.cornerRadius)
        centerPanelShadowOpacity = clamp(
            variant?.centerPanelShadowOpacity ?? 0
        )
        centerPanelShadowRadius = max(0, centerPanel.shadowBlur)
        centerPanelShadowOffsetX = centerPanel.shadowOffsetX
        centerPanelShadowOffsetY = centerPanel.shadowOffsetY
        centerPanelHorizontalPadding = max(
            0,
            centerPanel.horizontalPadding
        )
        centerPanelVerticalPadding = max(0, centerPanel.verticalPadding)

        requestedWallpaperAssetID = variant?.backgroundAssetID
        wallpaperAssetWasMissing = false
        wallpaperAssetWasInvalid = false
        wallpaperAssetRejectedSize = nil
        if let assetID = requestedWallpaperAssetID {
            if let asset = theme.assets.first(where: { $0.id == assetID }) {
                guard let data = asset.decodedData else {
                    wallpaperImage = nil
                    wallpaperAssetWasInvalid = true
                    return
                }
                switch Self.decodeWallpaper(
                    data,
                    mediaType: asset.mediaType,
                    maximumPixelDimension: maximumWallpaperPixelDimension
                ) {
                case let .image(image):
                    wallpaperImage = image
                case .invalid:
                    wallpaperImage = nil
                    wallpaperAssetWasInvalid = true
                case let .tooLarge(width, height):
                    wallpaperImage = nil
                    wallpaperAssetRejectedSize = (width, height)
                }
            } else {
                wallpaperImage = nil
                wallpaperAssetWasMissing = true
            }
        } else {
            wallpaperImage = nil
        }
    }

    private enum WallpaperDecodeResult {
        case image(NSImage)
        case invalid
        case tooLarge(width: Int, height: Int)
    }

    private static func decodeWallpaper(
        _ data: Data,
        mediaType: String,
        maximumPixelDimension: Int
    ) -> WallpaperDecodeResult {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ),
        let sourceType = CGImageSourceGetType(source) as String?,
        sourceTypeMatches(sourceType, mediaType: mediaType),
        CGImageSourceGetCount(source) > 0,
        let properties = CGImageSourceCopyPropertiesAtIndex(
            source,
            0,
            nil
        ) as? [CFString: Any],
        let width = (
            properties[kCGImagePropertyPixelWidth] as? NSNumber
        )?.intValue,
        let height = (
            properties[kCGImagePropertyPixelHeight] as? NSNumber
        )?.intValue,
        width > 0,
        height > 0 else {
            return .invalid
        }

        let pixels = Int64(width) * Int64(height)
        guard width <= maximumWallpaperSourceDimension,
              height <= maximumWallpaperSourceDimension,
              pixels <= Int64(maximumWallpaperSourcePixels) else {
            return .tooLarge(width: width, height: height)
        }

        let thumbnailSize = min(
            8_192,
            max(240, maximumPixelDimension)
        )
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return .invalid
        }
        return .image(
            NSImage(
                cgImage: image,
                size: NSSize(width: image.width, height: image.height)
            )
        )
    }

    private static func sourceTypeMatches(
        _ sourceType: String,
        mediaType: String
    ) -> Bool {
        let expected: Set<String>
        switch mediaType.lowercased() {
        case "image/png":
            expected = ["public.png"]
        case "image/jpeg":
            expected = ["public.jpeg", "public.jpg"]
        case "image/gif":
            expected = ["com.compuserve.gif"]
        case "image/webp":
            expected = ["org.webmproject.webp", "public.webp"]
        case "image/avif":
            expected = ["public.avif", "org.aomedia.avif"]
        default:
            return false
        }
        return expected.contains(sourceType.lowercased())
    }
}

private enum AgentCSSColor {
    static func color(_ value: String, fallback: Color) -> Color {
        guard let parsed = nsColor(value) else { return fallback }
        return Color(nsColor: parsed)
    }

    static func nsColor(_ rawValue: String) -> NSColor? {
        let value = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        switch value.lowercased() {
        case "transparent", "clear":
            return NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)
        case "black":
            return .black
        case "white":
            return .white
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "gray", "grey":
            return .gray
        default:
            break
        }

        if value.hasPrefix("#") {
            var hex = String(value.dropFirst())
            guard [3, 4, 6, 8].contains(hex.count) else { return nil }
            if hex.count == 3 || hex.count == 4 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard let number = UInt64(hex, radix: 16) else { return nil }
            if hex.count == 8 {
                return NSColor(
                    srgbRed: CGFloat((number >> 24) & 0xff) / 255,
                    green: CGFloat((number >> 16) & 0xff) / 255,
                    blue: CGFloat((number >> 8) & 0xff) / 255,
                    alpha: CGFloat(number & 0xff) / 255
                )
            }
            return NSColor(
                srgbRed: CGFloat((number >> 16) & 0xff) / 255,
                green: CGFloat((number >> 8) & 0xff) / 255,
                blue: CGFloat(number & 0xff) / 255,
                alpha: 1
            )
        }

        let pattern =
            #"^rgba?\s*\(\s*([+-]?[\d.]+)\s*,\s*([+-]?[\d.]+)\s*,\s*([+-]?[\d.]+)(?:\s*,\s*([+-]?[\d.]+))?\s*\)$"#
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ),
        let match = expression.firstMatch(
            in: value,
            range: NSRange(value.startIndex..., in: value)
        ),
        let red = capture(1, match: match, in: value),
        let green = capture(2, match: match, in: value),
        let blue = capture(3, match: match, in: value)
        else {
            return nil
        }
        let alpha = capture(4, match: match, in: value) ?? 1
        return NSColor(
            srgbRed: clamp(red / 255),
            green: clamp(green / 255),
            blue: clamp(blue / 255),
            alpha: clamp(alpha)
        )
    }

    private static func capture(
        _ index: Int,
        match: NSTextCheckingResult,
        in value: String
    ) -> Double? {
        guard match.range(at: index).location != NSNotFound,
              let range = Range(match.range(at: index), in: value)
        else {
            return nil
        }
        return Double(value[range])
    }
}

private extension String {
    var agentFirstCSSNumber: CGFloat? {
        let allowed = CharacterSet(charactersIn: "-.0123456789")
        let prefix = unicodeScalars.prefix { allowed.contains($0) }
        guard !prefix.isEmpty else { return nil }
        return Double(String(String.UnicodeScalarView(prefix))).map {
            CGFloat($0)
        }
    }
}

private func clamp(_ value: Double) -> Double {
    max(0, min(1, value))
}
