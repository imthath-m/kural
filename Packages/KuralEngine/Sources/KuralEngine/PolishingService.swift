import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
import KuralDomain

public enum PolishingError: Error {
    case modelLoadingFailed
    case generationFailed
    case invalidInput
}

public actor PolishingService {
    private let modelName = "mlx-community/gemma-4-e2b-it-4bit"
    
    public init() {}
    
    public func polish(transcript: String) async throws -> String {
        Logger.info("Starting text polishing for transcript length: \(transcript.count)")
        guard !transcript.isEmpty else {
            Logger.error("Polishing failed: input transcript is empty")
            throw PolishingError.invalidInput
        }
        
        do {
            Logger.info("Loading polishing model: \(modelName)")
            let configuration = ModelConfiguration(id: modelName)
            let modelContainer = try await #huggingFaceLoadModelContainer(configuration: configuration)
            Logger.info("Successfully loaded polishing model")
            
            let systemPrompt = "You are a transcription polishing assistant. Remove filler words (um, uh, like, etc.), apply proper punctuation and capitalization, and format the text into paragraphs or lists where appropriate. DO NOT rephrase or add new information. Preserve the original tone."
            let prompt = "<start_of_turn>user\n\(systemPrompt)\n\nTranscript: \(transcript)<end_of_turn>\n<start_of_turn>model\n"
            
            Logger.debug("Preparing model input")
            let input = try await modelContainer.prepare(input: UserInput(prompt: prompt))
            let parameters = GenerateParameters()
            
            Logger.info("Generating polished text")
            let stream = try await modelContainer.generate(input: input, parameters: parameters)
            
            var fullOutput = ""
            for await event in stream {
                if case .chunk(let chunk) = event {
                    Logger.info("Chunk from LLM: \(chunk)")
                    fullOutput += chunk
                } else {
                    Logger.error("No chunk from LLM")
                }
            }
            
            Logger.info("Successfully completed text polishing \(fullOutput)")
            return fullOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            Logger.error("Polishing failed: \(error)")
            throw PolishingError.generationFailed
        }
    }
}
