import SwiftUI
import SwiftData
import KuralKit
import KuralDomain
import KuralStorage

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
        
        do {
            let schema = Schema([SessionRecord.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            let sessionStore = SessionStore(modelContainer: container)
            let insertionService = TextInsertionService()
            
            DictationOrchestrator.shared.setup(
                sessionStore: sessionStore,
                insertionService: insertionService
            )
            
            PlatformOrchestrator.shared.start()
            
            HotkeyManager.shared.onKeyDown = {
                Task {
                    try? await DictationOrchestrator.shared.startDictation()
                }
            }
            
            HotkeyManager.shared.onKeyUp = {
                Task {
                    try? await DictationOrchestrator.shared.stopDictation()
                }
            }
        } catch {
            print("Failed to initialize: \(error)")
        }
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
        #endif
        WindowGroup(id: "main") {
            ContentView()
        }
    }
}
