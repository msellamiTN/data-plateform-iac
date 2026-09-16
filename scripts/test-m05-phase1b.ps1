$ErrorActionPreference = 'Continue'
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules

Write-Output "=== terraform validate ==="
& terraform validate 2>&1

Write-Output ""
Write-Output "=== terraform plan ==="
& terraform plan -out m05.tfplan 2>&1

Write-Output ""
Write-Output "=== terraform apply ==="
& terraform apply m05.tfplan 2>&1

Write-Output ""
Write-Output "=== Verify in Snowflake ==="
& snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M05_RAW_DEV'" 2>&1
& snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01_M05_ETL_DEV'" 2>&1

Write-Output ""
Write-Output "=== M05 PHASE 1 COMPLETE ==="
