import SwiftUI
import KuralKit
import KuralDomain
import KuralModels

public struct MenuBarView: View {
    @StateObject private var accessibility = AccessibilityManager.shared
    private var modelManager = ModelManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Kural")
                    .font(.headline)
            }
            
            if accessibility.permissionState != .authorized {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("Accessibility Permission Required")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Kural needs accessibility permission to insert text into other apps.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Button("Enable Accessibility") {
                        accessibility.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Models")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                ModelStatusView(
                    name: "Transcription",
                    state: modelManager.transcriptionModelState,
                    action: {
                        Task {
                            try? await modelManager.downloadTranscriptionModel()
                        }
                    }
                )
                
                ModelStatusView(
                    name: "Polishing",
                    state: modelManager.polishingModelState,
                    action: {
                        Task {
                            try? await modelManager.downloadPolishingModel()
                        }
                    }
                )
            }
            
            Divider()
            
            Button("Settings...") {
                // TODO: Open settings
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit Kural") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            accessibility.checkTrust()
        }
    }
}

struct ModelStatusView: View {
    let name: String
    let state: ModelDownloadState
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                
                switch state {
                case .notDownloaded:
                    Text("Not Downloaded")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                case .downloading(let progress):
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                    Text("Downloading \(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                case .ready:
                    Text("Ready")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            if case .notDownloaded = state {
                Button(action: action) {
                    Image(systemName: "icloud.and.arrow.down")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            } else if case .ready = state {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}
