import Foundation

public struct LaunchContext: Sendable {
    public static func shouldTerminateAfterRouting(isSettingsWindowOpen: Bool) -> Bool {
        !isSettingsWindowOpen
    }
}
