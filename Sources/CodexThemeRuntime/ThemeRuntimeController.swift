import Foundation

public struct RuntimeHelperRunner: Sendable {
    public let helperScript: URL
    public let codexApp: URL
    public let userRoot: URL
    public let nodeExecutable: URL?

    public init(
        helperScript: URL,
        codexApp: URL = RuntimeLocator.defaultCodexApp,
        userRoot: URL = RuntimeLocator.defaultUserRoot,
        nodeExecutable: URL? = nil
    ) {
        self.helperScript = helperScript
        self.codexApp = codexApp
        self.userRoot = userRoot
        self.nodeExecutable = nodeExecutable
    }

    public static func standard(
        codexApp: URL = RuntimeLocator.defaultCodexApp
    ) throws -> RuntimeHelperRunner {
        RuntimeHelperRunner(
            helperScript: try RuntimeLocator.helperScriptURL(),
            codexApp: codexApp,
            userRoot: RuntimeLocator.defaultUserRoot
        )
    }

    public func status() async throws -> ThemeRuntimeResult {
        try await run(command: "status")
    }

    public func launch() async throws -> ThemeRuntimeResult {
        try await run(command: "launch")
    }

    public func inject() async throws -> ThemeRuntimeResult {
        try await run(command: "inject")
    }

    public func apply(
        css: String,
        themeID: String,
        themeName: String,
        avatarOverlayCSS: String = "",
        assets: [ThemeRuntimeAsset] = []
    ) async throws -> ThemeRuntimeResult {
        let input = try JSONEncoder().encode(
            RuntimeThemePayload(
                themeID: themeID,
                themeName: themeName,
                css: css,
                avatarOverlayCSS: avatarOverlayCSS,
                assets: assets
            )
        )
        return try await run(command: "apply", standardInput: input)
    }

    public func clear() async throws -> ThemeRuntimeResult {
        try await run(command: "clear")
    }

    public func stop() async throws -> ThemeRuntimeResult {
        try await run(command: "stop")
    }

    public func run(
        command: String,
        standardInput: Data? = nil
    ) async throws -> ThemeRuntimeResult {
        let helperPath = helperScript.path
        let codexPath = codexApp.path
        let rootPath = userRoot.path
        let nodePath = nodeExecutable?.path

        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let resolvedNode = nodePath.map(URL.init(fileURLWithPath:))
                ?? RuntimeLocator.defaultNodeExecutable(
                    codexApp: URL(fileURLWithPath: codexPath)
                )
            guard let resolvedNode else {
                throw RuntimeLocationError.missingNode
            }

            process.executableURL = resolvedNode
            process.arguments = [
                helperPath,
                command,
                "--codex-app", codexPath,
                "--user-root", rootPath,
                "--json"
            ]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            let stdin: Pipe?
            if standardInput != nil {
                let pipe = Pipe()
                process.standardInput = pipe
                stdin = pipe
            } else {
                stdin = nil
            }

            try process.run()
            if let standardInput, let stdin {
                stdin.fileHandleForWriting.write(standardInput)
                try? stdin.fileHandleForWriting.close()
            }
            process.waitUntilExit()

            let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if var decoded = try? JSONDecoder().decode(
                ThemeRuntimeResult.self,
                from: outputData
            ) {
                if decoded.ok && process.terminationStatus != 0 {
                    decoded = ThemeRuntimeResult(
                        ok: false,
                        status: decoded.status,
                        error: ThemeRuntimeErrorPayload(
                            message: errorOutput.isEmpty
                                ? "Runtime helper exited with status \(process.terminationStatus)."
                                : errorOutput,
                            code: "process-exit"
                        ),
                        rawOutput: output
                    )
                }
                return decoded
            }

            return ThemeRuntimeResult(
                ok: false,
                status: nil,
                error: ThemeRuntimeErrorPayload(
                    message: output.isEmpty ? errorOutput : output,
                    code: "invalid-output"
                ),
                rawOutput: output
            )
        }.value
    }
}

public actor ThemeRuntimeController {
    private let runner: RuntimeHelperRunner

    public init(runner: RuntimeHelperRunner) {
        self.runner = runner
    }

    public static func standard(
        codexApp: URL = RuntimeLocator.defaultCodexApp
    ) throws -> ThemeRuntimeController {
        ThemeRuntimeController(runner: try .standard(codexApp: codexApp))
    }

    public func status() async throws -> ThemeRuntimeResult {
        try await runner.status()
    }

    public func launch() async throws -> ThemeRuntimeResult {
        try await runner.launch()
    }

    public func inject() async throws -> ThemeRuntimeResult {
        try await runner.inject()
    }

    public func apply(
        css: String,
        themeID: String,
        themeName: String,
        avatarOverlayCSS: String = "",
        assets: [ThemeRuntimeAsset] = []
    ) async throws -> ThemeRuntimeResult {
        try await runner.apply(
            css: css,
            themeID: themeID,
            themeName: themeName,
            avatarOverlayCSS: avatarOverlayCSS,
            assets: assets
        )
    }

    public func clear() async throws -> ThemeRuntimeResult {
        try await runner.clear()
    }

    public func stop() async throws -> ThemeRuntimeResult {
        try await runner.stop()
    }
}
