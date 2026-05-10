import Foundation
import MLXSwiftLM

public enum PolishingError: Error {
    case modelLoadingFailed
    case generationFailed
    case invalidInput
}

public actor PolishingService {
    private let modelName = "mlx-community/gemma-4-e2b-it-4bit"
    private let systemPrompt = """
    You are a transcription polishing assistant. Remove filler words (um, uh, like, etc.), apply proper punctuation and capitalization, and format the text into paragraphs or lists where appropriate. DO NOT rephrase or add new information. Preserve the original tone.
    """

    public init() {}

    public func polish(transcript: String) async throws -> String {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PolishingError.invalidInput
        }

        do {
            // Load the model
            let modelContainer = try await LLMModelFactory.shared.loadContainer(hub: HubApi(), modelName: modelName)
            
            // Format the prompt
            let prompt = """
            <start_of_turn>user
            \(systemPrompt)

            Polish the following transcript:
            \(transcript)<end_of_turn>
            <start_of_turn>model
            """
            
            // Generate the response
            let result = try await modelContainer.generate(prompt: prompt)
            
            return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("Polishing failed: \(error)")
            throw PolishingError.generationFailed
        }
    }
}
