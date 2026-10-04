import Testing
import Foundation
@testable import MailtoCore

@Test func testScenarioT4_ExactDomainDoesNotMatchSubdomain() {
    let rule = Rule(
        name: "Work Exact",
        isEnabled: true,
        target: .webmail(provider: .outlook365),
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")]
    )
    let ctx = MatchContext(
        recipients: [EmailAddress(raw: "user@sub.work.com", address: "user@sub.work.com", domain: "sub.work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: ctx) == false)
}

@Test func testScenarioT5_DomainAndSubdomainsMatchesSubdomain() {
    let rule = Rule(
        name: "Work With Subdomains",
        isEnabled: true,
        target: .webmail(provider: .outlook365),
        recipientMatchers: [RecipientMatcher(kind: .domainAndSubdomains, value: "work.com")]
    )
    let ctx = MatchContext(
        recipients: [EmailAddress(raw: "user@sub.work.com", address: "user@sub.work.com", domain: "sub.work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: ctx) == true)
}

@Test func testScenarioT6_PriorityOrderFirstMatchWins() {
    let rule1 = Rule(
        name: "First Rule",
        isEnabled: true,
        target: .webmail(provider: .gmail),
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")]
    )
    let rule2 = Rule(
        name: "Second Rule",
        isEnabled: true,
        target: .webmail(provider: .fastmail),
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")]
    )
    let ctx = MatchContext(
        recipients: [EmailAddress(raw: "user@work.com", address: "user@work.com", domain: "work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    let matched = RuleEngine.evaluate(rules: [rule1, rule2], context: ctx)
    #expect(matched?.id == rule1.id)
    #expect(matched?.target == .webmail(provider: .gmail))
}

@Test func testScenarioT7_DisabledRuleFallbackToPrimary() {
    let disabledRule = Rule(
        name: "Disabled",
        isEnabled: false,
        target: .clipboard,
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")]
    )
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-t7")!)
    settings.primaryTarget = .webmail(provider: .outlookCom)
    settings.rules = [disabledRule]

    let router = Router(settings: settings, modifierReader: MockModifierReader(isActive: false), sourceResolver: MockSourceAppResolver(appId: nil))
    let msg = MailtoParser.parse(URL(string: "mailto:colleague@work.com")!)
    let result = router.route(message: msg)

    #expect(result.target == .webmail(provider: .outlookCom))
    #expect(result.matchedRule == nil)
}

@Test func testScenarioT8AndT9_SourceAppFiltering() {
    let slackOnlyRule = Rule(
        name: "Slack Links",
        isEnabled: true,
        target: .clipboard,
        recipientMatchers: [],
        sourceAppBundleIdentifiers: ["com.tinyspeck.slackmacgap"]
    )
    let slackCtx = MatchContext(recipients: [], sourceAppBundleIdentifier: "com.tinyspeck.slackmacgap")
    let safariCtx = MatchContext(recipients: [], sourceAppBundleIdentifier: "com.apple.Safari")

    #expect(RuleEngine.matches(slackOnlyRule, context: slackCtx) == true)
    #expect(RuleEngine.matches(slackOnlyRule, context: safariCtx) == false)
}

@Test func testScenarioT10_FnKeyModifierOverridesAllRules() {
    let rule = Rule(
        name: "Important Rule",
        isEnabled: true,
        target: .clipboard,
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")]
    )
    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-t10")!)
    settings.primaryTarget = .nativeApp(bundleId: "com.apple.mail", name: "Mail")
    settings.alternativeTarget = .webmail(provider: .fastmail)
    settings.rules = [rule]

    let router = Router(settings: settings, modifierReader: MockModifierReader(isActive: true), sourceResolver: MockSourceAppResolver(appId: nil))
    let msg = MailtoParser.parse(URL(string: "mailto:colleague@work.com")!)
    let result = router.route(message: msg)

    #expect(result.wasModifierActive == true)
    #expect(result.target == .webmail(provider: .fastmail))
    #expect(result.matchedRule == nil)
}

@Test func testScenarioT11_ClipboardCopiesOnlyAddress() {
    let mockPB = MockPasteboardWriter()
    let dispatcher = TargetDispatcher(clipboardWriter: mockPB, urlOpener: MockURLOpener(), appLauncher: MockNativeAppLauncher())
    let msg = MailtoParser.parse(URL(string: "mailto:vip@client.com?subject=Proposal&body=Details")!)

    dispatcher.dispatch(target: .clipboard, message: msg) { _ in }
    #expect(mockPB.copiedText == "vip@client.com")
}

@Test func testScenarioT12_CustomURLTemplateExpansion() {
    let template = "https://custom.mail.corp/compose?to={to}&raw={mailto}&domain={domain}"
    let url = URL(string: "mailto:developer@mycorp.io?subject=CodeReview")!
    let msg = MailtoParser.parse(url)

    let generatedURL = WebmailURLBuilder.buildURL(target: .customURL(template: template), message: msg)
    #expect(generatedURL != nil)
    let str = generatedURL!.absoluteString
    #expect(str.contains("to=developer@mycorp.io"))
    #expect(str.contains("domain=mycorp.io"))
    #expect(str.contains("raw=mailto:developer@mycorp.io?subject=CodeReview"))
}

@Test func testScenarioT13_MultipleRecipientsPreserved() {
    let url = URL(string: "mailto:to1@test.com,to2@test.com?cc=cc1@test.com&bcc=bcc1@test.com&subject=Multi")!
    let msg = MailtoParser.parse(url)

    #expect(msg.to.count == 2)
    #expect(msg.to.map(\.address) == ["to1@test.com", "to2@test.com"])
    #expect(msg.cc.map(\.address) == ["cc1@test.com"])
    #expect(msg.bcc.map(\.address) == ["bcc1@test.com"])
}

@Test func testScenarioT15_EmptyMailtoDoesNotCrash() {
    let url = URL(string: "mailto:")!
    let msg = MailtoParser.parse(url)
    #expect(msg.to.isEmpty)
    #expect(msg.subject.isEmpty)

    let settings = SettingsStore(defaults: UserDefaults(suiteName: "test-t15")!)
    let router = Router(settings: settings, modifierReader: MockModifierReader(isActive: false), sourceResolver: MockSourceAppResolver(appId: nil))
    let result = router.route(message: msg)
    #expect(result.target == settings.primaryTarget)
}

@Test func testScenarioT18_LongBodyIsTruncated() {
    let hugeBody = String(repeating: "LargeTextPayload", count: 1000) // ~16,000 chars
    let url = URL(string: "mailto:test@example.com?body=\(hugeBody)")!
    let msg = MailtoParser.parse(url)

    let urlResult = WebmailURLBuilder.buildURL(target: .webmail(provider: .gmail), message: msg, maxBodyLength: 4000)
    #expect(urlResult != nil)
    #expect(urlResult!.absoluteString.count < 6000)
}
