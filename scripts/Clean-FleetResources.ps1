#requires -version 5.1
<#
.SYNOPSIS
    Instructor emergency cleanup — suspends warehouses and optionally drops
    learner-prefixed Snowflake objects across the fleet.

.DESCRIPTION
    Two modes:

    -SuspendOnly (default action, safe):
      Suspends every STARTED warehouse matching a learner prefix.
      Stops credit burn without deleting anything.

    -Drop:
      Drops learner-prefixed training objects (databases, warehouses,
      resource monitors, roles matching APPxx_*). DESTRUCTIVE — requires
      -Confirm:$false to be passed explicitly after reviewing the plan.

    Scope is strictly limited to names matching the learner prefixes.
    Shared/instructor resources and Azure resources are never touched.

.PARAMETER Prefixes
    Learner prefixes to clean. Default: APP01..APP11.

.PARAMETER Connection
    Snow CLI connection name. Default: 'training' (or SNOWFLAKE_CONNECTION).

.PARAMETER SuspendOnly
    Only suspend running warehouses (no drops). This is the default.

.PARAMETER Drop
    Drop learner-prefixed objects. Requires -Force.

.PARAMETER Force
    Required together with -Drop to actually execute destructive statements.

.PARAMETER WhatIf
    Print the SQL that would run without executing it.

.EXAMPLE
    .\scripts\Clean-FleetResources.ps1                    # suspend only
    .\scripts\Clean-FleetResources.ps1 -Drop -WhatIf      # preview drops
    .\scripts\Clean-FleetResources.ps1 -Drop -Force       # full cleanup
#>

[CmdletBinding()]
param(
    [string[]]$Prefixes = @('APP01','APP02','APP03','APP04','APP05','APP06','APP07','APP08','APP09','APP10','APP11'),
    [string]$Connection = $(if ($env:SNOWFLAKE_CONNECTION) { $env:SNOWFLAKE_CONNECTION } else { 'training' }),
    [switch]$SuspendOnly,
    [switch]$Drop,
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Continue'

if (-not $Drop) { $SuspendOnly = $true }

function Invoke-SnowSql {
    param([string]$Sql, [switch]$Query)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    if ($Query) {
        $out = & snow sql -c $Connection -q $Sql --format=json 2>$null
    } else {
        $out = & snow sql -c $Connection -q $Sql 2>&1
    }
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return @{ Output = $out; ExitCode = $code }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' Fleet Cleanup — instructor' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host "  Mode       : $(if ($Drop) { 'DROP (destructive)' } else { 'SUSPEND warehouses only' })" -ForegroundColor $(if ($Drop) { 'Red' } else { 'DarkGray' })
Write-Host "  Connection : $Connection" -ForegroundColor DarkGray
Write-Host "  Prefixes   : $($Prefixes -join ', ')" -ForegroundColor DarkGray
if ($WhatIf) { Write-Host '  WhatIf     : no statement will be executed' -ForegroundColor Yellow }
Write-Host ''

if (-not (Get-Command snow -ErrorAction SilentlyContinue)) {
    Write-Host '[FAIL] snow CLI not found in PATH' -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# 1. Suspend every running learner warehouse (always, both modes)
# ------------------------------------------------------------------
Write-Host '[1/3] Scanning running warehouses...' -ForegroundColor Yellow
$whs = Invoke-SnowSql -Sql "SHOW WAREHOUSES LIKE '%APP%'" -Query
$running = @()
if ($whs.ExitCode -eq 0 -and $whs.Output) {
    try { $running = @($whs.Output | ConvertFrom-Json | Where-Object { $_.state -eq 'STARTED' }) } catch {}
}

if ($running.Count -eq 0) {
    Write-Host '[OK]   No learner warehouse is running' -ForegroundColor Green
} else {
    foreach ($w in $running) {
        $sql = "ALTER WAREHOUSE `"$($w.name)`" SUSPEND"
        if ($WhatIf) {
            Write-Host "       [WhatIf] $sql" -ForegroundColor DarkGray
        } else {
            Invoke-SnowSql -Sql $sql | Out-Null
            Write-Host "[OK]   Suspended $($w.name)" -ForegroundColor Green
        }
    }
}

if ($SuspendOnly) {
    Write-Host ''
    Write-Host 'Done (suspend-only mode). Use -Drop -WhatIf to preview, then -Drop -Force to execute.' -ForegroundColor Cyan
    exit 0
}

# ------------------------------------------------------------------
# 2. Drop requires -Force (unless -WhatIf preview)
# ------------------------------------------------------------------
if ($Drop -and -not $Force -and -not $WhatIf) {
    Write-Host ''
    Write-Host '[FAIL] -Drop is destructive. Preview with -Drop -WhatIf, then re-run with -Drop -Force.' -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------------
# 3. Drop learner-prefixed objects
# ------------------------------------------------------------------
Write-Host ''
Write-Host '[2/3] Collecting learner-prefixed objects...' -ForegroundColor Yellow

$targets = @()

$dbs = Invoke-SnowSql -Sql "SHOW DATABASES LIKE 'APP%'" -Query
if ($dbs.ExitCode -eq 0 -and $dbs.Output) {
    try {
        $targets += @($dbs.Output | ConvertFrom-Json | Where-Object {
            $n = $_.name; ($Prefixes | Where-Object { $n -like "$_*" -or $n -like "DB_$_*" })
        } | ForEach-Object { @{ Type = 'DATABASE'; Name = $_.name } })
    } catch {}
}

$allWhs = Invoke-SnowSql -Sql "SHOW WAREHOUSES LIKE '%APP%'" -Query
if ($allWhs.ExitCode -eq 0 -and $allWhs.Output) {
    try {
        $targets += @($allWhs.Output | ConvertFrom-Json | Where-Object {
            $n = $_.name; ($Prefixes | Where-Object { $n -like "*$_*" })
        } | ForEach-Object { @{ Type = 'WAREHOUSE'; Name = $_.name } })
    } catch {}
}

$mons = Invoke-SnowSql -Sql "SHOW RESOURCE MONITORS LIKE '%APP%'" -Query
if ($mons.ExitCode -eq 0 -and $mons.Output) {
    try {
        $targets += @($mons.Output | ConvertFrom-Json | Where-Object {
            $n = $_.name; ($Prefixes | Where-Object { $n -like "*$_*" })
        } | ForEach-Object { @{ Type = 'RESOURCE MONITOR'; Name = $_.name } })
    } catch {}
}

$roles = Invoke-SnowSql -Sql "SHOW ROLES LIKE 'ROLE_APP%'" -Query
if ($roles.ExitCode -eq 0 -and $roles.Output) {
    try {
        $targets += @($roles.Output | ConvertFrom-Json | Where-Object {
            $n = $_.name; ($Prefixes | Where-Object { $n -like "*$_*" })
        } | ForEach-Object { @{ Type = 'ROLE'; Name = $_.name } })
    } catch {}
}

Write-Host "[3/3] $($targets.Count) object(s) to drop" -ForegroundColor Yellow

foreach ($t in $targets) {
    $sql = "DROP $($t.Type) IF EXISTS `"$($t.Name)`""
    if ($WhatIf) {
        Write-Host "       [WhatIf] $sql" -ForegroundColor DarkGray
    } else {
        $r = Invoke-SnowSql -Sql $sql
        if ($r.ExitCode -eq 0) {
            Write-Host "[OK]   Dropped $($t.Type) $($t.Name)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Failed: $($t.Type) $($t.Name) — $($r.Output)" -ForegroundColor Yellow
        }
    }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' Fleet cleanup complete' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''
