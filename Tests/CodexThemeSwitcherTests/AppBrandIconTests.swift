import AppKit
import Foundation
import SwiftUI
import XCTest
@testable import CodexThemeSwitcher

final class AppBrandIconTests: XCTestCase {
    @MainActor
    func testMenuBarImageLoadsFromProcessedResourceBundle() throws {
        let image = try XCTUnwrap(AppBrandIcon.menuBarImage)

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    @MainActor
    func testMenuBarIconViewCannotOverflowItsStatusItemFrame() {
        let height: CGFloat = 18
        let hostingView = NSHostingView(
            rootView: MenuBarBrandIcon()
        )
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertEqual(
            hostingView.fittingSize.height,
            height,
            accuracy: 0.5
        )
        XCTAssertLessThan(hostingView.fittingSize.width, 30)
    }

    @MainActor
    func testStatusBarImageHasMenuBarPointSizeBeforeRendering() throws {
        let source = try XCTUnwrap(AppBrandIcon.menuBarImage)
        let statusBarImage = try XCTUnwrap(AppBrandIcon.statusBarImage)
        let expected = AppBrandIcon.frameSize(
            forHeight: 18,
            imageSize: source.size
        )

        XCTAssertEqual(
            statusBarImage.size.width,
            expected.width,
            accuracy: 0.01
        )
        XCTAssertEqual(
            statusBarImage.size.height,
            expected.height,
            accuracy: 0.01
        )
    }

    @MainActor
    func testMenuBarImageLocatorSupportsSignedAppResourceLayout() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let app = root.appendingPathComponent(
            "CodexThemeSwitcher.app",
            isDirectory: true
        )
        let resources = app.appendingPathComponent(
            "Contents/Resources",
            isDirectory: true
        )
        let icon = resources
            .appendingPathComponent(
                "CodexThemeSwitcher_CodexThemeSwitcher.bundle",
                isDirectory: true
            )
            .appendingPathComponent("MenuBarIcon.png")
        try FileManager.default.createDirectory(
            at: icon.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(
            FileManager.default.createFile(
                atPath: icon.path,
                contents: Data()
            )
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let resolved = AppBrandIcon.menuBarIconURL(
            mainBundleURL: app,
            mainResourceURL: resources,
            currentDirectoryURL: root
        )

        XCTAssertEqual(resolved?.standardizedFileURL, icon.standardizedFileURL)
    }
}
