import Testing
import Foundation
@testable import MailtoCore

@Test func testDefaultMailAppStatusCheck() {
    // Should return a valid boolean without crashing
    let isDefault = DefaultMailAppManager.isMailtoDefault
    #expect(isDefault == true || isDefault == false)
}

@Test func testSetMailtoAsDefault() {
    let result = DefaultMailAppManager.setMailtoAsDefault()
    #expect(result == true)
    #expect(DefaultMailAppManager.isMailtoDefault == true)
}
