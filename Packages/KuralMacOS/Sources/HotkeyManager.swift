import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    public static let pushToTalk = Self("pushToTalk")
}

@MainActor
public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    private init() {
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) {
            print("Hotkey pressed: pushToTalk")
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) {
            print("Hotkey released: pushToTalk")
        }
    }
    
    public func setup() {
        // Just to trigger the singleton initialization
        print("HotkeyManager initialized and listening for pushToTalk hotkey")
    }
}
