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
                await self.updateTranscriptionState(.downloading(progress: 0))
                _ = try await self.hub.snapshot(from: self.transcriptionRepoId) { progress in
                    Task { @MainActor in
                        self.transcriptionModelState = .downloading(progress: progress.fractionCompleted)
                    }
                }
                await self.updateTranscriptionState(.ready)
            }
            
            group.addTask {
                await self.updatePolishingState(.downloading(progress: 0))
                _ = try await self.hub.snapshot(from: self.polishingRepoId) { progress in
                    Task { @MainActor in
                        self.polishingModelState = .downloading(progress: progress.fractionCompleted)
                    }
                }
                await self.updatePolishingState(.ready)
            }
            
            try await group.waitForAll()
        }
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
