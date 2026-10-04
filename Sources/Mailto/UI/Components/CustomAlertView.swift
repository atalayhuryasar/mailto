import AppKit
import SwiftUI

public struct AlertActionItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let isPrimary: Bool
    public let isCancel: Bool
    public let action: () -> Void

    public init(title: String, isPrimary: Bool = false, isCancel: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isPrimary = isPrimary
        self.isCancel = isCancel
        self.action = action
    }
}

public struct CustomAlertView: View {
    public let iconSystemName: String?
    public let iconColor: Color?
    public let title: String
    public let message: String
    public let actions: [AlertActionItem]

    public init(
        iconSystemName: String? = nil,
        iconColor: Color? = nil,
        title: String,
        message: String,
        actions: [AlertActionItem]
    ) {
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.actions = actions
    }

    public var body: some View {
        VStack(spacing: 16) {
            if let iconSystemName = iconSystemName {
                Image(systemName: iconSystemName)
                    .font(.system(size: 44))
                    .foregroundStyle(iconColor ?? .accentColor)
                    .frame(height: 56)
            } else if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(actions) { item in
                    if item.isPrimary {
                        Button(action: item.action) {
                            Text(item.title)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 3)
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    } else {
                        Button(action: item.action) {
                            Text(item.title)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 3)
                        }
                        .keyboardShortcut(item.isCancel ? .cancelAction : .none)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(width: 300)
    }
}

@MainActor
public enum CustomAlertPresenter {
    public static func show(
        iconSystemName: String? = nil,
        iconColor: Color? = nil,
        title: String,
        message: String,
        actions: [AlertActionItem]
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 220),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let wrappedActions = actions.map { item in
            AlertActionItem(title: item.title, isPrimary: item.isPrimary, isCancel: item.isCancel) {
                NSApp.stopModal()
                window.close()
                item.action()
            }
        }

        let alertView = CustomAlertView(
            iconSystemName: iconSystemName,
            iconColor: iconColor,
            title: title,
            message: message,
            actions: wrappedActions
        )

        let hostingView = NSHostingView(rootView: alertView)
        window.contentView = hostingView
        let fitting = hostingView.fittingSize
        window.setContentSize(NSSize(width: 300, height: fitting.height))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
    }
}
