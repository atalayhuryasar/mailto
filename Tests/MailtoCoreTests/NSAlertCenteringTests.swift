import Testing
import AppKit
@testable import MailtoCore

@Suite("NSAlert Centering Tests")
@MainActor
struct NSAlertCenteringTests {
    @Test func testCenterTextFieldsInView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 200))
        let tf = NSTextField(labelWithString: "You're Up to Date!")
        tf.frame = NSRect(x: 20, y: 100, width: 220, height: 20)
        tf.alignment = .natural
        container.addSubview(tf)

        #expect(tf.alignment == .natural)

        NSAlert.centerTextFields(in: container)

        #expect(tf.alignment == .center)
        let paragraphStyle = tf.attributedStringValue.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(paragraphStyle?.alignment == .center)
    }

    @Test func testAlertCenteredInvocation() {
        let alert = NSAlert()
        alert.messageText = "Test Title"
        alert.informativeText = "Test Informative Message"
        let returnedAlert = alert.centered()
        #expect(returnedAlert === alert)
    }
}
