import Foundation

/// The top-level JSON object stored in a single-file `.codextheme` archive.
public struct ThemeArchiveEnvelope: Codable, Equatable, Sendable {
    public var format: String
    public var archiveVersion: Int
    public var exportedAt: Date
    public var theme: ThemeDocument

    public init(
        format: String,
        archiveVersion: Int,
        exportedAt: Date,
        theme: ThemeDocument
    ) {
        self.format = format
        self.archiveVersion = archiveVersion
        self.exportedAt = exportedAt
        self.theme = theme
    }
}

public struct ThemeArchiveInspection: Equatable, Sendable {
    public var format: String
    public var archiveVersion: Int
    public var exportedAt: Date
    public var encodedByteCount: Int
    public var theme: ThemeDocument

    public init(
        format: String,
        archiveVersion: Int,
        exportedAt: Date,
        encodedByteCount: Int,
        theme: ThemeDocument
    ) {
        self.format = format
        self.archiveVersion = archiveVersion
        self.exportedAt = exportedAt
        self.encodedByteCount = encodedByteCount
        self.theme = theme
    }

    public var summary: ThemeSummary {
        ThemeSummary(document: theme, isBuiltIn: false)
    }
}

/// Reads and writes the portable, single JSON `.codextheme` representation.
///
/// Assets remain Base64-encoded inside `ThemeDocument`; no extraction step or
/// archive path is involved, eliminating zip-slip and partial-import hazards.
public struct ThemeArchiveService: Sendable {
    public static let formatIdentifier = "com.codex-theme-switcher.theme"
    public static let currentArchiveVersion = 1

    public var validator: ThemeValidator
    public var maximumArchiveBytes: Int
    private let now: @Sendable () -> Date

    public init(
        validator: ThemeValidator = ThemeValidator(),
        maximumArchiveBytes: Int = 48 * 1_024 * 1_024,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.validator = validator
        self.maximumArchiveBytes = maximumArchiveBytes
        self.now = now
    }

    public func export(_ theme: ThemeDocument, to destination: URL) throws {
        try validator.validateOrThrow(theme)
        let envelope = ThemeArchiveEnvelope(
            format: Self.formatIdentifier,
            archiveVersion: Self.currentArchiveVersion,
            exportedAt: now(),
            theme: theme
        )
        let data = try ThemeJSONCoding.encoder().encode(envelope)
        guard data.count <= maximumArchiveBytes else {
            throw ThemeArchiveError.archiveTooLarge(
                actual: data.count,
                maximum: maximumArchiveBytes
            )
        }

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: destination, options: .atomic)
    }

    public func inspect(_ source: URL) throws -> ThemeArchiveInspection {
        let decoded = try readEnvelope(from: source)
        return ThemeArchiveInspection(
            format: decoded.envelope.format,
            archiveVersion: decoded.envelope.archiveVersion,
            exportedAt: decoded.envelope.exportedAt,
            encodedByteCount: decoded.byteCount,
            theme: decoded.envelope.theme
        )
    }

    @discardableResult
    public func importTheme(
        from source: URL,
        into repository: FileThemeRepository,
        collisionPolicy: ThemeCollisionPolicy = .clone
    ) async throws -> ThemeDocument {
        let decoded = try readEnvelope(from: source)
        return try await repository.save(
            decoded.envelope.theme,
            collisionPolicy: collisionPolicy
        )
    }

    private func readEnvelope(
        from source: URL
    ) throws -> (envelope: ThemeArchiveEnvelope, byteCount: Int) {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: source.path),
           let fileSize = attributes[.size] as? NSNumber,
           fileSize.intValue > maximumArchiveBytes {
            throw ThemeArchiveError.archiveTooLarge(
                actual: fileSize.intValue,
                maximum: maximumArchiveBytes
            )
        }

        let data: Data
        do {
            data = try Data(contentsOf: source, options: .mappedIfSafe)
        } catch {
            throw ThemeArchiveError.unreadableArchive
        }
        guard data.count <= maximumArchiveBytes else {
            throw ThemeArchiveError.archiveTooLarge(
                actual: data.count,
                maximum: maximumArchiveBytes
            )
        }

        let envelope: ThemeArchiveEnvelope
        do {
            envelope = try ThemeJSONCoding.decoder().decode(
                ThemeArchiveEnvelope.self,
                from: data
            )
        } catch {
            throw ThemeArchiveError.unreadableArchive
        }

        guard envelope.format == Self.formatIdentifier else {
            throw ThemeArchiveError.unsupportedFormat(envelope.format)
        }
        guard envelope.archiveVersion == Self.currentArchiveVersion else {
            throw ThemeArchiveError.unsupportedArchiveVersion(envelope.archiveVersion)
        }
        try validator.validateOrThrow(envelope.theme)
        return (envelope, data.count)
    }
}
