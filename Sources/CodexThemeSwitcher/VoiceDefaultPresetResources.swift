import Foundation

enum VoiceDefaultPresetResources {
    static let mouthSpriteFilename = "anime-girl-mouth-2x2.png"
    static let blinkFilename = "anime-girl-blink-closed.png"

    static var directoryURL: URL? {
        let fileManager = FileManager.default
        let bundledCandidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent("VoiceDefaults", isDirectory: true),
            Bundle.module.resourceURL?
                .appendingPathComponent("VoiceDefaults", isDirectory: true)
        ].compactMap { $0 }

        for candidate in bundledCandidates
        where containsRequiredResources(candidate, fileManager: fileManager) {
            return candidate
        }

        let sourceTree = URL(fileURLWithPath: #filePath)
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
