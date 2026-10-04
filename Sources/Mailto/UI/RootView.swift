import SwiftUI
import MailtoCore

public enum MainTab: String, CaseIterable {
    case general = "General"
    case rules = "Rules"
}

public struct RootView: View {
    @ObservedObject public var settings: SettingsStore
    @State private var selectedTab: MainTab = .general
    @State private var showOnboarding: Bool = false

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(settings: settings) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        settings.hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                }
            } else {
                mainContent
            }
        }
        .frame(width: 560, height: showOnboarding ? 360 : 410)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if !settings.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Centered Tab Control matching Mailway design
            HStack(spacing: 24) {
                tabButton(
                    tab: .general,
                    title: "General",
                    iconName: "gearshape"
                )

                tabButton(
                    tab: .rules,
                    title: "Rules",
                    iconName: "arrow.triangle.branch"
                )
            }
            .padding(.top, 12)
            .padding(.bottom, 14)

            Divider()

            // Tab Content
            switch selectedTab {
            case .general:
                GeneralView(settings: settings) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOnboarding = true
                    }
                }
            case .rules:
                RulesView(settings: settings)
            }
        }
        .navigationTitle(selectedTab.rawValue)
    }

    private func tabButton(tab: MainTab, title: String, iconName: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1.5)
                            .background(Color.blue.opacity(0.12).clipShape(RoundedRectangle(cornerRadius: 8)))
                            .frame(width: 36, height: 36)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                            .frame(width: 36, height: 36)
                    }

                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(selectedTab == tab ? Color.blue : Color.secondary)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundStyle(selectedTab == tab ? Color.blue : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
