import Foundation

public struct RouteResult: Equatable, Sendable {
    public let target: EmailTarget
    public let matchedRule: Rule?
    public let wasModifierActive: Bool

    public init(target: EmailTarget, matchedRule: Rule?, wasModifierActive: Bool) {
        self.target = target
        self.matchedRule = matchedRule
        self.wasModifierActive = wasModifierActive
    }
}

public final class Router: @unchecked Sendable {
    private let settings: SettingsStore
    private let modifierReader: ModifierKeyReading
    private let sourceResolver: SourceAppResolving
    private let ownBundleIdentifier: String

    public init(
        settings: SettingsStore,
        modifierReader: ModifierKeyReading = SystemModifierKeyReader(),
        sourceResolver: SourceAppResolving = SystemSourceAppResolver(),
        ownBundleIdentifier: String = "com.atalayhuryasar.mailto"
    ) {
        self.settings = settings
        self.modifierReader = modifierReader
        self.sourceResolver = sourceResolver
        self.ownBundleIdentifier = ownBundleIdentifier
    }

    public func route(message: MailtoMessage) -> RouteResult {
        // 1. Check modifier key override (Fn)
        if modifierReader.isAlternativeModifierActive() {
            let target = sanitizeTarget(settings.alternativeTarget)
            return RouteResult(target: target, matchedRule: nil, wasModifierActive: true)
        }

        // 2. Resolve source app and recipients
        let sourceApp = sourceResolver.resolveFrontmostApp()
        let recipients = message.to + message.cc + message.bcc
        let matchContext = MatchContext(recipients: recipients, sourceAppBundleIdentifier: sourceApp)

        // 3. Evaluate rules
        if let matchedRule = RuleEngine.evaluate(rules: settings.rules, context: matchContext) {
            let target = sanitizeTarget(matchedRule.target)
            return RouteResult(target: target, matchedRule: matchedRule, wasModifierActive: false)
        }

        // 4. Default to Primary target
        let target = sanitizeTarget(settings.primaryTarget)
        return RouteResult(target: target, matchedRule: nil, wasModifierActive: false)
    }

    private func sanitizeTarget(_ target: EmailTarget) -> EmailTarget {
        if case .nativeApp(let bundleId, _) = target, bundleId == ownBundleIdentifier {
            // Self-loop protection: fallback to system Apple Mail
            return .nativeApp(bundleId: "com.apple.mail", name: "Mail")
        }
        return target
    }
}
