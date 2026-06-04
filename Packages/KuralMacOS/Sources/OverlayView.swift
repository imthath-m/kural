import SwiftUI

struct OverlayView: View {
    let ghostText: String
    let isPolishing: Bool
    let isListening: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                }
                .padding(.bottom, ghostText.isEmpty ? 0 : 8)
            }

            if isListening && ghostText.isEmpty && errorMessage == nil {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse, options: .repeating)
                    Text("Listening…")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else if !ghostText.isEmpty {
                Text(ghostText)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if isPolishing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Polishing your text...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .frame(maxWidth: 600)
    }
}

#Preview {
    VStack(spacing: 16) {
        OverlayView(ghostText: "", isPolishing: false, isListening: true, errorMessage: nil)
        OverlayView(ghostText: "Testing ghost text transcription...", isPolishing: false, isListening: true, errorMessage: nil)
        OverlayView(ghostText: "Testing ghost text transcription...", isPolishing: true, isListening: false, errorMessage: nil)
        OverlayView(ghostText: "", isPolishing: false, isListening: false, errorMessage: "Microphone is unavailable. Please check your system settings.")
    }
    .padding()
}
