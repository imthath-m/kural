import SwiftUI
import KeyboardShortcuts
import KuralEngine
import KuralDomain

public struct SettingsView: View {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @State private var microphoneStatus: PermissionState = PermissionManager.shared.microphonePermissionStatus
    
    public init() {}
    
    public var body: some View {
        Form {
            Section("General") {
                Picker("Hotkey Mode", selection: $hotkeyManager.mode) {
                    Text("Key Combo").tag(HotkeyMode.combo)
                    Text("Single Modifier").tag(HotkeyMode.singleModifier)
                }
                .pickerStyle(.segmented)
                
                if hotkeyManager.mode == .combo {
                    HStack {
                        Text("Push-to-Talk Hotkey")
                        Spacer()
                        KeyboardShortcuts.Recorder(for: .pushToTalk)
                    }
                } else {
                    Picker("Modifier Key", selection: $hotkeyManager.singleModifier) {
                        ForEach(SingleModifier.allCases) { modifier in
                            Text(modifier.rawValue).tag(modifier)
                        }
                    }
                }
            }
            
            Section("Permissions") {
                PermissionRow(
                    title: "Microphone",
                    description: "Required for recording audio.",
                    state: microphoneStatus,
                    actionLabel: "Grant Access",
                    action: {
                        Task {
                            _ = await PermissionManager.shared.requestMicrophonePermission()
                            microphoneStatus = PermissionManager.shared.microphonePermissionStatus
                        }
                    }
                )
                
                Divider()
                
                PermissionRow(
                    title: "Accessibility",
                    description: "Required to insert text into other applications.",
                    state: accessibilityManager.permissionState,
                    actionLabel: "Open System Settings",
                    action: {
                        accessibilityManager.openSystemSettings()
                    }
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 350)
        .navigationTitle("Kural Settings")
        .onAppear {
            microphoneStatus = PermissionManager.shared.microphonePermissionStatus
            accessibilityManager.checkTrust()
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let state: PermissionState
    let actionLabel: String
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text(stateLabel)
                        .font(.subheadline)
                        .foregroundStyle(stateColor)
                    
                    Image(systemName: stateImage)
                        .foregroundStyle(stateColor)
                }
                
                if state != .authorized {
                    Button(actionLabel) {
                        action()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var stateLabel: String {
        switch state {
        case .authorized: return "Authorized"
        case .rejected: return "Rejected"
        case .notRequested: return "Not Requested"
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .authorized: return .green
        case .rejected: return .red
        case .notRequested: return .orange
        }
    }
    
    private var stateImage: String {
        switch state {
        case .authorized: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .notRequested: return "questionmark.circle.fill"
        }
    }
}
