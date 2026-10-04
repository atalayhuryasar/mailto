import SwiftUI
import MacMailCore

public struct GeneralView: View {
    @ObservedObject public var settings: SettingsStore

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        VStack(spacing: 16) {
            DefaultAppStatusView()

            VStack(spacing: 0) {
                TargetPickerRow(
                    title: "Primary email app",
                    selection: $settings.primaryTarget
                )

                Divider()
                    .padding(.horizontal, 14)

                TargetPickerRow(
                    title: "Alternative email app",
                    subtitle: "Hold Fn to use this target, skipping rules.",
                    hasHelpButton: true,
                    selection: $settings.alternativeTarget
                )
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 16)
    }
}
