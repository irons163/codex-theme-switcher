import AppKit
import CodexThemeSwitcherCore
import SwiftUI
import XCTest
@testable import CodexThemeSwitcher

final class ThemePreviewRenderTests: XCTestCase {
    func testPreviewWallpaperScopeUsesMainContentWidthWhenRequested() {
        let sidebarWidth = ThemePreviewLayout.sidebarWidth(
            containerWidth: 680
        )

        XCTAssertEqual(sidebarWidth, 124, accuracy: 0.001)
        XCTAssertEqual(
            ThemePreviewLayout.wallpaperWidth(
                containerWidth: 680,
                sidebarWidth: sidebarWidth,
                scope: .fullWindow
            ),
            680,
            accuracy: 0.001
        )
        XCTAssertEqual(
            ThemePreviewLayout.wallpaperWidth(
                containerWidth: 680,
                sidebarWidth: sidebarWidth,
                scope: .mainContent
            ),
            556,
            accuracy: 0.001
        )
    }

    func testWallpaperBlurOverscanMatchesCompilerRule() {
        XCTAssertEqual(
            SkinWallpaperLayout.blurOverscan(
                fit: .cover,
                imageBlur: 12
            ),
            28,
            accuracy: 0.001
        )
        XCTAssertEqual(
            SkinWallpaperLayout.blurOverscan(
                fit: .fill,
                imageBlur: 6.5
            ),
            17,
            accuracy: 0.001
        )
        XCTAssertEqual(
            SkinWallpaperLayout.blurOverscan(
                fit: .contain,
                imageBlur: 12
            ),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            SkinWallpaperLayout.blurOverscan(
                fit: .cover,
                imageBlur: 0
            ),
            0,
            accuracy: 0.001
        )
    }

    func testSkinWallpaperLayoutResolvesNewIntrinsicSizingModes() {
        let imageSize = CGSize(width: 400, height: 200)
        let containerSize = CGSize(width: 300, height: 300)

        let fitWidth = SkinWallpaperLayout.resolve(
            imageSize: imageSize,
            containerSize: containerSize,
            fit: .fitWidth,
            zoom: 1,
            positionX: 0.5,
            positionY: 0.5
        )
        let fitHeight = SkinWallpaperLayout.resolve(
            imageSize: imageSize,
            containerSize: containerSize,
            fit: .fitHeight,
            zoom: 1,
            positionX: 0.5,
            positionY: 0.5
        )
        let original = SkinWallpaperLayout.resolve(
            imageSize: imageSize,
            containerSize: containerSize,
            fit: .original,
            zoom: 1,
            positionX: 0.5,
            positionY: 0.5
        )

        assert(
            fitWidth,
            renderedSize: CGSize(width: 300, height: 150),
            offset: .zero
        )
        assert(
            fitHeight,
            renderedSize: CGSize(width: 600, height: 300),
            offset: .zero
        )
        assert(
            original,
            renderedSize: imageSize,
            offset: .zero
        )
    }

    func testSkinWallpaperLayoutAppliesZoomBeforePositionTravel() {
        let resolution = SkinWallpaperLayout.resolve(
            imageSize: CGSize(width: 400, height: 200),
            containerSize: CGSize(width: 300, height: 300),
            fit: .fitWidth,
            zoom: 1.5,
            positionX: 0.25,
            positionY: 0.75
        )

        assert(
            resolution,
            renderedSize: CGSize(width: 450, height: 225),
            offset: CGSize(width: 37.5, height: 18.75)
        )
    }

    func testSkinWallpaperLayoutPositionsOriginalSizeAtEdges() {
        let topLeft = SkinWallpaperLayout.resolve(
            imageSize: CGSize(width: 400, height: 200),
            containerSize: CGSize(width: 300, height: 300),
            fit: .original,
            zoom: 1,
            positionX: 0,
            positionY: 0
        )
        let bottomRight = SkinWallpaperLayout.resolve(
            imageSize: CGSize(width: 400, height: 200),
            containerSize: CGSize(width: 300, height: 300),
            fit: .original,
            zoom: 1,
            positionX: 1,
            positionY: 1
        )

        assert(
            topLeft,
            renderedSize: CGSize(width: 400, height: 200),
            offset: CGSize(width: 50, height: -50)
        )
        assert(
            bottomRight,
            renderedSize: CGSize(width: 400, height: 200),
            offset: CGSize(width: -50, height: 50)
        )
    }

    @MainActor
    func testImageSkinHomePreviewRendersAtExpectedSize() throws {
        let wallpaper = try makeWallpaper()
        let asset = ThemeAsset(
            name: "preview-wallpaper.png",
            mediaType: "image/png",
            data: wallpaper
        )
        var skin = ThemeImageSkin()
        skin.wallpaperScope = .mainContent
        skin.dark.backgroundAssetID = asset.id
        skin.dark.positionX = 0.68
        skin.dark.scrimOpacity = 0.58
        skin.dark.vignetteOpacity = 0.34

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.assets = [asset]
        theme.imageSkin = skin

        let renderer = ImageRenderer(
            content: ThemePreviewView(
                theme: theme,
                appearance: .dark,
                surface: .home
            )
            .environment(\.colorScheme, .dark)
            .frame(width: 680, height: 420)
        )
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)

        XCTAssertEqual(image.size.width, 680, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 420, accuracy: 0.5)

        if let destination = ProcessInfo.processInfo.environment[
            "CTS_PREVIEW_SNAPSHOT"
        ],
        let data = image.pngData {
            try data.write(to: URL(fileURLWithPath: destination))
        }
    }

    @MainActor
    func testLightImageSkinHomePreviewRendersAtExpectedSize() throws {
        let wallpaper = try makeWallpaper()
        let asset = ThemeAsset(
            name: "preview-wallpaper.png",
            mediaType: "image/png",
            data: wallpaper
        )
        var skin = ThemeImageSkin()
        skin.light.backgroundAssetID = asset.id
        skin.light.positionX = 0.68
        skin.light.scrimOpacity = 0.12

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.assets = [asset]
        theme.imageSkin = skin

        let renderer = ImageRenderer(
            content: ThemePreviewView(
                theme: theme,
                appearance: .light,
                surface: .home
            )
            .environment(\.colorScheme, .light)
            .frame(width: 680, height: 420)
        )
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.nsImage)

        XCTAssertEqual(image.size.width, 680, accuracy: 0.5)
        XCTAssertEqual(image.size.height, 420, accuracy: 0.5)

        if let destination = ProcessInfo.processInfo.environment[
            "CTS_PREVIEW_LIGHT_SNAPSHOT"
        ],
        let data = image.pngData {
            try data.write(to: URL(fileURLWithPath: destination))
        }
    }

    @MainActor
    func testCenterPanelPreviewRendersHomeAndChatSurfaces() throws {
        var skin = ThemeImageSkin()
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 24,
            backdropSaturation: 1.35,
            borderWidth: 2,
            cornerRadius: 28,
            shadowBlur: 40,
            shadowOffsetX: 8,
            shadowOffsetY: 16,
            maximumWidth: 520,
            horizontalPadding: 32,
            verticalPadding: 24
        )
        skin.dark.centerPanelTint = "#17110D"
        skin.dark.centerPanelOpacity = 0.72
        skin.dark.centerPanelBorderColor = "#E4B768"
        skin.dark.centerPanelBorderOpacity = 0.74
        skin.dark.centerPanelShadowColor = "#000000"
        skin.dark.centerPanelShadowOpacity = 0.48

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.imageSkin = skin

        for surface in ThemePreviewSurface.allCases {
            let renderer = ImageRenderer(
                content: ThemePreviewView(
                    theme: theme,
                    appearance: .dark,
                    surface: surface
                )
                .environment(\.colorScheme, .dark)
                .frame(width: 680, height: 420)
            )
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.nsImage)

            XCTAssertEqual(image.size.width, 680, accuracy: 0.5)
            XCTAssertEqual(image.size.height, 420, accuracy: 0.5)

            if let directory = ProcessInfo.processInfo.environment[
                "CTS_CENTER_PANEL_SNAPSHOT_DIR"
            ],
            let data = image.pngData {
                let url = URL(fileURLWithPath: directory)
                    .appendingPathComponent("\(surface.rawValue).png")
                try data.write(to: url)
            }
        }

        theme.imageSkin?.centerPanel.isEnabled = false
        let legacyRenderer = ImageRenderer(
            content: ThemePreviewView(
                theme: theme,
                appearance: .dark,
                surface: .chat
            )
            .environment(\.colorScheme, .dark)
            .frame(width: 680, height: 420)
        )
        legacyRenderer.scale = 1
        let legacyImage = try XCTUnwrap(legacyRenderer.nsImage)
        XCTAssertEqual(legacyImage.size.width, 680, accuracy: 0.5)
        XCTAssertEqual(legacyImage.size.height, 420, accuracy: 0.5)

        if let directory = ProcessInfo.processInfo.environment[
            "CTS_CENTER_PANEL_SNAPSHOT_DIR"
        ],
        let data = legacyImage.pngData {
            let url = URL(fileURLWithPath: directory)
                .appendingPathComponent("chat-legacy.png")
            try data.write(to: url)
        }
    }

    @MainActor
    func testVisualSnapshotPreservesExactBackdropParameters() {
        var skin = ThemeImageSkin()
        skin.glass.blurRadius = 13.5
        skin.glass.saturation = 1.42
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 0,
            backdropSaturation: 1.6,
            borderWidth: 2.25,
            cornerRadius: 31,
            shadowBlur: 44,
            shadowOffsetX: -7,
            shadowOffsetY: 12,
            maximumWidth: 930,
            horizontalPadding: 33,
            verticalPadding: 21
        )

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.imageSkin = skin

        let snapshot = ThemeVisualSnapshot(
            theme: theme,
            appearance: .light
        )

        XCTAssertEqual(snapshot.glassBackdropBlur, 13.5, accuracy: 0.001)
        XCTAssertEqual(
            snapshot.glassBackdropSaturation,
            1.42,
            accuracy: 0.001
        )
        XCTAssertEqual(
            snapshot.centerPanelBackdropBlur,
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            snapshot.centerPanelBackdropSaturation,
            1.6,
            accuracy: 0.001
        )
        XCTAssertTrue(snapshot.sidebarUsesBackdrop)
        XCTAssertTrue(snapshot.composerUsesBackdrop)
        XCTAssertTrue(snapshot.cardUsesBackdrop)
        XCTAssertTrue(snapshot.centerPanelUsesBackdrop)
    }

    @MainActor
    func testUnitBackdropSettingsDoNotAddPreviewMaterial() {
        var skin = ThemeImageSkin()
        skin.glass.blurRadius = 0
        skin.glass.saturation = 1
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 0,
            backdropSaturation: 1
        )

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.imageSkin = skin

        let snapshot = ThemeVisualSnapshot(
            theme: theme,
            appearance: .light
        )

        XCTAssertFalse(snapshot.sidebarUsesBackdrop)
        XCTAssertFalse(snapshot.composerUsesBackdrop)
        XCTAssertFalse(snapshot.cardUsesBackdrop)
        XCTAssertFalse(snapshot.centerPanelUsesBackdrop)
    }

    @MainActor
    func testSaturationOnlyPanelReusesAlignedBackdropWithoutMaterialTint()
        throws
    {
        let asset = ThemeAsset(
            name: "alignment-wallpaper.png",
            mediaType: "image/png",
            data: try makeGrayscaleWallpaper()
        )
        var skin = ThemeImageSkin()
        skin.light.backgroundAssetID = asset.id
        skin.light.imageFit = .fill
        skin.light.overlayOpacity = 0
        skin.light.scrimDirection = .none
        skin.light.scrimOpacity = 0
        skin.light.vignetteOpacity = 0
        skin.light.contentOpacity = 0
        skin.light.centerPanelOpacity = 0
        skin.light.centerPanelBorderOpacity = 0
        skin.light.centerPanelShadowOpacity = 0
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 0,
            backdropSaturation: 1.8,
            borderWidth: 0,
            cornerRadius: 0,
            shadowBlur: 0,
            shadowOffsetX: 0,
            shadowOffsetY: 0,
            maximumWidth: 520,
            horizontalPadding: 28,
            verticalPadding: 24
        )

        var enabledTheme = BuiltInThemes.paper
        enabledTheme.id = UUID()
        enabledTheme.assets = [asset]
        enabledTheme.imageSkin = skin

        var disabledTheme = enabledTheme
        disabledTheme.imageSkin?.centerPanel.isEnabled = false

        let enabledImage = try render(
            theme: enabledTheme,
            appearance: .light,
            surface: .home
        )
        let disabledImage = try render(
            theme: disabledTheme,
            appearance: .light,
            surface: .home
        )
        let samplePoint = CGPoint(x: 190, y: 330)
        let enabledColor = try pixelColor(
            in: enabledImage,
            at: samplePoint
        )
        let disabledColor = try pixelColor(
            in: disabledImage,
            at: samplePoint
        )

        XCTAssertEqual(
            enabledColor.redComponent,
            disabledColor.redComponent,
            accuracy: 0.02
        )
        XCTAssertEqual(
            enabledColor.greenComponent,
            disabledColor.greenComponent,
            accuracy: 0.02
        )
        XCTAssertEqual(
            enabledColor.blueComponent,
            disabledColor.blueComponent,
            accuracy: 0.02
        )
    }

    @MainActor
    func testDisabledTargetsKeepNativePreviewGeometry() {
        var skin = ThemeImageSkin()
        skin.glass = ThemeSkinGlass(
            blurRadius: 30,
            saturation: 1.8,
            borderWidth: 8,
            cornerRadius: 64,
            shadowOpacity: 0.9,
            shadowBlur: 70,
            textShadowOpacity: 0.4
        )
        skin.targets = ThemeSkinTargets(
            sidebar: false,
            content: true,
            titlebar: false,
            composer: false,
            cards: false,
            popovers: false,
            codeBlocks: false
        )

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.imageSkin = skin

        let snapshot = ThemeVisualSnapshot(
            theme: theme,
            appearance: .light
        )

        XCTAssertFalse(snapshot.sidebarUsesBackdrop)
        XCTAssertFalse(snapshot.composerUsesBackdrop)
        XCTAssertFalse(snapshot.cardUsesBackdrop)
        XCTAssertFalse(snapshot.codeUsesBackdrop)
        XCTAssertEqual(snapshot.sidebarBorderWidth, 1, accuracy: 0.001)
        XCTAssertEqual(snapshot.composerBorderWidth, 1, accuracy: 0.001)
        XCTAssertEqual(snapshot.cardBorderWidth, 1, accuracy: 0.001)
        XCTAssertEqual(snapshot.codeBorderWidth, 1, accuracy: 0.001)
        XCTAssertNotEqual(snapshot.resolvedComposerRadius, 64)
        XCTAssertNotEqual(snapshot.cardCornerRadius, 64)
        XCTAssertNotEqual(snapshot.codeCornerRadius, 64)
        XCTAssertEqual(snapshot.codeShadowOpacity, 0, accuracy: 0.001)
    }

    @MainActor
    func testWallpaperScopeStartsAtMainContentPixelBoundary() throws {
        let asset = ThemeAsset(
            name: "scope-wallpaper.png",
            mediaType: "image/png",
            data: try makeSolidWallpaper(color: .red)
        )
        var skin = ThemeImageSkin()
        skin.targets = ThemeSkinTargets(
            sidebar: false,
            content: true,
            titlebar: false,
            composer: false,
            cards: false,
            popovers: false,
            codeBlocks: false
        )
        skin.light.backgroundAssetID = asset.id
        skin.light.backgroundColor = "#000000"
        skin.light.imageFit = .fill
        skin.light.overlayOpacity = 0
        skin.light.scrimDirection = .none
        skin.light.scrimOpacity = 0
        skin.light.vignetteOpacity = 0
        skin.light.contentOpacity = 0

        var theme = BuiltInThemes.paper
        theme.id = UUID()
        theme.assets = [asset]

        skin.wallpaperScope = .mainContent
        theme.imageSkin = skin
        let mainContentImage = try renderBackdrop(theme: theme)

        skin.wallpaperScope = .fullWindow
        theme.imageSkin = skin
        let fullWindowImage = try renderBackdrop(theme: theme)

        let leftMainContent = try pixelColor(
            in: mainContentImage,
            at: CGPoint(x: 30, y: 165)
        )
        let rightMainContent = try pixelColor(
            in: mainContentImage,
            at: CGPoint(x: 220, y: 165)
        )
        let leftFullWindow = try pixelColor(
            in: fullWindowImage,
            at: CGPoint(x: 30, y: 165)
        )

        XCTAssertLessThan(leftMainContent.redComponent, 0.1)
        XCTAssertGreaterThan(rightMainContent.redComponent, 0.9)
        XCTAssertGreaterThan(leftFullWindow.redComponent, 0.9)
    }

    @MainActor
    func testCompactEditorHeightKeepsHomeAndChatContentVisible() throws {
        var skin = ThemeImageSkin()
        skin.centerPanel = ThemeSkinCenterPanel(
            isEnabled: true,
            backdropBlur: 12,
            backdropSaturation: 1.2,
            borderWidth: 2,
            cornerRadius: 24,
            shadowBlur: 24,
            shadowOffsetX: 0,
            shadowOffsetY: 8,
            maximumWidth: 560,
            horizontalPadding: 28,
            verticalPadding: 24
        )

        var theme = BuiltInThemes.midnight
        theme.id = UUID()
        theme.imageSkin = skin

        for surface in ThemePreviewSurface.allCases {
            let image = try render(
                theme: theme,
                appearance: .dark,
                surface: surface,
                size: CGSize(width: 680, height: 330)
            )
            XCTAssertEqual(image.size.height, 330, accuracy: 0.5)
            XCTAssertGreaterThan(
                try brightPixelCount(
                    in: image,
                    screenRect: CGRect(
                        x: 155,
                        y: 58,
                        width: 500,
                        height: 130
                    )
                ),
                100,
                "\(surface.rawValue) content disappeared at editor height"
            )

            if let directory = ProcessInfo.processInfo.environment[
                "CTS_COMPACT_PREVIEW_SNAPSHOT_DIR"
            ],
            let data = image.pngData {
                let url = URL(fileURLWithPath: directory)
                    .appendingPathComponent("\(surface.rawValue).png")
                try data.write(to: url)
            }
        }
    }

    @MainActor
    private func makeWallpaper() throws -> Data {
        let image = NSImage(size: NSSize(width: 1_600, height: 1_000))
        image.lockFocus()
        NSGradient(
            colors: [
                NSColor(
                    displayP3Red: 0.08,
                    green: 0.1,
                    blue: 0.16,
                    alpha: 1
                ),
                NSColor(
                    displayP3Red: 0.42,
                    green: 0.18,
                    blue: 0.12,
                    alpha: 1
                ),
                NSColor(
                    displayP3Red: 0.8,
                    green: 0.58,
                    blue: 0.22,
                    alpha: 1
                )
            ]
        )?.draw(
            in: NSRect(x: 0, y: 0, width: 1_600, height: 1_000),
            angle: 12
        )
        image.unlockFocus()
        return try XCTUnwrap(image.pngData)
    }

    @MainActor
    private func makeGrayscaleWallpaper() throws -> Data {
        let image = NSImage(size: NSSize(width: 680, height: 420))
        image.lockFocus()
        NSGradient(
            colors: [.black, .white]
        )?.draw(
            in: NSRect(x: 0, y: 0, width: 680, height: 420),
            angle: 0
        )
        image.unlockFocus()
        return try XCTUnwrap(image.pngData)
    }

    @MainActor
    private func makeSolidWallpaper(color: NSColor) throws -> Data {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()
        color.setFill()
        NSBezierPath(
            rect: NSRect(x: 0, y: 0, width: 16, height: 16)
        ).fill()
        image.unlockFocus()
        return try XCTUnwrap(image.pngData)
    }

    @MainActor
    private func render(
        theme: ThemeDocument,
        appearance: ThemeSkinAppearance,
        surface: ThemePreviewSurface,
        size: CGSize = CGSize(width: 680, height: 420)
    ) throws -> NSImage {
        let renderer = ImageRenderer(
            content: ThemePreviewView(
                theme: theme,
                appearance: appearance,
                surface: surface
            )
            .environment(
                \.colorScheme,
                appearance == .dark ? .dark : .light
            )
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 1
        return try XCTUnwrap(renderer.nsImage)
    }

    @MainActor
    private func renderBackdrop(theme: ThemeDocument) throws -> NSImage {
        let size = CGSize(width: 680, height: 330)
        let visual = ThemeVisualSnapshot(
            theme: theme,
            appearance: .light
        )
        let renderer = ImageRenderer(
            content: ThemePreviewBackdropCanvas(
                visual: visual,
                canvasSize: size,
                sidebarWidth: ThemePreviewLayout.sidebarWidth(
                    containerWidth: size.width
                )
            )
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 1
        return try XCTUnwrap(renderer.nsImage)
    }

    private func pixelColor(
        in image: NSImage,
        at point: CGPoint
    ) throws -> NSColor {
        let data = try XCTUnwrap(image.tiffRepresentation)
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))
        let color = try XCTUnwrap(
            representation.colorAt(
                x: Int(point.x),
                y: Int(point.y)
            )
        )
        return color.usingColorSpace(.sRGB) ?? color
    }

    private func brightPixelCount(
        in image: NSImage,
        screenRect: CGRect
    ) throws -> Int {
        let data = try XCTUnwrap(image.tiffRepresentation)
        let representation = try XCTUnwrap(NSBitmapImageRep(data: data))
        var count = 0
        let minX = max(0, Int(screenRect.minX))
        let maxX = min(representation.pixelsWide, Int(screenRect.maxX))
        let minY = max(0, Int(screenRect.minY))
        let maxY = min(representation.pixelsHigh, Int(screenRect.maxY))

        for screenY in minY..<maxY {
            let bitmapY = representation.pixelsHigh - screenY - 1
            for x in minX..<maxX {
                guard let color = representation.colorAt(
                    x: x,
                    y: bitmapY
                )?.usingColorSpace(.sRGB)
                else { continue }
                if max(
                    color.redComponent,
                    color.greenComponent,
                    color.blueComponent
                ) > 0.65 {
                    count += 1
                }
            }
        }
        return count
    }

    private func assert(
        _ resolution: SkinWallpaperLayout.Resolution,
        renderedSize: CGSize,
        offset: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            resolution.renderedSize.width,
            renderedSize.width,
            accuracy: 0.001,
            file: file,
            line: line
        )
        XCTAssertEqual(
            resolution.renderedSize.height,
            renderedSize.height,
            accuracy: 0.001,
            file: file,
            line: line
        )
        XCTAssertEqual(
            resolution.offset.width,
            offset.width,
            accuracy: 0.001,
            file: file,
            line: line
        )
        XCTAssertEqual(
            resolution.offset.height,
            offset.height,
            accuracy: 0.001,
            file: file,
            line: line
        )
    }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }
        return representation.representation(
            using: .png,
            properties: [:]
        )
    }
}
