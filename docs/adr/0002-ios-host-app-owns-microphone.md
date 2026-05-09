# iOS Host App Owns the Microphone

On iOS, the MLX engine (~2GB) and the microphone both live in the Host App process, not the Keyboard Extension. The extension is a thin client that sends start/stop signals via Mach Ports and receives tokens for insertion via `textDocumentProxy`. The user must "arm" the Host App (open it) before switching to their target app; the Host App stays alive in the background using the Audio Background Mode entitlement while a Dictation Session is active.

## Considered Options

- **Extension owns the mic and streams audio via MMAP to Host App**: rejected because Keyboard Extensions have ~70-150MB memory limits and unreliable process lifetimes — iOS can suspend the extension mid-recording if the user briefly switches apps.
- **Extension runs the full engine**: rejected outright — 2GB of models cannot fit in an extension's memory budget.

## Consequences

- Users must open the Kural app at least once before dictation works from the keyboard. This is an onboarding friction point that needs clear UX guidance.
- "Full Access" permission is required for the Mach Port bridge, but no data leaves the device — this is a trust/messaging challenge, not a technical one.
