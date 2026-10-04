import Foundation

public struct ReleaseInfo: Sendable, Equatable, Decodable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?

    public init(
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlUrl: String,
        publishedAt: String? = nil
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }
}

public enum UpdateCheckResult: Equatable, Sendable {
    case updateAvailable(newVersion: String, release: ReleaseInfo)
    case upToDate(currentVersion: String)
}

public final class UpdateChecker: @unchecked Sendable {
    public static let defaultReleaseURL = URL(string: "https://api.github.com/repos/atalayhuryasar/mailto/releases/latest")!

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public static func evaluate(release: ReleaseInfo, currentVersion: String = MailtoCoreVersion) -> UpdateCheckResult {
        let latestVersion = release.tagName.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
        let comparison = AppLocationDetector.compareVersions(latestVersion, currentVersion)

        if comparison == .orderedDescending {
            return .updateAvailable(newVersion: latestVersion, release: release)
        } else {
            return .upToDate(currentVersion: currentVersion)
        }
    }

    public func checkForUpdates(
        currentVersion: String = MailtoCoreVersion,
        from url: URL = defaultReleaseURL
    ) async throws -> UpdateCheckResult {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("mailto-app/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let release = try JSONDecoder().decode(ReleaseInfo.self, from: data)
        return Self.evaluate(release: release, currentVersion: currentVersion)
    }
}
