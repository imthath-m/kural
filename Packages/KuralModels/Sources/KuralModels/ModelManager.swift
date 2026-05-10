import Foundation
import Hub
import Observation

public enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
}

@Observable
public final class ModelManager {
    public static let shared = ModelManager()
    
    public private(set) var transcriptionModelState: ModelDownloadState = .notDownloaded
    public private(set) var polishingModelState: ModelDownloadState = .notDownloaded
    
    // Default model IDs based on common MLX models or placeholders
    private let transcriptionModelRepo = "mlx-community/whisper-tiny"
    private let polishingModelRepo = "mlx-community/mistral-7b-instruct-v0.2-4bit-mlx"
    
    private init() {
        checkLocalModels()
    }
    
    private func checkLocalModels() {
        // In a real app, check if the files exist in Hub.defaultStorage
        // For now, initializing as notDownloaded
    }
    
    public func downloadModels() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.downloadTranscriptionModel()
            }
            group.addTask {
                try await self.downloadPolishingModel()
            }
            try await group.waitForAll()
        }
    }
    
    public func downloadTranscriptionModel() async throws {
        await MainActor.run {
            transcriptionModelState = .downloading(progress: 0)
        }
        let hub = HubApi()
        _ = try await hub.snapshot(from: transcriptionModelRepo) { progress in
            Task { @MainActor in
                self.transcriptionModelState = .downloading(progress: progress.fractionCompleted)
            }
        }
        await MainActor.run {
            transcriptionModelState = .ready
        }
    }
    
    public func downloadPolishingModel() async throws {
        await MainActor.run {
            polishingModelState = .downloading(progress: 0)
        }
        let hub = HubApi()
        _ = try await hub.snapshot(from: polishingModelRepo) { progress in
            Task { @MainActor in
                self.polishingModelState = .downloading(progress: progress.fractionCompleted)
            }
        }
        await MainActor.run {
            polishingModelState = .ready
        }
    }
    
    /// Downloads a model from Hugging Face Hub. (Legacy)
    public func downloadModel(repoId: String) async throws -> URL {
        let hub = HubApi()
        let modelDir = try await hub.snapshot(from: repoId) { progress in
            print("Downloading \(repoId): \(Int(progress.fractionCompleted * 100))%")
        }
        return modelDir
    }
}
