import SwiftUI
import MailtoCore

public struct RulesView: View {
    @ObservedObject public var settings: SettingsStore
    @State private var editingRule: Rule? = nil
    @State private var isShowingEditorSheet: Bool = false

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Card container
            VStack(alignment: .leading, spacing: 0) {
                if settings.rules.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("No rules configured")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Create rules to route emails based on domain, address, or source app.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(settings.rules.enumerated()), id: \.element.id) { index, rule in
                                RuleRowView(
                                    rule: Binding(
                                        get: { settings.rules[index] },
                                        set: { settings.rules[index] = $0 }
                                    ),
                                    onEdit: {
                                        editingRule = rule
                                        isShowingEditorSheet = true
                                    },
                                    onDelete: {
                                        settings.rules.remove(at: index)
                                    }
                                )

                                if index < settings.rules.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                    .frame(minHeight: 180, maxHeight: 220)
                }

                Divider()

                // Bottom toolbar row inside card
                HStack {
                    Button {
                        editingRule = nil
                        isShowingEditorSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Add new rule")

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
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
        .sheet(isPresented: $isShowingEditorSheet) {
            RuleEditorSheet(
                rule: editingRule,
                onSave: { updatedRule in
                    if let index = settings.rules.firstIndex(where: { $0.id == updatedRule.id }) {
                        settings.rules[index] = updatedRule
                    } else {
                        settings.rules.append(updatedRule)
                    }
                    isShowingEditorSheet = false
                    editingRule = nil
                },
                onCancel: {
                    isShowingEditorSheet = false
                    editingRule = nil
                }
            )
        }
    }
}
