import Testing
import Foundation
@testable import MacMailCore

@Test func testRuleSerializationRoundTrip() throws {
    let rule = Rule(
        id: UUID(),
        name: "Work Domain",
        isEnabled: true,
        target: .webmail(provider: .gmail),
        recipientMatchers: [
            RecipientMatcher(kind: .domain, value: "work.com"),
            RecipientMatcher(kind: .domainAndSubdomains, value: "corp.org")
        ],
        sourceAppBundleIdentifiers: ["com.tinyspeck.slackmacgap"]
    )
    let data = try JSONEncoder().encode(rule)
    let decoded = try JSONDecoder().decode(Rule.self, from: data)
    #expect(decoded == rule)
}

@Test func testSettingsDefaultValues() {
    let defaults = UserDefaults(suiteName: "test-defaults-\(UUID().uuidString)")!
    let settings = SettingsStore(defaults: defaults)
    #expect(settings.primaryTarget == .nativeApp(bundleId: "com.apple.mail", name: "Mail"))
    #expect(settings.alternativeTarget == .clipboard)
    #expect(settings.rules.isEmpty)
}

@Test func testSettingsPersistence() {
    let suiteName = "test-persistence-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    let settings = SettingsStore(defaults: defaults)
    
    let newRule = Rule(
        id: UUID(),
        name: "Personal",
        isEnabled: true,
        target: .clipboard,
        recipientMatchers: [RecipientMatcher(kind: .emailAddress, value: "me@home.com")],
        sourceAppBundleIdentifiers: []
    )
    settings.rules = [newRule]
    settings.primaryTarget = .webmail(provider: .fastmail)
    settings.save()

    let reloadedSettings = SettingsStore(defaults: defaults)
    #expect(reloadedSettings.rules.count == 1)
    #expect(reloadedSettings.rules[0] == newRule)
    #expect(reloadedSettings.primaryTarget == .webmail(provider: .fastmail))
}
