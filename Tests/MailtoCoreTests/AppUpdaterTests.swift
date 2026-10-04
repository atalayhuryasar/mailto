import Testing
import Foundation
@testable import MailtoCore

@Suite("AppUpdater Tests")
struct AppUpdaterTests {

    @Test("Finds .app bundle in directory")
    func testFindAppBundle() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let mockApp = tempDir.appendingPathComponent("mailto.app")
        try FileManager.default.createDirectory(at: mockApp, withIntermediateDirectories: true)

        let updater = AppUpdater()
        let found = try updater.findAppBundle(in: tempDir)
        #expect(found.lastPathComponent == "mailto.app")
    }

    @Test("Validates authentic app bundle")
    func testValidateAuthenticAppBundle() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let mockApp = tempDir.appendingPathComponent("mailto.app")
        let contents = mockApp.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

        let plistData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.atalayhuryasar.mailto</string>
            <key>CFBundleShortVersionString</key>
            <string>1.2.4</string>
        </dict>
        </plist>
        """.data(using: .utf8)!

        try plistData.write(to: contents.appendingPathComponent("Info.plist"))

        let updater = AppUpdater()
        let isValid = try updater.validateAppBundle(at: mockApp)
        #expect(isValid == true)
    }

    @Test("Rejects app bundle with invalid bundle identifier")
    func testRejectsInvalidBundleIdentifier() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let mockApp = tempDir.appendingPathComponent("mailto.app")
        let contents = mockApp.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

        let plistData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.malicious.app</string>
        </dict>
        </plist>
        """.data(using: .utf8)!

        try plistData.write(to: contents.appendingPathComponent("Info.plist"))

        let updater = AppUpdater()
        #expect(throws: AppUpdaterError.invalidBundle) {
            try updater.validateAppBundle(at: mockApp)
        }
    }
}
