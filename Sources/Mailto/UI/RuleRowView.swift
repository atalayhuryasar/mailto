import SwiftUI
import MailtoCore

public struct RuleRowView: View {
    @Binding public var rule: Rule
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    public init(rule: Binding<Rule>, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self._rule = rule
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $rule.isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(rule.isEnabled ? Color.primary : Color.secondary)

                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onEdit()
        }
        .contextMenu {
            Button("Edit…") {
                onEdit()
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private var subtitleText: String {
        let count = rule.recipientMatchers.count
        let matcherDesc = count == 1 ? "1 recipient matcher" : "\(count) recipient matchers"
        return "\(matcherDesc) → \(rule.target.displayName)"
    }
}
