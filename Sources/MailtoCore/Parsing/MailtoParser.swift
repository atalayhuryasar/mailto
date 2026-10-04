import Foundation

public struct MailtoMessage: Equatable, Sendable {
    public let to: [EmailAddress]
    public let cc: [EmailAddress]
    public let bcc: [EmailAddress]
    public let subject: String
    public let body: String
    public let rawURL: URL

    public init(
        to: [EmailAddress] = [],
        cc: [EmailAddress] = [],
        bcc: [EmailAddress] = [],
        subject: String = "",
        body: String = "",
        rawURL: URL
    ) {
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.rawURL = rawURL
    }
}

public enum MailtoParser {
    public static func parse(_ url: URL) -> MailtoMessage {
        var toRecipients: [EmailAddress] = []
        var ccRecipients: [EmailAddress] = []
        var bccRecipients: [EmailAddress] = []
        var subject: String = ""
        var body: String = ""

        let urlString = url.absoluteString
        guard urlString.lowercased().hasPrefix("mailto:") else {
            return MailtoMessage(rawURL: url)
        }

        // Separate path (main recipients) from query
        let afterScheme = String(urlString.dropFirst("mailto:".count))
        let pathPart: String
        let queryPart: String?

        if let questionIndex = afterScheme.firstIndex(of: "?") {
            pathPart = String(afterScheme[..<questionIndex])
            queryPart = String(afterScheme[afterScheme.index(after: questionIndex)...])
        } else {
            pathPart = afterScheme
            queryPart = nil
        }

        // Parse pathPart (comma-separated recipients)
        if !pathPart.isEmpty {
            let decodedPath = pathPart.removingPercentEncoding ?? pathPart
            let rawAddresses = decodedPath.components(separatedBy: ",")
            for raw in rawAddresses {
                if let addr = EmailAddress.parse(raw) {
                    toRecipients.append(addr)
                }
            }
        }

        // Parse queryPart using custom key-value split to avoid URLComponents encoding quirks
        if let query = queryPart, !query.isEmpty {
            let pairs = query.components(separatedBy: "&")
            for pair in pairs {
                guard let equalsIndex = pair.firstIndex(of: "=") else { continue }
                let key = String(pair[..<equalsIndex]).trimmingCharacters(in: .whitespaces).lowercased()
                let rawValue = String(pair[pair.index(after: equalsIndex)...])
                let decodedValue = rawValue.removingPercentEncoding ?? rawValue

                switch key {
                case "to":
                    let addrs = decodedValue.components(separatedBy: ",")
                    for raw in addrs {
                        if let addr = EmailAddress.parse(raw) {
                            toRecipients.append(addr)
                        }
                    }
                case "cc":
                    let addrs = decodedValue.components(separatedBy: ",")
                    for raw in addrs {
                        if let addr = EmailAddress.parse(raw) {
                            ccRecipients.append(addr)
                        }
                    }
                case "bcc":
                    let addrs = decodedValue.components(separatedBy: ",")
                    for raw in addrs {
                        if let addr = EmailAddress.parse(raw) {
                            bccRecipients.append(addr)
                        }
                    }
                case "subject":
                    subject = decodedValue
                case "body":
                    body = decodedValue
                default:
                    break
                }
            }
        }

        return MailtoMessage(
            to: toRecipients,
            cc: ccRecipients,
            bcc: bccRecipients,
            subject: subject,
            body: body,
            rawURL: url
        )
    }
}
