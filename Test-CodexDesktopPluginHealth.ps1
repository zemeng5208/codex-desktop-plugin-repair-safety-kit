[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-CheckResult {
    param([string] $Name, [bool] $Ok, [string] $Detail)
    $state = if ($Ok) { 'OK' } else { 'CHECK' }
    Write-Output ("[{0}] {1}: {2}" -f $state, $Name, $Detail)
}

$package = Get-AppxPackage -Name OpenAI.Codex -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending | Select-Object -First 1
if ($package) {
    Write-CheckResult 'Store package' ($package.Status -eq 'Ok') (
        'version={0}; status={1}; signature={2}' -f
        $package.Version, $package.Status, $package.SignatureKind
    )
} else {
    Write-CheckResult 'Store package' $false 'OpenAI.Codex was not found'
}

$codex = Get-Command codex.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $codex) {
    $codex = Get-Command codex.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($codex) {
    $pluginOutput = & $codex.Source plugin list 2>&1 | Out-String
    foreach ($plugin in @('browser', 'chrome', 'computer-use')) {
        $present = $pluginOutput -match [regex]::Escape($plugin)
        $detail = if ($present) { 'listed by the Codex CLI' } else { 'not listed by the Codex CLI' }
        Write-CheckResult ("Plugin {0}" -f $plugin) $present $detail
    }
} else {
    Write-CheckResult 'Codex CLI' $false 'not found on PATH'
}

$configPath = Join-Path $env:USERPROFILE '.codex\config.toml'
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    $configText = [System.IO.File]::ReadAllText($configPath)
    $hasStalePipe = $configText -match '(?m)^\s*SKY_CUA_NATIVE_PIPE(?:_DIRECTORY)?\s*='
    $detail = if ($hasStalePipe) {
        'stale-looking entries found; preview Repair-StaleNodeReplPipeConfig.ps1'
    } else { 'no stale entries found' }
    Write-CheckResult 'Task-specific pipe settings' (-not $hasStalePipe) $detail
} else {
    Write-CheckResult 'User configuration' $false 'config.toml was not found'
}

Write-Output ''
Write-Output 'Final validation must be performed in a newly created Codex Desktop task.'
