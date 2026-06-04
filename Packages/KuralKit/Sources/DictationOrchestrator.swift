import Foundation
import Combine
import KuralEngine
import KuralDomain
import KuralModels
import KuralStorage

public enum EngineState {
    case idle, recording, polishing, inserting
}

public protocol DictationOrchestratorProtocol {
    var state: AnyPublisher<EngineState, Never> { get }
    var ghostText: AnyPublisher<String, Never> { get }
    var error: AnyPublisher<String?, Never> { get }
    
    var currentState: EngineState { get }
    var currentError: String? { get }
    
    func startDictation() async throws
    func stopDictation() async throws
    func cancelDictation() async
    func clearError()
}

public final class DictationOrchestrator: DictationOrchestratorProtocol {
    public static let shared = DictationOrchestrator()
    
    private let audioStreamer = AudioStreamer()
    private let transcriptionService = TranscriptionService()
    private let polishingService = PolishingService()
    private let modelManager = ModelManager.shared
    
    // Lazy initialized when needed
    private var sessionStore: SessionStore?
    private var insertionService: TextInsertionProtocol?
    
    private let stateSubject = CurrentValueSubject<EngineState, Never>(.idle)
    private let ghostTextSubject = PassthroughSubject<String, Never>()
    private let errorSubject = CurrentValueSubject<String?, Never>(nil)
    
    private var transcriptionTask: Task<Void, Never>?
    private var postProcessingTask: Task<Void, Error>?
    private var currentGhostText = ""
    private var startTime: Date?
    
    public var state: AnyPublisher<EngineState, Never> { stateSubject.eraseToAnyPublisher() }
    public var ghostText: AnyPublisher<String, Never> { ghostTextSubject.eraseToAnyPublisher() }
    public var error: AnyPublisher<String?, Never> { errorSubject.eraseToAnyPublisher() }
    
    public var currentState: EngineState { stateSubject.value }
    public var currentError: String? { errorSubject.value }
    
    private init() {}
    
    public func setup(sessionStore: SessionStore, insertionService: TextInsertionProtocol) {
        self.sessionStore = sessionStore
        self.insertionService = insertionService
    }
    
    public func startDictation() async throws {
        guard stateSubject.value == .idle else { return }
        
        // Set state immediately before any suspension point to prevent
        // concurrent calls from racing past the .idle guard above.
        stateSubject.send(.recording)
        errorSubject.send(nil)
        currentGhostText = ""
        startTime = Date()
        
        do {
            let audioStream = try audioStreamer.stream()
            let transcriptionStream = await transcriptionService.startStreaming(audio: audioStream)
            
            transcriptionTask = Task {
                for await text in transcriptionStream {
                    currentGhostText = text
                    ghostTextSubject.send(text)
                }
            }
        } catch {
            let userMessage = mapErrorToUserMessage(error)
            errorSubject.send(userMessage)
            stateSubject.send(.idle)
            throw error
        }
    }
    
    public func stopDictation() async throws {
        guard stateSubject.value == .recording else { return }
        
        // If no speech was captured, cancel silently instead of
        // trying to polish an empty transcript.
        if currentGhostText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await cancelDictation()
            return
        }
        
        audioStreamer.stop()
        transcriptionTask?.cancel()
        transcriptionTask = nil
        
        stateSubject.send(.polishing)
        
        let transcript = currentGhostText
        let startTime = self.startTime
        
        postProcessingTask = Task {
            do {
                let polishedText = try await polishingService.polish(transcript: transcript)
                try Task.checkCancellation()
                
                stateSubject.send(.inserting)
                try await insertionService?.insertText(polishedText)
                try Task.checkCancellation()
                
                // Save to storage
                if let store = sessionStore {
                    let duration = Date().timeIntervalSince(startTime ?? Date())
                    await store.saveSession(
                        ghostText: transcript,
                        polishedText: polishedText,
                        duration: duration
                    )
                }
                
                stateSubject.send(.idle)
            } catch is CancellationError {
                // Return gracefully on cancellation
            } catch {
                let userMessage = mapErrorToUserMessage(error)
            errorSubject.send(userMessage)
            stateSubject.send(.idle)
                throw error
            }
        }
        
        do {
            try await postProcessingTask?.value
        } catch is CancellationError {
            // Handled in task
        } catch {
            throw error
        }
        postProcessingTask = nil
    }
    
    public func cancelDictation() async {
        audioStreamer.stop()
        transcriptionTask?.cancel()
        transcriptionTask = nil
        postProcessingTask?.cancel()
        postProcessingTask = nil
        errorSubject.send(nil)
        stateSubject.send(.idle)
    }

    public func clearError() {
        errorSubject.send(nil)
    }

    private func mapErrorToUserMessage(_ error: Error) -> String {
        if let audioError = error as? AudioEngineError {
            switch audioError {
            case .inputNodeUnavailable:
                return "Microphone is unavailable. Please check your system settings."
            case .engineFailedToStart(let reason):
                return "Could not start audio engine: \(reason)"
            case .converterFailedToInitialize, .resamplingFailed:
                return "Audio processing failed. Please try again."
            }
        }

        if let transError = error as? TranscriptionError {
            switch transError {
            case .modelLoadingFailed:
                return "Failed to load transcription model. Check your connection."
            case .transcriptionFailed:
                return "Transcription failed. Please try again."
            }
        }

        if let polishError = error as? PolishingError {
            switch polishError {
            case .modelLoadingFailed:
                return "Failed to load polishing model. Check your connection."
            case .generationFailed:
                return "Polishing failed. You can try again or use the raw text."
            case .invalidInput:
                return "No text to polish."
            }
        }

        return "An unexpected error occurred: \(error.localizedDescription)"
    }
}
