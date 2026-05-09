# Text Insertion Strategy: Multi-Layer Fallback Chain

Text insertion on macOS uses a layered fallback chain, inspired by [FluidVoice's TypingService](https://github.com/altic-dev/FluidVoice). Ghost Text is shown in a floating overlay window; only the final polished text is inserted into the target app.

The insertion pipeline, in priority order:

1. **CGEvent Unicode Insertion** (preferred): Posts keyboard events with unicode strings directly to the target PID. Works well with terminals, Electron apps (VSCode, Discord), and most native apps. Limited to ~200 UTF-16 units per event.
2. **Accessibility API (AXUIElement)**: Finds the focused text element and sets its `AXValue` attribute directly. Works for native text fields but fails silently in web views and some sandboxed apps.
3. **Clipboard-Paste with Snapshot/Restore**: Saves the full pasteboard contents (including rich content), sets the text, simulates ⌘V, then restores the previous clipboard. Only restores if the clipboard hasn't been changed externally during the operation.
4. **Menu Paste via AppleScript**: Clicks Edit → Paste via System Events as a last resort.
5. **Character-by-character CGEvent**: Final fallback for edge cases.

On iOS, the Keyboard Extension uses `textDocumentProxy.insertText()` directly — no fallback chain needed.

## Consequences

- The clipboard-paste path preserves and restores the user's full pasteboard (not just plain text — all `NSPasteboardItem` types). A `changeCount` check prevents clobbering if the user pastes between our set and restore.
- FluidVoice also offers a user-facing "Reliable Paste" mode that skips CGEvent entirely and goes straight to clipboard-paste. We should consider exposing a similar setting for users who experience issues with the primary path.
