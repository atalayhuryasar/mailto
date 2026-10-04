import Testing
@testable import MailtoCore

@Test func testRuleValidationRequirements() {
    let emptyNameRule = Rule(name: "   ", isEnabled: true, target: .clipboard, recipientMatchers: [], sourceAppBundleIdentifiers: [])
    #expect(emptyNameRule.isValid == false)

    let validRule = Rule(name: "Work", isEnabled: true, target: .webmail(provider: .gmail), recipientMatchers: [], sourceAppBundleIdentifiers: [])
    #expect(validRule.isValid == true)
}
