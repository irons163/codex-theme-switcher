import Foundation

enum L10n {
    static var usesChinese: Bool {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
    }

    static func text(_ zh: String, _ en: String) -> String {
        usesChinese ? zh : en
    }

    static let appName = text("Codex 主題切換器", "Codex Theme Switcher")
    static let themes = text("主題庫", "Themes")
    static let preview = text("預覽", "Preview")
    static let skin = text("背景與玻璃", "Skin")
    static let colors = text("色彩", "Colors")
    static let typography = text("字體與版面", "Type & Layout")
    static let components = text("元件", "Components")
    static let rules = text("規則", "Rules")
    static let rawCSS = text("進階 CSS", "Advanced CSS")
    static let assets = text("素材", "Assets")
    static let info = text("資訊", "Info")
    static let apply = text("套用", "Apply")
    static let save = text("儲存", "Save")
    static let duplicate = text("製作可編輯副本", "Make editable copy")
    static let importTheme = text("導入", "Import")
    static let exportTheme = text("導出", "Export")
    static let attach = text("啟動並連接 Codex", "Launch + Attach Codex")
    static let clear = text("恢復 Codex 原始樣式", "Restore Codex style")
    static let quit = text("結束", "Quit")
    static let newTheme = text("新增主題", "New theme")
}
