# CORAILS-ID-SCHEME — Stable IDs, separate priority

## Rule
- IDs are **identity**, not priority. Never renumber IDs.
- Priority is stored separately (e.g., ledger fields/tags/views).

## Recommended
- Use monotonic IDs per namespace: BPOE-0001, BPOE-0002, ...
- Add/change priority by ledger event fields (e.g., priority=P0..P3), NOT by renaming IDs.

## Optional (distributed creation)
- ULID-based IDs can be used where coordination is hard.
  Still: priority remains separate.

## Enforcement
- Generator/validator should fail on duplicate IDs.
