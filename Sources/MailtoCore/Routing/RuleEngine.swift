import Foundation

public struct RuleEngine {
    public static func matches(_ rule: Rule, context: MatchContext) -> Bool {
        guard rule.isEnabled else { return false }

        // Source app condition
        if !rule.sourceAppBundleIdentifiers.isEmpty {
            guard let appId = context.sourceAppBundleIdentifier,
                  rule.sourceAppBundleIdentifiers.contains(appId) else {
                return false
            }
        }

        // Recipient condition: if empty, rule unconditionally matches recipients
        if rule.recipientMatchers.isEmpty {
            return true
        }

        // Must match at least one recipient matcher across any recipient
        return rule.recipientMatchers.contains { matcher in
            let pattern = matcher.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !pattern.isEmpty else { return false }

            return context.recipients.contains { recipient in
                let address = recipient.address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let domain = recipient.domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                switch matcher.kind {
                case .emailAddress:
                    return address == pattern
                case .domain:
                    return domain == pattern
                case .domainAndSubdomains:
                    return domain == pattern || domain.hasSuffix("." + pattern)
                }
            }
        }
    }

    public static func evaluate(rules: [Rule], context: MatchContext) -> Rule? {
        rules.first { matches($0, context: context) }
    }
}
