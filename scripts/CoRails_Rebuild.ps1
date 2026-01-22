param(
  [string]$CoRailsRoot = (Join-Path (Get-Location) "CoRails")
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest

function UTS { (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") }
function Sha256File([string]$p){
  (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}

$ledger = Join-Path $CoRailsRoot "ledger\CoRails_Ledger.ndjson"
$rulesDir = Join-Path $CoRailsRoot "rules"
$outMd = Join-Path $CoRailsRoot "generated\CoRails_Register.md"
$outJson = Join-Path $CoRailsRoot "generated\CoRails_Register.json"
$rcptDir = Join-Path $CoRailsRoot "receipts"

if(-not (Test-Path $ledger)){ throw "Missing ledger: $ledger" }

# Parse ledger (ndjson)
$events = Get-Content -LiteralPath $ledger | ? { $_.Trim() } | % { $_ | ConvertFrom-Json }

# Parse rules (ID-based md files if present)
$rules = @()
if(Test-Path $rulesDir){
  Get-ChildItem -LiteralPath $rulesDir -Filter "*.md" | ForEach-Object {
    $id = [IO.Path]::GetFileNameWithoutExtension($_.Name)
    $txt = Get-Content -LiteralPath $_.FullName -Raw
    $rules += [pscustomobject]@{
      id = $id
      path = $_.FullName
      sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
      text = $txt
    }
  }
}

# Minimal register object (extend later)
$register = [pscustomobject]@{
  generated_utc = (UTS)
  ledger_events = $events.Count
  rule_files = $rules.Count
  rules = $rules | Select-Object id, sha256, path
  events = $events
}

# Write JSON
$register | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outJson -Encoding utf8

# Write MD (human view)
$md = @()
$md += "# CoRails Register"
$md += ""
$md += "* Generated (UTC): $($register.generated_utc)"
$md += "* Ledger events: $($register.ledger_events)"
$md += "* Rule files: $($register.rule_files)"
$md += ""
$md += "## Rules (by file)"
if($rules.Count -eq 0){
  $md += "_None yet (add ID-based files under CoRails\\rules\\)_."
}else{
  foreach($r in ($rules | Sort-Object id)){
    $md += "- **$($r.id)** — sha256=$($r.sha256)"
  }
}
$md += ""
$md += "## Ledger (append-only)"
function GetProp([object]$o, [string]$name, [string]$fallback=""){
  if($null -eq $o){ return $fallback }
  $p = $o.PSObject.Properties[$name]
  if($null -eq $p){ return $fallback }
  $v = $p.Value
  if($null -eq $v){ return $fallback }
  return [string]$v
}

foreach($e in $events){
  $ts   = GetProp $e "ts"   ""
  $ev   = GetProp $e "event" ""
  $id   = GetProp $e "id"   "-"
  $note = GetProp $e "note" ""
  $md += "- $ts — $ev — $id $note".Trim()
}
$md -join "`r`n" | Set-Content -LiteralPath $outMd -Encoding utf8

# Receipt
$ts = (UTS)
$rcpt = Join-Path $rcptDir "CoRails_Register.$ts.sha256"
@(
  "$(Sha256File $outMd)  generated\CoRails_Register.md",
  "$(Sha256File $outJson)  generated\CoRails_Register.json",
  "$(Sha256File $ledger)  ledger\CoRails_Ledger.ndjson"
) -join "`r`n" | Set-Content -LiteralPath $rcpt -Encoding ascii

Write-Host "OK: rebuilt CoRails register. Receipt: $rcpt"

