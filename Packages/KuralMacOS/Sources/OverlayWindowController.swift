import AppKit
import SwiftUI

public final class OverlayWindowController: NSWindowController {
    public static let shared = OverlayWindowController()
    
    private let ghostTextSubject = NSBindingName("ghostText")
    
    public init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(ghostText: String, isPolishing: Bool, isListening: Bool = false, errorMessage: String? = nil) {
        let contentView = OverlayView(ghostText: ghostText, isPolishing: isPolishing, isListening: isListening, errorMessage: errorMessage)
        let hostingView = NSHostingView(rootView: contentView)
        
        guard let window = window else { return }
        
        window.contentView = hostingView
        
        // Size to fit
        let size = hostingView.fittingSize
        window.setFrame(NSRect(origin: window.frame.origin, size: size), display: true)
        
        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.origin.x + (screenRect.width - size.width) / 2
            let y = screenRect.origin.y + (screenRect.height / 4) // Position slightly above center
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        if !window.isVisible {
            window.orderFrontRegardless()
        }
    }
    
    public func hide() {
        window?.orderOut(nil)
    }
}
