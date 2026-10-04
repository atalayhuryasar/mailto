import Foundation
import AppKit

public protocol ClipboardWriting: Sendable {
    func copy(text: String)
}

public struct SystemClipboardWriter: ClipboardWriting {
    public init() {}

    public func copy(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
