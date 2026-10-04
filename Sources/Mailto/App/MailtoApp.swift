import SwiftUI
import AppKit
import MailtoCore

@main
struct MailtoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("mailto:", id: "settings") {
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
