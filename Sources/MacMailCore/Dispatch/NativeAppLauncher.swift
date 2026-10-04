import Foundation
import AppKit

public protocol NativeAppLaunching: Sendable {
    func launch(bundleId: String, url: URL, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
}

public struct SystemNativeAppLauncher: NativeAppLaunching {
    public init() {}

    public func launch(bundleId: String, url: URL, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            completion(.failure(NSError(domain: "MacMail", code: 404, userInfo: [NSLocalizedDescriptionKey: "Application with bundle ID \(bundleId) not found."])))
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = false

        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: config) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
