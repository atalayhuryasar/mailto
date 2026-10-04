import SwiftUI
import AppKit
import MailtoCore

public struct TargetPickerRow: View {
    public let title: String
    public let subtitle: String?
    public let hasHelpButton: Bool
    @Binding public var selection: EmailTarget

    public init(
        title: String,
        subtitle: String? = nil,
        hasHelpButton: Bool = false,
        selection: Binding<EmailTarget>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.hasHelpButton = hasHelpButton
        self._selection = selection
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.body)
                    if hasHelpButton {
                        Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("When pressing the Fn key while clicking an email link, this application will be used regardless of any matching rules.")
                    }
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            TargetPickerMenu(selection: $selection)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
    }
}
