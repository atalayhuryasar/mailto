import Foundation
import CoreGraphics

public protocol ModifierKeyReading: Sendable {
    func isAlternativeModifierActive() -> Bool
}

public struct SystemModifierKeyReader: ModifierKeyReading {
    public init() {}

    public func isAlternativeModifierActive() -> Bool {
        // NX_SECONDARYFNMASK is 0x00800000 or CGEventFlags.maskSecondaryFn
        let flags = CGEventSource.flagsState(.combinedSessionState)
        return flags.contains(.maskSecondaryFn)
    }
}
