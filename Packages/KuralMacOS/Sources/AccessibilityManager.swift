import Foundation
import ApplicationServices
import Cocoa
import KuralDomain

public final class AccessibilityManager: ObservableObject {
    @Published public private(set) var permissionState: PermissionState = .notRequested
    
    public static let shared = AccessibilityManager()
    
    private init() {
        checkTrust()
    }
    
    public func checkTrust() {
        permissionState = AXIsProcessTrusted() ? .authorized : .rejected
    }
    
    public func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Re-check trust after a short delay, though the user has to go to settings
        // and come back, so we might need a way to poll or react to app activation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkTrust()
        }
    }
    
    public func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
