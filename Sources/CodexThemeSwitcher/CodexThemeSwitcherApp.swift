import AppKit
import SwiftUI

@main
struct CodexThemeSwitcherApp: App {
    @StateObject private var model = ThemeAppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ThemeSwitcherRootView(model: model)
                .frame(width: 920, height: 720)
        } label: {
            Image(systemName: model.menuBarSymbol)
                .accessibilityLabel(model.activeThemeName ?? L10n.appName)
        }
        .menuBarExtraStyle(.window)
    }
}
