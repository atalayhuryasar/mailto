import Foundation

public struct Rule: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var target: EmailTarget
    public var recipientMatchers: [RecipientMatcher]
    public var sourceAppBundleIdentifiers: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        target: EmailTarget,
        recipientMatchers: [RecipientMatcher] = [],
        sourceAppBundleIdentifiers: [String] = []
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.target = target
        self.recipientMatchers = recipientMatchers
        self.sourceAppBundleIdentifiers = sourceAppBundleIdentifiers
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
