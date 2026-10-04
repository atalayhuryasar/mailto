import SwiftUI
import AppKit
import MailtoCore

@main
struct MailtoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var didSkipInstall: Bool = false

    private var installStatus: InstallationStatus {
        AppLocationDetector.default().evaluate()
    }

    private var shouldPromptInstall: Bool {
        if didSkipInstall { return false }
        switch installStatus {
        case .notInstalled, .updateAvailable:
            return true
        default:
            return false
        }
    }

    private var targetDestinationURL: URL {
        switch installStatus {
        case .notInstalled(let destURL):
            return destURL
        case .updateAvailable(let destURL, _, _):
            return destURL
        default:
            return FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first?.appendingPathComponent("mailto.app")
                ?? URL(fileURLWithPath: "/Applications/mailto.app")
        }
    }

    var body: some Scene {
        Window("mailto:", id: "settings") {
            Group {
                if shouldPromptInstall {
                    AppInstallPromptView(
                        sourceURL: AppLocationDetector.default().runningBundleURL,
                        destinationURL: targetDestinationURL,
                        onSkip: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                didSkipInstall = true
                            }
                        }
                    )
                } else {
                    RootView(settings: appDelegate.settings)
                        .onAppear {
                            appDelegate.handleWindowOpened()
                        }
                        .onDisappear {
                            appDelegate.handleWindowClosed()
                        }
                }
            }
            .onOpenURL { url in
                appDelegate.handleMailto(url: url)
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About mailto:") {
                    appDelegate.handleAboutMenu()
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
