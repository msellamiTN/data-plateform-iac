#requires -version 5.1
<#
.SYNOPSIS
    Pre-flight check before running terraform plan.
    Verifies that the PAT file exists and TF_VAR_snowflake_token is set.

.DESCRIPTION
    Run this from any terraform root (labs/mXX-*, environments/dev/) before terraform plan.
    It checks:
    1. Current directory is a Terraform root (has .tf files)
    2. secrets/snowflake_pat.txt exists (two levels up)
    3. TF_VAR_snowflake_token is set OR the PAT file is readable
    4. LEARNER_PREFIX is set
    5. ARM_* variables (warn-only — required only for Day 2 remote backend / Day 4+ labs)

    If all checks pass, terraform plan will not prompt for var.snowflake_token.

.EXAMPLE
    .\scripts\Test-TerraformReady.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

$allOk = $true

function Check-Ok { param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Check-Fail { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red; $script:allOk = $false }
function Check-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' Terraform Pre-Flight Check' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

# 1. Check current directory has .tf files
$tfFiles = Get-ChildItem -Path '.' -Filter '*.tf' -ErrorAction SilentlyContinue
if ($tfFiles) {
    Check-Ok "Terraform files found in current directory ($($tfFiles.Count) .tf files)"
} else {
    Check-Fail "No .tf files in current directory. Run from a lab root (labs/mXX-*) or environments/dev/."
}

# 2. Check PAT file exists
$patFile = Join-Path $projectRoot 'secrets\snowflake_pat.txt'
if (Test-Path $patFile) {
    $patLen = (Get-Content $patFile -Raw).Trim().Length
    if ($patLen -gt 50) {
        Check-Ok "PAT file found (secrets/snowflake_pat.txt, $patLen chars)"
    } else {
        Check-Fail "PAT file exists but is too short ($patLen chars). Re-run New-SnowflakeConnection.ps1."
    }
} else {
    Check-Fail "PAT file not found at $patFile"
    Write-Host "       Run: .\scripts\New-SnowflakeConnection.ps1" -ForegroundColor DarkGray
}

# 3. Check TF_VAR_snowflake_token (optional - provider.tf reads file directly now)
if ($env:TF_VAR_snowflake_token) {
    Check-Ok "TF_VAR_snowflake_token is set (env var)"
} else {
    if (Test-Path $patFile) {
        Check-Warn "TF_VAR_snowflake_token not set (OK - provider.tf reads PAT file directly)"
    } else {
        Check-Fail "TF_VAR_snowflake_token not set and PAT file missing"
    }
}

# 4. Check LEARNER_PREFIX
if ($env:LEARNER_PREFIX) {
    Check-Ok "LEARNER_PREFIX = $env:LEARNER_PREFIX"
} else {
    Check-Fail "LEARNER_PREFIX not set. Run: .\scripts\Learner-Login.ps1 -LearnerPrefix APP01 -SnowflakeOnly"
}

# 5. Check ARM_SUBSCRIPTION_ID (optionnel : requis uniquement pour les labs avancés Day 4+)
if ($env:ARM_SUBSCRIPTION_ID) {
    Check-Ok "ARM_SUBSCRIPTION_ID is set"
} else {
    Check-Warn "ARM_SUBSCRIPTION_ID is not set (OK for Snowflake-only labs — required for Day 4+ remote backend)"
}

# 6. Check ARM_CLIENT_ID (optionnel : requis uniquement pour les labs avancés Day 4+)
if ($env:ARM_CLIENT_ID) {
    Check-Ok "ARM_CLIENT_ID is set"
} else {
    Check-Warn "ARM_CLIENT_ID is not set (OK for Snowflake-only labs — required for Day 4+ remote backend)"
}

# 6. Check terraform is available
# Try terraform in PATH, then fall back to .data2ai\bin\terraform.exe
$tfExe = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $tfExe) {
    $localTf = Join-Path $HOME '.data2ai\bin\terraform.exe'
    if (Test-Path $localTf) {
        $env:PATH = "$HOME\.data2ai\bin;$env:PATH"
        $tfExe = Get-Command terraform -ErrorAction SilentlyContinue
    }
}

if ($tfExe) {
    $tfOutput = & terraform version 2>&1
    $tfExit = $LASTEXITCODE
    $tfVersion = ($tfOutput | Select-Object -First 1).ToString().Trim()
    if ($tfExit -eq 0 -and $tfVersion) {
        Check-Ok "Terraform: $tfVersion"
    } else {
        Check-Fail "Terraform found but 'terraform version' failed (exit $tfExit)"
        Write-Host "       Output: $tfVersion" -ForegroundColor DarkGray
        Write-Host "       Try: & `"$HOME\.data2ai\bin\terraform.exe`" version" -ForegroundColor DarkGray
    }
} else {
    Check-Fail "Terraform not found in PATH or .data2ai\bin"
    Write-Host "       Run: .\scripts\Install-Tools.ps1" -ForegroundColor DarkGray
}

# 7. Check terraform init was run
if (Test-Path '.terraform') {
    Check-Ok "terraform init done (.terraform/ exists)"
} else {
    Check-Warn "terraform init not run yet. Run: terraform init"
}

Write-Host ''
if ($allOk) {
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host ' READY for terraform plan' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next:' -ForegroundColor Cyan
    Write-Host '  terraform plan -out "m01.tfplan"' -ForegroundColor DarkGray
    Write-Host '  terraform show "m01.tfplan"' -ForegroundColor DarkGray
    Write-Host '  terraform apply "m01.tfplan"' -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ' NOT READY - fix FAIL items before terraform plan' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Common fixes:' -ForegroundColor Cyan
    Write-Host '  cd "$HOME\Data2AI-Labs\data-platform"' -ForegroundColor DarkGray
    Write-Host '  .\scripts\New-SnowflakeConnection.ps1' -ForegroundColor DarkGray
    Write-Host '  .\scripts\Learner-Login.ps1 -LearnerPrefix APP01 -SnowflakeOnly' -ForegroundColor DarkGray
    Write-Host '  cd labs\m01-iac-workflow' -ForegroundColor DarkGray
    Write-Host '  terraform init' -ForegroundColor DarkGray
    exit 1
}
