import Foundation
import AVFoundation
import KuralDomain

public final class PermissionManager {
    public static let shared = PermissionManager()
    
    private init() {}
    
    public var microphonePermissionStatus: PermissionState {
        mapStatus(AVCaptureDevice.authorizationStatus(for: .audio))
    }
    
    public func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func mapStatus(_ status: AVAuthorizationStatus) -> PermissionState {
        switch status {
        case .notDetermined:
            return .notRequested
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .rejected
        @unknown default:
            return .rejected
        }
    }
}
