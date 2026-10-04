import Foundation

public struct ReleaseAsset: Sendable, Equatable, Decodable {
    public let name: String
    public let browserDownloadUrl: String
    public let size: Int?

    public init(name: String, browserDownloadUrl: String, size: Int? = nil) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.size = size
    }

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

public struct ReleaseInfo: Sendable, Equatable, Decodable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let assets: [ReleaseAsset]?

    public init(
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlUrl: String,
        publishedAt: String? = nil,
        assets: [ReleaseAsset]? = nil
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
        self.assets = assets
    }

    public var zipDownloadURL: URL? {
        if let assetUrlString = assets?.first(where: { $0.name.lowercased().hasSuffix(".zip") })?.browserDownloadUrl,
           let url = URL(string: assetUrlString) {
            return url
        }
        let fallback = "https://github.com/atalayhuryasar/mailto/releases/download/\(tagName)/mailto.zip"
        return URL(string: fallback)
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
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
