import Foundation

public enum InstallationStatus: Equatable, Sendable {
    /// The app is already running from an official Applications directory.
    case installedInApplications
    /// The app is running in development, Xcode test, or build directory.
    case runningFromDevOrBuild
    /// The app is running outside Applications and no installation was found.
    case notInstalled(destinationURL: URL)
    /// An installation already exists in Applications with the same or newer version.
    case alreadyInstalledSameOrOlder(installedURL: URL, installedVersion: String, runningVersion: String)
    /// An installation exists in Applications, but the running app is newer.
    case updateAvailable(installedURL: URL, installedVersion: String, newVersion: String)
}

public struct AppLocationDetector: Sendable {
    public let runningBundleURL: URL
    public let applicationsDirectoryURL: URL
    public let bundleName: String
    public let runningVersion: String
    public let versionReader: @Sendable (URL) -> String?
    public let fileChecker: @Sendable (URL) -> Bool

    public init(
        runningBundleURL: URL,
        applicationsDirectoryURL: URL,
        bundleName: String,
        runningVersion: String,
        versionReader: @escaping @Sendable (URL) -> String?,
        fileChecker: @escaping @Sendable (URL) -> Bool
    ) {
        self.runningBundleURL = runningBundleURL
        self.applicationsDirectoryURL = applicationsDirectoryURL
        self.bundleName = bundleName
        self.runningVersion = runningVersion
        self.versionReader = versionReader
        self.fileChecker = fileChecker
    }

    public static func `default`() -> AppLocationDetector {
        let bundle = Bundle.main
        let bundleURL = bundle.bundleURL
        let version = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        let appsURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first
            ?? URL(fileURLWithPath: "/Applications")
        let name = bundleURL.lastPathComponent.isEmpty ? "mailto.app" : bundleURL.lastPathComponent

        return AppLocationDetector(
            runningBundleURL: bundleURL,
            applicationsDirectoryURL: appsURL,
            bundleName: name,
            runningVersion: version,
            versionReader: { url in
                Bundle(url: url)?.infoDictionary?["CFBundleShortVersionString"] as? String
            },
            fileChecker: { url in
                FileManager.default.fileExists(atPath: url.path)
            }
        )
    }

    public func evaluate() -> InstallationStatus {
        let path = runningBundleURL.path

        // 1. Dev / Build / Xcode environment check
        if isDevelopmentOrTestPath(path) {
            return .runningFromDevOrBuild
        }

        // 2. Translocation check (AppTranslocation is always temporary / uninstalled)
        if path.contains("/AppTranslocation/") {
            let destinationURL = applicationsDirectoryURL.appendingPathComponent(bundleName)
            return evaluateAgainstExisting(destinationURL: destinationURL)
        }

        // 3. Check if running directly inside Applications directory
        if isInstalledInApplicationsPath(path) {
            return .installedInApplications
        }

        // 4. Running outside Applications (e.g., Downloads, Desktop)
        let destinationURL = applicationsDirectoryURL.appendingPathComponent(bundleName)
        if path == destinationURL.path {
            return .installedInApplications
        }

        return evaluateAgainstExisting(destinationURL: destinationURL)
    }

    private func evaluateAgainstExisting(destinationURL: URL) -> InstallationStatus {
        guard fileChecker(destinationURL) else {
            return .notInstalled(destinationURL: destinationURL)
        }

        let installedVersion = versionReader(destinationURL) ?? "0.0.0"
        let comparison = Self.compareVersions(runningVersion, installedVersion)

        if comparison == .orderedDescending {
            return .updateAvailable(
                installedURL: destinationURL,
                installedVersion: installedVersion,
                newVersion: runningVersion
            )
        } else {
            return .alreadyInstalledSameOrOlder(
                installedURL: destinationURL,
                installedVersion: installedVersion,
                runningVersion: runningVersion
            )
        }
    }

    private func isDevelopmentOrTestPath(_ path: String) -> Bool {
        return path.contains("/.build/") ||
            path.contains("/build/") ||
            path.contains("/DerivedData/") ||
            path.hasSuffix(".xctest") ||
            path.contains("/PlugIns/")
    }

    private func isInstalledInApplicationsPath(_ path: String) -> Bool {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let userApps = "\(homeDir)/Applications"

        if path.hasPrefix("/Applications/") || path == "/Applications" {
            return true
        }
        if path.hasPrefix("/System/Applications/") {
            return true
        }
        if path.hasPrefix("\(userApps)/") || path == userApps {
            return true
        }
        return false
    }

    /// Compares two semantic version strings (e.g., "1.1.0" vs "1.0.0").
    public static func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let clean1 = v1.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
        let clean2 = v2.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")

        let parts1 = clean1.split(separator: ".").compactMap { Int($0) }
        let parts2 = clean2.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let part1 = i < parts1.count ? parts1[i] : 0
            let part2 = i < parts2.count ? parts2[i] : 0

            if part1 > part2 {
                return .orderedDescending
            } else if part1 < part2 {
                return .orderedAscending
            }
        }

        return .orderedSame
    }
}
