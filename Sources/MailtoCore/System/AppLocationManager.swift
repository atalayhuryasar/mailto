import Foundation
import AppKit

public final class AppLocationManager: @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Copies the app bundle from source to destination, replacing any existing item.
    public func copyAppBundle(from sourceURL: URL, to destinationURL: URL) throws {
        let parentDir = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    /// Installs the app bundle from source to destination. If `cleanSource` is true,
    /// moves the source bundle to Trash (falling back to removal if trash is unavailable).
    public func installApp(from sourceURL: URL, to destinationURL: URL, cleanSource: Bool = false) throws {
        try copyAppBundle(from: sourceURL, to: destinationURL)
        if cleanSource {
            // If running from AppTranslocation, find original bundle in ~/Downloads
            if sourceURL.path.contains("/AppTranslocation/") {
                if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                    let downloadApp = downloadsURL.appendingPathComponent(sourceURL.lastPathComponent)
                    if fileManager.fileExists(atPath: downloadApp.path) {
                        do {
                            try fileManager.trashItem(at: downloadApp, resultingItemURL: nil)
                        } catch {
                            try? fileManager.removeItem(at: downloadApp)
                        }
                    }
                }
            }

            do {
                try fileManager.trashItem(at: sourceURL, resultingItemURL: nil)
            } catch {
                try? fileManager.removeItem(at: sourceURL)
            }
        }
    }

    /// Strips the macOS Gatekeeper quarantine extended attribute from the application bundle.
    public func stripQuarantine(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-dr", "com.apple.quarantine", url.path]
        try? process.run()
        process.waitUntilExit()
    }

    /// Launches the app at destinationURL and terminates the calling application.
    @MainActor
    public func relaunchAndTerminate(at applicationURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", applicationURL.path]
        try? process.run()
        NSApp.terminate(nil)
    }

    /// Checks the current running location against /Applications and prompts the user if needed.
    /// Returns true if an action or alert was presented, false otherwise.
    public typealias InstallPromptHandler = @MainActor (_ sourceURL: URL, _ destinationURL: URL) -> Bool

    @MainActor
    @discardableResult
    public func promptAndHandleIfNeeded(
        detector: AppLocationDetector = .default(),
        sourceURL: URL? = nil,
        customInstallPrompter: InstallPromptHandler? = nil
    ) -> Bool {
        let runningSource = sourceURL ?? detector.runningBundleURL
        let status = detector.evaluate()

        switch status {
        case .installedInApplications, .runningFromDevOrBuild:
            return false

        case .notInstalled(let destinationURL):
            if let customPrompter = customInstallPrompter {
                return customPrompter(runningSource, destinationURL)
            }

            let alert = NSAlert()
            alert.messageText = "Move to Applications folder?"
            alert.informativeText = "mailto: works best when located in your Applications folder. Moving it keeps your installation safe and ensures email routing always works properly."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Move to Applications")
            alert.addButton(withTitle: "Do Not Move")

            let response = alert.centered().runModal()
            if response == .alertFirstButtonReturn {
                do {
                    try installApp(from: runningSource, to: destinationURL, cleanSource: true)
                    stripQuarantine(at: destinationURL)
                    relaunchAndTerminate(at: destinationURL)
                    return true
                } catch {
                    showErrorAlert(message: "Failed to move application", error: error)
                    return false
                }
            }
            return false

        case .alreadyInstalledSameOrOlder(let installedURL, let installedVersion, _):
            let alert = NSAlert()
            alert.messageText = "mailto: is Already Installed"
            alert.informativeText = "A copy of mailto: (v\(installedVersion)) is already installed in your Applications folder.\n\nThe existing application will be opened."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Installed App")
            alert.addButton(withTitle: "Cancel")

            let response = alert.centered().runModal()
            if response == .alertFirstButtonReturn {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: installedURL, configuration: config) { _, _ in
                    Task { @MainActor in
                        NSApp.terminate(nil)
                    }
                }
                return true
            }
            return false

        case .updateAvailable(let installedURL, let installedVersion, let newVersion):
            let alert = NSAlert()
            alert.messageText = "Update mailto: to v\(newVersion)?"
            alert.informativeText = "An existing installation of mailto: (v\(installedVersion)) was found in your Applications folder.\n\nWould you like to update it to v\(newVersion) and relaunch?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Update & Relaunch")
            alert.addButton(withTitle: "Not Now")

            let response = alert.centered().runModal()
            if response == .alertFirstButtonReturn {
                do {
                    try copyAppBundle(from: runningSource, to: installedURL)
                    stripQuarantine(at: installedURL)
                    relaunchAndTerminate(at: installedURL)
                    return true
                } catch {
                    showErrorAlert(message: "Failed to update application", error: error)
                    return false
                }
            }
            return false
        }
    }

    @MainActor
    private func showErrorAlert(message: String, error: Error) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.centered().runModal()
    }
}
