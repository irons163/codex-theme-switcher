import CodexThemeRuntime
import CodexThemeSwitcherCore
import Darwin
import Foundation

public struct AgentCLIExecution: Sendable {
    public var standardOutput: Data
    public var standardError: Data
    public var exitCode: Int32

    public init(
        standardOutput: Data = Data(),
        standardError: Data = Data(),
        exitCode: Int32 = 0
    ) {
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.exitCode = exitCode
    }
}

private struct AgentCLIError: Error, LocalizedError, Sendable {
    var code: String
    var message: String
    var exitCode: Int32
    var details: [String: String]

    init(
        _ code: String,
        _ message: String,
        exitCode: Int32 = 2,
        details: [String: String] = [:]
    ) {
        self.code = code
        self.message = message
        self.exitCode = exitCode
        self.details = details
    }

    var errorDescription: String? { message }
}

private struct ParsedAgentArguments {
    var command: String
    var values: [String: String]
    var flags: Set<String>

    func value(_ name: String) -> String? {
        values[name]
    }

    func hasFlag(_ name: String) -> Bool {
        flags.contains(name)
    }

    func validateOptions(
        values allowedValues: Set<String> = [],
        flags allowedFlags: Set<String> = []
    ) throws {
        let globalValues: Set<String> = ["codex-app", "root"]
        let globalFlags: Set<String> = ["help"]
        if let unknown = Set(values.keys)
            .subtracting(allowedValues.union(globalValues))
            .sorted()
            .first {
            throw AgentCLIError(
                "unknown_option",
                "Unknown option --\(unknown) for command \(command)."
            )
        }
        if let unknown = flags
            .subtracting(allowedFlags.union(globalFlags))
            .sorted()
            .first {
            throw AgentCLIError(
                "unknown_option",
                "Unknown flag --\(unknown) for command \(command)."
            )
        }
    }
}

private struct AgentThemeInput {
    var document: ThemeDocument
    var archive: ThemeArchiveEnvelope?

    var wasArchive: Bool {
        archive != nil
    }
}

@MainActor
public struct CodexThemeAgentCLI {
    public static let protocolVersion = 1
    public static let maximumInputBytes = 48 * 1_024 * 1_024

    private static let valueOptions: Set<String> = [
        "appearance",
        "codex-app",
        "collision",
        "height",
        "id",
        "input",
        "output",
        "preset",
        "root",
        "surface",
        "width"
    ]
    private static let flagOptions: Set<String> = [
        "archive",
        "help",
        "install",
        "launch",
        "user-only"
    ]
    private static let inputCommands: Set<String> = [
        "apply",
        "compile",
        "import",
        "install",
        "normalize",
        "preview",
        "render-preview",
        "validate"
    ]

    public init() {}

    public static func requiresStandardInput(arguments: [String]) -> Bool {
        if let index = arguments.firstIndex(of: "--input"),
           arguments.indices.contains(index + 1),
           arguments[index + 1] == "-" {
            return true
        }
        if arguments.contains(where: { $0 == "--input=-" }) {
            return true
        }
        if arguments.contains("--id")
            || arguments.contains(where: { $0.hasPrefix("--id=") }) {
            return false
        }

        guard let command = arguments.first(where: { !$0.hasPrefix("-") }),
              inputCommands.contains(command),
              !arguments.contains("--input"),
              !arguments.contains(where: { $0.hasPrefix("--input=") })
        else {
            return false
        }
        return isatty(STDIN_FILENO) == 0
    }

    public func run(
        arguments: [String],
        standardInput: Data = Data()
    ) async -> AgentCLIExecution {
        let fallbackCommand = arguments.first ?? "help"
        do {
            let parsed = try Self.parse(arguments)
            if parsed.hasFlag("help") && parsed.command != "help" {
                return try success(
                    command: parsed.command,
                    data: helpPayload(command: parsed.command)
                )
            }

            switch parsed.command {
            case "help", "--help", "-h":
                try parsed.validateOptions()
                return try success(
                    command: "help",
                    data: helpPayload(command: nil)
                )
            case "capabilities":
                try parsed.validateOptions()
                return try success(
                    command: parsed.command,
                    data: capabilitiesPayload()
                )
            case "schema":
                return try schema(parsed)
            case "sample":
                return try sample(parsed)
            case "list":
                return try await list(parsed)
            case "get":
                return try await get(parsed)
            case "validate":
                return try await validate(parsed, standardInput: standardInput)
            case "normalize":
                return try await normalize(parsed, standardInput: standardInput)
            case "compile":
                return try await compile(parsed, standardInput: standardInput)
            case "install":
                return try await install(parsed, standardInput: standardInput)
            case "import":
                return try await install(parsed, standardInput: standardInput)
            case "export":
                return try await export(parsed, standardInput: standardInput)
            case "preview", "render-preview":
                return try await preview(parsed, standardInput: standardInput)
            case "status":
                return try await status(parsed)
            case "attach":
                return try await attach(parsed)
            case "apply":
                return try await apply(parsed, standardInput: standardInput)
            case "clear":
                return try await clear(parsed)
            default:
                throw AgentCLIError(
                    "unknown_command",
                    "Unknown command \(parsed.command). Run `codex-theme help`."
                )
            }
        } catch let error as AgentCLIError {
            return failure(command: fallbackCommand, error: error)
        } catch let error as ThemeValidationError {
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    "validation_failed",
                    error.localizedDescription,
                    exitCode: 4
                ),
                data: [
                    "validation": try? codableObject(
                        ThemeValidationResult(issues: error.issues)
                    )
                ].compactMapValues { $0 }
            )
        } catch let error as ThemeCompilationError {
            switch error {
            case let .validationFailed(validationError):
                return failure(
                    command: fallbackCommand,
                    error: AgentCLIError(
                        "validation_failed",
                        validationError.localizedDescription,
                        exitCode: 4
                    ),
                    data: [
                        "validation": try? codableObject(
                            ThemeValidationResult(
                                issues: validationError.issues
                            )
                        )
                    ].compactMapValues { $0 }
                )
            case .missingAsset, .malformedAssetReference:
                return failure(
                    command: fallbackCommand,
                    error: AgentCLIError(
                        "compilation_failed",
                        error.localizedDescription,
                        exitCode: 4
                    )
                )
            }
        } catch let error as AgentPreviewRendererError {
            let code: String
            switch error {
            case .invalidSize:
                code = "invalid_preview_size"
            case .outputMustBeFileURL:
                code = "invalid_preview_output"
            case .imageRendererFailed:
                code = "preview_renderer_failed"
            case .pngEncodingFailed:
                code = "png_encoding_failed"
            }
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    code,
                    error.localizedDescription,
                    exitCode: 3
                )
            )
        } catch let error as ThemeRuntimeFailure {
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    error.code ?? "runtime_failed",
                    error.message,
                    exitCode: 5
                )
            )
        } catch let error as ThemeRepositoryError {
            let code: String
            let exitCode: Int32
            switch error {
            case .themeNotFound:
                code = "theme_not_found"
                exitCode = 3
            case .themeAlreadyExists:
                code = "theme_already_exists"
                exitCode = 6
            case .cannotReplaceBuiltIn:
                code = "cannot_replace_built_in"
                exitCode = 6
            case .cannotDeleteBuiltIn:
                code = "cannot_delete_built_in"
                exitCode = 6
            case .corruptThemeFile:
                code = "corrupt_theme_file"
                exitCode = 3
            case .invalidActiveTheme:
                code = "invalid_active_theme"
                exitCode = 3
            }
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    code,
                    error.localizedDescription,
                    exitCode: exitCode
                )
            )
        } catch let error as ThemeArchiveError {
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    "archive_error",
                    error.localizedDescription,
                    exitCode: 3
                )
            )
        } catch let error as RuntimeLocationError {
            let code = switch error {
            case .missingHelper: "runtime_helper_not_found"
            case .missingNode: "node_runtime_not_found"
            case .invalidCodexApp: "codex_app_invalid"
            }
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    code,
                    error.localizedDescription,
                    exitCode: 5
                )
            )
        } catch {
            return failure(
                command: fallbackCommand,
                error: AgentCLIError(
                    "operation_failed",
                    error.localizedDescription,
                    exitCode: 1
                )
            )
        }
    }

    private func schema(_ parsed: ParsedAgentArguments) throws -> AgentCLIExecution {
        try parsed.validateOptions(values: ["output"])
        let schemaURL = try locateSchema()
        let schemaData = try Data(contentsOf: schemaURL, options: .mappedIfSafe)
        guard schemaData.count <= 2 * 1_024 * 1_024,
              let schema = try JSONSerialization.jsonObject(
                with: schemaData
              ) as? [String: Any] else {
            throw AgentCLIError(
                "invalid_schema",
                "The bundled .codextheme JSON Schema is invalid."
            )
        }

        var data: [String: Any] = [
            "schema": schema,
            "schemaPath": schemaURL.path
        ]
        if let output = parsed.value("output") {
            let outputURL = fileURL(output)
            try write(schemaData, to: outputURL)
            data["outputPath"] = outputURL.path
        }
        return try success(command: parsed.command, data: data)
    }

    private func sample(_ parsed: ParsedAgentArguments) throws -> AgentCLIExecution {
        try parsed.validateOptions(
            values: ["output", "preset"],
            flags: ["archive"]
        )
        let preset = parsed.value("preset") ?? "blank"
        let document: ThemeDocument
        switch preset {
        case "blank":
            document = Self.agentStarterTheme()
        case "midnight":
            document = Self.editableCopy(of: BuiltInThemes.midnight)
        case "paper":
            document = Self.editableCopy(of: BuiltInThemes.paper)
        case "high-contrast", "highContrast":
            document = Self.editableCopy(of: BuiltInThemes.highContrast)
        default:
            throw AgentCLIError(
                "invalid_preset",
                "Preset must be blank, midnight, paper, or high-contrast."
            )
        }

        let archive = parsed.hasFlag("archive")
        let envelope = archive ? archiveEnvelope(document) : nil
        var data: [String: Any] = [
            "preset": preset,
            "representation": archive ? "archive" : "document"
        ]
        if let envelope {
            data["archive"] = try codableObject(envelope)
        } else {
            data["document"] = try codableObject(document)
        }
        if let output = parsed.value("output") {
            let outputURL = fileURL(output)
            let encoded = try encodeTheme(
                document,
                archive: envelope
            )
            try write(encoded, to: outputURL)
            data["outputPath"] = outputURL.path
        }
        return try success(command: parsed.command, data: data)
    }

    private func list(_ parsed: ParsedAgentArguments) async throws -> AgentCLIExecution {
        try parsed.validateOptions(flags: ["user-only"])
        let repository = repository(for: parsed)
        let summaries = try await repository.list(
            includeBuiltIns: !parsed.hasFlag("user-only")
        )
        let activeThemeID = try await repository.activeThemeID()
        return try success(
            command: parsed.command,
            data: [
                "activeThemeID": activeThemeID?.uuidString.lowercased()
                    ?? NSNull(),
                "themes": try codableObject(summaries)
            ]
        )
    }

    private func get(_ parsed: ParsedAgentArguments) async throws -> AgentCLIExecution {
        try parsed.validateOptions(
            values: ["id", "output"],
            flags: ["archive"]
        )
        let id = try requiredUUID(parsed, name: "id")
        let document = try await repository(for: parsed).load(id: id)
        let envelope = parsed.hasFlag("archive")
            ? archiveEnvelope(document)
            : nil
        var data: [String: Any] = [
            "representation": envelope == nil ? "document" : "archive"
        ]
        if let envelope {
            data["archive"] = try codableObject(envelope)
        } else {
            data["document"] = try codableObject(document)
        }
        if let output = parsed.value("output") {
            let outputURL = fileURL(output)
            try write(
                encodeTheme(document, archive: envelope),
                to: outputURL
            )
            data["outputPath"] = outputURL.path
        }
        return try success(command: parsed.command, data: data)
    }

    private func validate(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(values: ["id", "input"])
        let input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        let validation = ThemeValidator().validate(input.document)
        let payload: [String: Any] = [
            "documentID": input.document.id.uuidString.lowercased(),
            "inputFormat": input.wasArchive ? "archive" : "document",
            "valid": validation.isValid,
            "validation": try codableObject(validation)
        ]
        guard validation.isValid else {
            return failure(
                command: parsed.command,
                error: AgentCLIError(
                    "validation_failed",
                    "Theme validation failed with \(validation.errors.count) error(s).",
                    exitCode: 4
                ),
                data: payload
            )
        }
        return try success(command: parsed.command, data: payload)
    }

    private func normalize(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(
            values: ["id", "input", "output"],
            flags: ["archive"]
        )
        let input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        try ThemeValidator().validateOrThrow(input.document)
        let archive = parsed.hasFlag("archive")
        let envelope = archive
            ? (input.archive ?? archiveEnvelope(input.document))
            : nil
        var data: [String: Any] = [
            "representation": archive ? "archive" : "document"
        ]
        if let envelope {
            data["archive"] = try codableObject(envelope)
        } else {
            data["document"] = try codableObject(input.document)
        }
        if let output = parsed.value("output") {
            let outputURL = fileURL(output)
            try write(
                encodeTheme(input.document, archive: envelope),
                to: outputURL
            )
            data["outputPath"] = outputURL.path
        }
        return try success(command: parsed.command, data: data)
    }

    private func compile(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(values: ["id", "input", "output"])
        let input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        let compiled = try ThemeCompiler().compile(input.document)
        var data: [String: Any] = [
            "assets": compiled.runtimeAssets.map {
                [
                    "byteCount": $0.decodedData?.count ?? 0,
                    "id": $0.id.uuidString.lowercased(),
                    "mediaType": $0.mediaType,
                    "name": $0.name
                ] as [String: Any]
            },
            "avatarOverlayCSS": compiled.avatarOverlayCSS,
            "avatarOverlayCSSCharacterCount":
                compiled.avatarOverlayCSS.count,
            "css": compiled.css,
            "cssCharacterCount": compiled.css.count,
            "themeID": compiled.themeID.uuidString.lowercased(),
            "themeName": input.document.metadata.name,
            "warnings": try codableObject(compiled.warnings)
        ]
        if let output = parsed.value("output") {
            let outputURL = fileURL(output)
            try write(Data(compiled.css.utf8), to: outputURL)
            data["outputPath"] = outputURL.path
        }
        return try success(command: parsed.command, data: data)
    }

    private func install(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(values: ["collision", "input"])
        guard parsed.value("input") != nil || !standardInput.isEmpty else {
            throw AgentCLIError(
                "missing_input",
                "install requires --input <path|->."
            )
        }
        let input = try decodeTheme(
            readInput(parsed, standardInput: standardInput)
        )
        let policy = try collisionPolicy(parsed)
        let saved = try await repository(for: parsed).save(
            input.document,
            collisionPolicy: policy
        )
        return try success(
            command: parsed.command,
            data: [
                "collisionPolicy": policy.rawValue,
                "document": try codableObject(saved),
                "installed": true
            ]
        )
    }

    private func export(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(values: ["id", "input", "output"])
        guard let output = parsed.value("output") else {
            throw AgentCLIError(
                "missing_output",
                "export requires --output <file.codextheme>."
            )
        }
        let input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        let outputURL = fileURL(output)
        try ThemeArchiveService().export(input.document, to: outputURL)
        let attributes = try FileManager.default.attributesOfItem(
            atPath: outputURL.path
        )
        return try success(
            command: parsed.command,
            data: [
                "byteCount": (attributes[.size] as? NSNumber)?.intValue ?? 0,
                "outputPath": outputURL.path,
                "themeID": input.document.id.uuidString.lowercased()
            ]
        )
    }

    private func preview(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(
            values: [
                "appearance",
                "height",
                "id",
                "input",
                "output",
                "surface",
                "width"
            ]
        )
        guard let output = parsed.value("output") else {
            throw AgentCLIError(
                "missing_output",
                "preview requires --output <file.png|directory>."
            )
        }
        let input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        try ThemeValidator().validateOrThrow(input.document)
        let appearances = try previewAppearances(
            parsed.value("appearance") ?? "all"
        )
        let surfaces = try previewSurfaces(
            parsed.value("surface") ?? "all"
        )
        let width = try integerOption(parsed, "width", default: 1280)
        let height = try integerOption(parsed, "height", default: 800)
        let requestedOutput = fileURL(output)
        let oneRender = appearances.count == 1 && surfaces.count == 1
        if !oneRender
            && requestedOutput.pathExtension.lowercased() == "png" {
            throw AgentCLIError(
                "preview_output_must_be_directory",
                "A multi-preview matrix requires a directory output, not a .png path."
            )
        }
        let exactFile = oneRender
            && requestedOutput.pathExtension.lowercased() == "png"
        let renderer = AgentPreviewRenderer()
        var renderObjects: [[String: Any]] = []

        for appearance in appearances {
            for surface in surfaces {
                let destination: URL
                if exactFile {
                    destination = requestedOutput
                } else {
                    destination = requestedOutput.appendingPathComponent(
                        "\(input.document.id.uuidString.lowercased())-\(appearance.rawValue)-\(surface.rawValue).png"
                    )
                }
                let result = try await renderer.render(
                    theme: input.document,
                    appearance: appearance,
                    surface: surface,
                    width: width,
                    height: height,
                    outputURL: destination
                )
                renderObjects.append([
                    "appearance": appearance.rawValue,
                    "byteCount": result.byteCount,
                    "isApproximation": result.isApproximation,
                    "outputPath": result.outputURL.path,
                    "size": [
                        "height": result.size.height,
                        "width": result.size.width
                    ],
                    "surface": surface.rawValue,
                    "warnings": try codableObject(result.warnings)
                ])
            }
        }

        return try success(
            command: parsed.command,
            data: [
                "renders": renderObjects,
                "themeID": input.document.id.uuidString.lowercased()
            ]
        )
    }

    private func status(_ parsed: ParsedAgentArguments) async throws -> AgentCLIExecution {
        try parsed.validateOptions()
        let result = try await runtime(for: parsed).status()
        guard result.ok else {
            throw ThemeRuntimeFailure(
                message: result.error?.message
                    ?? result.rawOutput
                    ?? "Unable to read runtime status.",
                code: result.error?.code
            )
        }
        return try success(
            command: parsed.command,
            data: ["status": try codableObject(result.status)]
        )
    }

    private func attach(_ parsed: ParsedAgentArguments) async throws -> AgentCLIExecution {
        try parsed.validateOptions()
        try ensureRuntimeMutationAuthorized(parsed)
        let result = try await runtime(for: parsed).launch().requiringSuccess()
        return try success(
            command: parsed.command,
            data: ["status": try codableObject(result.status)]
        )
    }

    private func apply(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentCLIExecution {
        try parsed.validateOptions(
            values: ["collision", "id", "input"],
            flags: ["install", "launch"]
        )
        try ensureRuntimeMutationAuthorized(parsed)
        var input = try await resolveTheme(
            parsed,
            standardInput: standardInput
        )
        // Compile before any repository or runtime mutation. This prevents an
        // invalid asset reference from leaving behind an installed document
        // when apply can never succeed.
        var compiled = try ThemeCompiler().compile(input.document)
        let sourcedFromRepository = parsed.value("id") != nil
        let repository = repository(for: parsed)
        var installed = false
        if parsed.hasFlag("install") {
            guard parsed.value("input") != nil || !standardInput.isEmpty else {
                throw AgentCLIError(
                    "install_requires_input",
                    "--install is only valid when applying an input document."
                )
            }
            input.document = try await repository.save(
                input.document,
                collisionPolicy: try collisionPolicy(parsed)
            )
            installed = true
            // Clone changes the ID/name, which are embedded in compiled output.
            compiled = try ThemeCompiler().compile(input.document)
        } else if parsed.value("collision") != nil {
            throw AgentCLIError(
                "unused_option",
                "--collision requires --install."
            )
        }

        let runtime = try runtime(for: parsed)
        let result: ThemeRuntimeResult
        do {
            if parsed.hasFlag("launch") {
                _ = try await runtime.launch().requiringSuccess()
            }
            result = try await runtime.apply(
                css: compiled.css,
                themeID: input.document.id.uuidString,
                themeName: input.document.metadata.name,
                avatarOverlayCSS: compiled.avatarOverlayCSS,
                assets: compiled.runtimeAssets.map {
                    ThemeRuntimeAsset(
                        id: $0.id.uuidString.lowercased(),
                        mediaType: $0.mediaType,
                        dataBase64: $0.dataBase64
                    )
                }
            ).requiringSuccess()
        } catch {
            throw AgentCLIError(
                "runtime_apply_failed",
                error.localizedDescription,
                exitCode: 5,
                details: [
                    "installed": String(installed),
                    "runtimeApplied": "false",
                    "themeID": input.document.id.uuidString.lowercased()
                ]
            )
        }
        do {
            if sourcedFromRepository || installed {
                try await repository.setActiveThemeID(input.document.id)
            } else {
                // A one-off input may share an ID with a different saved
                // revision. Clearing the pointer prevents the GUI from claiming
                // that stale repository content is currently in the runtime.
                try await repository.setActiveThemeID(nil)
            }
        } catch {
            throw AgentCLIError(
                "repository_pointer_sync_failed",
                error.localizedDescription,
                exitCode: 6,
                details: [
                    "installed": String(installed),
                    "runtimeApplied": "true",
                    "themeID": input.document.id.uuidString.lowercased()
                ]
            )
        }

        return try success(
            command: parsed.command,
            data: [
                "compilationWarnings": try codableObject(compiled.warnings),
                "installed": installed,
                "repositoryActive": sourcedFromRepository || installed,
                "status": try codableObject(result.status),
                "themeID": input.document.id.uuidString.lowercased(),
                "themeName": input.document.metadata.name
            ]
        )
    }

    private func clear(_ parsed: ParsedAgentArguments) async throws -> AgentCLIExecution {
        try parsed.validateOptions()
        try ensureRuntimeMutationAuthorized(parsed)
        let result = try await runtime(for: parsed).clear().requiringSuccess()
        do {
            try await repository(for: parsed).setActiveThemeID(nil)
        } catch {
            throw AgentCLIError(
                "repository_pointer_sync_failed",
                error.localizedDescription,
                exitCode: 6,
                details: [
                    "runtimeCleared": "true"
                ]
            )
        }
        return try success(
            command: parsed.command,
            data: ["status": try codableObject(result.status)]
        )
    }

    private func resolveTheme(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) async throws -> AgentThemeInput {
        let hasID = parsed.value("id") != nil
        let hasInput = parsed.value("input") != nil || !standardInput.isEmpty
        guard hasID != hasInput else {
            throw AgentCLIError(
                "ambiguous_input",
                hasID
                    ? "Use exactly one of --id or --input."
                    : "Provide --id <uuid> or --input <path|->."
            )
        }
        if hasID {
            let id = try requiredUUID(parsed, name: "id")
            return AgentThemeInput(
                document: try await repository(for: parsed).load(id: id),
                archive: nil
            )
        }
        return try decodeTheme(
            readInput(parsed, standardInput: standardInput)
        )
    }

    private func decodeTheme(_ data: Data) throws -> AgentThemeInput {
        guard !data.isEmpty else {
            throw AgentCLIError(
                "empty_input",
                "Theme input is empty.",
                exitCode: 3
            )
        }
        guard data.count <= Self.maximumInputBytes else {
            throw AgentCLIError(
                "input_too_large",
                "Theme input exceeds the 48 MiB archive limit.",
                exitCode: 3
            )
        }
        let decoder = ThemeJSONCoding.decoder()
        if let envelope = try? decoder.decode(
            ThemeArchiveEnvelope.self,
            from: data
        ) {
            guard envelope.format == ThemeArchiveService.formatIdentifier else {
                throw AgentCLIError(
                    "unsupported_format",
                    "Unsupported archive format \(envelope.format).",
                    exitCode: 3
                )
            }
            guard envelope.archiveVersion
                == ThemeArchiveService.currentArchiveVersion else {
                throw AgentCLIError(
                    "unsupported_archive_version",
                    "Unsupported archive version \(envelope.archiveVersion).",
                    exitCode: 3
                )
            }
            return AgentThemeInput(
                document: envelope.theme,
                archive: envelope
            )
        }
        do {
            return AgentThemeInput(
                document: try decoder.decode(ThemeDocument.self, from: data),
                archive: nil
            )
        } catch {
            throw AgentCLIError(
                "invalid_theme_json",
                "Input is neither a ThemeDocument nor a .codextheme archive: \(error.localizedDescription)",
                exitCode: 3
            )
        }
    }

    private func readInput(
        _ parsed: ParsedAgentArguments,
        standardInput: Data
    ) throws -> Data {
        guard let input = parsed.value("input") else {
            guard !standardInput.isEmpty else {
                throw AgentCLIError(
                    "missing_input",
                    "Provide --input <path|->.",
                    exitCode: 3
                )
            }
            return standardInput
        }
        if input == "-" {
            guard !standardInput.isEmpty else {
                throw AgentCLIError(
                    "empty_stdin",
                    "No theme JSON was received on standard input.",
                    exitCode: 3
                )
            }
            return standardInput
        }
        let inputURL = fileURL(input)
        if let attributes = try? FileManager.default.attributesOfItem(
            atPath: inputURL.path
        ),
           let byteCount = attributes[.size] as? NSNumber,
           byteCount.int64Value > Int64(Self.maximumInputBytes) {
            throw AgentCLIError(
                "input_too_large",
                "Theme input exceeds the 48 MiB archive limit.",
                exitCode: 3
            )
        }
        do {
            return try Data(
                contentsOf: inputURL,
                options: .mappedIfSafe
            )
        } catch {
            throw AgentCLIError(
                "unreadable_input",
                "Unable to read theme input at \(inputURL.path).",
                exitCode: 3
            )
        }
    }

    private func repository(
        for parsed: ParsedAgentArguments
    ) -> FileThemeRepository {
        FileThemeRepository(rootDirectory: rootURL(parsed))
    }

    private func runtime(
        for parsed: ParsedAgentArguments
    ) throws -> ThemeRuntimeController {
        ThemeRuntimeController(
            runner: RuntimeHelperRunner(
                helperScript: try RuntimeLocator.helperScriptURL(),
                codexApp: parsed.value("codex-app").map(fileURL)
                    ?? RuntimeLocator.defaultCodexApp,
                userRoot: rootURL(parsed)
            )
        )
    }

    private func rootURL(_ parsed: ParsedAgentArguments) -> URL {
        guard let root = parsed.value("root") else {
            return FileThemeRepository.defaultRootDirectory
        }
        return fileURL(root)
    }

    private func ensureRuntimeMutationAuthorized(
        _ parsed: ParsedAgentArguments
    ) throws {
        guard parsed.value("root") != nil,
              rootURL(parsed)
                != FileThemeRepository.defaultRootDirectory.standardizedFileURL else {
            return
        }
        throw AgentCLIError(
            "custom_root_runtime_unsupported",
            """
            Runtime mutation with a custom --root is unsafe because Codex/CDP \
            ports are shared. Omit --root to attach, apply, or clear.
            """
        )
    }

    private func locateSchema() throws -> URL {
        let executableResources = Bundle.main.executableURL?
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Schemas", isDirectory: true)
        let packagedCandidates: [URL?] = [
            Bundle.main.resourceURL?
                .appendingPathComponent("Schemas/codextheme.schema.json"),
            executableResources?
                .appendingPathComponent("codextheme.schema.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(
                    "Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json"
                )
        ]
        if let result = packagedCandidates.compactMap({ $0 }).first(
            where: { FileManager.default.fileExists(atPath: $0.path) }
        ) {
            return result
        }
        throw AgentCLIError(
            "schema_not_found",
            "The .codextheme JSON Schema could not be located."
        )
    }

    private func encodeTheme(
        _ document: ThemeDocument,
        archive: ThemeArchiveEnvelope?
    ) throws -> Data {
        if let archive {
            return try ThemeJSONCoding.encoder().encode(archive)
        }
        return try ThemeJSONCoding.encoder().encode(document)
    }

    private func archiveEnvelope(
        _ document: ThemeDocument
    ) -> ThemeArchiveEnvelope {
        ThemeArchiveEnvelope(
            format: ThemeArchiveService.formatIdentifier,
            archiveVersion: ThemeArchiveService.currentArchiveVersion,
            exportedAt: Date(),
            theme: document
        )
    }

    private func collisionPolicy(
        _ parsed: ParsedAgentArguments
    ) throws -> ThemeCollisionPolicy {
        let rawValue = parsed.value("collision") ?? "fail"
        guard let policy = ThemeCollisionPolicy(rawValue: rawValue) else {
            throw AgentCLIError(
                "invalid_collision_policy",
                "Collision policy must be fail, replace, or clone."
            )
        }
        return policy
    }

    private func requiredUUID(
        _ parsed: ParsedAgentArguments,
        name: String
    ) throws -> UUID {
        guard let rawValue = parsed.value(name) else {
            throw AgentCLIError(
                "missing_option",
                "Missing required option --\(name)."
            )
        }
        guard let value = UUID(uuidString: rawValue) else {
            throw AgentCLIError(
                "invalid_uuid",
                "--\(name) must be a UUID."
            )
        }
        return value
    }

    private func integerOption(
        _ parsed: ParsedAgentArguments,
        _ name: String,
        default defaultValue: Int
    ) throws -> Int {
        guard let rawValue = parsed.value(name) else {
            return defaultValue
        }
        guard let value = Int(rawValue) else {
            throw AgentCLIError(
                "invalid_integer",
                "--\(name) must be an integer."
            )
        }
        return value
    }

    private func previewAppearances(
        _ rawValue: String
    ) throws -> [AgentPreviewAppearance] {
        if rawValue == "all" {
            return AgentPreviewAppearance.allCases
        }
        guard let appearance = AgentPreviewAppearance(rawValue: rawValue) else {
            throw AgentCLIError(
                "invalid_appearance",
                "Appearance must be light, dark, or all."
            )
        }
        return [appearance]
    }

    private func previewSurfaces(
        _ rawValue: String
    ) throws -> [AgentPreviewSurface] {
        if rawValue == "all" {
            return AgentPreviewSurface.allCases
        }
        guard let surface = AgentPreviewSurface(rawValue: rawValue) else {
            throw AgentCLIError(
                "invalid_surface",
                "Surface must be home, chat, or all."
            )
        }
        return [surface]
    }

    private func fileURL(_ path: String) -> URL {
        URL(
            fileURLWithPath: (path as NSString).expandingTildeInPath,
            relativeTo: nil
        ).standardizedFileURL
    }

    private func write(_ data: Data, to destination: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: destination, options: .atomic)
        } catch {
            throw AgentCLIError(
                "write_failed",
                "Unable to write \(destination.path): \(error.localizedDescription)",
                exitCode: 3
            )
        }
    }

    private func codableObject<T: Encodable>(_ value: T) throws -> Any {
        let encoded = try ThemeJSONCoding.encoder().encode(value)
        return try JSONSerialization.jsonObject(with: encoded)
    }

    private func success(
        command: String,
        data: [String: Any]
    ) throws -> AgentCLIExecution {
        let envelope: [String: Any] = [
            "command": command,
            "data": data,
            "ok": true,
            "protocolVersion": Self.protocolVersion
        ]
        return AgentCLIExecution(
            standardOutput: try serialized(envelope),
            exitCode: 0
        )
    }

    private func failure(
        command: String,
        error: AgentCLIError,
        data: [String: Any]? = nil
    ) -> AgentCLIExecution {
        var envelope: [String: Any] = [
            "command": command,
            "error": [
                "code": error.code,
                "details": error.details,
                "message": error.message
            ],
            "ok": false,
            "protocolVersion": Self.protocolVersion
        ]
        if let data {
            envelope["data"] = data
        }
        let encoded = (try? serialized(envelope))
            ?? Data(
                "{\"ok\":false,\"error\":{\"code\":\"encoding_failed\"}}\n"
                    .utf8
            )
        return AgentCLIExecution(
            standardError: encoded,
            exitCode: error.exitCode
        )
    }

    private func serialized(_ object: Any) throws -> Data {
        var data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        data.append(0x0A)
        return data
    }

    private func capabilitiesPayload() -> [String: Any] {
        [
            "archive": [
                "format": ThemeArchiveService.formatIdentifier,
                "version": ThemeArchiveService.currentArchiveVersion
            ],
            "commands": [
                ["name": "capabilities", "sideEffects": ["none"]],
                [
                    "name": "schema",
                    "sideEffects": ["optional_file_write"]
                ],
                [
                    "name": "sample",
                    "sideEffects": ["optional_file_write"]
                ],
                [
                    "name": "list",
                    "sideEffects": [
                        "optional_repository_directory_create"
                    ]
                ],
                [
                    "name": "get",
                    "sideEffects": ["optional_file_write"]
                ],
                ["name": "validate", "sideEffects": ["none"]],
                [
                    "name": "normalize",
                    "sideEffects": ["optional_file_write"]
                ],
                [
                    "name": "compile",
                    "sideEffects": ["optional_file_write"]
                ],
                ["name": "install", "sideEffects": ["repository_write"]],
                ["name": "import", "sideEffects": ["repository_write"]],
                ["name": "export", "sideEffects": ["file_write"]],
                ["name": "preview", "sideEffects": ["file_write"]],
                ["name": "status", "sideEffects": ["none"]],
                [
                    "name": "attach",
                    "sideEffects": [
                        "codex_process",
                        "runtime_state_write"
                    ]
                ],
                [
                    "name": "apply",
                    "sideEffects": [
                        "codex_runtime",
                        "repository_pointer",
                        "runtime_state_write"
                    ],
                    "conditionalSideEffects": [
                        "install": ["repository_write"],
                        "launch": ["codex_process"]
                    ]
                ],
                [
                    "name": "clear",
                    "sideEffects": [
                        "codex_runtime",
                        "repository_pointer",
                        "runtime_state_write"
                    ]
                ]
            ],
            "inputFormats": ["ThemeDocument", ".codextheme archive"],
            "limits": [
                "archiveBytes": 48 * 1_024 * 1_024,
                "assetBytes": 16 * 1_024 * 1_024,
                "cssCharacters": 1_000_000,
                "totalAssetBytes": 32 * 1_024 * 1_024
            ],
            "preview": [
                "appearances": AgentPreviewAppearance.allCases.map(\.rawValue),
                "isApproximation": true,
                "surfaces": AgentPreviewSurface.allCases.map(\.rawValue),
                "warning": "Raw CSS and arbitrary selectors are reported but not executed by the native preview."
            ],
            "protocolVersion": Self.protocolVersion,
            "runtime": [
                "codexAppOption": "--codex-app <path>",
                "codexAppResolution": [
                    "saved_preference",
                    "running_application",
                    "launch_services",
                    "known_locations"
                ],
                "rendererTargets": [
                    "main",
                    "avatar-overlay"
                ],
                "voiceMouthAnimation": true,
                "voiceMouthFrameLimit": 9,
                "voiceMouthSpriteSheets": ["2x2", "3x3"],
                "voiceMouthSynchronization": "amplitude-envelope-discrete",
                "voiceAvatarModes": ["native", "image", "live2D"],
                "voiceLive2DModelImport": ".model3.json",
                "voiceLive2DMouthSynchronization":
                    "amplitude-envelope-continuous",
                "voiceIdleAnimation": true,
                "voiceBlinkImage": true,
                "voiceStyleIsolation": true
            ],
            "schemaVersion": ThemeDocument.currentSchemaVersion,
            "security": [
                "applyAcceptsRawCompiledCSS": false,
                "coreValidationRequired": true,
                "externalNetworkURLsAllowed": false,
                "javascriptAllowed": false
            ]
        ]
    }

    private func helpPayload(command: String?) -> [String: Any] {
        let usage = """
        codex-theme <command> [options]

        Agent design loop:
          codex-theme schema
          codex-theme sample --archive --output /tmp/theme.codextheme
          codex-theme validate --input /tmp/theme.codextheme
          codex-theme preview --input /tmp/theme.codextheme --output /tmp/previews
          codex-theme install --input /tmp/theme.codextheme --collision fail
          codex-theme apply --id <uuid> --launch

        Commands:
          capabilities, schema, sample, list, get, validate, normalize,
          compile, install (alias: import), export, preview, status, attach,
          apply, clear

        All command responses are JSON. --codex-app <path> overrides automatic
        Codex discovery for runtime commands. --root <directory> changes only
        the Theme Switcher data root; it does not sandbox the real Codex
        process or CDP ports. attach/apply/clear reject non-default roots. Use
        --input - for stdin.
        """
        return [
            "command": command ?? NSNull(),
            "usage": usage
        ]
    }

    private static func parse(_ arguments: [String]) throws -> ParsedAgentArguments {
        if arguments.isEmpty {
            return ParsedAgentArguments(
                command: "help",
                values: [:],
                flags: []
            )
        }
        if arguments == ["--help"] || arguments == ["-h"] {
            return ParsedAgentArguments(
                command: "help",
                values: [:],
                flags: []
            )
        }

        let command = arguments[0]
        guard !command.hasPrefix("-") else {
            throw AgentCLIError(
                "missing_command",
                "A command is required. Run `codex-theme help`."
            )
        }
        var values: [String: String] = [:]
        var flags = Set<String>()
        var index = 1
        while index < arguments.count {
            let argument = arguments[index]
            guard argument.hasPrefix("--") else {
                throw AgentCLIError(
                    "unexpected_argument",
                    "Unexpected positional argument \(argument)."
                )
            }
            let body = String(argument.dropFirst(2))
            if let equals = body.firstIndex(of: "=") {
                let name = String(body[..<equals])
                let value = String(body[body.index(after: equals)...])
                guard valueOptions.contains(name) else {
                    throw AgentCLIError(
                        "unknown_option",
                        "Unknown option --\(name)."
                    )
                }
                guard values[name] == nil else {
                    throw AgentCLIError(
                        "duplicate_option",
                        "Option --\(name) was provided more than once."
                    )
                }
                values[name] = value
                index += 1
                continue
            }
            if flagOptions.contains(body) {
                guard flags.insert(body).inserted else {
                    throw AgentCLIError(
                        "duplicate_option",
                        "Flag --\(body) was provided more than once."
                    )
                }
                index += 1
                continue
            }
            guard valueOptions.contains(body) else {
                throw AgentCLIError(
                    "unknown_option",
                    "Unknown option --\(body)."
                )
            }
            guard arguments.indices.contains(index + 1) else {
                throw AgentCLIError(
                    "missing_option_value",
                    "Option --\(body) requires a value."
                )
            }
            guard values[body] == nil else {
                throw AgentCLIError(
                    "duplicate_option",
                    "Option --\(body) was provided more than once."
                )
            }
            values[body] = arguments[index + 1]
            index += 2
        }
        return ParsedAgentArguments(
            command: command,
            values: values,
            flags: flags
        )
    }

    private static func agentStarterTheme() -> ThemeDocument {
        ThemeDocument(
            metadata: ThemeMetadata(
                name: "Agent Theme",
                author: "AI Agent",
                description: "A structured starting point for an agent-designed Codex theme.",
                tags: ["agent"]
            ),
            layers: [
                ThemeLayer(
                    name: "Base",
                    variables: [
                        ThemeVariable(
                            value: "#111827",
                            semanticRole: .backgroundPrimary
                        ),
                        ThemeVariable(
                            value: "#172033",
                            semanticRole: .backgroundSecondary
                        ),
                        ThemeVariable(
                            value: "rgba(31, 41, 55, 0.88)",
                            semanticRole: .surface
                        ),
                        ThemeVariable(
                            value: "#f8fafc",
                            semanticRole: .textPrimary
                        ),
                        ThemeVariable(
                            value: "#a9b4c5",
                            semanticRole: .textSecondary
                        ),
                        ThemeVariable(
                            value: "#60a5fa",
                            semanticRole: .accent
                        ),
                        ThemeVariable(
                            value: "rgba(148, 163, 184, 0.24)",
                            semanticRole: .border
                        )
                    ],
                    components: [
                        ThemeComponentOverride(
                            componentID: "composer",
                            declarations: [
                                ThemeCSSDeclaration(
                                    property: "border-radius",
                                    value: "16px"
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }

    private static func editableCopy(
        of source: ThemeDocument
    ) -> ThemeDocument {
        var copy = source
        copy.id = UUID()
        copy.metadata.name += " Copy"
        copy.metadata.createdAt = Date()
        copy.metadata.updatedAt = copy.metadata.createdAt
        for layerIndex in copy.layers.indices {
            copy.layers[layerIndex].id = UUID()
            for variableIndex in copy.layers[layerIndex].variables.indices {
                copy.layers[layerIndex].variables[variableIndex].id = UUID()
            }
            for componentIndex in copy.layers[layerIndex].components.indices {
                copy.layers[layerIndex].components[componentIndex].id = UUID()
                for declarationIndex
                    in copy.layers[layerIndex].components[componentIndex]
                        .declarations.indices {
                    copy.layers[layerIndex].components[componentIndex]
                        .declarations[declarationIndex].id = UUID()
                }
            }
            for ruleIndex in copy.layers[layerIndex].rules.indices {
                copy.layers[layerIndex].rules[ruleIndex].id = UUID()
                for declarationIndex
                    in copy.layers[layerIndex].rules[ruleIndex]
                        .declarations.indices {
                    copy.layers[layerIndex].rules[ruleIndex]
                        .declarations[declarationIndex].id = UUID()
                }
            }
        }
        for assetIndex in copy.assets.indices {
            let oldID = copy.assets[assetIndex].id
            let newID = UUID()
            copy.assets[assetIndex].id = newID
            if copy.imageSkin?.light.backgroundAssetID == oldID {
                copy.imageSkin?.light.backgroundAssetID = newID
            }
            if copy.imageSkin?.dark.backgroundAssetID == oldID {
                copy.imageSkin?.dark.backgroundAssetID = newID
            }
            if copy.voiceStyle?.light.backgroundAssetID == oldID {
                copy.voiceStyle?.light.backgroundAssetID = newID
            }
            if copy.voiceStyle?.dark.backgroundAssetID == oldID {
                copy.voiceStyle?.dark.backgroundAssetID = newID
            }
            if copy.voiceStyle?.light.orbBackgroundAssetID == oldID {
                copy.voiceStyle?.light.orbBackgroundAssetID = newID
            }
            if copy.voiceStyle?.dark.orbBackgroundAssetID == oldID {
                copy.voiceStyle?.dark.orbBackgroundAssetID = newID
            }
            if var voiceStyle = copy.voiceStyle {
                if voiceStyle.light.orbBlinkAssetID == oldID {
                    voiceStyle.light.orbBlinkAssetID = newID
                }
                if voiceStyle.dark.orbBlinkAssetID == oldID {
                    voiceStyle.dark.orbBlinkAssetID = newID
                }
                voiceStyle.light.orbMouthFrameAssetIDs =
                    voiceStyle.light.orbMouthFrameAssetIDs.map {
                    $0 == oldID ? newID : $0
                    }
                voiceStyle.dark.orbMouthFrameAssetIDs =
                    voiceStyle.dark.orbMouthFrameAssetIDs.map {
                        $0 == oldID ? newID : $0
                    }
                if var live2D = voiceStyle.light.live2DModel {
                    live2D.resources = live2D.resources.map { resource in
                        var copy = resource
                        if copy.assetID == oldID {
                            copy.assetID = newID
                        }
                        return copy
                    }
                    voiceStyle.light.live2DModel = live2D
                }
                if var live2D = voiceStyle.dark.live2DModel {
                    live2D.resources = live2D.resources.map { resource in
                        var copy = resource
                        if copy.assetID == oldID {
                            copy.assetID = newID
                        }
                        return copy
                    }
                    voiceStyle.dark.live2DModel = live2D
                }
                copy.voiceStyle = voiceStyle
            }
        }
        return copy
    }
}
