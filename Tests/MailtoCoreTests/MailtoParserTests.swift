import Testing
import Foundation
@testable import MailtoCore

@Test func testStandardMailtoParsing() throws {
    let url = URL(string: "mailto:alice@example.com?cc=bob@example.com&subject=Hello%20World&body=Greetings")!
    let msg = MailtoParser.parse(url)
    #expect(msg.to.map(\.address) == ["alice@example.com"])
    #expect(msg.cc.map(\.address) == ["bob@example.com"])
    #expect(msg.subject == "Hello World")
    #expect(msg.body == "Greetings")
}

@Test func testDisplayNameAndPlusParsing() throws {
    let url = URL(string: "mailto:John%20Doe%20%3Cjohn%2Bwork@company.com%3E?to=jane@company.com")!
    let msg = MailtoParser.parse(url)
    #expect(msg.to.count == 2)
    #expect(msg.to[0].address == "john+work@company.com")
    #expect(msg.to[0].displayName == "John Doe")
    #expect(msg.to[0].domain == "company.com")
    #expect(msg.to[1].address == "jane@company.com")
}

@Test func testEmptyAndMalformedMailto() {
    let url = URL(string: "mailto:?subject=No%20Recipient")!
    let msg = MailtoParser.parse(url)
    #expect(msg.to.isEmpty)
    #expect(msg.subject == "No Recipient")
}

@Test func testSpecialCharactersInQueryPreserved() {
    let url = URL(string: "mailto:?to=dev%2Bteam@work.com&subject=Fix%20%26%20Release&body=Line1%0ALine2")!
    let msg = MailtoParser.parse(url)
    #expect(msg.to.map(\.address) == ["dev+team@work.com"])
    #expect(msg.subject == "Fix & Release")
    #expect(msg.body == "Line1\nLine2")
}
