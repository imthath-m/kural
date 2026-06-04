import SwiftUI
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
            let sessionStore = try SessionStore.create()
            let insertionService = TextInsertionService()
            
            DictationOrchestrator.shared.setup(
                sessionStore: sessionStore,
                insertionService: insertionService
            )
            
            PlatformOrchestrator.shared.start()
            
            // Push-to-talk: single modifier (hold to record, release to stop)
            HotkeyManager.shared.onPushToTalkDown = {
                Task {
                    try? await DictationOrchestrator.shared.startDictation()
                }
            }
            HotkeyManager.shared.onPushToTalkUp = {
                Task {
                    try? await DictationOrchestrator.shared.stopDictation()
                }
            }
            
            // Toggle: key combo (press to start, press again to stop)
            HotkeyManager.shared.onTogglePressed = {
                Task {
                    let orchestrator = DictationOrchestrator.shared
                    if orchestrator.currentState == .recording {
                        try? await orchestrator.stopDictation()
                    } else {
                        try? await orchestrator.startDictation()
                    }
                }
            }
            
            // Return key stops active dictation
            HotkeyManager.shared.onReturnPressed = {
                Task {
                    let orchestrator = DictationOrchestrator.shared
                    if orchestrator.currentState == .recording {
                        try? await orchestrator.stopDictation()
                    }
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
