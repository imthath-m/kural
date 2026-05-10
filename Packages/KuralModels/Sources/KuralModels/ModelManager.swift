import Foundation
import Observation
import Hub

public enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
}

@Observable
public final class ModelManager {
    public private(set) var transcriptionModelState: ModelDownloadState = .notDownloaded
    public private(set) var polishingModelState: ModelDownloadState = .notDownloaded
    
    private let transcriptionRepoId = "mlx-community/parakeet-tdt-0.6b-v3-8bit"
    private let polishingRepoId = "mlx-community/gemma-2-2b-it-4bit"
    
    private let hub = HubApi()
    
    public init() {}
    
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
        await updateTranscriptionState(.downloading(progress: 0))
        _ = try await hub.snapshot(from: transcriptionRepoId) { progress in
            Task { @MainActor in
                self.transcriptionModelState = .downloading(progress: progress.fractionCompleted)
            }
        }
        await updateTranscriptionState(.ready)
    }
    
    public func downloadPolishingModel() async throws {
        await updatePolishingState(.downloading(progress: 0))
        _ = try await hub.snapshot(from: polishingRepoId) { progress in
            Task { @MainActor in
                self.polishingModelState = .downloading(progress: progress.fractionCompleted)
            }
        }
        await updatePolishingState(.ready)
    }
    
    @MainActor
    private func updateTranscriptionState(_ state: ModelDownloadState) {
        self.transcriptionModelState = state
    }
    
    @MainActor
    private func updatePolishingState(_ state: ModelDownloadState) {
        self.polishingModelState = state
    }
}
