import AppKit
import SwiftUI
import MailtoCore

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
        // When launched directly (not via mailto: URL dispatch), activate UI immediately
        if !isSettingsWindowOpen {
            handleWindowOpened()
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
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

    public func handleWindowOpened() {
        // Check installation location and prompt user if needed (e.g. AppTranslocation or duplicate install)
        if AppLocationManager().promptAndHandleIfNeeded() {
            return
        }

        isSettingsWindowOpen = true
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
        NSApp.activate(ignoringOtherApps: true)

        if let existing = NSApp.windows.first(where: { $0.title == "General" || $0.title == "Rules" || $0.title == "mailto:" }) {
            existing.makeKeyAndOrderFront(nil)
        }

        // Check for updates in background if enabled
        if settings.automaticallyCheckForUpdates {
            Task {
                await checkSilentlyForUpdates()
            }
        }
    }

    public func openSettingsWindow() {
        handleWindowOpened()
    }

    public func handleWindowClosed() {
        isSettingsWindowOpen = false
        NSApp.terminate(nil)
    }

    // MARK: - Native Menu Bar Setup
    public func setupMenuBar() {
        let mainMenu = NSMenu()

        // 1. Application Menu ("mailto:")
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "mailto:")

        let aboutItem = NSMenuItem(
            title: "About mailto:",
            action: #selector(handleAboutMenu),
            keyEquivalent: ""
        )
        aboutItem.target = self
        appMenu.addItem(aboutItem)

        let checkUpdatesItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(handleCheckForUpdatesMenu),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        appMenu.addItem(checkUpdatesItem)

        appMenu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(handleOpenSettingsMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(NSMenuItem.separator())

        let hideItem = NSMenuItem(
            title: "Hide mailto:",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        appMenu.addItem(hideItem)

        let hideOthersItem = NSMenuItem(
            title: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        )
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)

        let showAllItem = NSMenuItem(
            title: "Show All",
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(showAllItem)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit mailto:",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. Edit Menu (Standard Undo/Redo/Cut/Copy/Paste/Select All)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        // 4. Help Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        let helpLinkItem = NSMenuItem(title: "mailto: Website & Documentation", action: #selector(handleOpenHelpMenu), keyEquivalent: "?")
        helpLinkItem.target = self
        helpMenu.addItem(helpLinkItem)
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Actions
    @objc public func handleAboutMenu() {
        let credits = NSMutableAttributedString()
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        pStyle.lineSpacing = 4

        credits.append(NSAttributedString(
            string: "Lightweight, zero-footprint mailto: router for macOS.\n\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: pStyle
            ]
        ))

        credits.append(NSAttributedString(
            string: "Created by Atalay Huryasar\n100% Open Source • MIT License\n\n",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 11),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: pStyle
            ]
        ))

        if let siteURL = URL(string: "https://mailto.huryasar.com") {
            credits.append(NSAttributedString(
                string: "mailto.huryasar.com",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .link: siteURL,
                    .foregroundColor: NSColor.linkColor,
                    .paragraphStyle: pStyle
                ]
            ))
        }

        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: credits
        ])
    }

    @objc public func handleCheckForUpdatesMenu() {
        Task {
            let alert = NSAlert()
            do {
                let result = try await UpdateChecker().checkForUpdates(currentVersion: MailtoCoreVersion)
                await MainActor.run {
                    switch result {
                    case .updateAvailable(let newVersion, let release):
                        promptUpdateAvailable(newVersion: newVersion, release: release)
                    case .upToDate:
                        alert.messageText = "You're Up to Date!"
                        alert.informativeText = "mailto: v\(MailtoCoreVersion) is currently the newest version."
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            } catch {
                await MainActor.run {
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Unable to check for updates: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    @objc public func handleOpenHelpMenu() {
        if let url = URL(string: "https://mailto.huryasar.com") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc public func handleOpenSettingsMenu() {
        openSettingsWindow()
    }

    private func checkSilentlyForUpdates() async {
        do {
            let result = try await UpdateChecker().checkForUpdates(currentVersion: MailtoCoreVersion)
            if case .updateAvailable(let newVersion, let release) = result {
                await MainActor.run {
                    promptUpdateAvailable(newVersion: newVersion, release: release)
                }
            }
        } catch {
            // Silently ignore background network errors
        }
    }

    private func promptUpdateAvailable(newVersion: String, release: ReleaseInfo) {
        let alert = NSAlert()
        alert.messageText = "A new version of mailto: is available!"
        alert.informativeText = "mailto: v\(newVersion) is available (you currently have v\(MailtoCoreVersion)).\n\nWould you like to open the download page?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: release.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
