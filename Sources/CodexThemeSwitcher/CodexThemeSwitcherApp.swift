import AppKit
import SwiftUI

@main
struct CodexThemeSwitcherApp: App {
    @StateObject private var model: ThemeAppModel
    @StateObject private var updateModel: AppUpdateModel
    @StateObject private var languageSettings: AppLanguageSettings

    init() {
        let themeModel = ThemeAppModel()
        let appUpdateModel = AppUpdateModel()
        let appLanguageSettings = AppLanguageSettings()
        _model = StateObject(wrappedValue: themeModel)
        _updateModel = StateObject(wrappedValue: appUpdateModel)
        _languageSettings = StateObject(
            wrappedValue: appLanguageSettings
        )
        NSApplication.shared.setActivationPolicy(.accessory)
        appUpdateModel.start()
    }

    var body: some Scene {
        MenuBarExtra {
            ThemeSwitcherRootView(
                model: model,
                updateModel: updateModel,
                languageSettings: languageSettings
            )
                .frame(width: 920, height: 720)
        } label: {
            MenuBarBrandIcon()
                .accessibilityLabel(model.activeThemeName ?? L10n.appName)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button(
                    model.undoDraftActionName.map {
                        L10n.format("復原 {0}", "Undo {0}", $0)
                    } ?? L10n.text("復原", "Undo")
                ) {
                    model.undoDraftChange()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!model.canUndoDraft || model.isBusy)

                Button(
                    model.redoDraftActionName.map {
                        L10n.format("重做 {0}", "Redo {0}", $0)
                    } ?? L10n.text("重做", "Redo")
                ) {
                    model.redoDraftChange()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!model.canRedoDraft || model.isBusy)
            }
        }
    }
}
