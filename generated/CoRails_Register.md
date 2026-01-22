# CoRails Register

* As-of (UTC): 20260122T235004Z
* Ledger events: 4
* Rule files: 4

## Rules (by file)
- **BPOE-0001** — sha256=e317e454ca76fbde514ec5c5c7b73791d68529436287742e2b5d4f579494fe36 — rules/BPOE-0001.md
- **BPOE-0002** — sha256=3bbaf20c9adcdba3784e3e9d80495a752282eec66950066daba43a66a3137f2c — rules/BPOE-0002.md
- **CORAILS-ID-SCHEME** — sha256=fbd0c2a9aae86ee71548cf2067493fea86033faf935402f2fc782663e2cd8c70 — rules/CORAILS-ID-SCHEME.md
- **CORAILS-LEDGER-SCHEMA** — sha256=0dc0da91135296deb4229e5e9c727ab1a839d8a9cfbf52393d5d00e6bce66de5 — rules/CORAILS-LEDGER-SCHEMA.md

## Ledger (append-only)
- 20260122T223014Z — INIT — - CoRails ledger initialized
- 20260122T223642Z — ADD_RULE — BPOE-0001 Automation-first; assume manual steps fail unless evidence read-back verifies.
- 20260122T230356Z — ADD_RULE — BPOE-0002 Chat not ledger; SideNotes are micro '#...' only; long notes become files w/ SHA.
- 20260122T235004Z — ADD_RULE — CORAILS-ID-SCHEME IDs are stable identity; priority is separate; no renumbering.
