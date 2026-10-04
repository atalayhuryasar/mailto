import Testing
import Foundation
@testable import MacMailCore

struct MockModifierReader: ModifierKeyReading {
    let isActive: Bool
    func isAlternativeModifierActive() -> Bool { isActive }
}

struct MockSourceAppResolver: SourceAppResolving {
    let appId: String?
    func resolveFrontmostApp() -> String? { appId }
}

@Test func testFnModifierBypassesRules() {
    let rule = Rule(name: "Rule 1", isEnabled: true, target: .clipboard, recipientMatchers: [], sourceAppBundleIdentifiers: [])
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-router-\(UUID().uuidString)")!)
    settings.primaryTarget = .nativeApp(bundleId: "com.apple.mail", name: "Mail")
    settings.alternativeTarget = .webmail(provider: .gmail)
    settings.rules = [rule]

    let router = Router(
        settings: settings,
        modifierReader: MockModifierReader(isActive: true),
        sourceResolver: MockSourceAppResolver(appId: nil)
    )
    let msg = MailtoParser.parse(URL(string: "mailto:test@test.com")!)
    let result = router.route(message: msg)

    #expect(result.wasModifierActive == true)
    #expect(result.target == .webmail(provider: .gmail))
    #expect(result.matchedRule == nil)
}

@Test func testRuleMatchingWhenModifierInactive() {
    let rule = Rule(
        name: "Work Outlook",
        isEnabled: true,
        target: .webmail(provider: .outlook365),
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")],
        sourceAppBundleIdentifiers: []
    )
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-router-\(UUID().uuidString)")!)
    settings.primaryTarget = .nativeApp(bundleId: "com.apple.mail", name: "Mail")
    settings.alternativeTarget = .clipboard
    settings.rules = [rule]

    let router = Router(
        settings: settings,
        modifierReader: MockModifierReader(isActive: false),
        sourceResolver: MockSourceAppResolver(appId: nil)
    )
    let msg = MailtoParser.parse(URL(string: "mailto:colleague@work.com")!)
    let result = router.route(message: msg)

    #expect(result.wasModifierActive == false)
    #expect(result.target == .webmail(provider: .outlook365))
    #expect(result.matchedRule?.id == rule.id)
}

@Test func testFallbackToPrimaryTarget() {
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-router-\(UUID().uuidString)")!)
    settings.primaryTarget = .webmail(provider: .fastmail)
    settings.alternativeTarget = .clipboard
    settings.rules = []

    let router = Router(
        settings: settings,
        modifierReader: MockModifierReader(isActive: false),
        sourceResolver: MockSourceAppResolver(appId: nil)
    )
    let msg = MailtoParser.parse(URL(string: "mailto:random@example.com")!)
    let result = router.route(message: msg)

    #expect(result.target == .webmail(provider: .fastmail))
    #expect(result.matchedRule == nil)
    #expect(result.wasModifierActive == false)
}

@Test func testSelfLoopProtection() {
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-router-\(UUID().uuidString)")!)
    // If target is configured as MacMail itself
    settings.primaryTarget = .nativeApp(bundleId: "com.atalayhuryasar.macmail", name: "MacMail")
    settings.alternativeTarget = .clipboard
    settings.rules = []

    let router = Router(
        settings: settings,
        modifierReader: MockModifierReader(isActive: false),
        sourceResolver: MockSourceAppResolver(appId: nil),
        ownBundleIdentifier: "com.atalayhuryasar.macmail"
    )
    let msg = MailtoParser.parse(URL(string: "mailto:test@example.com")!)
    let result = router.route(message: msg)

    // Must fallback to Apple Mail or clipboard to prevent recursive loop
    #expect(result.target != .nativeApp(bundleId: "com.atalayhuryasar.macmail", name: "MacMail"))
}
