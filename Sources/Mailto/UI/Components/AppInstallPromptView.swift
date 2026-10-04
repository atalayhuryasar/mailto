import AppKit
import SwiftUI
import MailtoCore

public struct AppInstallPromptView: View {
    public let sourceURL: URL
    public let destinationURL: URL
    public var onInstalled: (() -> Void)?
    public var onSkip: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isTargetHovered: Bool = false
    @State private var isInstalling: Bool = false
    @State private var errorMessage: String?

    public init(
        sourceURL: URL,
        destinationURL: URL,
        onInstalled: (() -> Void)? = nil,
        onSkip: @escaping () -> Void
    ) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.onInstalled = onInstalled
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                Text("Move to Applications")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("mailto: works best when installed in your Applications folder. Moving it keeps email routing reliable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)

            // Drag and Drop Area
            HStack(spacing: 32) {
                // Source: App Icon
                VStack(spacing: 8) {
                    ZStack {
                        if let appIcon = NSImage(named: NSImage.applicationIconName) {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 68, height: 68)
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: .black.opacity(0.18), radius: dragOffset == .zero ? 4 : 12, y: dragOffset == .zero ? 2 : 6)
                        } else {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 68, height: 68)
                                .overlay(
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.accentColor)
                                )
                        }
                    }
                    .frame(width: 68, height: 68)
                    .contentShape(Rectangle())
                    .offset(dragOffset)
                    .zIndex(1)
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                dragOffset = CGSize(
                                    width: max(-10, min(150, value.translation.width)),
                                    height: value.translation.height * 0.2
                                )
                                if dragOffset.width > 65 {
                                    isTargetHovered = true
                                } else {
                                    isTargetHovered = false
                                }
                            }
                            .onEnded { value in
                                if value.translation.width > 65 {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        dragOffset = CGSize(width: 140, height: 0)
                                    }
                                    isTargetHovered = true
                                    executeInstall()
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                        dragOffset = .zero
                                        isTargetHovered = false
                                    }
                                }
                            }
                    )

                    Text("mailto:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                // Middle: Arrow
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(isTargetHovered ? Color.accentColor : Color.secondary.opacity(0.6))
                        .scaleEffect(isTargetHovered ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isTargetHovered)

                    Text("or click")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                // Destination: Applications Folder
                VStack(spacing: 8) {
                    ZStack {
                        let appsIcon = NSWorkspace.shared.icon(forFile: "/Applications")
                        Image(nsImage: appsIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 68, height: 68)
                            .scaleEffect(isTargetHovered ? 1.08 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargetHovered)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.accentColor.opacity(isTargetHovered ? 0.8 : 0.0), lineWidth: 2.5)
                            .padding(-4)
                    )

                    Text("Applications")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, 8)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }

            // Actions
            VStack(spacing: 10) {
                Button(action: {
                    executeInstall()
                }) {
                    HStack(spacing: 6) {
                        if isInstalling {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Move to Applications Folder")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(isInstalling)

                Button("Don't Move") {
                    onSkip()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                .keyboardShortcut(.cancelAction)
                .disabled(isInstalling)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(width: 380)
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func executeInstall() {
        isInstalling = true
        errorMessage = nil
        let manager = AppLocationManager()
        do {
            try manager.installApp(from: sourceURL, to: destinationURL, cleanSource: true)
            manager.stripQuarantine(at: destinationURL)
            onInstalled?()
            manager.relaunchAndTerminate(at: destinationURL)
        } catch {
            isInstalling = false
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
public enum AppInstallPresenter {
    public static func showPrompt(sourceURL: URL, destinationURL: URL) -> Bool {
        var didInstall = false

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 320),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let view = AppInstallPromptView(
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            onInstalled: {
                didInstall = true
                NSApp.stopModal()
                window.close()
            },
            onSkip: {
                NSApp.stopModal()
                window.close()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView
        let fit = hostingView.fittingSize
        window.setContentSize(NSSize(width: 380, height: fit.height))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        NSApp.runModal(for: window)
        return didInstall
    }
}
