import SwiftUI
import AppKit
import MacMailCore

@main
struct MacMailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("MacMail", id: "settings") {
            RootView(settings: appDelegate.settings)
                .onAppear {
                    appDelegate.isSettingsWindowOpen = true
                }
                .onDisappear {
                    appDelegate.isSettingsWindowOpen = false
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
