import Foundation
import KeyboardShortcuts
import AppKit
import KuralDomain
import SwiftUI

extension KeyboardShortcuts.Name {
    public static let toggleDictation = Self("pushToTalk")
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

@MainActor
public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()
    
    // MARK: - Callbacks
    
    /// Push-to-talk (single modifier): hold down to record, release to stop.
    public var onPushToTalkDown: (() -> Void)?
    public var onPushToTalkUp: (() -> Void)?
    
    /// Toggle (key combo): press once to start, press again to stop.
    public var onTogglePressed: (() -> Void)?
    
    /// Return key: stops active dictation.
    public var onReturnPressed: (() -> Void)?
    
    // MARK: - Settings
    
    @AppStorage("singleModifierEnabled") public var singleModifierEnabled: Bool = true {
        didSet {
            updateModifierListeners()
        }
    }
    
    @AppStorage("singleModifierKey") public var singleModifier: SingleModifier = .option {
        didSet {
            updateModifierListeners()
        }
    }
    
    // MARK: - Private state
    
    private var modifierGlobalMonitor: Any?
    private var modifierLocalMonitor: Any?
    private var returnKeyGlobalMonitor: Any?
    private var returnKeyLocalMonitor: Any?
    private var isModifierPressed = false
    
    private init() {
        Logger.info("HotkeyManager initialized")
        setupComboListener()
        updateModifierListeners()
        installReturnKeyMonitor()
    }
    
    /// Trigger singleton initialization from AppEntry.
    public func setup() {}
    
    // MARK: - Combo listener (toggle mode)
    
    private func setupComboListener() {
        KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in
            self?.onTogglePressed?()
        }
        // No onKeyUp — combo mode uses toggle semantics, not push-to-talk.
    }
    
    // MARK: - Modifier listeners (push-to-talk)
    
    private func updateModifierListeners() {
        // Remove existing monitors
        if let monitor = modifierGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            modifierGlobalMonitor = nil
        }
        if let monitor = modifierLocalMonitor {
            NSEvent.removeMonitor(monitor)
            modifierLocalMonitor = nil
        }
        
        isModifierPressed = false
        
        guard singleModifierEnabled else { return }
        
        let flagsToMatch = singleModifier.eventFlags
        
        let handler: (NSEvent) -> NSEvent? = { [weak self] event in
            self?.handleFlagsChanged(event: event, expectedFlags: flagsToMatch)
            return event
        }
        
        modifierGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event, expectedFlags: flagsToMatch)
        }
        modifierLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: handler)
    }
    
    private func handleFlagsChanged(event: NSEvent, expectedFlags: NSEvent.ModifierFlags) {
        let cleanFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad, .function])
        let isPressed = cleanFlags == expectedFlags
        
        if isPressed && !isModifierPressed {
            isModifierPressed = true
            onPushToTalkDown?()
        } else if !isPressed && isModifierPressed {
            isModifierPressed = false
            onPushToTalkUp?()
        }
    }
    
    // MARK: - Return key monitor
    
    private func installReturnKeyMonitor() {
        returnKeyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 36 { // Return key
                self?.onReturnPressed?()
            }
        }
        
        returnKeyLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 36 { // Return key
                self?.onReturnPressed?()
            }
            return event
        }
    }
}
