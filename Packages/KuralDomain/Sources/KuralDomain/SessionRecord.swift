import Foundation
import SwiftData

@Model
public final class SessionRecord {
    public var id: UUID
    public var ghostText: String
    public var polishedText: String
    public var timestamp: Date
    public var duration: TimeInterval
    
    public init(
        id: UUID = UUID(),
        ghostText: String,
        polishedText: String,
        timestamp: Date = Date(),
        duration: TimeInterval
    ) {
        self.id = id
        self.ghostText = ghostText
        self.polishedText = polishedText
        self.timestamp = timestamp
        self.duration = duration
    }
}
