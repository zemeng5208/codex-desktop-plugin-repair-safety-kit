[CmdletBinding(SupportsShouldProcess)]
param([switch] $Apply)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $env:USERPROFILE '.codex\config.toml'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw 'Codex user configuration was not found.'
}

$text = [System.IO.File]::ReadAllText($configPath)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$hadTrailingNewline = $text.EndsWith("`n")
$lines = [System.Collections.Generic.List[string]]::new()
foreach ($line in ($text -split "`r?`n")) { $lines.Add($line) }

$envStart = -1
$envEnd = $lines.Count
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '[mcp_servers.node_repl.env]') {
        $envStart = $i
        continue
    }
    if ($envStart -ge 0 -and $i -gt $envStart -and $lines[$i] -match '^\s*\[') {
        $envEnd = $i
        break
    }
}
if ($envStart -lt 0) {
    Write-Output 'No [mcp_servers.node_repl.env] table was found. No change is needed.'
    exit 0
}

$removeIndexes = [System.Collections.Generic.List[int]]::new()
for ($i = $envStart + 1; $i -lt $envEnd; $i++) {
    if ($lines[$i] -match '^\s*SKY_CUA_NATIVE_PIPE(?:_DIRECTORY)?\s*=') {
        $removeIndexes.Add($i)
    }
}
if ($removeIndexes.Count -eq 0) {
    Write-Output 'No stale task-specific native pipe entries were found. No change is needed.'
    exit 0
}

Write-Output ("Found {0} stale task-specific pipe entries." -f $removeIndexes.Count)
if (-not $Apply) {
    Write-Output 'Dry run only. Re-run with -Apply to back up the file and remove those entries.'
    exit 0
}

$backupDir = Join-Path $env:USERPROFILE '.codex\backups\config'
[System.IO.Directory]::CreateDirectory($backupDir) | Out-Null
$backupPath = Join-Path $backupDir (
    'config.toml.{0}.stale-pipe.bak' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
)
if (-not $PSCmdlet.ShouldProcess($configPath, 'Back up config.toml and remove stale pipe entries')) {
    exit 0
}

[System.IO.File]::Copy($configPath, $backupPath, $false)
for ($i = $removeIndexes.Count - 1; $i -ge 0; $i--) {
    $lines.RemoveAt($removeIndexes[$i])
}

$updated = [string]::Join($newline, $lines)
if (-not $hadTrailingNewline) { $updated = $updated.TrimEnd("`r", "`n") }
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($configPath, $updated, $utf8NoBom)

Write-Output 'Repair applied. A private timestamped backup was created.'
Write-Output 'Restart Codex Desktop yourself, then validate in a newly created task.'
