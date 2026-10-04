import SwiftUI
import AppKit
import MacMailCore

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
                Text("MacMail Kurulumu")
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
        case 0: return "Adım 1/3: Hoş Geldiniz & Varsayılan Yapma"
        case 1: return "Adım 2/3: İstemci Tercihleri"
        case 2: return "Adım 3/3: Süper Güçler & Test"
        default: return ""
        }
    }

    // MARK: - Step 0: Welcome & Default App
    private var welcomeStepView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("MacMail'e Hoş Geldiniz")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("MacMail, arka planda sıfır kaynak tüketen, tıklanan mail bağlantılarını kurallarınıza göre doğru istemciye aktaran akıllı bir yönlendiricidir.")
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
                    Text(isDefaultEmailApp ? "MacMail varsayılan e-posta okuyucunuz." : "Varsayılan E-posta Uygulaması Değil")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(isDefaultEmailApp ? "Safari, Chrome ve Slack linkleri otomatik olarak MacMail'e yönlendirilecek." : "MacMail'i tek tıkla doğrudan ve sessizce varsayılan yapabilirsiniz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isDefaultEmailApp {
                    Button("Varsayılan Yap") {
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
                Text("Hedef İstemcilerinizi Belirleyin")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Bir e-posta bağlantısına tıklandığında standart veya Fn tuşuna basılıyken açılacak uygulamayı seçin.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                TargetPickerRow(
                    title: "Birincil E-posta Hedefi",
                    subtitle: "Normal tıklamalarda açılacak istemci",
                    selection: $settings.primaryTarget
                )

                Divider()
                    .padding(.horizontal, 14)

                TargetPickerRow(
                    title: "Alternatif Hedef (Fn)",
                    subtitle: "Fn tuşu basılıyken kuralları atlayarak açılır",
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
                Text("Her Şey Hazır!")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Dilediğiniz zaman 'Rules' sekmesinden şirket (@sirket.com) veya belirli adreslere özel kurallar ekleyebilirsiniz.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Test Action Card
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Canlı Bağlantı Testi")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Şu anki birincil hedef: \(settings.primaryTarget.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        triggerTestMailto()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Şimdi Test Et")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if testSentFeedback {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Örnek e-posta bağlantısı hedef istemciye iletildi!")
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
                Text("İpucu: Mail linkine tıklarken **Fn** tuşuna basılı tutarsanız alternatif istemciniz açılır.")
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
                Button("Geri") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                }
                .controlSize(.regular)
            }

            Spacer()

            if currentStep < 2 {
                Button("İleri") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep += 1
                        checkDefaultAppStatus()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            } else {
                Button("Kullanmaya Başla") {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    // MARK: - Helpers
    private func checkDefaultAppStatus() {
        isDefaultEmailApp = DefaultMailAppManager.isMacMailDefault
    }

    private func makeDefault() {
        DefaultMailAppManager.setMacMailAsDefault()
        withAnimation {
            isDefaultEmailApp = DefaultMailAppManager.isMacMailDefault
        }
    }

    private func triggerTestMailto() {
        guard let testURL = URL(string: "mailto:test@example.com?subject=MacMail%20Test&body=MacMail%20basariyla%20calisiyor!") else { return }
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
