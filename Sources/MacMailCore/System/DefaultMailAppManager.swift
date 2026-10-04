import Foundation
import CoreServices
import AppKit

public enum DefaultMailAppManager {
    public static let macMailBundleIdentifier = "com.atalayhuryasar.macmail"

    public static var isMacMailDefault: Bool {
        guard let mailtoURL = URL(string: "mailto:") else { return false }
        if let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: mailtoURL),
           let bundle = Bundle(url: defaultAppURL),
           bundle.bundleIdentifier == macMailBundleIdentifier {
            return true
        }
        return false
    }

    @discardableResult
    public static func setMacMailAsDefault() -> Bool {
        let scheme = "mailto" as CFString
        let bundleId = macMailBundleIdentifier as CFString
        let status = LSSetDefaultHandlerForURLScheme(scheme, bundleId)
        return status == noErr
    }

    public static func openMailAppSettings() {
        // macOS manages default email client inside Apple Mail > Settings > General
        let script = """
        tell application "Mail"
            activate
        end tell
        tell application "System Events"
            keystroke "," using command down
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
