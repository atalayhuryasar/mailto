import AppKit
import SwiftUI
import MacMailCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public let settings = SettingsStore()
    public lazy var router = Router(settings: settings)
    public let dispatcher = TargetDispatcher()

    public var isSettingsWindowOpen: Bool = false
    private var frontmostAppAtLaunch: String?

    public func applicationWillFinishLaunching(_ notification: Notification) {
        // Capture caller before activation changes frontmost application
        frontmostAppAtLaunch = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // If launched normally (not via URL/event) and no window visible, show settings
        if !isSettingsWindowOpen && NSApp.windows.filter({ $0.isVisible }).isEmpty {
            openSettingsWindow()
        }
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        guard let mailtoURL = urls.first(where: { $0.scheme?.lowercased() == "mailto" }) else {
            return
        }

        handleMailto(url: mailtoURL)
    }

    public func handleMailto(url: URL) {
        let msg = MailtoParser.parse(url)
        let routeResult = router.route(message: msg)

        dispatcher.dispatch(target: routeResult.target, message: msg) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if LaunchContext.shouldTerminateAfterRouting(isSettingsWindowOpen: self.isSettingsWindowOpen) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    public func openSettingsWindow() {
        isSettingsWindowOpen = true
        NSApp.activate(ignoringOtherApps: true)
        if let existing = NSApp.windows.first(where: { $0.title == "General" || $0.title == "Rules" || $0.title == "MacMail" }) {
            existing.makeKeyAndOrderFront(nil)
        }
    }
}
