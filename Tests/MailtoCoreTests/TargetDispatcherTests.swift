import Testing
import Foundation
@testable import MailtoCore

final class Box: @unchecked Sendable {
    var value: Bool = false
}

final class MockPasteboardWriter: ClipboardWriting, @unchecked Sendable {
    var copiedText: String?
    func copy(text: String) { copiedText = text }
}

final class MockURLOpener: URLOpening, @unchecked Sendable {
    var openedURL: URL?
    func open(_ url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        openedURL = url
        completion(true)
    }
}

final class MockNativeAppLauncher: NativeAppLaunching, @unchecked Sendable {
    var launchedAppBundleId: String?
    var launchedURL: URL?
    func launch(bundleId: String, url: URL, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        launchedAppBundleId = bundleId
        launchedURL = url
        completion(.success(()))
    }
}

@Test func testClipboardDispatchCopiesRecipient() {
    let mockPB = MockPasteboardWriter()
    let dispatcher = TargetDispatcher(
        clipboardWriter: mockPB,
        urlOpener: MockURLOpener(),
        appLauncher: MockNativeAppLauncher()
    )
    let msg = MailtoParser.parse(URL(string: "mailto:copy-me@work.com?subject=Test")!)

    let box = Box()
    dispatcher.dispatch(target: .clipboard, message: msg) { result in
        #expect(mockPB.copiedText == "copy-me@work.com")
        box.value = true
    }
    #expect(box.value == true)
}

@Test func testWebmailDispatchOpensBrowserURL() {
    let mockOpener = MockURLOpener()
    let dispatcher = TargetDispatcher(
        clipboardWriter: MockPasteboardWriter(),
        urlOpener: mockOpener,
        appLauncher: MockNativeAppLauncher()
    )
    let msg = MailtoParser.parse(URL(string: "mailto:support@work.com?subject=Bug")!)

    let box = Box()
    dispatcher.dispatch(target: .webmail(provider: .gmail), message: msg) { result in
        #expect(mockOpener.openedURL != nil)
        #expect(mockOpener.openedURL?.absoluteString.contains("mail.google.com") == true)
        box.value = true
    }
    #expect(box.value == true)
}

@Test func testNativeAppDispatchLaunchesClient() {
    let mockLauncher = MockNativeAppLauncher()
    let dispatcher = TargetDispatcher(
        clipboardWriter: MockPasteboardWriter(),
        urlOpener: MockURLOpener(),
        appLauncher: mockLauncher
    )
    let msg = MailtoParser.parse(URL(string: "mailto:boss@company.com")!)

    let box = Box()
    dispatcher.dispatch(target: .nativeApp(bundleId: "com.apple.mail", name: "Mail"), message: msg) { result in
        #expect(mockLauncher.launchedAppBundleId == "com.apple.mail")
        #expect(mockLauncher.launchedURL == msg.rawURL)
        box.value = true
    }
    #expect(box.value == true)
}
