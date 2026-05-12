import Foundation
import ApplicationServices
import Cocoa
import KuralDomain

public final class AccessibilityManager: ObservableObject {
    @Published public private(set) var permissionState: PermissionState = .notRequested
    
    public static let shared = AccessibilityManager()
    
    private var activeObserver: NSObjectProtocol?
    private var workspaceObserver: NSObjectProtocol?
    
    private init() {
        checkTrust()
        
        // Observe app becoming active
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.info("App became active, checking accessibility trust")
            self?.checkTrust()
        }
        
        // For LSUIElement apps, didBecomeActiveNotification might not fire reliably.
        // Also observe when other apps deactivate, which might mean we became active or user clicked our menu
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // When user switches away from System Settings, they might be interacting with us
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               app.bundleIdentifier == Bundle.main.bundleIdentifier {
                Logger.info("App activated via Workspace, checking accessibility trust")
                self?.checkTrust()
            } else {
                // Also check if we just gained focus in general
                self?.checkTrust()
            }
        }
    }
    
    deinit {
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let wObserver = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wObserver)
        }
    }
    
    public func checkTrust() {
        let isTrusted = AXIsProcessTrusted()
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let path = Bundle.main.bundlePath
        Logger.debug("Checking trust for bundle ID: \(bundleId) at path: \(path)")
        Logger.info("Accessibility trust check. isTrusted: \(isTrusted), previous state: \(permissionState)")
        
        // Only update if changed to avoid unnecessary view redraws, though @Published handles this usually.
        let newState: PermissionState = isTrusted ? .authorized : .rejected
        if permissionState != newState {
            Logger.info("Accessibility permission state changed: \(permissionState) -> \(newState)")
            permissionState = newState
        }
    }
    
    public func requestPermission() {
        Logger.info("Requesting accessibility permission")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        Logger.info("Prompted for accessibility. isTrusted after prompt: \(isTrusted)")
        checkTrust()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkTrust()
        }
    }
    
    public func openSystemSettings() {
        Logger.info("Opening System Settings for Accessibility")
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
