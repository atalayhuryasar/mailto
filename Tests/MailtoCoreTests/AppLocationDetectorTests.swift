import Testing
import Foundation
@testable import MailtoCore

@Suite("AppLocationDetector Tests")
struct AppLocationDetectorTests {

    @Test("Running inside /Applications returns .installedInApplications")
    func testRunningInsideApplications() {
        let detector = AppLocationDetector(
            runningBundleURL: URL(fileURLWithPath: "/Applications/mailto.app"),
            applicationsDirectoryURL: URL(fileURLWithPath: "/Applications"),
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in nil },
            fileChecker: { _ in true }
        )

        let status = detector.evaluate()
        #expect(status == .installedInApplications)
    }

    @Test("Running inside user ~/Applications returns .installedInApplications")
    func testRunningInsideUserApplications() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let userAppsURL = URL(fileURLWithPath: "\(homeDir)/Applications/mailto.app")
        let detector = AppLocationDetector(
            runningBundleURL: userAppsURL,
            applicationsDirectoryURL: URL(fileURLWithPath: "/Applications"),
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in nil },
            fileChecker: { _ in true }
        )

        let status = detector.evaluate()
        #expect(status == .installedInApplications)
    }

    @Test("Running inside build or dev directory returns .runningFromDevOrBuild")
    func testRunningFromBuildOrDev() {
        let detector = AppLocationDetector(
            runningBundleURL: URL(fileURLWithPath: "/Users/dev/Project/.build/debug/mailto.app"),
            applicationsDirectoryURL: URL(fileURLWithPath: "/Applications"),
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in nil },
            fileChecker: { _ in false }
        )

        let status = detector.evaluate()
        #expect(status == .runningFromDevOrBuild)
    }

    @Test("Running from Downloads when /Applications does not have mailto.app returns .notInstalled")
    func testRunningFromDownloadsNotInstalled() {
        let downloadsURL = URL(fileURLWithPath: "/Users/user/Downloads/mailto.app")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let expectedDest = URL(fileURLWithPath: "/Applications/mailto.app")

        let detector = AppLocationDetector(
            runningBundleURL: downloadsURL,
            applicationsDirectoryURL: appsURL,
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in nil },
            fileChecker: { _ in false } // destination does not exist
        )

        let status = detector.evaluate()
        #expect(status == .notInstalled(destinationURL: expectedDest))
    }

    @Test("Running from Downloads when same version already exists in /Applications returns .alreadyInstalledSameOrOlder")
    func testRunningFromDownloadsSameVersionExists() {
        let downloadsURL = URL(fileURLWithPath: "/Users/user/Downloads/mailto.app")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let installedURL = URL(fileURLWithPath: "/Applications/mailto.app")

        let detector = AppLocationDetector(
            runningBundleURL: downloadsURL,
            applicationsDirectoryURL: appsURL,
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in "1.0.0" },
            fileChecker: { url in url.path == installedURL.path }
        )

        let status = detector.evaluate()
        #expect(status == .alreadyInstalledSameOrOlder(
            installedURL: installedURL,
            installedVersion: "1.0.0",
            runningVersion: "1.0.0"
        ))
    }

    @Test("Running from Downloads when older version exists in Downloads and newer exists in /Applications returns .alreadyInstalledSameOrOlder")
    func testRunningFromDownloadsOlderVersionThanInstalled() {
        let downloadsURL = URL(fileURLWithPath: "/Users/user/Downloads/mailto.app")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let installedURL = URL(fileURLWithPath: "/Applications/mailto.app")

        let detector = AppLocationDetector(
            runningBundleURL: downloadsURL,
            applicationsDirectoryURL: appsURL,
            bundleName: "mailto.app",
            runningVersion: "0.9.0",
            versionReader: { _ in "1.0.0" },
            fileChecker: { url in url.path == installedURL.path }
        )

        let status = detector.evaluate()
        #expect(status == .alreadyInstalledSameOrOlder(
            installedURL: installedURL,
            installedVersion: "1.0.0",
            runningVersion: "0.9.0"
        ))
    }

    @Test("Running from Downloads when newer version is downloaded returns .updateAvailable")
    func testRunningFromDownloadsNewerVersionAvailable() {
        let downloadsURL = URL(fileURLWithPath: "/Users/user/Downloads/mailto.app")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let installedURL = URL(fileURLWithPath: "/Applications/mailto.app")

        let detector = AppLocationDetector(
            runningBundleURL: downloadsURL,
            applicationsDirectoryURL: appsURL,
            bundleName: "mailto.app",
            runningVersion: "1.1.0",
            versionReader: { _ in "1.0.0" },
            fileChecker: { url in url.path == installedURL.path }
        )

        let status = detector.evaluate()
        #expect(status == .updateAvailable(
            installedURL: installedURL,
            installedVersion: "1.0.0",
            newVersion: "1.1.0"
        ))
    }

    @Test("Running from AppTranslocation returns .notInstalled when destination does not exist")
    func testRunningFromAppTranslocation() {
        let translocatedURL = URL(fileURLWithPath: "/private/var/folders/xx/yy/AppTranslocation/d7a8b/d/mailto.app")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let expectedDest = URL(fileURLWithPath: "/Applications/mailto.app")

        let detector = AppLocationDetector(
            runningBundleURL: translocatedURL,
            applicationsDirectoryURL: appsURL,
            bundleName: "mailto.app",
            runningVersion: "1.0.0",
            versionReader: { _ in nil },
            fileChecker: { _ in false }
        )

        let status = detector.evaluate()
        #expect(status == .notInstalled(destinationURL: expectedDest))
    }

    @Test("Version comparator handles semantic versions correctly")
    func testVersionComparison() {
        #expect(AppLocationDetector.compareVersions("1.0.0", "1.0.0") == .orderedSame)
        #expect(AppLocationDetector.compareVersions("1.1.0", "1.0.0") == .orderedDescending)
        #expect(AppLocationDetector.compareVersions("1.0.1", "1.0.0") == .orderedDescending)
        #expect(AppLocationDetector.compareVersions("2.0", "1.9.9") == .orderedDescending)
        #expect(AppLocationDetector.compareVersions("1.0", "1.0.0") == .orderedSame)
        #expect(AppLocationDetector.compareVersions("1.0.0", "1.1.0") == .orderedAscending)
    }
}
