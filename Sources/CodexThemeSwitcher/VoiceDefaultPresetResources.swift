import Foundation

enum VoiceDefaultPresetResources {
    static let mouthSpriteFilename = "anime-girl-mouth-2x2.png"
    static let blinkFilename = "anime-girl-blink-closed.png"
    static let phoneBackgroundFilename = "frame-phone-balanced.png"
    static let live2DModelDirectoryName = "KurisuAmadeus"
    static let live2DModelFilename = "kurisu-amadeus.model3.json"

    static var live2DModelRelativePath: String {
        "\(live2DModelDirectoryName)/\(live2DModelFilename)"
    }

    static var directoryURL: URL? {
        directoryURL(
            mainResourceURL: Bundle.main.resourceURL,
            sourceFileURL: URL(fileURLWithPath: #filePath)
        )
    }

    static func directoryURL(
        mainResourceURL: URL?,
        sourceFileURL: URL,
        fileManager: FileManager = .default
    ) -> URL? {
        if let bundledDirectory = mainResourceURL?
            .appendingPathComponent("VoiceDefaults", isDirectory: true),
           containsRequiredResources(
               bundledDirectory,
               fileManager: fileManager
           ) {
            return bundledDirectory
        }

        let sourceTree = sourceFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples", isDirectory: true)
            .appendingPathComponent(
                "voice-mouth-sprites",
                isDirectory: true
            )
        return containsRequiredResources(sourceTree, fileManager: fileManager)
            ? sourceTree
            : nil
    }

    static func live2DModelURL(
        in directory: URL,
        sourceFileURL: URL = URL(fileURLWithPath: #filePath),
        fileManager: FileManager = .default
    ) -> URL? {
        let packagedURL = directory.appendingPathComponent(
            live2DModelRelativePath
        )
        if fileManager.fileExists(atPath: packagedURL.path) {
            return packagedURL
        }

        let projectRoot = sourceFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = projectRoot
            .appendingPathComponent("GeneratedModels", isDirectory: true)
            .appendingPathComponent(
                live2DModelDirectoryName,
                isDirectory: true
            )
            .appendingPathComponent("runtime", isDirectory: true)
            .appendingPathComponent(live2DModelFilename)
        return fileManager.fileExists(atPath: sourceURL.path)
            ? sourceURL
            : nil
    }

    private static func containsRequiredResources(
        _ directory: URL,
        fileManager: FileManager
    ) -> Bool {
        fileManager.fileExists(
            atPath: directory
                .appendingPathComponent(mouthSpriteFilename)
                .path
        ) && fileManager.fileExists(
            atPath: directory
                .appendingPathComponent(blinkFilename)
                .path
        ) && fileManager.fileExists(
            atPath: directory
                .appendingPathComponent(phoneBackgroundFilename)
                .path
        )
    }
}
