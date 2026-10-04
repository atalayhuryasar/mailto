import SwiftUI
import AppKit
import MailtoCore

public struct DefaultAppStatusView: View {
    @State private var isDefaultEmailApp: Bool

    private let statusChecker: () -> Bool
    private let makeDefaultAction: () -> Void

    public init(
        initialIsDefault: Bool? = nil,
        statusChecker: @escaping () -> Bool = { DefaultMailAppManager.isMailtoDefault },
        makeDefaultAction: @escaping () -> Void = { DefaultMailAppManager.setMailtoAsDefault() }
    ) {
        self.statusChecker = statusChecker
        self.makeDefaultAction = makeDefaultAction
        _isDefaultEmailApp = State(initialValue: initialIsDefault ?? statusChecker())
    }

    public var body: some View {
        Group {
            if !isDefaultEmailApp {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("mailto: is not your default email client")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Click 'Set as Default' to route clicked mailto links automatically.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Set as Default") {
                        makeDefault()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            checkDefaultAppStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkDefaultAppStatus()
        }
    }

    private func checkDefaultAppStatus() {
        let current = statusChecker()
        if isDefaultEmailApp != current {
            withAnimation(.easeInOut(duration: 0.2)) {
                isDefaultEmailApp = current
            }
        }
    }

    private func makeDefault() {
        makeDefaultAction()
        withAnimation(.easeInOut(duration: 0.2)) {
            isDefaultEmailApp = statusChecker()
        }
    }
}
