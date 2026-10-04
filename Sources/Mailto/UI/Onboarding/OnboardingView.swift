import SwiftUI
import AppKit
import MailtoCore

public struct OnboardingView: View {
    @ObservedObject public var settings: SettingsStore
    public let onFinish: () -> Void

    @State private var currentStep: Int = 0
    @State private var isDefaultEmailApp: Bool = false
    @State private var testSentFeedback: Bool = false

    public init(settings: SettingsStore, onFinish: @escaping () -> Void) {
        self.settings = settings
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with App Icon and Step Indicator
            headerView
                .padding(.top, 20)
                .padding(.horizontal, 24)

            Divider()
                .padding(.top, 14)

            // Step Content
            ZStack {
                switch currentStep {
                case 0:
                    welcomeStepView
                case 1:
                    setupStepView
                case 2:
                    testStepView
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // Footer Navigation
            footerView
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 560, height: 360)
        .onAppear {
            checkDefaultAppStatus()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.85), Color.indigo.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "envelope.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("mailto: Setup")
                    .font(.headline)
                Text(stepSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Step Dots
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 7, height: 7)
                }
            }
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "Step 1/3: Welcome & Set as Default"
        case 1: return "Step 2/3: Target Preferences"
        case 2: return "Step 3/3: Superpowers & Live Test"
        default: return ""
        }
    }

    // MARK: - Step 0: Welcome & Default App
    private var welcomeStepView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Welcome to mailto:")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("mailto: is an intelligent, zero-footprint router that intercepts clicked email links and dispatches them according to your custom rules.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            // Default App Action Box
            HStack(spacing: 12) {
                Image(systemName: isDefaultEmailApp ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isDefaultEmailApp ? Color.green : Color.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isDefaultEmailApp ? "mailto: is your default email app." : "Not Your Default Email App")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(isDefaultEmailApp ? "Email links clicked in Safari, Chrome, Slack, and other apps will automatically route to mailto:." : "Click below to silently set mailto: as your default email reader.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isDefaultEmailApp {
                    Button("Set as Default") {
                        makeDefault()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDefaultEmailApp ? Color.green.opacity(0.2) : Color.orange.opacity(0.25), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Step 1: Targets Setup
    private var setupStepView: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Choose Your Email Targets")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Select the default app for standard clicks, and an alternative target when holding the Fn key.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                TargetPickerRow(
                    title: "Primary Email Target",
                    subtitle: "Used for standard clicks",
                    selection: $settings.primaryTarget
                )

                Divider()
                    .padding(.horizontal, 14)

                TargetPickerRow(
                    title: "Alternative Target (Fn)",
                    subtitle: "Hold Fn while clicking to bypass all rules",
                    hasHelpButton: true,
                    selection: $settings.alternativeTarget
                )
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Step 2: Superpowers & Live Test
    private var testStepView: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("You're All Set!")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("You can add custom rules anytime in the Rules tab to route work domains (@company.com) or specific addresses.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Test Action Card
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Connection Test")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Current primary target: \(settings.primaryTarget.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        triggerTestMailto()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Test Now")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if testSentFeedback {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Sample mailto: link dispatched to your target!")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .transition(.opacity)
                }
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Tip: Hold the **Fn** key while clicking any email link to route to your alternative target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                }
                .controlSize(.regular)
            }

            Spacer()

            if currentStep < 2 {
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep += 1
                        checkDefaultAppStatus()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else {
                Button("Get Started") {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    // MARK: - Helpers
    private func checkDefaultAppStatus() {
        isDefaultEmailApp = DefaultMailAppManager.isMailtoDefault
    }

    private func makeDefault() {
        DefaultMailAppManager.setMailtoAsDefault()
        withAnimation {
            isDefaultEmailApp = DefaultMailAppManager.isMailtoDefault
        }
    }

    private func triggerTestMailto() {
        guard let testURL = URL(string: "mailto:test@example.com?subject=mailto:%20Test&body=mailto:%20is%20working%20great!") else { return }
        let msg = MailtoParser.parse(testURL)
        let dispatcher = TargetDispatcher()
        dispatcher.dispatch(target: settings.primaryTarget, message: msg) { _ in
            Task { @MainActor in
                withAnimation {
                    self.testSentFeedback = true
                }
            }
        }
    }
}
