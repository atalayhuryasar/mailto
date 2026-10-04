import Testing
import Foundation
@testable import MacMailCore

@Test func testExactDomainMatchingExcludesSubdomains() {
    let rule = Rule(
        name: "Work Domain",
        isEnabled: true,
        target: .webmail(provider: .outlook365),
        recipientMatchers: [RecipientMatcher(kind: .domain, value: "work.com")],
        sourceAppBundleIdentifiers: []
    )
    let matchCtx = MatchContext(
        recipients: [EmailAddress(raw: "user@sub.work.com", address: "user@sub.work.com", domain: "sub.work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: matchCtx) == false)

    let exactCtx = MatchContext(
        recipients: [EmailAddress(raw: "user@work.com", address: "user@work.com", domain: "work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: exactCtx) == true)
}

@Test func testDomainAndSubdomainsMatching() {
    let rule = Rule(
        name: "Corp Domain",
        isEnabled: true,
        target: .webmail(provider: .gmail),
        recipientMatchers: [RecipientMatcher(kind: .domainAndSubdomains, value: "work.com")],
        sourceAppBundleIdentifiers: []
    )
    let subCtx = MatchContext(
        recipients: [EmailAddress(raw: "user@sub.work.com", address: "user@sub.work.com", domain: "sub.work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: subCtx) == true)

    let exactCtx = MatchContext(
        recipients: [EmailAddress(raw: "user@work.com", address: "user@work.com", domain: "work.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: exactCtx) == true)
}

@Test func testEmailAddressMatchingCaseInsensitive() {
    let rule = Rule(
        name: "CEO",
        isEnabled: true,
        target: .clipboard,
        recipientMatchers: [RecipientMatcher(kind: .emailAddress, value: "Boss@Company.com")],
        sourceAppBundleIdentifiers: []
    )
    let ctx = MatchContext(
        recipients: [EmailAddress(raw: "boss@company.com", address: "boss@company.com", domain: "company.com", displayName: nil)],
        sourceAppBundleIdentifier: nil
    )
    #expect(RuleEngine.matches(rule, context: ctx) == true)
}

@Test func testDisabledRuleIsSkipped() {
    let rule = Rule(
        name: "Disabled Rule",
        isEnabled: false,
        target: .clipboard,
        recipientMatchers: [],
        sourceAppBundleIdentifiers: []
    )
    let ctx = MatchContext(recipients: [], sourceAppBundleIdentifier: nil)
    #expect(RuleEngine.matches(rule, context: ctx) == false)
}

@Test func testSourceAppConstraintAndPriority() {
    let slackRule = Rule(
        name: "Slack Links",
        isEnabled: true,
        target: .clipboard,
        recipientMatchers: [],
        sourceAppBundleIdentifiers: ["com.tinyspeck.slackmacgap"]
    )
    let generalRule = Rule(
        name: "All Emails",
        isEnabled: true,
        target: .webmail(provider: .gmail),
        recipientMatchers: [],
        sourceAppBundleIdentifiers: []
    )
    let slackCtx = MatchContext(recipients: [], sourceAppBundleIdentifier: "com.tinyspeck.slackmacgap")
    let safariCtx = MatchContext(recipients: [], sourceAppBundleIdentifier: "com.apple.Safari")

    #expect(RuleEngine.evaluate(rules: [slackRule, generalRule], context: slackCtx)?.id == slackRule.id)
    #expect(RuleEngine.evaluate(rules: [slackRule, generalRule], context: safariCtx)?.id == generalRule.id)
}
