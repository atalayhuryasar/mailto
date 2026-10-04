import SwiftUI
import AppKit
import MacMailCore

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
                    Text("Click 'Set as Default' to route clicked mailto: links automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Set as Default") {
                    makeDefault()
                }
                .buttonStyle(.borderedProminent)
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
        isDefaultEmailApp = DefaultMailAppManager.isMacMailDefault
    }

    private func makeDefault() {
        DefaultMailAppManager.setMacMailAsDefault()
        withAnimation {
            isDefaultEmailApp = DefaultMailAppManager.isMacMailDefault
        }
    }
}
