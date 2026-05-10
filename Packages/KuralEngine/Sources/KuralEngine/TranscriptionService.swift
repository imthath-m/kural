import Foundation
import MLX
import MLXAudioSTT

public enum TranscriptionError: Error {
    case modelLoadingFailed
    case transcriptionFailed
}

public actor TranscriptionService {
    private let modelName = "mlx-community/parakeet-tdt-0.6b-v3-8bit"
    private var model: ParakeetModel?

    public init() {}

    private func loadModel() async throws -> ParakeetModel {
        if let model = model { return model }
        do {
            let loadedModel = try await ParakeetModel.fromPretrained(modelName)
            self.model = loadedModel
            return loadedModel
        } catch {
            throw TranscriptionError.modelLoadingFailed
        }
    }

    /// Processes an audio stream and yields real-time Ghost Text updates.
    public func startStreaming(audio: AsyncStream<[Float]>) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                do {
                    let model = try await loadModel()
                    var accumulatedText = ""
                    
                    for await samples in audio {
                        let mlxArray = MLXArray(samples)
                        let result = try await model.generate(audio: mlxArray)
                        if !result.text.isEmpty {
                            accumulatedText += (accumulatedText.isEmpty ? "" : " ") + result.text
                            continuation.yield(accumulatedText)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}
