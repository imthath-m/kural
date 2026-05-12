import Foundation
import KeyboardShortcuts
import AppKit
import KuralDomain
import SwiftUI

extension KeyboardShortcuts.Name {
    public static let pushToTalk = Self("pushToTalk")
}

public enum SingleModifier: String, CaseIterable, Identifiable {
    case option = "Option"
    case command = "Command"
    case control = "Control"
    case shift = "Shift"
    
    public var id: String { self.rawValue }
    
    public var eventFlags: NSEvent.ModifierFlags {
        switch self {
        case .option: return .option
        case .command: return .command
        case .control: return .control
        case .shift: return .shift
        }
    }
}

public enum HotkeyMode: String, Equatable {
    case combo
    case singleModifier
}

@MainActor
public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    public var onKeyDown: (() -> Void)?
    public var onKeyUp: (() -> Void)?
    
    @AppStorage("hotkeyMode") public var mode: HotkeyMode = .combo {
        didSet {
            updateListeners()
        }
    }
    
    @AppStorage("singleModifierKey") public var singleModifier: SingleModifier = .option {
        didSet {
            updateListeners()
        }
    }
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isModifierPressed = false
    
    private init() {
        Logger.info("HotkeyManager initialized")
        setupComboListeners()
        updateListeners()
    }
    
    public func setup() {
        // Just to trigger the singleton initialization
    }
    
    private func setupComboListeners() {
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            guard let self = self, self.mode == .combo else { return }
            self.onKeyDown?()
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            guard let self = self, self.mode == .combo else { return }
            self.onKeyUp?()
        }
    }
    
    private func updateListeners() {
        // Remove existing monitors
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        isModifierPressed = false
        
        if mode == .singleModifier {
            let flagsToMatch = singleModifier.eventFlags
            
            let handler: (NSEvent) -> NSEvent? = { [weak self] event in
                self?.handleFlagsChanged(event: event, expectedFlags: flagsToMatch)
                return event
            }
            
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event: event, expectedFlags: flagsToMatch)
            }
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: handler)
        }
    }
    
    private func handleFlagsChanged(event: NSEvent, expectedFlags: NSEvent.ModifierFlags) {
        let cleanFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad, .function])
        let isPressed = cleanFlags == expectedFlags
        
        if isPressed && !isModifierPressed {
            isModifierPressed = true
            onKeyDown?()
        } else if !isPressed && isModifierPressed {
            isModifierPressed = false
            onKeyUp?()
        }
    }
}
