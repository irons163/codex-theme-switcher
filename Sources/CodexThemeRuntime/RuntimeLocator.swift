import AppKit
import Foundation

public enum RuntimeLocator {
    public static let codexBundleIdentifier = "com.openai.codex"

    public static var defaultCodexApp: URL {
        resolvedCodexApp()
            ?? URL(fileURLWithPath: "/Applications/Codex.app")
    }

    public static var defaultUserRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/CodexThemeSwitcher",
                isDirectory: true
            )
    }

    public static func resolvedCodexApp(
        userRoot: URL = defaultUserRoot
    ) -> URL? {
        resolveCodexApp(
            persistedURL: persistedCodexApp(userRoot: userRoot),
            runningURLs: NSRunningApplication.runningApplications(
                withBundleIdentifier: codexBundleIdentifier
            ).compactMap(\.bundleURL),
            registeredURL: NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: codexBundleIdentifier
            ),
            candidates: commonCodexAppCandidates()
        )
    }

    public static func automaticCodexApp() -> URL? {
        resolveCodexApp(
            persistedURL: nil,
            runningURLs: NSRunningApplication.runningApplications(
                withBundleIdentifier: codexBundleIdentifier
            ).compactMap(\.bundleURL),
            registeredURL: NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: codexBundleIdentifier
            ),
            candidates: commonCodexAppCandidates()
        )
    }

    public static func persistedCodexApp(
        userRoot: URL = defaultUserRoot
    ) -> URL? {
        guard let data = try? Data(
            contentsOf: codexAppPathURL(userRoot: userRoot)
        ),
        let rawPath = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
        !rawPath.isEmpty
        else {
            return nil
        }
        let url = URL(fileURLWithPath: rawPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        return isCodexDesktopApp(url) ? url : nil
    }

    public static func persistCodexApp(
        _ url: URL,
        userRoot: URL = defaultUserRoot
    ) throws {
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
        guard isCodexDesktopApp(resolved) else {
            throw RuntimeLocationError.invalidCodexApp(resolved.path)
        }
        let destination = codexAppPathURL(userRoot: userRoot)
        let directory = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try Data("\(resolved.path)\n".utf8).write(
            to: destination,
            options: .atomic
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: destination.path
        )
    }

    public static func clearPersistedCodexApp(
        userRoot: URL = defaultUserRoot
    ) throws {
        let destination = codexAppPathURL(userRoot: userRoot)
        guard FileManager.default.fileExists(atPath: destination.path) else {
            return
        }
        try FileManager.default.removeItem(at: destination)
    }

    public static func isCodexDesktopApp(_ url: URL) -> Bool {
        guard let bundle = Bundle(url: url),
              bundle.bundleIdentifier == codexBundleIdentifier,
              let executableURL = bundle.executableURL else {
            return false
        }
        return FileManager.default.isExecutableFile(
            atPath: executableURL.path
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

    static func resolveCodexApp(
        persistedURL: URL?,
        runningURLs: [URL],
        registeredURL: URL?,
        candidates: [URL],
        validator: (URL) -> Bool = isCodexDesktopApp
    ) -> URL? {
        var seen: Set<String> = []
        let ordered = [persistedURL].compactMap { $0 }
            + runningURLs
            + [registeredURL].compactMap { $0 }
            + candidates
        for candidate in ordered {
            let resolved = candidate.standardizedFileURL
                .resolvingSymlinksInPath()
            guard seen.insert(resolved.path).inserted else {
                continue
            }
            if validator(resolved) {
                return resolved
            }
        }
        return nil
    }

    private static func commonCodexAppCandidates() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/Applications/Codex.app"),
            URL(fileURLWithPath: "/Applications/ChatGPT.app"),
            home.appendingPathComponent("Applications/Codex.app"),
            home.appendingPathComponent("Applications/ChatGPT.app")
        ]
    }

    private static func codexAppPathURL(userRoot: URL) -> URL {
        userRoot
            .appendingPathComponent("Runtime", isDirectory: true)
            .appendingPathComponent("codex-app-path")
    }
}

public enum RuntimeLocationError: LocalizedError {
    case missingHelper
    case missingNode
    case invalidCodexApp(String)

    public var errorDescription: String? {
        switch self {
        case .missingHelper:
            "Bundled Codex Theme runtime helper was not found."
        case .missingNode:
            "A compatible Node.js runtime was not found."
        case let .invalidCodexApp(path):
            "The selected application is not Codex: \(path)"
        }
    }
}
