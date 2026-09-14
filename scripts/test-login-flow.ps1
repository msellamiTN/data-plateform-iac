$projectRoot = 'C:\Data2AI-Labs\data-platform'
$localSpFile = Join-Path $projectRoot 'secrets\shared-sp.txt'
$localPatFile = Join-Path $projectRoot 'secrets\snowflake_pat.txt'

Write-Output "=== Checking secrets files ==="
Write-Output "shared-sp.txt exists: $(Test-Path $localSpFile)"
Write-Output "snowflake_pat.txt exists: $(Test-Path $localPatFile)"

if (Test-Path $localSpFile) {
    $content = Get-Content $localSpFile -Raw
    Write-Output "shared-sp.txt content length: $($content.Length)"
    Write-Output "shared-sp.txt first 30 chars: $($content.Substring(0, [Math]::Min(30, $content.Length)))"
}

if (Test-Path $localPatFile) {
    $content = Get-Content $localPatFile -Raw
    Write-Output "snowflake_pat.txt content length: $($content.Length)"
}

Write-Output ""
Write-Output "=== Checking MI login ==="
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$miResult = & az login --identity --output none 2>&1
$miExit = $LASTEXITCODE
$ErrorActionPreference = $prevEAP
Write-Output "MI login exit code: $miExit"
Write-Output "MI login output: $miResult"

if ($miExit -eq 0) {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $secretResult = & az keyvault secret show --vault-name kvdata2aitfsecretsmsn --name SnowflakePAT --query value -o tsv 2>&1
    $secretExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
    Write-Output "KV secret fetch exit code: $secretExit"
    Write-Output "KV secret fetch result length: $($secretResult.ToString().Length)"
    & az logout 2>&1 | Out-Null
}

Write-Output ""
Write-Output "=== Simulating Learner-Login flow ==="
$hasLocalSecrets = (Test-Path $localSpFile) -and (Test-Path $localPatFile)
Write-Output "hasLocalSecrets: $hasLocalSecrets"
Write-Output "kvFirstSuccess would be: false (MI fails or KV fetch fails)"
Write-Output "Would skip browser login: $hasLocalSecrets"
