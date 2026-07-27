import CodexThemeRuntime
import CodexThemeSwitcherCore
import Foundation

enum AppErrorLocalization {
    static func message(for error: Error) -> String {
        switch error {
        case let error as ThemeAppError:
            return error.localizedDescription
        case let error as RuntimeLocationError:
            return message(for: error)
        case let error as ThemeRuntimeFailure:
            return runtimeMessage(
                code: error.code,
                fallback: error.message
            )
        case let error as ThemeRepositoryError:
            return message(for: error)
        case let error as ThemeArchiveError:
            return message(for: error)
        case let error as ThemeCompilationError:
            return message(for: error)
        case let error as ThemeValidationError:
            return message(for: error)
        default:
            return L10n.format(
                "操作失敗：{0}",
                "Operation failed: {0}",
                error.localizedDescription
            )
        }
    }

    static func runtimeMessage(
        code: String?,
        fallback: String?
    ) -> String {
        switch code {
        case "missing-codex-app":
            return L10n.text(
                "找不到 Codex App。",
                "The Codex app could not be found."
            )
        case "missing-cdp-target":
            return L10n.text(
                "找不到可連接的 Codex 畫面。",
                "No attachable Codex renderer was found."
            )
        case "cdp-protocol-error", "renderer-error":
            return L10n.text(
                "無法與 Codex 畫面通訊。",
                "Could not communicate with the Codex renderer."
            )
        case "payload-too-large", "theme-too-large":
            return L10n.text(
                "主題資料過大。",
                "The theme data is too large."
            )
        case "invalid-json", "invalid-theme":
            return L10n.text(
                "主題資料無效。",
                "The theme data is invalid."
            )
        case "invalid-theme-asset":
            return L10n.text(
                "主題素材無效。",
                "A theme asset is invalid."
            )
        case "theme-asset-too-large":
            return L10n.text(
                "主題素材過大。",
                "A theme asset is too large."
            )
        case "theme-assets-too-large":
            return L10n.text(
                "主題素材總容量過大。",
                "The theme assets are too large in total."
            )
        case "missing-theme-asset":
            return L10n.text(
                "主題引用了不存在的素材。",
                "The theme references a missing asset."
            )
        case "unreferenced-theme-asset":
            return L10n.text(
                "主題包含未被引用的素材。",
                "The theme contains an unreferenced asset."
            )
        case "unsafe-css":
            return L10n.text(
                "主題 CSS 包含不安全的內容。",
                "The theme CSS contains unsafe content."
            )
        case "unauthorized":
            return L10n.text(
                "Runtime 拒絕了這次操作。",
                "The runtime rejected the request."
            )
        case "not-found":
            return L10n.text(
                "找不到 Runtime 端點。",
                "The runtime endpoint was not found."
            )
        case "usage":
            return L10n.text(
                "Runtime 指令無效。",
                "The runtime command is invalid."
            )
        case "bridge-error", "http-error", "runtime-error":
            return L10n.text(
                "無法與 Codex 通訊。",
                "Could not communicate with Codex."
            )
        default:
            if L10n.language == .english, let fallback, !fallback.isEmpty {
                return fallback
            }
            return L10n.text(
                "Codex runtime 操作失敗。",
                "The Codex runtime operation failed."
            )
        }
    }

    private static func message(
        for error: RuntimeLocationError
    ) -> String {
        switch error {
        case .missingHelper:
            return L10n.text(
                "找不到內附的 Codex Theme runtime helper。",
                "The bundled Codex Theme runtime helper was not found."
            )
        case .missingNode:
            return L10n.text(
                "找不到相容的 Node.js runtime。",
                "A compatible Node.js runtime was not found."
            )
        }
    }

    private static func message(
        for error: ThemeRepositoryError
    ) -> String {
        switch error {
        case let .themeNotFound(id):
            return L10n.format(
                "找不到主題 {0}。",
                "Theme {0} was not found.",
                id.uuidString
            )
        case let .themeAlreadyExists(id):
            return L10n.format(
                "主題 {0} 已存在。",
                "Theme {0} already exists.",
                id.uuidString
            )
        case let .cannotReplaceBuiltIn(id):
            return L10n.format(
                "無法取代內建主題 {0}。",
                "Built-in theme {0} cannot be replaced.",
                id.uuidString
            )
        case let .cannotDeleteBuiltIn(id):
            return L10n.format(
                "無法刪除內建主題 {0}。",
                "Built-in theme {0} cannot be deleted.",
                id.uuidString
            )
        case let .corruptThemeFile(name):
            return L10n.format(
                "主題檔案 {0} 已損壞或不受支援。",
                "Theme file {0} is corrupt or unsupported.",
                name
            )
        case let .invalidActiveTheme(id):
            return L10n.format(
                "主題 {0} 不存在，無法設為使用中。",
                "Theme {0} cannot be made active because it does not exist.",
                id.uuidString
            )
        }
    }

    private static func message(
        for error: ThemeArchiveError
    ) -> String {
        switch error {
        case let .archiveTooLarge(actual, maximum):
            return L10n.format(
                "主題封存檔為 {0} bytes；上限為 {1} bytes。",
                "The theme archive is {0} bytes; the maximum is {1} bytes.",
                String(actual),
                String(maximum)
            )
        case let .unsupportedFormat(format):
            return L10n.format(
                "不支援的主題封存格式：{0}。",
                "Unsupported theme archive format: {0}.",
                format
            )
        case let .unsupportedArchiveVersion(version):
            return L10n.format(
                "不支援的主題封存版本：{0}。",
                "Unsupported theme archive version: {0}.",
                String(version)
            )
        case .unreadableArchive:
            return L10n.text(
                "無法讀取主題封存檔。",
                "The theme archive could not be read."
            )
        }
    }

    private static func message(
        for error: ThemeCompilationError
    ) -> String {
        switch error {
        case let .validationFailed(error):
            return message(for: error)
        case let .missingAsset(id):
            return L10n.format(
                "CSS 引用了不存在的主題素材 {0}。",
                "CSS references missing theme asset {0}.",
                id.uuidString
            )
        case let .malformedAssetReference(reference):
            return L10n.format(
                "主題素材參照格式錯誤：{0}",
                "Malformed theme asset reference: {0}",
                reference
            )
        }
    }

    private static func message(
        for error: ThemeValidationError
    ) -> String {
        let paths = error.issues
            .filter { $0.severity == .error }
            .prefix(3)
            .map(\.path)
            .joined(separator: ", ")
        guard !paths.isEmpty else {
            return L10n.text(
                "主題驗證失敗。",
                "Theme validation failed."
            )
        }
        return L10n.format(
            "主題驗證失敗，請檢查：{0}",
            "Theme validation failed. Check: {0}",
            paths
        )
    }
}
