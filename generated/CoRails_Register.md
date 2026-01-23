# CoRails Register

* As-of (UTC): 20260123T013056Z
* Ledger events: 9
* Rule files: 7

## Rules (by file)
- **BPOE-0001** — sha256=9c96c1c2eca9fb42a7ee235338cf97f4cccbec170690b538a317cd6f48dea26e — rules/BPOE-0001.md
- **BPOE-0002** — sha256=0dbff8ecd5eb44e37910fe5b8cf772353a23b5e7b98902b00009b88d3ddb4fe4 — rules/BPOE-0002.md
- **BPOE-0003** — sha256=2d6124eac81c3189c812192bd8384bd4d99e50fa5a4c195a1e55ebdfd13471fc — rules/BPOE-0003.md
- **BPOE-0004** — sha256=b8806e49bc3a37047f3a0ad024609431e6dccefcc88e7f922d2b4335716c60f3 — rules/BPOE-0004.md
- **BPOE-0005** — sha256=e43001dd5e6268b53b15d2f9d65ca8e0ded8c3ecb9c6318d26f49aec941260bd — rules/BPOE-0005.md
- **CORAILS-ID-SCHEME** — sha256=6cf90ac70b7feb532d8835ae85739ebcd7fe3f93ad22d7ed9e984ae86408e507 — rules/CORAILS-ID-SCHEME.md
- **CORAILS-LEDGER-SCHEMA** — sha256=be7c9271d08a0bb0792a72f63be013f740a958d8ea6c62248ff5c6d9c81dc74c — rules/CORAILS-LEDGER-SCHEMA.md

## Ledger (append-only)
- 20260122T223014Z — INIT — - CoRails ledger initialized
- 20260122T223642Z — ADD_RULE — BPOE-0001 Automation-first; assume manual steps fail unless evidence read-back verifies.
- 20260122T230356Z — ADD_RULE — BPOE-0002 Chat not ledger; SideNotes are micro '#...' only; long notes become files w/ SHA.
- 20260122T235004Z — ADD_RULE — CORAILS-ID-SCHEME IDs are stable identity; priority is separate; no renumbering.
- 20260123T003055Z — ADD_RULE — BPOE-0003 CoPulse: one micro-question per wave; answer q1..q9 using compact icon anchors.
- 20260123T005444Z — UPD_RULE — BPOE-0003 CoPulse-3: one micro-question per wave; reply !1=CoGo, !2=CoMeh, !3=CoNo.
- 20260123T011336Z — ADD_RULE — BPOE-0004 NoPause default: keep executing until explicit stop token (CoStop/!3).
- 20260123T011345Z — ADD_RULE — CORAILS-PLACEHOLDER-SAFE Ban <PLACEHOLDERS> in PS examples; use RUN_ID_HERE / {RUN_ID} / vars.
- 20260123T013056Z — ADD_RULE — BPOE-0005 PreBakeNext: every response includes DONE + NEXT runnable queue to reduce CoPong wait.
