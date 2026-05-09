import SwiftUI
import KuralKit

public struct MenuBarView: View {
    @StateObject private var accessibility = AccessibilityManager.shared
    
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
            
            if !accessibility.isTrusted {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("Accessibility Permission Required")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Kural needs accessibility permission to insert polished text into other apps.")
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
        .frame(width: 220)
        .onAppear {
            accessibility.checkTrust()
        }
    }
}
