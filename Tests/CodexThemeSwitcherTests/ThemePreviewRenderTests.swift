import AppKit
import CodexThemeSwitcherCore
import SwiftUI
import XCTest
@testable import CodexThemeSwitcher

final class ThemePreviewRenderTests: XCTestCase {
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
