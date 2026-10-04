import Foundation
import AppKit

public protocol URLOpening: Sendable {
    func open(_ url: URL, completion: @escaping @Sendable (Bool) -> Void)
}

public struct SystemURLOpener: URLOpening {
    public init() {}

    public func open(_ url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            completion(error == nil)
        }
    }
}

public protocol TargetDispatching: Sendable {
    func dispatch(target: EmailTarget, message: MailtoMessage, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
}

public final class TargetDispatcher: TargetDispatching, @unchecked Sendable {
    private let clipboardWriter: ClipboardWriting
    private let urlOpener: URLOpening
    private let appLauncher: NativeAppLaunching

    public init(
        clipboardWriter: ClipboardWriting = SystemClipboardWriter(),
        urlOpener: URLOpening = SystemURLOpener(),
        appLauncher: NativeAppLaunching = SystemNativeAppLauncher()
    ) {
        self.clipboardWriter = clipboardWriter
        self.urlOpener = urlOpener
        self.appLauncher = appLauncher
    }

    public func dispatch(target: EmailTarget, message: MailtoMessage, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        switch target {
        case .clipboard:
            let addresses = message.to.map(\.address).joined(separator: ", ")
            clipboardWriter.copy(text: addresses)
            completion(.success(()))

        case .webmail, .customURL:
            guard let url = WebmailURLBuilder.buildURL(target: target, message: message) else {
                completion(.failure(NSError(domain: "mailto", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to construct valid URL from template."])))
                return
            }
            urlOpener.open(url) { success in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "mailto", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to open URL in browser."])))
                }
            }

        case .nativeApp(let bundleId, _):
            appLauncher.launch(bundleId: bundleId, url: message.rawURL, completion: completion)
        }
    }
}
