import Foundation
import CoreServices
import AppKit

public enum DefaultMailAppManager {
    public static let mailtoBundleIdentifier = "com.atalayhuryasar.mailto"

    public static func isAppDefault(bundleIdentifier: String, scheme: String = "mailto") -> Bool {
        guard let url = URL(string: "\(scheme):") else { return false }
        if let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: url),
           let bundle = Bundle(url: defaultAppURL),
           bundle.bundleIdentifier == bundleIdentifier {
            return true
        }
        return false
    }

    public static var isMailtoDefault: Bool {
        return isAppDefault(bundleIdentifier: mailtoBundleIdentifier)
    }

    @discardableResult
    public static func setMailtoAsDefault() -> Bool {
        let scheme = "mailto" as CFString
        let bundleId = mailtoBundleIdentifier as CFString
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
