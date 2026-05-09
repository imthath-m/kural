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

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Kural", systemImage: "waveform") {
            MenuBarView()
        }
        #endif

        WindowGroup {
            ContentView()
                .onAppear {
                    #if os(macOS)
                    hotkeyManager.setup()
                    #endif
                }
        }
    }
}
