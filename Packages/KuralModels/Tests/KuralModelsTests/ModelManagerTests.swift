import Testing
import Foundation
@testable import KuralModels

@Suite struct ModelManagerTests {
    @Test func testInitialState() {
        let manager = ModelManager.shared
        #expect(manager.transcriptionModelState == .notDownloaded || manager.transcriptionModelState == .ready)
        #expect(manager.polishingModelState == .notDownloaded || manager.polishingModelState == .ready)
    }
    
    @Test func testObservability() async throws {
        let manager = ModelManager.shared
        #expect(manager.transcriptionModelState == .notDownloaded || manager.transcriptionModelState == .ready)
    }
}
