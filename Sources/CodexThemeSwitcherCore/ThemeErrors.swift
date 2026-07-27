import Foundation

public enum ThemeRepositoryError: LocalizedError, Equatable, Sendable {
    case themeNotFound(UUID)
    case themeAlreadyExists(UUID)
    case cannotReplaceBuiltIn(UUID)
    case cannotDeleteBuiltIn(UUID)
    case corruptThemeFile(String)
    case invalidActiveTheme(UUID)

    public var errorDescription: String? {
        switch self {
        case let .themeNotFound(id):
            return "Theme \(id.uuidString) was not found."
        case let .themeAlreadyExists(id):
            return "Theme \(id.uuidString) already exists."
        case let .cannotReplaceBuiltIn(id):
            return "Built-in theme \(id.uuidString) cannot be replaced."
        case let .cannotDeleteBuiltIn(id):
            return "Built-in theme \(id.uuidString) cannot be deleted."
        case let .corruptThemeFile(name):
            return "Theme file \(name) is corrupt or unsupported."
        case let .invalidActiveTheme(id):
            return "Theme \(id.uuidString) cannot be made active because it does not exist."
        }
    }
}

public enum ThemeArchiveError: LocalizedError, Equatable, Sendable {
    case archiveTooLarge(actual: Int, maximum: Int)
    case unsupportedFormat(String)
    case unsupportedArchiveVersion(Int)
    case unreadableArchive

    public var errorDescription: String? {
        switch self {
        case let .archiveTooLarge(actual, maximum):
            return "Theme archive is \(actual) bytes; the maximum is \(maximum) bytes."
        case let .unsupportedFormat(format):
            return "Unsupported theme archive format: \(format)."
        case let .unsupportedArchiveVersion(version):
            return "Unsupported theme archive version: \(version)."
        case .unreadableArchive:
            return "The theme archive could not be read."
        }
    }
}
