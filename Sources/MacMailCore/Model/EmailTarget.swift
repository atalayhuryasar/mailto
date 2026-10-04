import Foundation

public enum EmailTarget: Codable, Equatable, Hashable, Sendable {
    case nativeApp(bundleId: String, name: String)
    case webmail(provider: WebmailProvider)
    case customURL(template: String)
    case clipboard

    public var displayName: String {
        switch self {
        case .nativeApp(_, let name):
            return name
        case .webmail(let provider):
            return provider.displayName
        case .customURL:
            return "Custom URL"
        case .clipboard:
            return "Copy to Clipboard"
        }
    }

    public var iconName: String {
        switch self {
        case .nativeApp:
            return "app.badge"
        case .webmail:
            return "globe"
        case .customURL:
            return "link"
        case .clipboard:
            return "doc.on.clipboard"
        }
    }
}
