import Testing
import Foundation
@testable import MailtoCore

@Suite("UpdateChecker Tests")
struct UpdateCheckerTests {

    @Test("Decodes GitHub release JSON accurately")
    func testDecodeGitHubRelease() throws {
        let json = """
        {
            "tag_name": "v1.2.0",
            "name": "mailto: v1.2.0 — Feature Release",
            "body": "• New auto-update support\\n• Native menu bar",
            "html_url": "https://github.com/atalayhuryasar/mailto/releases/tag/v1.2.0",
            "published_at": "2026-10-04T12:00:00Z"
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(ReleaseInfo.self, from: json)
        #expect(release.tagName == "v1.2.0")
        #expect(release.name == "mailto: v1.2.0 — Feature Release")
        #expect(release.htmlUrl == "https://github.com/atalayhuryasar/mailto/releases/tag/v1.2.0")
        #expect(release.body?.contains("Native menu bar") == true)
    }

    @Test("Evaluate update availability when newer version exists")
    func testUpdateAvailable() {
        let release = ReleaseInfo(
            tagName: "v1.2.0",
            name: "v1.2.0",
            body: "Notes",
            htmlUrl: "https://example.com"
        )

        let result = UpdateChecker.evaluate(release: release, currentVersion: "1.1.0")
        #expect(result == .updateAvailable(newVersion: "1.2.0", release: release))
    }

    @Test("Evaluate update availability when current version is same")
    func testSameVersionUpToDate() {
        let release = ReleaseInfo(
            tagName: "v1.1.0",
            name: "v1.1.0",
            body: "Notes",
            htmlUrl: "https://example.com"
        )

        let result = UpdateChecker.evaluate(release: release, currentVersion: "1.1.0")
        #expect(result == .upToDate(currentVersion: "1.1.0"))
    }

    @Test("Evaluate update availability when current version is ahead")
    func testAheadVersionUpToDate() {
        let release = ReleaseInfo(
            tagName: "v1.0.0",
            name: "v1.0.0",
            body: "Notes",
            htmlUrl: "https://example.com"
        )

        let result = UpdateChecker.evaluate(release: release, currentVersion: "1.1.0")
        #expect(result == .upToDate(currentVersion: "1.1.0"))
    }
}
