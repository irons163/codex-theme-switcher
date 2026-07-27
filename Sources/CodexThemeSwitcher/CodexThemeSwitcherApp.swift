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
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button(
                    model.undoDraftActionName.map {
                        L10n.text("復原 \($0)", "Undo \($0)")
                    } ?? L10n.text("復原", "Undo")
                ) {
                    model.undoDraftChange()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!model.canUndoDraft || model.isBusy)

                Button(
                    model.redoDraftActionName.map {
                        L10n.text("重做 \($0)", "Redo \($0)")
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
