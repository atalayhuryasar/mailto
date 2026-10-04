import Testing
import Foundation
@testable import MacMailCore

@Test func testTargetPickerLabelResolution() {
    let gmailTarget = EmailTarget.webmail(provider: .gmail)
    #expect(gmailTarget.displayName == "Gmail")
    #expect(gmailTarget.iconName == "globe")

    let nativeTarget = EmailTarget.nativeApp(bundleId: "com.apple.mail", name: "Mail")
    #expect(nativeTarget.displayName == "Mail")
    #expect(nativeTarget.iconName == "app.badge")

    let customTarget = EmailTarget.customURL(template: "https://mymail.org/?to={to}")
    #expect(customTarget.displayName == "Custom URL")
    #expect(customTarget.iconName == "link")

    let clipboardTarget = EmailTarget.clipboard
    #expect(clipboardTarget.displayName == "Copy to Clipboard")
    #expect(clipboardTarget.iconName == "doc.on.clipboard")
}
