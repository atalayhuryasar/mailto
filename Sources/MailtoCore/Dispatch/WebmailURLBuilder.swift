import Foundation

public struct WebmailURLBuilder {
    public static func defaultTemplate(for provider: WebmailProvider) -> String {
        switch provider {
        case .gmail:
            return "https://mail.google.com/mail/?view=cm&fs=1&to={to}&cc={cc}&bcc={bcc}&su={subject}&body={body}"
        case .fastmail:
            return "https://app.fastmail.com/mail/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .outlook365:
            return "https://outlook.office.com/mail/deeplink/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .outlookCom:
            return "https://outlook.live.com/mail/deeplink/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .yahoo:
            return "https://compose.mail.yahoo.com/?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .yandex:
            return "https://mail.yandex.com/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .aol:
            return "https://mail.aol.com/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        case .zoho:
            return "https://mail.zoho.com/mail/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}"
        }
    }

    public static func buildURL(target: EmailTarget, message: MailtoMessage, maxBodyLength: Int = 8000) -> URL? {
        let template: String
        switch target {
        case .webmail(let provider):
            template = defaultTemplate(for: provider)
        case .customURL(let customTemplate):
            template = customTemplate
        default:
            return nil
        }

        let toAddresses = message.to.map(\.address).joined(separator: ",")
        let ccAddresses = message.cc.map(\.address).joined(separator: ",")
        let bccAddresses = message.bcc.map(\.address).joined(separator: ",")
        let domain = message.to.first?.domain ?? ""

        var body = message.body
        if body.count > maxBodyLength {
            body = String(body.prefix(maxBodyLength))
        }

        let replacements: [String: String] = [
            "{to}": toAddresses,
            "{cc}": ccAddresses,
            "{bcc}": bccAddresses,
            "{subject}": message.subject,
            "{body}": body,
            "{domain}": domain,
            "{mailto}": message.rawURL.absoluteString
        ]

        var finalURLString = template
        for (token, value) in replacements {
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            finalURLString = finalURLString.replacingOccurrences(of: token, with: encodedValue)
        }

        return URL(string: finalURLString)
    }
}
