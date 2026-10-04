import Testing
import Foundation
@testable import MailtoCore

@Test func testDefaultMailAppStatusCheck() {
    // Should return a valid boolean without crashing
    let isDefault = DefaultMailAppManager.isMailtoDefault
    #expect(isDefault == true || isDefault == false)
}

@Test func testIsAppDefaultWithBogusBundle() {
    let isBogusDefault = DefaultMailAppManager.isAppDefault(bundleIdentifier: "com.nonexistent.fakeapp")
    #expect(isBogusDefault == false)
}

@Test func testSetMailtoAsDefault() {
    let result = DefaultMailAppManager.setMailtoAsDefault()
    #expect(result == true)
    #expect(DefaultMailAppManager.isMailtoDefault == true)
}
