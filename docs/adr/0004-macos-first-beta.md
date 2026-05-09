# macOS-First Beta

The Beta ships macOS-only. iOS follows as a separate Beta phase after the macOS release stabilizes. The v1 optimization features (Committed Prefix Buffer, formality slider) come after both platforms have shipped.

The iOS architecture (Keyboard Extension + Mach Port IPC + Host App arming flow) is 3-4x the platform-specific work compared to macOS (global hotkey + menu bar extra). Shipping macOS first lets us validate the core engine — Parakeet STT quality, Gemma Polishing prompt, text insertion reliability — before tackling iOS IPC complexity. No code is wasted: the Shared Core (KuralEngine, AudioStreamer, TextProcessingService) transfers directly.

## Consequences

- macOS Beta users get earlier access while iOS plumbing is built.
- The `project.yml` iOS target and Keyboard Extension target can be deferred — no need to configure App Groups, background entitlements, or Mach Port bridging until Phase 2.
