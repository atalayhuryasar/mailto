import Testing
import Foundation
@testable import MailtoCore

@Test func testGmailURLGeneration() throws {
    let url = URL(string: "mailto:test@example.com?subject=Hi%20There&body=Line1%0ALine2")!
    let msg = MailtoParser.parse(url)
    let composeURL = WebmailURLBuilder.buildURL(target: .webmail(provider: .gmail), message: msg)
    #expect(composeURL != nil)
    let str = composeURL!.absoluteString
    #expect(str.contains("mail.google.com/mail"))
    #expect(str.contains("to=test%40example.com") || str.contains("to=test@example.com"))
    #expect(str.contains("su=Hi%20There"))
}

@Test func testCustomURLTemplateExpansion() throws {
    let url = URL(string: "mailto:colleague@corp.com?subject=Review")!
    let msg = MailtoParser.parse(url)
    let template = "https://internal.mail/compose?recipient={to}&domain={domain}&subj={subject}"
    let resultURL = WebmailURLBuilder.buildURL(target: .customURL(template: template), message: msg)
    #expect(resultURL?.absoluteString == "https://internal.mail/compose?recipient=colleague@corp.com&domain=corp.com&subj=Review")
}

@Test func testExcessiveBodyTruncation() throws {
    let largeBody = String(repeating: "A", count: 10000)
    let url = URL(string: "mailto:a@b.com?body=\(largeBody)")!
    let msg = MailtoParser.parse(url)
    let composeURL = WebmailURLBuilder.buildURL(target: .webmail(provider: .fastmail), message: msg, maxBodyLength: 1000)
    #expect(composeURL != nil)
    #expect(composeURL!.absoluteString.count < 2000)
}

@Test func testAllWebmailProvidersGenerateValidURLs() {
    let url = URL(string: "mailto:user@domain.com?cc=cc@domain.com&subject=Test&body=Hello")!
    let msg = MailtoParser.parse(url)

    for provider in WebmailProvider.allCases {
        let composeURL = WebmailURLBuilder.buildURL(target: .webmail(provider: provider), message: msg)
        #expect(composeURL != nil)
        #expect(composeURL!.scheme == "https")
    }
}
