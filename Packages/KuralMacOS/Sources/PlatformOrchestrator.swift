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
                    OverlayWindowController.shared.hide()
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
    }
}
