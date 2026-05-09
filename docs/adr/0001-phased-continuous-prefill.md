# Phased Dictation Pipeline

Beta does full-text handoff: Parakeet streams Ghost Text to the UI, and only after the user stops does Gemma receive the entire transcript for Polishing. This adds 1-2s of visible delay but avoids the complexity of incremental KV cache management — specifically the problem of TDT models rewriting earlier words, which would require cache invalidation.

v1 introduces a Committed Prefix Buffer: words that have stabilized in the STT stream are incrementally prefilled into Gemma's KV cache while the user is still speaking, cutting Polishing latency to sub-500ms.

## Considered Options

- **Direct incremental prefill from day one**: rejected because TDT models frequently revise earlier tokens, and KV cache rewinding is expensive and error-prone.
- **Wait-for-silence (traditional dictation)**: rejected because it doesn't meet the "speed of thought" latency target.
