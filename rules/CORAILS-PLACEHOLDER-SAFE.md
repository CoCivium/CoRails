# CORAILS-PLACEHOLDER-SAFE — PowerShell-safe placeholders only

## Rule
Never use angle-bracket placeholders in PowerShell examples (e.g., <RUN_ID>).
PowerShell reserves '<' and it can hard-fail copy/paste runs.

## Allowed patterns
- ALLCAPS_WITH_UNDERSCORES (e.g., RUN_ID_HERE)
- {BRACED_TOKENS} (e.g., {RUN_ID})
- `$variables` with assignment shown above the command

## Also banned
- Markdown fences inside PowerShell prompts (e.g., ```powershell) — they break copy/paste

## Example (preferred)
```
$repo="CoCivium/CoRails"
$id=(gh run list -R $repo --limit 1 --json databaseId | ConvertFrom-Json).databaseId
gh run view -R $repo $id
```
