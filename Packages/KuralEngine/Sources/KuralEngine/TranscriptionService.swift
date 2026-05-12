import Foundation
import MLX
import MLXAudioSTT
import KuralDomain

public enum TranscriptionError: Error {
    case modelLoadingFailed
    case transcriptionFailed
}

public actor TranscriptionService {
    private let modelName = "mlx-community/parakeet-tdt-0.6b-v2"
    private var model: ParakeetModel?

    public init() {}

    private func loadModel() async throws -> ParakeetModel {
        if let model = model { return model }
        Logger.info("Loading transcription model: \(modelName)")
        do {
            let loadedModel = try await ParakeetModel.fromPretrained(modelName)
            self.model = loadedModel
            Logger.info("Successfully loaded transcription model")
            return loadedModel
        } catch {
            Logger.error("Failed to load transcription model: \(error)")
            throw TranscriptionError.modelLoadingFailed
        }
    }

    /// Processes an audio stream and yields real-time Ghost Text updates.
    public func startStreaming(audio: AsyncStream<[Float]>) -> AsyncStream<String> {
        Logger.info("Starting audio transcription stream")
        return AsyncStream { continuation in
            Task {
                do {
                    let model = try await loadModel()
                    var accumulatedText = ""
                    
                    for await samples in audio {
                        Logger.debug("Received audio samples chunk: \(samples.count) samples")
                        let mlxArray = MLXArray(samples)
                        let result = model.generate(audio: mlxArray)
                        if !result.text.isEmpty {
                            accumulatedText += (accumulatedText.isEmpty ? "" : " ") + result.text
                            Logger.debug("Generated text chunk: '\(result.text)'")
                            continuation.yield(accumulatedText)
                        }
                    }
                    Logger.info("Audio stream completed, finishing transcription")
                    continuation.finish()
                } catch {
                    Logger.error("Error during transcription streaming: \(error)")
                    continuation.finish()
                }
            }
        }
    }
}
