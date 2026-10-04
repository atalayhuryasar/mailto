import SwiftUI
import AppKit

public struct DefaultAppStatusView: View {
    @State private var isDefaultEmailApp: Bool = true

    public init() {}

    public var body: some View {
        if !isDefaultEmailApp {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MacMail is not your default email app")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Set MacMail as the default in System Settings to route clicked links.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .onAppear {
                checkDefaultAppStatus()
            }
        }
    }

    private func checkDefaultAppStatus() {
        guard let mailtoURL = URL(string: "mailto:") else { return }
        if let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: mailtoURL),
           let bundle = Bundle(url: defaultAppURL),
           bundle.bundleIdentifier == "com.atalayhuryasar.macmail" {
            isDefaultEmailApp = true
        } else {
            isDefaultEmailApp = false
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.DefaultApps-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
