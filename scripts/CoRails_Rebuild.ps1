param(
  [string]$CoRailsRoot = (Get-Location)
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest

function Sha256Raw([string]$p){
  (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Sha256CanonicalText([string]$p){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $t = Get-Content -LiteralPath $p -Raw
  $t = ($t -replace "`r`n","`n" -replace "`r","`n")
  $bytes = $utf8NoBom.GetBytes($t)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  ($sha.ComputeHash($bytes) | ForEach-Object { param(
  [string]$CoRailsRoot = (Get-Location)
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest

function Sha256File([string]$p){
  (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function WriteUtf8NoBomLf([string]$path,[string]$text){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $t = ($text -replace "`r`n","`n" -replace "`r","`n")
  [System.IO.File]::WriteAllText($path, $t, $utf8NoBom)
}
function WriteAsciiLf([string]$path,[string]$text){
  $t = ($text -replace "`r`n","`n" -replace "`r","`n")
  [System.IO.File]::WriteAllText($path, $t, [System.Text.Encoding]::ASCII)
}
function RelPath([string]$base,[string]$full){
  $b = [IO.Path]::GetFullPath($base).TrimEnd('\','/')
  $f = [IO.Path]::GetFullPath($full)
  if($f.StartsWith($b, [System.StringComparison]::OrdinalIgnoreCase)){
    $r = $f.Substring($b.Length).TrimStart('\','/')
  } else {
    $r = $full
  }
  return ($r -replace '\\','/')
}
function GetProp([object]$o, [string]$name, [string]$fallback=""){
  if($null -eq $o){ return $fallback }
  $p = $o.PSObject.Properties[$name]
  if($null -eq $p){ return $fallback }
  $v = $p.Value
  if($null -eq $v){ return $fallback }
  return [string]$v
}

$ledger   = Join-Path $CoRailsRoot "ledger/CoRails_Ledger.ndjson"
$rulesDir = Join-Path $CoRailsRoot "rules"
$outMd    = Join-Path $CoRailsRoot "generated/CoRails_Register.md"
$outJson  = Join-Path $CoRailsRoot "generated/CoRails_Register.json"
$rcpt     = Join-Path $CoRailsRoot "receipts/CoRails_Register.sha256"

# Ensure dirs exist
New-Item -ItemType Directory -Force -Path (Split-Path $outMd)   | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $outJson) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $rcpt)    | Out-Null

if(-not (Test-Path $ledger)){
  # Fallback: parent root (handles accidental CoRails/CoRails)
  $p = Split-Path -Parent $CoRailsRoot
  $alt = Join-Path $p "ledger/CoRails_Ledger.ndjson"
  if(Test-Path $alt){
    $CoRailsRoot = $p
    $ledger   = Join-Path $CoRailsRoot "ledger/CoRails_Ledger.ndjson"
    $rulesDir = Join-Path $CoRailsRoot "rules"
    $outMd    = Join-Path $CoRailsRoot "generated/CoRails_Register.md"
    $outJson  = Join-Path $CoRailsRoot "generated/CoRails_Register.json"
    $rcpt     = Join-Path $CoRailsRoot "receipts/CoRails_Register.sha256"
  } else {
    throw "Missing ledger: $ledger"
  }
}
# Fallback: parent root

# Parse ledger (preserve order)
$events = @()
foreach($line in (Get-Content -LiteralPath $ledger)){
  if($line.Trim()){
    $events += ($line | ConvertFrom-Json)
  }
}

# Stable "as-of": max ts observed in ledger (not "now")
$tsList = @()
foreach($e in $events){
  $ts = GetProp $e "ts" ""
  if($ts){ $tsList += $ts }
}
$asOf = if($tsList.Count){ ($tsList | Sort-Object | Select-Object -Last 1) } else { "00000000T000000Z" }

# Rules: repo-relative paths only (stable across machines)
$rules = @()
if(Test-Path $rulesDir){
  Get-ChildItem -LiteralPath $rulesDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
    $id  = [IO.Path]::GetFileNameWithoutExtension($_.Name)
    $rel = RelPath $CoRailsRoot $_.FullName
    $rules += [pscustomobject]@{
      id     = $id
      path   = $rel
      sha256 = (Sha256File $_.FullName)
    }
  }
}

$register = [pscustomobject]@{
  as_of_utc     = $asOf
  ledger_events = $events.Count
  rule_files    = $rules.Count
  rules         = $rules
  events        = $events
}

# JSON (stable LF/noBOM)
WriteUtf8NoBomLf $outJson ((ConvertTo-Json $register -Depth 8 -Compress) + "`n")

# MD (stable LF/noBOM)
$md = @()
$md += "# CoRails Register"
$md += ""
$md += "* As-of (UTC): $asOf"
$md += "* Ledger events: $($events.Count)"
$md += "* Rule files: $($rules.Count)"
$md += ""
$md += "## Rules (by file)"
if($rules.Count -eq 0){
  $md += "_None yet (add ID-based files under CoRails/rules/)_"
}else{
  foreach($r in ($rules | Sort-Object id)){
    $md += "- **$($r.id)** — sha256=$($r.sha256) — $($r.path)"
  }
}
$md += ""
$md += "## Ledger (append-only)"
foreach($e in $events){
  $ts   = GetProp $e "ts"    ""
  $ev   = GetProp $e "event" ""
  $id   = GetProp $e "id"    "-"
  $note = GetProp $e "note"  ""
  $md += ("- $ts — $ev — $id $note".Trim())
}
WriteUtf8NoBomLf $outMd (($md -join "`n") + "`n")

# Fixed receipt path (no timestamp drift)
$rcptText = @(
  "$(Sha256File $outMd)  generated/CoRails_Register.md",
  "$(Sha256File $outJson)  generated/CoRails_Register.json",
  "$(Sha256File $ledger)  ledger/CoRails_Ledger.ndjson"
) -join "`n"
WriteAsciiLf $rcpt ($rcptText + "`n")

Write-Host "OK: rebuilt CoRails register (deterministic). Receipt: receipts/CoRails_Register.sha256"

.ToString("x2") }) -join ""
}
function Sha256File([string]$p){
  $ext = [IO.Path]::GetExtension($p).ToLowerInvariant()
  if($ext -in @(".zip",".png",".jpg",".jpeg",".webp")){ return Sha256Raw $p }
  return Sha256CanonicalText $p
}
function WriteUtf8NoBomLf([string]$path,[string]$text){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $t = ($text -replace "`r`n","`n" -replace "`r","`n")
  [System.IO.File]::WriteAllText($path, $t, $utf8NoBom)
}
function WriteAsciiLf([string]$path,[string]$text){
  $t = ($text -replace "`r`n","`n" -replace "`r","`n")
  [System.IO.File]::WriteAllText($path, $t, [System.Text.Encoding]::ASCII)
}
function RelPath([string]$base,[string]$full){
  $b = [IO.Path]::GetFullPath($base).TrimEnd('\','/')
  $f = [IO.Path]::GetFullPath($full)
  if($f.StartsWith($b, [System.StringComparison]::OrdinalIgnoreCase)){
    $r = $f.Substring($b.Length).TrimStart('\','/')
  } else {
    $r = $full
  }
  return ($r -replace '\\','/')
}
function GetProp([object]$o, [string]$name, [string]$fallback=""){
  if($null -eq $o){ return $fallback }
  $p = $o.PSObject.Properties[$name]
  if($null -eq $p){ return $fallback }
  $v = $p.Value
  if($null -eq $v){ return $fallback }
  return [string]$v
}

$ledger   = Join-Path $CoRailsRoot "ledger/CoRails_Ledger.ndjson"
$rulesDir = Join-Path $CoRailsRoot "rules"
$outMd    = Join-Path $CoRailsRoot "generated/CoRails_Register.md"
$outJson  = Join-Path $CoRailsRoot "generated/CoRails_Register.json"
$rcpt     = Join-Path $CoRailsRoot "receipts/CoRails_Register.sha256"

# Ensure dirs exist
New-Item -ItemType Directory -Force -Path (Split-Path $outMd)   | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $outJson) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $rcpt)    | Out-Null

if(-not (Test-Path $ledger)){
  # Fallback: parent root (handles accidental CoRails/CoRails)
  $p = Split-Path -Parent $CoRailsRoot
  $alt = Join-Path $p "ledger/CoRails_Ledger.ndjson"
  if(Test-Path $alt){
    $CoRailsRoot = $p
    $ledger   = Join-Path $CoRailsRoot "ledger/CoRails_Ledger.ndjson"
    $rulesDir = Join-Path $CoRailsRoot "rules"
    $outMd    = Join-Path $CoRailsRoot "generated/CoRails_Register.md"
    $outJson  = Join-Path $CoRailsRoot "generated/CoRails_Register.json"
    $rcpt     = Join-Path $CoRailsRoot "receipts/CoRails_Register.sha256"
  } else {
    throw "Missing ledger: $ledger"
  }
}
# Fallback: parent root

# Parse ledger (preserve order)
$events = @()
foreach($line in (Get-Content -LiteralPath $ledger)){
  if($line.Trim()){
    $events += ($line | ConvertFrom-Json)
  }
}

# Stable "as-of": max ts observed in ledger (not "now")
$tsList = @()
foreach($e in $events){
  $ts = GetProp $e "ts" ""
  if($ts){ $tsList += $ts }
}
$asOf = if($tsList.Count){ ($tsList | Sort-Object | Select-Object -Last 1) } else { "00000000T000000Z" }

# Rules: repo-relative paths only (stable across machines)
$rules = @()
if(Test-Path $rulesDir){
  Get-ChildItem -LiteralPath $rulesDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
    $id  = [IO.Path]::GetFileNameWithoutExtension($_.Name)
    $rel = RelPath $CoRailsRoot $_.FullName
    $rules += [pscustomobject]@{
      id     = $id
      path   = $rel
      sha256 = (Sha256File $_.FullName)
    }
  }
}

$register = [pscustomobject]@{
  as_of_utc     = $asOf
  ledger_events = $events.Count
  rule_files    = $rules.Count
  rules         = $rules
  events        = $events
}

# JSON (stable LF/noBOM)
WriteUtf8NoBomLf $outJson ((ConvertTo-Json $register -Depth 8 -Compress) + "`n")

# MD (stable LF/noBOM)
$md = @()
$md += "# CoRails Register"
$md += ""
$md += "* As-of (UTC): $asOf"
$md += "* Ledger events: $($events.Count)"
$md += "* Rule files: $($rules.Count)"
$md += ""
$md += "## Rules (by file)"
if($rules.Count -eq 0){
  $md += "_None yet (add ID-based files under CoRails/rules/)_"
}else{
  foreach($r in ($rules | Sort-Object id)){
    $md += "- **$($r.id)** — sha256=$($r.sha256) — $($r.path)"
  }
}
$md += ""
$md += "## Ledger (append-only)"
foreach($e in $events){
  $ts   = GetProp $e "ts"    ""
  $ev   = GetProp $e "event" ""
  $id   = GetProp $e "id"    "-"
  $note = GetProp $e "note"  ""
  $md += ("- $ts — $ev — $id $note".Trim())
}
WriteUtf8NoBomLf $outMd (($md -join "`n") + "`n")

# Fixed receipt path (no timestamp drift)
$rcptText = @(
  "$(Sha256File $outMd)  generated/CoRails_Register.md",
  "$(Sha256File $outJson)  generated/CoRails_Register.json",
  "$(Sha256File $ledger)  ledger/CoRails_Ledger.ndjson"
) -join "`n"
WriteAsciiLf $rcpt ($rcptText + "`n")

Write-Host "OK: rebuilt CoRails register (deterministic). Receipt: receipts/CoRails_Register.sha256"




