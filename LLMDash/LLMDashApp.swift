import SwiftUI

@main
struct LLMDashApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environmentObject(appState)
        } label: {
            Label("LLMDash", systemImage: "brain.head.profile")
        }
        .menuBarExtraStyle(.window)

        Window("LLMDash Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState)
        }
        .defaultSize(width: 520, height: 450)
    }
}
