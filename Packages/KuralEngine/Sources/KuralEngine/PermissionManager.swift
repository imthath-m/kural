import Foundation
import AVFoundation

public final class PermissionManager {
    public static let shared = PermissionManager()
    
    private init() {}
    
    public var microphonePermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    public func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
