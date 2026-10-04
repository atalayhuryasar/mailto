import Foundation
import AppKit

public struct InstalledMailApp: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { bundleId }
    public let bundleId: String
    public let name: String
    public let url: URL

    public init(bundleId: String, name: String, url: URL) {
        self.bundleId = bundleId
        self.name = name
        self.url = url
    }
}

public struct MailAppDiscovery {
    public static func findInstalledMailApps(excludingBundleId: String? = "com.atalayhuryasar.macmail") -> [InstalledMailApp] {
        guard let mailtoURL = URL(string: "mailto:") else { return [] }
        let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: mailtoURL)

        var apps: [InstalledMailApp] = []
        for url in appURLs {
            guard let bundle = Bundle(url: url),
                  let bundleId = bundle.bundleIdentifier else { continue }

            if let excluding = excludingBundleId, bundleId == excluding {
                continue
            }

            let name = FileManager.default.displayName(atPath: url.path)
            apps.append(InstalledMailApp(bundleId: bundleId, name: name, url: url))
        }

        // Sort: Apple Mail (com.apple.mail) first, then alphabetically
        return apps.sorted { a, b in
            if a.bundleId == "com.apple.mail" { return true }
            if b.bundleId == "com.apple.mail" { return false }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
