import Foundation
import AppKit

public protocol SourceAppResolving: Sendable {
    func resolveFrontmostApp() -> String?
}

public struct SystemSourceAppResolver: SourceAppResolving {
    public init() {}

    public func resolveFrontmostApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
}
