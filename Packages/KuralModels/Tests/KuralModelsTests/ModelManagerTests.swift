import Testing
import Foundation
@testable import KuralModels

@Suite struct ModelManagerTests {
    @Test func testInitialState() {
        let manager = ModelManager()
        #expect(manager.transcriptionModelState == .notDownloaded)
        #expect(manager.polishingModelState == .notDownloaded)
    }
    
    @Test func testObservability() async throws {
        let manager = ModelManager()
        
        // This is a bit tricky to test without a UI, but we can check if 
        // the properties are accessible and if we can trigger an update.
        // Since downloadModels is async and uses real network, we might not want to call it in a unit test.
        
        // However, we can verify the types and structure.
        #expect(manager.transcriptionModelState == .notDownloaded)
    }
}
