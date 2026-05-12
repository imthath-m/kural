import Foundation
import Observation
import Hub
import KuralDomain

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
    
    private let transcriptionRepoId = "mlx-community/parakeet-tdt-0.6b-v2"
    private let polishingRepoId = "mlx-community/gemma-2-2b-it-4bit"
    
    private let hub = HubApi()
    
    private init() {
        Logger.info("Initializing ModelManager")
        checkLocalModels()
    }

    private func checkLocalModels() {
        Logger.info("Checking for local models")
        let transcriptionRepo = Hub.Repo(id: transcriptionRepoId)
        let polishingRepo = Hub.Repo(id: polishingRepoId)
        
        let transcriptionURL = hub.localRepoLocation(transcriptionRepo)
        let polishingURL = hub.localRepoLocation(polishingRepo)
        
        if FileManager.default.fileExists(atPath: transcriptionURL.path) {
            Logger.info("Transcription model found locally at \(transcriptionURL.path)")
            transcriptionModelState = .ready
        } else {
            Logger.info("Transcription model not found locally")
        }
        
        if FileManager.default.fileExists(atPath: polishingURL.path) {
            Logger.info("Polishing model found locally at \(polishingURL.path)")
            polishingModelState = .ready
        } else {
            Logger.info("Polishing model not found locally")
        }
    }
    
    public func downloadModels() async throws {
        Logger.info("Starting download of all models")
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.downloadTranscriptionModel()
            }
            group.addTask {
                try await self.downloadPolishingModel()
            }
            try await group.waitForAll()
        }
        Logger.info("All model downloads completed")
    }
    
    public func downloadTranscriptionModel() async throws {
        Logger.info("Starting download for transcription model: \(transcriptionRepoId)")
        await updateTranscriptionState(.downloading(progress: 0))
        do {
            _ = try await hub.snapshot(from: transcriptionRepoId) { progress in
                Logger.debug("Transcription download progress: \(progress.fractionCompleted)")
                Task { @MainActor in
                    self.transcriptionModelState = .downloading(progress: progress.fractionCompleted)
                }
            }
            Logger.info("Download completed for transcription model")
            await updateTranscriptionState(.ready)
        } catch {
            Logger.error("Failed to download transcription model: \(error)")
            throw error
        }
    }
    
    public func downloadPolishingModel() async throws {
        Logger.info("Starting download for polishing model: \(polishingRepoId)")
        await updatePolishingState(.downloading(progress: 0))
        do {
            _ = try await hub.snapshot(from: polishingRepoId) { progress in
                Logger.debug("Polishing download progress: \(progress.fractionCompleted)")
                Task { @MainActor in
                    self.polishingModelState = .downloading(progress: progress.fractionCompleted)
                }
            }
            Logger.info("Download completed for polishing model")
            await updatePolishingState(.ready)
        } catch {
            Logger.error("Failed to download polishing model: \(error)")
            throw error
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
