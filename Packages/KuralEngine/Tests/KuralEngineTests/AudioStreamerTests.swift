import XCTest
import AVFoundation
@testable import KuralEngine

final class AudioStreamerTests: XCTestCase {
    func testInitialization() {
        let streamer = AudioStreamer()
        XCTAssertNotNil(streamer)
    }
    
    func testStreamCreation() {
        let streamer = AudioStreamer()
        do {
            // This might fail in CI if there's no audio input device,
            // but we can at least check if it throws for the right reasons.
            _ = try streamer.stream()
        } catch AudioEngineError.inputNodeUnavailable {
            // This is expected if no microphone is available
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
