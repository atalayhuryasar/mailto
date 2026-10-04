import Foundation

public enum MatcherKind: String, Codable, CaseIterable, Sendable {
    case emailAddress
    case domain
    case domainAndSubdomains

    public var title: String {
        switch self {
        case .emailAddress: return "Email address"
        case .domain: return "Domain"
        case .domainAndSubdomains: return "Domain and subdomains"
        }
    }

    public var explanatoryText: String {
        switch self {
        case .emailAddress:
            return "Matches the exact email address."
        case .domain:
            return "Matches addresses on the exact domain. It does not match subdomains."
        case .domainAndSubdomains:
            return "Matches the domain and any of its subdomains."
        }
    }
}

public struct RecipientMatcher: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var kind: MatcherKind
    public var value: String

    public init(id: UUID = UUID(), kind: MatcherKind, value: String) {
        self.id = id
        self.kind = kind
        self.value = value
    }
}
