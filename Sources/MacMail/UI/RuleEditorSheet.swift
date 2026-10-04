import SwiftUI
import AppKit
import MacMailCore

public struct RuleEditorSheet: View {
    public let isNew: Bool
    public let onSave: (Rule) -> Void
    public let onCancel: () -> Void

    @State private var rule: Rule
    @State private var installedApps: [InstalledMailApp] = []
    @State private var isShowingAppPicker: Bool = false

    public init(
        rule: Rule? = nil,
        onSave: @escaping (Rule) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.isNew = rule == nil
        self._rule = State(initialValue: rule ?? Rule(
            name: "",
            isEnabled: true,
            target: .nativeApp(bundleId: "com.apple.mail", name: "Mail"),
            recipientMatchers: [RecipientMatcher(kind: .domain, value: "")],
            sourceAppBundleIdentifiers: []
        ))
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(isNew ? "New Rule" : "Edit Rule")
                .font(.headline)
                .fontWeight(.bold)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Group 1: Name & Open in
                    VStack(spacing: 0) {
                        HStack {
                            Text("Name")
                                .font(.body)
                            Spacer()
                            TextField("Rule name", text: $rule.name)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 260)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)

                        Divider()
                            .padding(.horizontal, 12)

                        HStack {
                            Text("Open in")
                                .font(.body)
                            Spacer()
                            TargetPickerMenu(selection: $rule.target)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                    // Group 2: Recipient Matchers
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recipient Matchers")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button {
                                rule.recipientMatchers.append(RecipientMatcher(kind: .domain, value: ""))
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderless)
                        }

                        if rule.recipientMatchers.isEmpty {
                            Text("No recipient matchers (matches all emails)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(10)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(Array(rule.recipientMatchers.enumerated()), id: \.element.id) { index, matcher in
                                    matcherRow(index: index, matcher: matcher)
                                }
                            }
                        }
                    }

                    // Group 3: Source Apps
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Source Apps")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button {
                                isShowingAppPicker = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderless)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            if rule.sourceAppBundleIdentifiers.isEmpty {
                                HStack {
                                    Text("No source apps")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                            } else {
                                ForEach(rule.sourceAppBundleIdentifiers, id: \.self) { bundleId in
                                    HStack {
                                        Text(displayName(for: bundleId))
                                            .font(.body)
                                        Spacer()
                                        Button {
                                            rule.sourceAppBundleIdentifiers.removeAll { $0 == bundleId }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )

                        Text("The email link must have been clicked in one of these apps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Bottom action buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    onSave(rule)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!rule.isValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 480, height: 440)
        .onAppear {
            installedApps = MailAppDiscovery.findInstalledMailApps()
        }
        .sheet(isPresented: $isShowingAppPicker) {
            sourceAppPickerSheet
        }
    }

    private func matcherRow(index: Int, matcher: RecipientMatcher) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("Detect via")
                    .font(.body)

                Picker("", selection: Binding(
                    get: { rule.recipientMatchers[index].kind },
                    set: { rule.recipientMatchers[index].kind = $0 }
                )) {
                    ForEach(MatcherKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .labelsHidden()
                .frame(width: 170)

                TextField("example.com", text: Binding(
                    get: { rule.recipientMatchers[index].value },
                    set: { rule.recipientMatchers[index].value = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                Button {
                    rule.recipientMatchers.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            Text(matcher.kind.explanatoryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var sourceAppPickerSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Source Application")
                .font(.headline)

            List(installedApps) { app in
                Button {
                    if !rule.sourceAppBundleIdentifiers.contains(app.bundleId) {
                        rule.sourceAppBundleIdentifiers.append(app.bundleId)
                    }
                    isShowingAppPicker = false
                } label: {
                    HStack {
                        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.name)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()
                Button("Done") {
                    isShowingAppPicker = false
                }
            }
        }
        .padding(16)
        .frame(width: 320, height: 320)
    }

    private func displayName(for bundleId: String) -> String {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: appURL.path)
        }
        return bundleId
    }
}
