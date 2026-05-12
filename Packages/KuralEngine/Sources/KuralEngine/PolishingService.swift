import Foundation
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers

public enum PolishingError: Error {
    case modelLoadingFailed
    case generationFailed
    case invalidInput
}

public actor PolishingService {
    private let modelName = "mlx-community/gemma-4-e2b-it-4bit"
    
    public init() {}
    
    public func polish(transcript: String) async throws -> String {
        guard !transcript.isEmpty else {
            throw PolishingError.invalidInput
        }
        
        do {
            let configuration = ModelConfiguration(id: modelName)
            let modelContainer = try await #huggingFaceLoadModelContainer(configuration: configuration)
            
            let systemPrompt = "You are a transcription polishing assistant. Remove filler words (um, uh, like, etc.), apply proper punctuation and capitalization, and format the text into paragraphs or lists where appropriate. DO NOT rephrase or add new information. Preserve the original tone."
            let prompt = "<start_of_turn>user\n\(systemPrompt)\n\nTranscript: \(transcript)<end_of_turn>\n<start_of_turn>model\n"
            
            let input = try await modelContainer.prepare(input: UserInput(prompt: prompt))
            let parameters = GenerateParameters()
            
            let stream = try await modelContainer.generate(input: input, parameters: parameters)
            
            var fullOutput = ""
            for await event in stream {
                if case .chunk(let chunk) = event {
                    fullOutput += chunk
                }
            }
            
            return fullOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Polishing failed: \(error)")
            throw PolishingError.generationFailed
        }
    }
}
