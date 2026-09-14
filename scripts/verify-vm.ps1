Set-Location C:\Data2AI-Labs\data-platform
$sp = Test-Path 'secrets\shared-sp.txt'
$pat = Test-Path 'secrets\snowflake_pat.txt'
$fix = Select-String -Path 'scripts\Learner-Login.ps1' -Pattern 'hasLocalSecrets' -Quiet
Write-Output "SP=$sp PAT=$pat FIX=$fix"
