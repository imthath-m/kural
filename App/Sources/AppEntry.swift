import SwiftUI
import KuralKit
#if os(macOS)
import KuralMacOS
#endif

@main
struct AppEntry: App {
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Kural", systemImage: "waveform") {
            MenuBarView()
        }
        #endif

        WindowGroup {
            ContentView()
        }
    }
}
