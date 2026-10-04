import Foundation

public struct EmailAddress: Equatable, Hashable, Sendable {
    public let raw: String
    public let address: String
    public let domain: String
    public let displayName: String?

    public init(raw: String, address: String, domain: String, displayName: String?) {
        self.raw = raw
        self.address = address
        self.domain = domain
        self.displayName = displayName
    }

    public static func parse(_ text: String) -> EmailAddress? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Format: "John Doe <john@work.com>" or "<john@work.com>"
        if let startAngle = trimmed.firstIndex(of: "<"),
           let endAngle = trimmed.lastIndex(of: ">"),
           startAngle < endAngle {
            let namePart = trimmed[..<startAngle].trimmingCharacters(in: .whitespacesAndNewlines)
            let addrPart = trimmed[trimmed.index(after: startAngle)..<endAngle].trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedName = namePart.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let displayName = cleanedName.isEmpty ? nil : cleanedName
            return createAddress(raw: trimmed, address: addrPart, displayName: displayName)
        }

        return createAddress(raw: trimmed, address: trimmed, displayName: nil)
    }

    private static func createAddress(raw: String, address: String, displayName: String?) -> EmailAddress {
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let domain: String
        if let atIndex = cleanAddress.lastIndex(of: "@") {
            domain = String(cleanAddress[cleanAddress.index(after: atIndex)...]).lowercased()
        } else {
            domain = ""
        }
        return EmailAddress(raw: raw, address: cleanAddress, domain: domain, displayName: displayName)
    }
}
