import Foundation

/// Actor-isolated persistence for user themes and the active theme pointer.
///
/// Each theme is one JSON file. Assets remain inline in `ThemeDocument`, which
/// keeps saves atomic and makes the on-disk representation easy to recover.
public actor FileThemeRepository {
    public nonisolated static var defaultRootDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("CodexThemeSwitcher", isDirectory: true)
    }

    public nonisolated let rootDirectory: URL

    private let themesDirectory: URL
    private let activeThemeFile: URL
    private let validator: ThemeValidator
    private let fileManager: FileManager

    public init(
        rootDirectory: URL = FileThemeRepository.defaultRootDirectory,
        validator: ThemeValidator = ThemeValidator()
    ) {
        self.rootDirectory = rootDirectory.standardizedFileURL
        themesDirectory = self.rootDirectory.appendingPathComponent("Themes", isDirectory: true)
        activeThemeFile = self.rootDirectory.appendingPathComponent("active-theme.json")
        self.validator = validator
        fileManager = FileManager()
    }

    public func list(includeBuiltIns: Bool = true) throws -> [ThemeSummary] {
        try ensureDirectories()
        var summaries: [ThemeSummary] = includeBuiltIns
            ? BuiltInThemes.all.map { ThemeSummary(document: $0, isBuiltIn: true) }
            : []

        let urls = try fileManager.contentsOfDirectory(
            at: themesDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for url in urls where url.pathExtension.lowercased() == "json" {
            let document = try decodeTheme(at: url)
            summaries.append(ThemeSummary(document: document, isBuiltIn: false))
        }

        return summaries.sorted {
            let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            if comparison == .orderedSame {
                return $0.id.uuidString < $1.id.uuidString
            }
            return comparison == .orderedAscending
        }
    }

    public func load(id: UUID) throws -> ThemeDocument {
        if let builtIn = BuiltInThemes.theme(id: id) {
            return builtIn
        }

        let url = themeFileURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else {
            throw ThemeRepositoryError.themeNotFound(id)
        }
        return try decodeTheme(at: url)
    }

    public func contains(id: UUID) -> Bool {
        BuiltInThemes.theme(id: id) != nil
            || fileManager.fileExists(atPath: themeFileURL(id: id).path)
    }

    @discardableResult
    public func save(
        _ document: ThemeDocument,
        collisionPolicy: ThemeCollisionPolicy = .replace
    ) throws -> ThemeDocument {
        try ensureDirectories()
        var savedDocument = document
        let collidesWithBuiltIn = BuiltInThemes.theme(id: document.id) != nil
        let collidesWithUserTheme = fileManager.fileExists(
            atPath: themeFileURL(id: document.id).path
        )

        if collidesWithBuiltIn || collidesWithUserTheme {
            switch collisionPolicy {
            case .fail:
                throw ThemeRepositoryError.themeAlreadyExists(document.id)
            case .replace:
                if collidesWithBuiltIn {
                    throw ThemeRepositoryError.cannotReplaceBuiltIn(document.id)
                }
            case .clone:
                repeat {
                    savedDocument.id = UUID()
                } while contains(id: savedDocument.id)
                savedDocument.metadata.name = Self.copyName(for: savedDocument.metadata.name)
                savedDocument.metadata.updatedAt = Date()
            }
        }

        try validator.validateOrThrow(savedDocument)
        let data = try ThemeJSONCoding.encoder().encode(savedDocument)
        try data.write(to: themeFileURL(id: savedDocument.id), options: .atomic)
        return savedDocument
    }

    public func delete(id: UUID) throws {
        if BuiltInThemes.theme(id: id) != nil {
            throw ThemeRepositoryError.cannotDeleteBuiltIn(id)
        }

        let url = themeFileURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else {
            throw ThemeRepositoryError.themeNotFound(id)
        }
        try fileManager.removeItem(at: url)

        if try activeThemeID() == id {
            try writeActiveThemeID(nil)
        }
    }

    public func activeThemeID() throws -> UUID? {
        guard fileManager.fileExists(atPath: activeThemeFile.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: activeThemeFile)
            return try ThemeJSONCoding.decoder().decode(ActiveThemeRecord.self, from: data).id
        } catch {
            throw ThemeRepositoryError.corruptThemeFile(activeThemeFile.lastPathComponent)
        }
    }

    public func setActiveThemeID(_ id: UUID?) throws {
        if let id, !contains(id: id) {
            throw ThemeRepositoryError.invalidActiveTheme(id)
        }
        try ensureDirectories()
        try writeActiveThemeID(id)
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(
            at: themesDirectory,
            withIntermediateDirectories: true
        )
    }

    private func themeFileURL(id: UUID) -> URL {
        themesDirectory
            .appendingPathComponent(id.uuidString.lowercased())
            .appendingPathExtension("json")
    }

    private func decodeTheme(at url: URL) throws -> ThemeDocument {
        do {
            let data = try Data(contentsOf: url)
            let document = try ThemeJSONCoding.decoder().decode(ThemeDocument.self, from: data)
            try validator.validateOrThrow(document)
            return document
        } catch {
            throw ThemeRepositoryError.corruptThemeFile(url.lastPathComponent)
        }
    }

    private func writeActiveThemeID(_ id: UUID?) throws {
        let data = try ThemeJSONCoding.encoder().encode(ActiveThemeRecord(id: id))
        try data.write(to: activeThemeFile, options: .atomic)
    }

    private static func copyName(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix(" Copy") ? trimmed : "\(trimmed) Copy"
    }
}

private struct ActiveThemeRecord: Codable {
    var id: UUID?
}

enum ThemeJSONCoding {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        JSONDecoder()
    }
}
