#requires -version 5.1
<#
.SYNOPSIS
    Instructor dashboard — probes Snowflake for all learner-prefixed objects.

.DESCRIPTION
    Queries Snowflake (via snow CLI, connection 'training') for resources
    belonging to the 11 learner prefixes (APP01..APP11, configurable) and
    prints a per-learner summary table:

      - databases created (APPxx_*)
      - warehouses created (WH_APPxx_* or APPxx_*)
      - warehouses currently STARTED (cost risk)
      - resource monitors

    Use before a session (are learners ready?) and during labs (who is
    blocked? who left a warehouse running?).

    Non-destructive: read-only SHOW commands. No secret is displayed.

.PARAMETER Prefixes
    Learner prefixes to scan. Default: APP01..APP11.

.PARAMETER Connection
    Snow CLI connection name. Default: 'training' (or SNOWFLAKE_CONNECTION).

.EXAMPLE
    .\scripts\Test-FleetReadiness.ps1
    .\scripts\Test-FleetReadiness.ps1 -Prefixes APP01,APP02,APP03
#>

[CmdletBinding()]
param(
    [string[]]$Prefixes = @('APP01','APP02','APP03','APP04','APP05','APP06','APP07','APP08','APP09','APP10','APP11'),
    [string]$Connection = $(if ($env:SNOWFLAKE_CONNECTION) { $env:SNOWFLAKE_CONNECTION } else { 'training' })
)

$ErrorActionPreference = 'Continue'

function Invoke-SnowQuery {
    param([string]$Sql)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & snow sql -c $Connection -q $Sql --format=json 2>$null
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -ne 0 -or -not $out) { return $null }
    try { return ($out | ConvertFrom-Json) } catch { return $null }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' Fleet Readiness — instructor dashboard' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host "  Connection : $Connection" -ForegroundColor DarkGray
Write-Host "  Prefixes   : $($Prefixes -join ', ')" -ForegroundColor DarkGray
Write-Host ''

if (-not (Get-Command snow -ErrorAction SilentlyContinue)) {
    Write-Host '[FAIL] snow CLI not found in PATH' -ForegroundColor Red
    exit 1
}

$whoami = Invoke-SnowQuery 'SELECT CURRENT_USER() AS U, CURRENT_ROLE() AS R'
if (-not $whoami) {
    Write-Host "[FAIL] Snowflake connection '$Connection' failed. Run New-SnowflakeConnection.ps1 first." -ForegroundColor Red
    exit 1
}
Write-Host ("[OK]   Connected as {0} (role {1})" -f $whoami[0].U, $whoami[0].R) -ForegroundColor Green
Write-Host ''

# Fetch all learner objects in two queries
$dbs = Invoke-SnowQuery "SHOW DATABASES LIKE 'APP%'"
$whs = Invoke-SnowQuery "SHOW WAREHOUSES LIKE '%APP%'"
$rms = Invoke-SnowQuery "SHOW RESOURCE MONITORS LIKE '%APP%'"

$rows = foreach ($p in $Prefixes) {
    $dbCount = @($dbs | Where-Object { $_.name -like "$p`*" -or $_.name -like "DB_$p`*" }).Count
    $whAll   = @($whs | Where-Object { $_.name -like "*$p`*" })
    $whCount = $whAll.Count
    $whOn    = @($whAll | Where-Object { $_.state -eq 'STARTED' }).Count
    $rmCount = @($rms | Where-Object { $_.name -like "*$p`*" }).Count
    [PSCustomObject]@{
        Prefix      = $p
        Databases   = $dbCount
        Warehouses  = $whCount
        WhStarted   = $whOn
        Monitors    = $rmCount
    }
}

$rows | Format-Table -AutoSize

$totalStarted = ($rows | Measure-Object -Property WhStarted -Sum).Sum
if ($totalStarted -gt 0) {
    Write-Host "[WARN] $totalStarted warehouse(s) STARTED across the fleet — suspend them to stop credit burn:" -ForegroundColor Yellow
    $running = $whs | Where-Object { $_.state -eq 'STARTED' }
    foreach ($w in $running) {
        Write-Host "       ALTER WAREHOUSE `"$($w.name)`" SUSPEND;" -ForegroundColor DarkGray
    }
} else {
    Write-Host '[OK]   No warehouse running — zero idle credit burn' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Tip: learners with 0 databases are likely blocked or not started.' -ForegroundColor DarkGray
Write-Host ''
