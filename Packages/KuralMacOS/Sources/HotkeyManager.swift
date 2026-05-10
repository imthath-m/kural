import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    public static let pushToTalk = Self("pushToTalk")
}

@MainActor
public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    public var onKeyDown: (() -> Void)?
    public var onKeyUp: (() -> Void)?
    
    private init() {
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            self?.onKeyDown?()
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            self?.onKeyUp?()
        }
    }
    
    public func setup() {
        // Just to trigger the singleton initialization
    }
}
