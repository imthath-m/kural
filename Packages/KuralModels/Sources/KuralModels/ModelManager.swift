import Foundation
import Hub

public final class ModelManager {
    public static let shared = ModelManager()
    
    private init() {}
    
    /// Downloads a model from Hugging Face Hub.
    public func downloadModel(repoId: String) async throws -> URL {
        let hub = HubApi()
        let modelDir = try await hub.snapshot(from: repoId) { progress in
            print("Downloading \(repoId): \(Int(progress.fractionCompleted * 100))%")
        }
        return modelDir
    }
}
