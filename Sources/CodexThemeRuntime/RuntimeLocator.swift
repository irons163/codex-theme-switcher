import Foundation

public enum RuntimeLocator {
    public static var defaultCodexApp: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            URL(fileURLWithPath: "/Applications/Codex.app"),
            URL(fileURLWithPath: "/Applications/ChatGPT.app"),
            home.appendingPathComponent("Applications/Codex.app"),
            home.appendingPathComponent("Applications/ChatGPT.app")
        ]
        return candidates.first(where: isCodexDesktopApp)
            ?? URL(fileURLWithPath: "/Applications/Codex.app")
    }

    public static var defaultUserRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/CodexThemeSwitcher",
                isDirectory: true
            )
    }

    public static func helperScriptURL() throws -> URL {
        let bundleName = "CodexThemeSwitcher_CodexThemeRuntime.bundle"
        let mainBundle = Bundle.main.bundleURL
        let mainResources = Bundle.main.resourceURL
        let enclosingAppResources = Bundle.main.executableURL?
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources", isDirectory: true)
        let candidates: [URL?] = [
            mainBundle
                .appendingPathComponent(bundleName)
                .appendingPathComponent("Resources/runtime/cli.js"),
            mainResources?
                .appendingPathComponent(bundleName)
                .appendingPathComponent("Resources/runtime/cli.js"),
            enclosingAppResources?
                .appendingPathComponent(bundleName)
                .appendingPathComponent("Resources/runtime/cli.js"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(
                    "Sources/CodexThemeRuntime/Resources/runtime/cli.js"
                )
        ]
        for candidate in candidates.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        throw RuntimeLocationError.missingHelper
    }

    public static func defaultNodeExecutable(
        codexApp: URL = defaultCodexApp,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> URL? {
        var candidates = [
            codexApp.appendingPathComponent("Contents/Resources/node"),
            codexApp.appendingPathComponent("Contents/Resources/cua_node/bin/node")
        ]
        if let path = environment["PATH"] {
            candidates.append(contentsOf: path
                .split(separator: ":")
                .map {
                    URL(fileURLWithPath: String($0))
                        .appendingPathComponent("node")
                })
        }
        candidates.append(contentsOf: [
            URL(fileURLWithPath: "/opt/homebrew/bin/node"),
            URL(fileURLWithPath: "/usr/local/bin/node"),
            URL(fileURLWithPath: "/opt/local/bin/node")
        ])
        return candidates.first {
            FileManager.default.isExecutableFile(atPath: $0.path)
        }
    }

    private static func isCodexDesktopApp(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        if url.lastPathComponent == "Codex.app" {
            return true
        }
        return Bundle(url: url)?.bundleIdentifier == "com.openai.codex"
    }
}

public enum RuntimeLocationError: LocalizedError {
    case missingHelper
    case missingNode

    public var errorDescription: String? {
        switch self {
        case .missingHelper:
            "Bundled Codex Theme runtime helper was not found."
        case .missingNode:
            "A compatible Node.js runtime was not found."
        }
    }
}
