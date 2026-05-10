import Foundation
import SwiftData
import KuralDomain

@ModelActor
public final actor SessionStore {
    public static func create() throws -> SessionStore {
        let schema = Schema([SessionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [config])
        return SessionStore(modelContainer: container)
    }

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
