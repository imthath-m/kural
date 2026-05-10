import Foundation
import SwiftData
import KuralDomain

public final class SessionStore {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    public func saveSession(ghostText: String, polishedText: String, duration: TimeInterval) {
        let session = SessionRecord(
            ghostText: ghostText,
            polishedText: polishedText,
            duration: duration
        )
        modelContext.insert(session)
    }
}
