import SwiftUI
import KuralKit

public struct MenuBarView: View {
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
        .frame(width: 200)
    }
}
