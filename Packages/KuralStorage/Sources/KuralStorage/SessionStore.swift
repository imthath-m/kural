import Foundation
import SwiftData
import KuralDomain

@ModelActor
public final actor SessionStore {
    public func saveSession(ghostText: String, polishedText: String, duration: TimeInterval) {
        let session = SessionRecord(
            ghostText: ghostText,
            polishedText: polishedText,
            duration: duration
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}
