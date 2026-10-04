import Foundation
import AppKit

public enum AppUpdaterError: LocalizedError, Equatable {
    case noZipURL
    case downloadFailed(String)
    case extractionFailed(String)
    case bundleNotFound
    case invalidBundle
    case installationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noZipURL:
            return "No download URL available for the release archive."
        case .downloadFailed(let reason):
            return "Failed to download update: \(reason)"
        case .extractionFailed(let reason):
            return "Failed to extract update package: \(reason)"
        case .bundleNotFound:
            return "Could not find mailto.app inside the downloaded archive."
        case .invalidBundle:
            return "The downloaded update is invalid or corrupted."
        case .installationFailed(let reason):
            return "Failed to install update: \(reason)"
        }
    }
}

public final class AppUpdater: @unchecked Sendable {
    public static let expectedBundleIdentifier = "com.atalayhuryasar.mailto"

    private let fileManager: FileManager
    private let session: URLSession

    public init(fileManager: FileManager = .default, session: URLSession = .shared) {
        self.fileManager = fileManager
        self.session = session
    }

    /// Finds a .app bundle in the given directory or its direct subdirectories.
    public func findAppBundle(in directory: URL) throws -> URL {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])
        if let directApp = contents.first(where: { $0.pathExtension == "app" }) {
            return directApp
        }

        for item in contents {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                let subContents = (try? fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)) ?? []
                if let subApp = subContents.first(where: { $0.pathExtension == "app" }) {
                    return subApp
                }
            }
        }

        throw AppUpdaterError.bundleNotFound
    }

    /// Validates that the .app contains an authentic mailto Info.plist.
    public func validateAppBundle(at appURL: URL) throws -> Bool {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            throw AppUpdaterError.invalidBundle
        }

        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any],
              let bundleId = plist["CFBundleIdentifier"] as? String else {
            throw AppUpdaterError.invalidBundle
        }

        guard bundleId == Self.expectedBundleIdentifier else {
            throw AppUpdaterError.invalidBundle
        }

        return true
    }

    /// Extracts a .zip archive into the specified destination directory using macOS ditto.
    public func extractZip(at zipURL: URL, to destinationDir: URL) throws {
        try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipURL.path, destinationDir.path]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw AppUpdaterError.extractionFailed(error.localizedDescription)
        }

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown extraction error"
            throw AppUpdaterError.extractionFailed(errorMsg)
        }
    }

    /// Strips quarantine attribute from the app bundle.
    public func stripQuarantine(at appURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = ["-dr", "com.apple.quarantine", appURL.path]
        try? process.run()
        process.waitUntilExit()
    }

    /// Replaces the destination app bundle with the new app bundle.
    public func installApp(from sourceAppURL: URL, to destinationAppURL: URL) throws {
        let parentDir = destinationAppURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: destinationAppURL.path) {
            try fileManager.removeItem(at: destinationAppURL)
        }

        try fileManager.copyItem(at: sourceAppURL, to: destinationAppURL)
        stripQuarantine(at: destinationAppURL)
    }

    /// Downloads the archive from the specified URL and returns the temporary file location.
    public func downloadZip(from url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("mailto-app/\(MailtoCoreVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60

        let (tempDownloadedURL, response) = try await session.download(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AppUpdaterError.downloadFailed("Server returned HTTP \(statusCode)")
        }

        // Move to unique location with .zip extension so ditto handles it properly
        let destination = fileManager.temporaryDirectory.appendingPathComponent("mailto-update-\(UUID().uuidString).zip")
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempDownloadedURL, to: destination)
        return destination
    }

    /// Downloads, unpacks, validates, and installs the update for the given release.
    /// Returns the installed application URL.
    @discardableResult
    public func downloadAndInstall(
        release: ReleaseInfo,
        targetAppURL: URL? = nil
    ) async throws -> URL {
        guard let zipURL = release.zipDownloadURL else {
            throw AppUpdaterError.noZipURL
        }

        let downloadedZip = try await downloadZip(from: zipURL)
        defer { try? fileManager.removeItem(at: downloadedZip) }

        let extractDir = fileManager.temporaryDirectory.appendingPathComponent("mailto-extract-\(UUID().uuidString)")
        defer { try? fileManager.removeItem(at: extractDir) }

        try extractZip(at: downloadedZip, to: extractDir)
        let discoveredApp = try findAppBundle(in: extractDir)
        _ = try validateAppBundle(at: discoveredApp)

        let destination = targetAppURL ?? resolveDefaultInstallDestination()
        try installApp(from: discoveredApp, to: destination)
        return destination
    }

    /// Determines the best install location based on the currently running bundle.
    public func resolveDefaultInstallDestination() -> URL {
        let runningBundle = Bundle.main.bundleURL
        if runningBundle.pathExtension == "app" && !runningBundle.path.contains("/.build/") {
            return runningBundle
        }
        return URL(fileURLWithPath: "/Applications/mailto.app")
    }

    /// Relaunches the updated app and terminates the current instance.
    @MainActor
    public func relaunchAndTerminate(at appURL: URL) {
        let escapedPath = appURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "sleep 0.6 && open -n \"\(escapedPath)\" &"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script]
        try? process.run()

        NSApp.terminate(nil)
    }
}
