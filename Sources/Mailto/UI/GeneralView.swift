import SwiftUI
import AppKit
import MailtoCore

public struct GeneralView: View {
    @ObservedObject public var settings: SettingsStore
    public var onRestartOnboarding: (() -> Void)?

    @State private var isCheckingForUpdates: Bool = false

    public init(settings: SettingsStore, onRestartOnboarding: (() -> Void)? = nil) {
        self.settings = settings
        self.onRestartOnboarding = onRestartOnboarding
    }

    public var body: some View {
        VStack(spacing: 14) {
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

            // Software Updates Card
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Software Updates")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("mailto: v\(MailtoCoreVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        checkForUpdatesManually()
                    } label: {
                        if isCheckingForUpdates {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Check for Updates")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(isCheckingForUpdates)
                }

                Divider()

                Toggle("Automatically check for updates", isOn: $settings.automaticallyCheckForUpdates)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            Spacer()

            if let onRestartOnboarding = onRestartOnboarding {
                Button {
                    onRestartOnboarding()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text("Re-run Setup Wizard")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 14)
    }

    private func checkForUpdatesManually() {
        isCheckingForUpdates = true
        Task {
            let alert = NSAlert()
            do {
                let result = try await UpdateChecker().checkForUpdates(currentVersion: MailtoCoreVersion)
                await MainActor.run {
                    isCheckingForUpdates = false
                    switch result {
                    case .updateAvailable(let newVersion, let release):
                        alert.messageText = "A new version of mailto: is available!"
                        alert.informativeText = "mailto: v\(newVersion) is available (you currently have v\(MailtoCoreVersion)).\n\nWould you like to open the download page?"
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "Download Update")
                        alert.addButton(withTitle: "Later")
                        if alert.runModal() == .alertFirstButtonReturn {
                            if let url = URL(string: release.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    case .upToDate:
                        alert.messageText = "You're Up to Date!"
                        alert.informativeText = "mailto: v\(MailtoCoreVersion) is currently the newest version."
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingForUpdates = false
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = "Unable to check for updates: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
}
