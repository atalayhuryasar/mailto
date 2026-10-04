import Foundation

public final class SettingsStore: ObservableObject, @unchecked Sendable {
    private let defaults: UserDefaults

    private enum Keys {
        static let primaryTarget = "primaryTarget"
        static let alternativeTarget = "alternativeTarget"
        static let rules = "rules"
    }

    @Published public var primaryTarget: EmailTarget {
        didSet { save() }
    }

    @Published public var alternativeTarget: EmailTarget {
        didSet { save() }
    }

    @Published public var rules: [Rule] {
        didSet { save() }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load primaryTarget
        if let data = defaults.data(forKey: Keys.primaryTarget),
           let target = try? JSONDecoder().decode(EmailTarget.self, from: data) {
            self.primaryTarget = target
        } else {
            self.primaryTarget = .nativeApp(bundleId: "com.apple.mail", name: "Mail")
        }

        // Load alternativeTarget
        if let data = defaults.data(forKey: Keys.alternativeTarget),
           let target = try? JSONDecoder().decode(EmailTarget.self, from: data) {
            self.alternativeTarget = target
        } else {
            self.alternativeTarget = .clipboard
        }

        // Load rules
        if let data = defaults.data(forKey: Keys.rules),
           let decodedRules = try? JSONDecoder().decode([Rule].self, from: data) {
            self.rules = decodedRules
        } else {
            self.rules = []
        }
    }

    public func save() {
        if let data = try? JSONEncoder().encode(primaryTarget) {
            defaults.set(data, forKey: Keys.primaryTarget)
        }
        if let data = try? JSONEncoder().encode(alternativeTarget) {
            defaults.set(data, forKey: Keys.alternativeTarget)
        }
        if let data = try? JSONEncoder().encode(rules) {
            defaults.set(data, forKey: Keys.rules)
        }
    }
}
