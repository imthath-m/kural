# Kural macOS Beta — PRD

## Problem Statement

Writers, developers, and knowledge workers who rely on dictation today face a frustrating tradeoff: cloud-based tools (like Whisper-powered services) offer good accuracy but incur network latency and privacy concerns, while Apple's built-in dictation lacks the intelligence to produce well-formatted, publish-ready text. The result is that dictated text always requires manual cleanup — filler word removal, punctuation, paragraph structuring — which defeats the speed advantage of speaking over typing.

## Solution

Kural is a macOS menu bar utility that lets users press a global hotkey, speak naturally, and see polished, formatted text appear instantly in any app's text field. It runs an entirely on-device AI pipeline using Apple Silicon's unified memory:

1. **Parakeet-MLX (TDT)** streams real-time Ghost Text to a floating overlay as the user speaks.
2. When the user releases the hotkey, **Gemma 4 E2B** performs a Polishing pass on the full transcript — removing filler words, adding punctuation, capitalization, paragraph breaks, and bullet lists while preserving the speaker's tone and intent.
3. The Polished Text is inserted into the active app's text field using a multi-layer fallback chain (CGEvent → Accessibility API → Clipboard-Paste → Menu Paste → Character-by-character).

No data leaves the device. No cloud API keys required.

## User Stories

1. As a writer, I want to press and hold - or double tap - a global hotkey to start dictation from any app, so that I don't have to switch windows or click a button.
2. As a writer, I want to see my words appear in real-time, so that I know the app is listening and can catch misheard words early.
3. As a writer, I want the real time text in a floating overlay which non-intrusive and positioned in a consistent screen location, so that it doesn't block my work.
4. As a writer, I want to release the hotkey - or single tap - to stop dictation, so that the trigger is intuitive and mirrors a "push-to-talk" or "tap-to-talk" interaction.
5. As a writer, I want to see a brief "Polishing your text…" indicator after I stop speaking, so that I know processing is happening and the app hasn't frozen.
6. As a writer, I want the Polished Text to preserve my original tone and intent while removing filler words (um, uh, like, basically), so that the output sounds like me but reads well.
7. As a writer, I want the Polished Text to include proper punctuation, capitalization, and paragraph breaks, so that I don't have to manually format it.
8. As a writer, I want the Polished Text to use bullet lists where my speech naturally enumerates items, so that structured content is formatted appropriately.
9. As a writer, I want the Polished Text to be automatically inserted at my cursor position in the currently focused app, so that I don't have to copy-paste manually.
10. As a writer, I want my existing clipboard contents to be preserved after text insertion, so that dictation doesn't disrupt my workflow.
11. As a user, I want text insertion to work reliably across diverse apps (Safari, VS Code, Terminal, Notes, Slack, etc.), so that I can dictate into any context.
12. As a first-time user, I want to download the AI models from within the app, so that I don't have to manage model files manually.
13. As a first-time user, I want to see download progress for models, so that I know how long setup will take.
14. As a user, I want a menu bar icon that shows the current status (idle, recording, polishing), so that I always know what state the app is in.
15. As a user, I want to configure my preferred global hotkey in settings, so that I can choose a shortcut that doesn't conflict with my other apps.
16. As a user, I want Kural to request only the minimum necessary permissions (microphone, accessibility), so that I feel confident the app is privacy-respecting.
17. As a user, I want the app to explain why it needs accessibility permissions during onboarding, so that I understand the trust requirement.
18. As a user, I want the AI models to load quickly when I first press the hotkey, so that there is minimal startup lag.
19. As a power user, I want to be able to cancel a Dictation Session mid-recording (e.g., by pressing Escape), so that I can discard a false start without inserting garbage text.
20. As a user, I want the app to gracefully handle errors (model load failure, no microphone permission, no accessibility permission), so that I get clear feedback instead of silent failure.
21. As a user, I want every Dictation Session (both the raw transcription and the Polished Text) to be saved locally, so that the data is available when history features ship in v1.

## Implementation Decisions

### Module Architecture

The implementation is organized into four major modules:

#### 1. KuralEngine (Shared Core — lives in KuralKit package)
The orchestrator that manages the full Dictation Session lifecycle via a state machine: `idle → recording → polishing → inserting → idle`. This module is platform-agnostic and will be reused for the iOS Beta without modification.

Contains three sub-modules:
- **AudioStreamer**: Captures audio from the microphone at the sample rate required by Parakeet. Manages the `AVAudioEngine` pipeline and provides a streaming audio buffer.
- **TranscriptionService**: Loads the Parakeet-MLX TDT model (`parakeet-tdt-0.6b-v3`) and runs streaming inference. Emits Ghost Text updates as a callback/async stream.
- **PolishingService**: Loads the Gemma 4 E2B model (`gemma-4-e2b-it-4bit`) with the MTP assistant (`gemma-4-e2b-asst-4bit`). Accepts the full transcript on `stopDictation`, runs the Polishing prompt, and returns Polished Text. The Polishing prompt preserves tone, removes filler, and formats for readability.

#### 2. TextInsertionService (macOS-specific)
A multi-layer fallback chain for inserting Polished Text into the active app's text field, inspired by FluidVoice's `TypingService`. The layers are: CGEvent Unicode → AXUIElement → Clipboard-Paste with snapshot/restore → Menu Paste via AppleScript → Character-by-character CGEvent. Includes focus snapshot capture/restore and pasteboard snapshot/restore logic.

#### 3. ModelManager (shared across platforms)
Handles downloading, storing, and loading MLX models. Provides a registry of available models with download status and progress tracking. Models are stored in the app's Application Support directory.

#### 4. SessionStore (shared across platforms)
Persists every completed Dictation Session using SwiftData. Each Session Record contains the raw transcription (Ghost Text), the Polished Text, a timestamp, and the duration. Lives in KuralKit so the same data model is shared across macOS and iOS. In Beta, sessions are written silently with no UI — the history UI ships in v1.

#### 5. macOS App Shell
- **Menu Bar Extra**: Status icon showing idle/recording/polishing state, with a dropdown for settings and model management.
- **Global Hotkey Listener**: System-wide keyboard shortcut registration. Push-to-talk: hold to record, release to stop. Also supports double-tap to start / single-tap to stop.
- **Floating Overlay Window**: Displays Ghost Text during recording and a "Polishing your text…" indicator during the Polishing phase. Always-on-top, translucent, positioned in a consistent screen location.

### Key Technical Decisions

- **Beta pipeline is full-text handoff** (ADR 0001): Parakeet streams Ghost Text to the overlay, but the LLM only receives the complete transcript after the user stops. No incremental KV cache prefill in Beta.
- **Ghost Text is displayed in a floating overlay, not injected inline** (ADR 0003): Only Polished Text touches the target app. This avoids undo history corruption and fragile text field mutation.
- **Text insertion uses a multi-layer fallback chain** (ADR 0003): CGEvent is preferred but falls back through AX, clipboard, and menu paste for broad app compatibility. Clipboard contents are fully preserved and restored.
- **macOS ships first** (ADR 0004): iOS Beta (with Keyboard Extension + Mach Port IPC) follows after macOS stabilizes.
- **KuralKit is the shared Swift package**: All engine logic lives here. The macOS app target depends on it. When iOS ships, it will use the same package.
- **MLX Swift is the inference runtime**: Both Parakeet and Gemma run via the Swift API for MLX, using Apple Silicon's unified memory. Both models share the same Metal device buffers.
- **Minimum deployment target is macOS 14.0** (Sonoma): Required for modern MLX Swift API support.

### Polishing Prompt Contract

The Gemma Polishing prompt must:
- Preserve the speaker's tone, vocabulary, and intent
- Remove filler words (um, uh, like, basically, you know, so)
- Apply proper punctuation and capitalization
- Break long speech into logical paragraphs
- Format enumerations as bullet lists
- NOT rephrase, summarize, or change the meaning
- NOT add information the speaker did not say

## Testing Decisions

A good test for this project validates external behavior — what the user sees or what text gets produced — not implementation internals like which CGEvent method was chosen.

### Modules to test

- **KuralEngine state machine**: Test the state transitions (idle → recording → polishing → inserting → idle) and edge cases (cancel mid-recording, stop with empty transcript, error during model load). This is a deep module with a simple interface that can be tested with mocked audio and model services.
- **PolishingService prompt**: Test that given known transcript inputs, the Polishing prompt produces expected formatting (filler removal, punctuation, paragraph breaks, bullet lists). These are integration tests that require the actual Gemma model and may need to run on Apple Silicon hardware.
- **TextInsertionService**: Integration tests for the fallback chain behavior. Verify that clipboard contents are preserved and restored. Reference: FluidVoice has `FluidDictationIntegrationTests` for similar coverage.

### Not tested in isolation
- AudioStreamer (requires hardware microphone)
- TranscriptionService (requires Parakeet model + audio input — tested end-to-end via KuralEngine)
- UI components (menu bar, overlay — tested manually)

## Out of Scope

The following are explicitly out of scope for the macOS Beta:

- **iOS support**: Keyboard Extension, Mach Port IPC, Host App arming flow (Phase 2)
- **Incremental KV cache prefill**: The Committed Prefix Buffer and Stability Scoring (v1)
- **Formality slider / user-configurable Polishing levels** (v1 or v2)
- **Multi-language support**: Beta targets English only
- **Cloud-based AI models or API integration**: All processing is on-device
- **Dictation history UI**: No browsing, search, or session replay in Beta — data is persisted silently for v1
- **Cross-device sync**: CloudKit sync for Session Records deferred until iOS ships
- **Command mode / write mode** (as seen in FluidVoice): Beta is dictation-only
- **Inline Ghost Text injection** into the target app's text field (potential v1 feature)
- **Auto-update mechanism**: Not needed for initial Beta distribution

## Further Notes

- **Reference implementation**: [FluidVoice](https://github.com/altic-dev/FluidVoice) (GPLv3) is a strong reference for the macOS app shell, global hotkey, overlay, and text insertion. Kural differentiates by adding on-device LLM Polishing and cross-platform architecture.
- **Memory budget**: Parakeet (~600MB) + Gemma 4 E2B (~1.5GB) + MTP assistant (~300MB) ≈ 2.4GB total. This fits comfortably on 16GB Macs but is tight on 8GB machines. Model loading strategy (lazy load, sequential not parallel) needs attention.
- **Domain glossary**: All development should use the canonical terms defined in `CONTEXT.md` — Dictation Session, Ghost Text, Polished Text, Polishing, KuralEngine.
