param(
  [Parameter(Mandatory=$false)]
  [string]$CoRailsRoot = (Get-Location).Path
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest

function NormLf([string]$s){
  if($null -eq $s){ return "" }
  return ($s -replace "`r`n","`n" -replace "`r","`n")
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
function Sha256Hex([byte[]]$bytes){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hashBytes = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($hashBytes) -replace '-','').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}
function Sha256Raw([string]$p){
  (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLowerInvariant()
}
function Sha256CanonicalText([string]$p){
  # Canonicalize newline (CRLF/CR -> LF) BEFORE hashing so CI + local match
  $t = Get-Content -LiteralPath $p -Raw
  $t = NormLf $t
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  return Sha256Hex ($utf8NoBom.GetBytes($t))
}
function Sha256File([string]$p){
  $ext = [IO.Path]::GetExtension($p).ToLowerInvariant()
  if($ext -in @(".zip",".png",".jpg",".jpeg",".webp",".gif")){ return Sha256Raw $p }
  return Sha256CanonicalText $p
}
function WriteUtf8NoBomLf([string]$path,[string]$text){
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($path, (NormLf $text), $utf8NoBom)
}
function WriteAsciiLf([string]$path,[string]$text){
  [System.IO.File]::WriteAllText($path, (NormLf $text), [System.Text.Encoding]::ASCII)
}
function GetProp([object]$o, [string]$name, [string]$fallback=""){
  if($null -eq $o){ return $fallback }
  $p = $o.PSObject.Properties[$name]
  if($null -eq $p){ return $fallback }
  $v = $p.Value
  if($null -eq $v){ return $fallback }
  return [string]$v
}

$CoRailsRoot = (Resolve-Path -LiteralPath $CoRailsRoot).Path

# Core paths (may be rewritten by fallback)
$ledger   = Join-Path $CoRailsRoot "ledger/CoRails_Ledger.ndjson"
$rulesDir = Join-Path $CoRailsRoot "rules"
$outMd    = Join-Path $CoRailsRoot "generated/CoRails_Register.md"
$outJson  = Join-Path $CoRailsRoot "generated/CoRails_Register.json"
$rcpt     = Join-Path $CoRailsRoot "receipts/CoRails_Register.sha256"

# Fallback: handle accidental CoRails/CoRails
if(-not (Test-Path $ledger)){
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

New-Item -ItemType Directory -Force -Path (Split-Path $outMd)   | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $outJson) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $rcpt)    | Out-Null

# Parse ledger (preserve order)
$events = @()
foreach($line in (Get-Content -LiteralPath $ledger)){
  $t = $line.Trim()
  if($t){ $events += ($t | ConvertFrom-Json) }
}

# Stable as-of: max ts observed in ledger
$tsList = @()
foreach($e in $events){
  $ts = GetProp $e "ts" ""
  if($ts){ $tsList += $ts }
}
$asOf = if($tsList.Count){ ($tsList | Sort-Object | Select-Object -Last 1) } else { "00000000T000000Z" }

# Rules: repo-relative + stable order
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

# JSON + MD (stable LF/noBOM)
WriteUtf8NoBomLf $outJson ((ConvertTo-Json $register -Depth 8 -Compress) + "`n")

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# CoRails Register")
$md.Add("")
$md.Add("* As-of (UTC): $asOf")
$md.Add("* Ledger events: $($events.Count)")
$md.Add("* Rule files: $($rules.Count)")
$md.Add("")
$md.Add("## Rules (by file)")
if($rules.Count -eq 0){
  $md.Add("_None yet (add ID-based files under CoRails/rules/)_")
} else {
  foreach($r in ($rules | Sort-Object id)){
    $md.Add("- **$($r.id)** — sha256=$($r.sha256) — $($r.path)")
  }
}
$md.Add("")
$md.Add("## Ledger (append-only)")
foreach($e in $events){
  $ts   = GetProp $e "ts"    ""
  $ev   = GetProp $e "event" ""
  $id   = GetProp $e "id"    "-"
  $note = GetProp $e "note"  ""
  $md.Add(("- $ts — $ev — $id $note").Trim())
}
WriteUtf8NoBomLf $outMd (($md -join "`n") + "`n")

# Fixed receipt (no timestamp drift)
$rcptText = @(
  "$(Sha256File $outMd)  generated/CoRails_Register.md",
  "$(Sha256File $outJson)  generated/CoRails_Register.json",
  "$(Sha256File $ledger)  ledger/CoRails_Ledger.ndjson"
) -join "`n"
WriteAsciiLf $rcpt ($rcptText + "`n")

Write-Host "OK: rebuilt CoRails register (deterministic). Receipt: receipts/CoRails_Register.sha256"
