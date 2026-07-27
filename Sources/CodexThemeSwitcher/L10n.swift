import Foundation

enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"
    case french = "fr"
    case spanish = "es"
    case japanese = "ja"
    case korean = "ko"

    static func resolve(
        preferredLanguages: [String]
    ) -> AppLanguage {
        for identifier in preferredLanguages {
            if let language = resolve(identifier: identifier) {
                return language
            }
        }
        return .english
    }

    private static func resolve(
        identifier: String
    ) -> AppLanguage? {
        let normalized = identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        guard let languageCode = normalized
            .split(separator: "-", omittingEmptySubsequences: true)
            .first
            .map(String.init) else {
            return nil
        }

        switch languageCode {
        case "en":
            return .english
        case "fr":
            return .french
        case "es":
            return .spanish
        case "ja":
            return .japanese
        case "ko":
            return .korean
        case "zh":
            let components = Set(
                normalized
                    .split(separator: "-", omittingEmptySubsequences: true)
                    .dropFirst()
                    .map { String($0) }
            )
            if components.contains("hant") {
                return .traditionalChinese
            }
            if components.contains("hans") {
                return .simplifiedChinese
            }
            if !components.isDisjoint(with: ["tw", "hk", "mo"]) {
                return .traditionalChinese
            }
            return .simplifiedChinese
        default:
            return nil
        }
    }
}

enum L10nCatalog {
    static let translations: [AppLanguage: [String: String]] = [
        .simplifiedChinese: L10nCatalogCJK.simplifiedChinese,
        .french: L10nCatalogWestern.french,
        .spanish: L10nCatalogWestern.spanish,
        .japanese: L10nCatalogCJK.japanese,
        .korean: L10nCatalogCJK.korean
    ]

    static func translation(
        for key: String,
        language: AppLanguage
    ) -> String? {
        translations[language]?[key]
    }
}

enum L10n {
    static var language: AppLanguage {
        AppLanguage.resolve(
            preferredLanguages: Locale.preferredLanguages
        )
    }

    static func text(_ zhHant: String, _ en: String) -> String {
        text(zhHant, en, language: language)
    }

    static func text(
        _ zhHant: String,
        _ en: String,
        language: AppLanguage
    ) -> String {
        switch language {
        case .english:
            return en
        case .traditionalChinese:
            return zhHant
        case .simplifiedChinese, .french, .spanish, .japanese, .korean:
            return L10nCatalog.translation(for: en, language: language)
                ?? en
        }
    }

    static func format(
        _ zhHant: String,
        _ en: String,
        _ values: String...
    ) -> String {
        format(
            zhHant,
            en,
            values: values,
            language: language
        )
    }

    static func format(
        _ zhHant: String,
        _ en: String,
        values: [String],
        language: AppLanguage
    ) -> String {
        var result = text(zhHant, en, language: language)
        for (index, value) in values.enumerated() {
            result = result.replacingOccurrences(
                of: "{\(index)}",
                with: value
            )
        }
        return result
    }

    static var appName: String {
        text("Codex 主題切換器", "Codex Theme Switcher")
    }

    static var themes: String {
        text("主題庫", "Themes")
    }

    static var preview: String {
        text("預覽", "Preview")
    }

    static var skin: String {
        text("背景與玻璃", "Skin")
    }

    static var colors: String {
        text("色彩", "Colors")
    }

    static var typography: String {
        text("字體與版面", "Type & Layout")
    }

    static var components: String {
        text("元件", "Components")
    }

    static var rules: String {
        text("規則", "Rules")
    }

    static var rawCSS: String {
        text("進階 CSS", "Advanced CSS")
    }

    static var assets: String {
        text("素材", "Assets")
    }

    static var info: String {
        text("資訊", "Info")
    }

    static var apply: String {
        text("套用", "Apply")
    }

    static var save: String {
        text("儲存", "Save")
    }

    static var duplicate: String {
        text("製作可編輯副本", "Make editable copy")
    }

    static var importTheme: String {
        text("導入", "Import")
    }

    static var exportTheme: String {
        text("導出", "Export")
    }

    static var attach: String {
        text("啟動並連接 Codex", "Launch + Attach Codex")
    }

    static var clear: String {
        text("恢復 Codex 原始樣式", "Restore Codex style")
    }

    static var quit: String {
        text("結束", "Quit")
    }

    static var newTheme: String {
        text("新增主題", "New theme")
    }
}
