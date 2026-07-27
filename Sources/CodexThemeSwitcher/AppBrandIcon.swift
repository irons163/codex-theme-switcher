import AppKit
import SwiftUI

struct AppBrandIcon: View {
    let height: CGFloat

    private static let resourceBundleName =
        "CodexThemeSwitcher_CodexThemeSwitcher.bundle"
    private static let iconFileName = "MenuBarIcon.png"

    static let menuBarImage = loadMenuBarImage()
    static let statusBarImage = makeStatusBarImage()

    static func menuBarIconURL(
        mainBundleURL: URL = Bundle.main.bundleURL,
        mainResourceURL: URL? = Bundle.main.resourceURL,
        currentDirectoryURL: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        ),
        fileManager: FileManager = .default
    ) -> URL? {
        let bundledResource = mainResourceURL?
            .appendingPathComponent(resourceBundleName, isDirectory: true)
            .appendingPathComponent(iconFileName)
        let bundleRootResource = mainBundleURL
            .appendingPathComponent(resourceBundleName, isDirectory: true)
            .appendingPathComponent(iconFileName)
        let siblingResource = mainBundleURL
            .deletingLastPathComponent()
            .appendingPathComponent(resourceBundleName, isDirectory: true)
            .appendingPathComponent(iconFileName)
        let sourceResource = currentDirectoryURL
            .appendingPathComponent(
                "Sources/CodexThemeSwitcher/Resources",
                isDirectory: true
            )
            .appendingPathComponent(iconFileName)

        return [
            bundledResource,
            bundleRootResource,
            siblingResource,
            sourceResource
        ]
        .compactMap { $0 }
        .first {
            fileManager.fileExists(atPath: $0.path)
        }
    }

    static func loadMenuBarImage() -> NSImage? {
        guard let url = menuBarIconURL() else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    static func frameSize(
        forHeight height: CGFloat,
        imageSize: CGSize?
    ) -> CGSize {
        let boundedHeight = max(0, height)
        guard let imageSize,
              imageSize.width > 0,
              imageSize.height > 0 else {
            return CGSize(
                width: boundedHeight,
                height: boundedHeight
            )
        }
        return CGSize(
            width: boundedHeight * imageSize.width / imageSize.height,
            height: boundedHeight
        )
    }

    static func makeStatusBarImage(height: CGFloat = 18) -> NSImage? {
        guard let image = menuBarImage?.copy() as? NSImage else {
            return nil
        }
        image.size = frameSize(
            forHeight: height,
            imageSize: menuBarImage?.size
        )
        image.isTemplate = false
        return image
    }

    var body: some View {
        let frameSize = Self.frameSize(
            forHeight: height,
            imageSize: Self.menuBarImage?.size
        )

        Group {
            if let image = Self.menuBarImage {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
            } else {
                Image(systemName: "paintpalette.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.cyan, .blue)
            }
        }
        .scaledToFit()
        .frame(
            width: frameSize.width,
            height: frameSize.height
        )
        .clipped()
        .fixedSize()
    }
}

struct MenuBarBrandIcon: View {
    var body: some View {
        if let image = AppBrandIcon.statusBarImage {
            Image(nsImage: image)
                .renderingMode(.original)
        } else {
            Image(systemName: "paintpalette.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.cyan, .blue)
        }
    }
}
