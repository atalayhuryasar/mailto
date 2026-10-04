import Testing
import Foundation
@testable import MailtoCore

@Suite("AppLocationManager Tests")
struct AppLocationManagerTests {

    @Test("installApp copies bundle to destination directory")
    func testInstallAppCopiesBundle() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceDir = tempDir.appendingPathComponent("Source")
        let destAppsDir = tempDir.appendingPathComponent("Applications")

        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destAppsDir, withIntermediateDirectories: true)

        let fakeAppURL = sourceDir.appendingPathComponent("mailto.app")
        try FileManager.default.createDirectory(at: fakeAppURL, withIntermediateDirectories: true)
        let dummyFile = fakeAppURL.appendingPathComponent("test.txt")
        try "hello".write(to: dummyFile, atomically: true, encoding: .utf8)

        let manager = AppLocationManager()
        let destinationURL = destAppsDir.appendingPathComponent("mailto.app")

        try manager.copyAppBundle(from: fakeAppURL, to: destinationURL)

        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent("test.txt").path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("copyAppBundle replaces existing destination bundle when updating")
    func testUpdateAppReplacesExisting() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceDir = tempDir.appendingPathComponent("Source")
        let destAppsDir = tempDir.appendingPathComponent("Applications")

        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destAppsDir, withIntermediateDirectories: true)

        // Existing old app
        let existingAppURL = destAppsDir.appendingPathComponent("mailto.app")
        try FileManager.default.createDirectory(at: existingAppURL, withIntermediateDirectories: true)
        let oldMarker = existingAppURL.appendingPathComponent("v1.txt")
        try "old".write(to: oldMarker, atomically: true, encoding: .utf8)

        // New source app
        let newAppURL = sourceDir.appendingPathComponent("mailto.app")
        try FileManager.default.createDirectory(at: newAppURL, withIntermediateDirectories: true)
        let newMarker = newAppURL.appendingPathComponent("v2.txt")
        try "new".write(to: newMarker, atomically: true, encoding: .utf8)

        let manager = AppLocationManager()
        try manager.copyAppBundle(from: newAppURL, to: existingAppURL)

        #expect(FileManager.default.fileExists(atPath: existingAppURL.path))
        #expect(!FileManager.default.fileExists(atPath: existingAppURL.appendingPathComponent("v1.txt").path))
        #expect(FileManager.default.fileExists(atPath: existingAppURL.appendingPathComponent("v2.txt").path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("installApp copies bundle and deletes source when cleanSource is true")
    func testMoveAppBundleCleansSource() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sourceDir = tempDir.appendingPathComponent("Downloads")
        let destAppsDir = tempDir.appendingPathComponent("Applications")

        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destAppsDir, withIntermediateDirectories: true)

        let sourceAppURL = sourceDir.appendingPathComponent("mailto.app")
        try FileManager.default.createDirectory(at: sourceAppURL, withIntermediateDirectories: true)
        let marker = sourceAppURL.appendingPathComponent("bundle.txt")
        try "installed".write(to: marker, atomically: true, encoding: .utf8)

        let destinationURL = destAppsDir.appendingPathComponent("mailto.app")
        let manager = AppLocationManager()

        try manager.installApp(from: sourceAppURL, to: destinationURL, cleanSource: true)

        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(FileManager.default.fileExists(atPath: destinationURL.appendingPathComponent("bundle.txt").path))
        #expect(!FileManager.default.fileExists(atPath: sourceAppURL.path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("promptAndHandleIfNeeded invokes customInstallPrompter when not installed")
    @MainActor
    func testPromptAndHandleIfNeededCallsCustomPrompter() {
        let detector = AppLocationDetector(
            runningBundleURL: URL(fileURLWithPath: "/Users/test/Downloads/mailto.app"),
            applicationsDirectoryURL: URL(fileURLWithPath: "/Applications"),
            bundleName: "mailto.app",
            runningVersion: "1.2.9",
            versionReader: { _ in nil },
            fileChecker: { _ in false }
        )

        var customPrompterCalled = false
        var capturedSource: URL?
        var capturedDest: URL?

        let manager = AppLocationManager()
        let result = manager.promptAndHandleIfNeeded(
            detector: detector,
            customInstallPrompter: { src, dest in
                customPrompterCalled = true
                capturedSource = src
                capturedDest = dest
                return true
            }
        )

        #expect(result == true)
        #expect(customPrompterCalled == true)
        #expect(capturedSource?.path == "/Users/test/Downloads/mailto.app")
        #expect(capturedDest?.path == "/Applications/mailto.app")
    }
}
