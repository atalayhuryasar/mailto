import Foundation

public enum WebmailProvider: String, CaseIterable, Codable, Sendable {
    case gmail
    case fastmail
    case outlook365
    case outlookCom
    case yahoo
    case yandex
    case aol
    case zoho

    public var displayName: String {
        switch self {
        case .gmail: return "Gmail"
        case .fastmail: return "Fastmail"
        case .outlook365: return "Outlook 365"
        case .outlookCom: return "Outlook.com"
        case .yahoo: return "Yahoo"
        case .yandex: return "Yandex"
        case .aol: return "AOL"
        case .zoho: return "Zoho"
        }
    }
}
