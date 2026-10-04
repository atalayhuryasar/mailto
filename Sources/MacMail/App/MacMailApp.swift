import SwiftUI
import AppKit
import MacMailCore

@main
struct MacMailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("General", id: "settings") {
            VStack {
                Text("MacMail Settings")
                    .font(.headline)
            }
            .frame(width: 560, height: 300)
            .onAppear {
                appDelegate.isSettingsWindowOpen = true
            }
            .onDisappear {
                appDelegate.isSettingsWindowOpen = false
            }
        }
        .windowResizability(.contentSize)
    }
}
