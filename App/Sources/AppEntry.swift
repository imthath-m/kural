import SwiftUI
import KuralKit
#if os(macOS)
import KuralMacOS
#endif

@main
struct AppEntry: App {
    #if os(macOS)
    @StateObject private var hotkeyManager = HotkeyManager.shared
    #endif

    init() {
        #if os(macOS)
        HotkeyManager.shared.setup()
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Kural", systemImage: "waveform") {
            MenuBarView()
        }
        Settings {
            SettingsView()
        }
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
