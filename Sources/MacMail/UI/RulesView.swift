import SwiftUI
import MacMailCore

public struct RulesView: View {
    @ObservedObject public var settings: SettingsStore

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        VStack {
            Text("Rules")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
