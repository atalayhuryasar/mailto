import SwiftUI
import AppKit
import MailtoCore

public struct TargetPickerMenu: View {
    @Binding public var selection: EmailTarget
    @State private var installedApps: [InstalledMailApp] = []
    @State private var isShowingCustomURLSheet: Bool = false
    @State private var customURLInput: String = ""

    public init(selection: Binding<EmailTarget>) {
        self._selection = selection
    }

    public var body: some View {
        Menu {
            Section("Applications") {
                ForEach(installedApps) { app in
                    Button {
                        selection = .nativeApp(bundleId: app.bundleId, name: app.name)
                    } label: {
                        HStack {
                            Text(app.name)
                            if case .nativeApp(let bundleId, _) = selection, bundleId == app.bundleId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section("Webmail") {
                ForEach(WebmailProvider.allCases, id: \.self) { provider in
                    Button {
                        selection = .webmail(provider: provider)
                    } label: {
                        HStack {
                            Text(provider.displayName)
                            if case .webmail(let p) = selection, p == provider {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    if case .customURL(let template) = selection {
                        customURLInput = template
                    } else {
                        customURLInput = "https://mail.google.com/mail/?view=cm&fs=1&to={to}&su={subject}&body={body}"
                    }
                    isShowingCustomURLSheet = true
                } label: {
                    HStack {
                        Text("Custom URL…")
                        if case .customURL = selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    selection = .clipboard
                } label: {
                    HStack {
                        Text("Copy to Clipboard")
                        if case .clipboard = selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                targetIcon
                Text(selection.displayName)
                    .font(.body)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .onAppear {
            loadInstalledApps()
        }
        .sheet(isPresented: $isShowingCustomURLSheet) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Custom Compose URL")
                    .font(.headline)
                Text("Available placeholders: {to}, {cc}, {bcc}, {subject}, {body}, {domain}, {mailto}")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Compose URL Template", text: $customURLInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 400)

                HStack {
                    Spacer()
                    Button("Cancel") {
                        isShowingCustomURLSheet = false
                    }
                    Button("Save") {
                        if !customURLInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            selection = .customURL(template: customURLInput)
                        }
                        isShowingCustomURLSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var targetIcon: some View {
        switch selection {
        case .nativeApp(let bundleId, _):
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "app.badge")
                    .frame(width: 16, height: 16)
            }
        case .webmail:
            Image(systemName: "globe")
                .frame(width: 16, height: 16)
        case .customURL:
            Image(systemName: "link")
                .frame(width: 16, height: 16)
        case .clipboard:
            Image(systemName: "doc.on.clipboard")
                .frame(width: 16, height: 16)
        }
    }

    private func loadInstalledApps() {
        installedApps = MailAppDiscovery.findInstalledMailApps()
    }
}
