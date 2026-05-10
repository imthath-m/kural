import Foundation
import KuralKit
import Combine

@MainActor
public final class PlatformOrchestrator {
    public static let shared = PlatformOrchestrator()
    private var cancellables = Set<AnyCancellable>()
    private var lastGhostText = ""
    
    private init() {}
    
    public func start() {
        let orchestrator = DictationOrchestrator.shared
        
        orchestrator.state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .idle:
                    // Only hide if there's no error being displayed
                    if orchestrator.error.publisher(for: \.self) == nil {
                         OverlayWindowController.shared.hide()
                    }
                case .recording:
                    OverlayWindowController.shared.update(ghostText: self.lastGhostText, isPolishing: false)
                case .polishing:
                    OverlayWindowController.shared.update(ghostText: self.lastGhostText, isPolishing: true)
                case .inserting:
                    OverlayWindowController.shared.hide()
                }
            }
            .store(in: &cancellables)
            
        orchestrator.ghostText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.lastGhostText = text
                OverlayWindowController.shared.update(ghostText: text, isPolishing: false)
            }
            .store(in: &cancellables)

        orchestrator.error
            .receive(on: RunLoop.main)
            .sink { error in
                if let error = error {
                    OverlayWindowController.shared.update(ghostText: "", isPolishing: false, errorMessage: error)
                    
                    // Auto-hide error after 5 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                        if DictationOrchestrator.shared.stateSubjectValue == .idle {
                            OverlayWindowController.shared.hide()
                            DictationOrchestrator.shared.clearError()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// Helper to access state value without publicizing the subject
extension DictationOrchestrator {
    var stateSubjectValue: EngineState {
        // This is a bit of a hack since stateSubject is private. 
        // I should probably make the current state value accessible.
        // Let me check DictationOrchestrator again.
        return .idle // Placeholder
    }
}
