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
    
    func startDictation() async throws
    func stopDictation() async throws
    func cancelDictation() async
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
    
    private var transcriptionTask: Task<Void, Never>?
    private var postProcessingTask: Task<Void, Error>?
    private var currentGhostText = ""
    private var startTime: Date?
    
    public var state: AnyPublisher<EngineState, Never> { stateSubject.eraseToAnyPublisher() }
    public var ghostText: AnyPublisher<String, Never> { ghostTextSubject.eraseToAnyPublisher() }
    
    private init() {}
    
    public func setup(sessionStore: SessionStore, insertionService: TextInsertionProtocol) {
        self.sessionStore = sessionStore
        self.insertionService = insertionService
    }
    
    public func startDictation() async throws {
        guard stateSubject.value == .idle else { return }
        
        stateSubject.send(.recording)
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
            stateSubject.send(.idle)
            throw error
        }
    }
    
    public func stopDictation() async throws {
        guard stateSubject.value == .recording else { return }
        
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
        stateSubject.send(.idle)
    }
}
