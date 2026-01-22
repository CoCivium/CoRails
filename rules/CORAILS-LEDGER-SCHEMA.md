# CORAILS-LEDGER-SCHEMA

Ledger file: CoRails/ledger/CoRails_Ledger.ndjson (append-only, one JSON object per line)

## Required fields (minimum viable event)
- vent : string (e.g., INIT, ADD_RULE, AMEND_RULE, DEPRECATE, ALIAS)
- 	s    : string UTC timestamp yyyyMMddTHHmmssZ

## Optional fields (common)
- id    : stable identifier for the rule/protocol affected (e.g., BPOE-0001)
- 
ote  : short human summary
- sha256: sha of referenced content (if applicable)
- path  : repo-relative path to canonical content (if applicable)
- rom / 	o : for deprecations/aliases/moves

## Generator rule
Generators MUST tolerate missing optional fields without error.
