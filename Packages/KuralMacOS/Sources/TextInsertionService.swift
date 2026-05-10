import Foundation
import KuralDomain
import AppKit

public final class TextInsertionService: TextInsertionProtocol {
    private let clipboardManager = ClipboardManager()
    
    public init() {}
    
    public func insertText(_ text: String) async throws {
        // Multi-layer fallback as per ADR 0003
        
        // Layer 1: Clipboard-Paste (Simplest for MVP)
        clipboardManager.snapshotContents()
        clipboardManager.setString(text)
        
        // Command + V (Virtual Key 0x09 is 'V')
        let source = CGEventSource(stateID: .combinedSessionState)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        
        // Wait a bit for the paste to complete before restoring
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        clipboardManager.restoreContents()
    }
}
