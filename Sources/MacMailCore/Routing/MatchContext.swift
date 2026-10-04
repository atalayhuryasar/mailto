import Foundation

public struct MatchContext: Sendable {
    public let recipients: [EmailAddress]
    public let sourceAppBundleIdentifier: String?

    public init(recipients: [EmailAddress], sourceAppBundleIdentifier: String?) {
        self.recipients = recipients
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
    }
}
