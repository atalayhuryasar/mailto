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
                    appDelegate.handleWindowOpened()
                }
                .onDisappear {
                    appDelegate.handleWindowClosed()
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About mailto:") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
                Button("Check for Updates...") {
                    appDelegate.handleCheckForUpdatesMenu()
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appDelegate.openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button("mailto: Website & Documentation") {
                    appDelegate.handleOpenHelpMenu()
                }
            }
        }
    }
}
