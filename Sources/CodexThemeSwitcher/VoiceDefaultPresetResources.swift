import Foundation

enum VoiceDefaultPresetResources {
    static let mouthSpriteFilename = "anime-girl-mouth-2x2.png"
    static let blinkFilename = "anime-girl-blink-closed.png"

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
        )
    }
}
