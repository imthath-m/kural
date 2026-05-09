# Kural

On-device dictation utility for macOS and iOS that turns speech into polished text at the speed of thought.

## Language

**Dictation Session**:
A single recording lifecycle, from trigger (hotkey press / keyboard tap) to text insertion.
_Avoid_: recording, transcription session

**Ghost Text**:
The raw, real-time transcription shown to the user while they are still speaking. Unpolished and may flicker as the STT model revises earlier words.
_Avoid_: draft text, raw text, preview

**Polished Text** / **Polishing**:
The LLM cleanup pass that replaces Ghost Text with readable, formatted text. The output is called **Polished Text**; the process is called **Polishing**. Preserves the speaker's tone and intent; does not rewrite for style. Removes filler words, applies punctuation, capitalization, paragraph breaks, and bullet lists where applicable.
_Avoid_: finalization, post-processing, correction pass, rewriting

**Committed Prefix**:
Words in the STT output that have stabilized and are safe to feed into the LLM's KV cache. Only relevant in the incremental-prefill architecture (post-Beta).
_Avoid_: stable text, confirmed text

**Pending Buffer**:
Words displayed as Ghost Text but not yet committed to the LLM because they may still be revised by the STT model.

**KuralEngine**:
The central orchestrator that manages the STT and LLM model lifecycle, KV cache, and the handoff between Ghost Text and Polishing.
_Avoid_: FlowEngine

**Host App**:
On iOS, the main application process where the MLX engine runs. The Keyboard Extension is a thin client that communicates with the Host App.
_Avoid_: main app, container app

**Keyboard Extension**:
On iOS, the custom keyboard that provides the dictation trigger. Does not run inference or capture audio.

**Session Record**:
A persisted snapshot of a completed Dictation Session, containing the raw transcription (Ghost Text), the Polished Text, timestamp, and duration. Stored locally via SwiftData.

## Relationships

- A **Dictation Session** produces **Ghost Text** in real-time, then **Polishing** replaces it with **Polished Text**
- Every completed **Dictation Session** is saved as a **Session Record**
- The **Pending Buffer** feeds the **Committed Prefix** once words stabilize (post-Beta only)
- The **KuralEngine** owns both the STT and LLM models and coordinates the full **Dictation Session**
- On iOS, the **Keyboard Extension** signals the **Host App** to start/stop a **Dictation Session**

## Example dialogue

> **Dev:** "When the user taps the dictation key, does the **Keyboard Extension** start recording?"
> **Domain expert:** "No — the **Keyboard Extension** sends a start signal to the **Host App**. The **Host App** owns the microphone."

> **Dev:** "Does the user see the **Polishing** happen in-place?"
> **Domain expert:** "No — **Ghost Text** appears in a floating overlay. After **Polishing**, the **Polished Text** is pasted into the active app."

## Flagged ambiguities

- "Continuous-Prefill" was used to describe both the Beta (full-text handoff) and v1 (incremental prefill) flows — resolved: Beta does no prefill; the term applies only to the v1 incremental architecture.
