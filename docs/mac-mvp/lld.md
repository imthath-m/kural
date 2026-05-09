# Kural Low-Level Design (LLD)

This document outlines the low-level design for the Kural on-device dictation application based on the PRD and recent architectural decisions. It details the Swift packages layout, dependencies, package APIs, files, and their specific responsibilities.

## 1. Swift Packages Layout

The project uses an XcodeGen configuration generating the `Kural-macOS` and `Kural-iOS` app targets. To ensure high modularity, code is broken down into independent Swift Packages. The core business logic is housed in a set of foundational packages, orchestrated by `KuralKit`, and platform-specific features are housed in platform packages like `KuralMacOS`.

```text
Packages/
├── KuralDomain/             # Shared entities and protocols
├── KuralEngine/             # AudioStreamer, Transcription, Polishing
├── KuralStorage/            # SessionStore (SwiftData)
├── KuralModels/             # ModelManager (MLX downloading and registry)
├── KuralMacOS/              # macOS specific features (Hotkeys, Overlay, Insertion, MenuBar)
└── KuralKit/                # Orchestrator package depending on the foundational packages
App/
└── Sources/
    └── macOS/
        └── AppEntry.swift   # The only file in the App target; entry point.
```

**Dependency Rules:**
- **KuralDomain**: Contains purely abstract types (like `SessionRecord` protocols or structs) shared across both platforms. 
- `KuralEngine`, `KuralStorage`, and `KuralModels` depend **downward on KuralDomain** to use its shared entities, but they have **no lateral dependencies** among themselves (e.g., Storage does not depend on Engine).
- `KuralKit` depends on all four foundational packages to orchestrate the dictation lifecycle.
- `KuralMacOS` depends on `KuralKit` and implements macOS-specific UI and insertion logic.
- Each package defines its own distinct errors conforming to the Swift `Error` protocol. There is no centralized error enum.

## 2. Dependencies

### Foundational Package Dependencies
- **mlx-audio-swift**: For `Parakeet-MLX` (Transcription) inside `KuralEngine`.
- **mlx-swift-lm**: For `Gemma-4-E2B` (Polishing) inside `KuralEngine`.
- **huggingface/swift-transformers (Hub module)**: For reliable model downloading and caching in `KuralModels`.
- **AudioToolbox / AVFoundation**: Native Apple frameworks for microphone capture (`AVAudioEngine`) in `KuralEngine`.
- **SwiftData**: Native Apple framework for local persistence in `KuralStorage`.

### macOS Package Dependencies (`KuralMacOS`)
- **sindresorhus/KeyboardShortcuts**: A popular, reliable library for registering system-wide global hotkeys.
- **ApplicationServices (CGEvent) / ApplicationAccessibility (AX)**: Native frameworks for text insertion into third-party apps.

---

## 3. Package APIs & Responsibilities

### Package: `KuralKit`
The central orchestrator of the `Dictation Session`. It bridges the independent foundational packages.

- **Exposed API:**
  ```swift
  public enum EngineState {
      case idle, recording, polishing, inserting
  }
  
  public protocol DictationOrchestratorProtocol {
      var state: AnyPublisher<EngineState, Never> { get }
      var ghostText: AnyPublisher<String, Never> { get }
      
      func startDictation() async throws
      func stopDictation() async throws -> String // Returns Polished Text
      func cancelDictation() async
  }
  ```

### Package: `KuralModels`
Handles the downloading and availability of the MLX models from Hugging Face.

- **Exposed API:**
  ```swift
  public enum ModelDownloadState {
      case notDownloaded, downloading(progress: Double), ready
  }
  
  // Utilizes the Observation framework (@Observable) so SwiftUI views 
  // can directly subscribe to state changes.
  @Observable
  public class ModelManager {
      public var transcriptionModelState: ModelDownloadState { get }
      public var polishingModelState: ModelDownloadState { get }
      
      public func downloadModels() async throws
  }
  ```

### Package: `KuralStorage`
Persists Dictation Sessions silently using SwiftData.

- **Exposed API:**
  ```swift
  public protocol SessionStoreProtocol {
      func saveSession(ghostText: String, polishedText: String, timestamp: Date, duration: TimeInterval) async throws
  }
  ```

### Package: `KuralMacOS`
Executes macOS-specific flows including multi-layer fallback insertion, global hotkeys, and the floating overlay.

- **Exposed API:**
  ```swift
  public protocol TextInsertionServiceProtocol {
      func insertText(_ text: String) async throws
  }
  ```

---

## 4. File-by-File Breakdown

### Foundational Packages

#### `KuralDomain`
- **`SessionRecord.swift`**: Defines the shared models or protocols for a Dictation Session (ghostText, polishedText, timestamp, duration). This guarantees cross-platform consistency for iOS and macOS.

#### `KuralEngine`
- **`AudioStreamer.swift`**: Wraps `AVAudioEngine`. Captures microphone input, resamples it to 16kHz, and yields an `AsyncStream<[Float]>`. Defines `AudioEngineError`.
- **`TranscriptionService.swift`**: Interacts with `mlx-audio-swift`. Loads the `parakeet-tdt-0.6b-v3` model. Exposes `func startStreaming(audio: AsyncStream<[Float]>) -> AsyncStream<String>` which yields Ghost Text. Defines `TranscriptionError`.
- **`PolishingService.swift`**: Interacts with `mlx-swift-lm`. Loads the base `gemma-4-e2b-it-4bit` model (no assistant). Exposes `func polish(transcript: String) async throws -> String` using the predefined prompt. Defines `PolishingError`.

#### `KuralModels`
- **`ModelManager.swift`**: Implements `ModelManager` as an `@Observable` class. Uses the `huggingface/swift-transformers` Hub API to download MLX weights. Tracks download progress. Defines `ModelManagerError`.

#### `KuralStorage`
- **`SessionStore.swift`**: Sets up the `ModelContainer` and `ModelContext`. Exposes a simple async method to write completed sessions to disk, including a timestamp. Defines `StorageError`.

#### `KuralKit`
- **`DictationOrchestrator.swift`**: Implements `DictationOrchestratorProtocol`. Coordinates `AudioStreamer`, `TranscriptionService`, `PolishingService`, `ModelManager`, and `SessionStore`. Maintains current state and publishes updates.

### Platform Package

#### `KuralMacOS`
- **`HotkeyManager.swift`**: Uses `KeyboardShortcuts` to register the global shortcut (hold to talk, double-tap to talk).
- **`TextInsertionService.swift`**: Implements the multi-layer fallback logic. Since there are no robust standalone Swift packages for this specific fallback chain, this service will be heavily modeled after the open-source `FluidVoice` macOS app's insertion implementation, which relies primarily on `CGEvent` and `NSPasteboard` backup/restore.
- **`ClipboardManager.swift`**: Helper for `TextInsertionService`. Captures `NSPasteboard` contents, injects new text, and restores original contents.
- **`MenuBarView.swift`**: SwiftUI view for the `NSMenu`. Shows current status and model download progress.
- **`OverlayWindowController.swift`**: An `NSWindowController` configuring an always-on-top, translucent, non-activating floating window.
- **`OverlayView.swift`**: SwiftUI view hosted in the overlay window. Displays the real-time dictation text and "Polishing your text..." indicator.

### App Target
- **`App/Sources/macOS/AppEntry.swift`**: The `@main` entry point. Bootstraps `KuralKit` orchestrator, initializes `KuralMacOS` features (menu bar, hotkeys), and sets up the app lifecycle. Contains no core logic.

## Verification Plan

### Automated Tests
- **`KuralKitTests.swift`**: Mock `AudioStreamer` and Model Services. Validate orchestrator state machine transitions.
- **`PolishingPromptTests.swift`**: Provide raw transcripts with fillers. Verify the prompt returns properly formatted text without fillers using `mlx-swift-lm`.
- **`SessionStoreTests.swift`**: Verify SwiftData save and retrieval logic works seamlessly.

### Manual Verification
- Run macOS App, press the global hotkey, and dictate into multiple applications (Safari, Xcode, Notes).
- Validate the overlay window positions correctly and doesn't steal focus.
- Verify existing clipboard content is not destroyed after dictation text insertion.
