import Testing
import Foundation
@testable import MacMailCore

@Test func testDefaultMailAppStatusCheck() {
    // Should return a valid boolean without crashing
    let isDefault = DefaultMailAppManager.isMacMailDefault
    #expect(isDefault == true || isDefault == false)
}

@Test func testSetMacMailAsDefault() {
    let result = DefaultMailAppManager.setMacMailAsDefault()
    #expect(result == true)
    #expect(DefaultMailAppManager.isMacMailDefault == true)
}
