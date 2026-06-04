import Foundation
import AVFoundation

public enum AudioEngineError: Error {
    case engineFailedToStart(String)
    case inputNodeUnavailable
    case converterFailedToInitialize
    case resamplingFailed
}

public final class AudioStreamer {
    private let engine = AVAudioEngine()
    private let targetSampleRate: Double = 16000
    private var isStreaming = false
    
    public init() {}
    
    /// Starts capturing audio from the microphone and yields resampled [Float] buffers.
    /// - Returns: An AsyncStream of Float arrays (PCM samples at 16kHz).
    /// - Throws: AudioEngineError if the engine or converter fails to initialize.
    public func stream() throws -> AsyncStream<[Float]> {
        guard !isStreaming else {
            throw AudioEngineError.engineFailedToStart("Audio stream is already active")
        }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0 else {
            throw AudioEngineError.inputNodeUnavailable
        }

        // Parakeet expects mono 16kHz
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioEngineError.converterFailedToInitialize
        }
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AudioEngineError.converterFailedToInitialize
        }
        
        // Remove any stale tap before installing a new one to prevent
        // the `nullptr == Tap()` assertion crash in AVAudioEngine.
        inputNode.removeTap(onBus: 0)
        isStreaming = true
        
        return AsyncStream { continuation in
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, time in
                let inputCallback: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                let ratio = outputFormat.sampleRate / inputFormat.sampleRate
                let targetCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
                
                guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: targetCapacity) else {
                    return
                }
                
                var error: NSError?
                let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputCallback)
                
                if status != .error, let channelData = outputBuffer.floatChannelData?[0] {
                    let data = Array(UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
                    if !data.isEmpty {
                        continuation.yield(data)
                    }
                }
            }
            
            do {
                engine.prepare()
                try engine.start()
            } catch {
                self.isStreaming = false
                continuation.finish()
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.stop()
            }
        }
    }
    
    public func stop() {
        guard isStreaming else { return }
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        isStreaming = false
    }
}
