import Testing
@testable import MacMailCore

@Test func testLaunchContextTerminationDecision() {
    #expect(LaunchContext.shouldTerminateAfterRouting(isSettingsWindowOpen: false) == true)
    #expect(LaunchContext.shouldTerminateAfterRouting(isSettingsWindowOpen: true) == false)
}
