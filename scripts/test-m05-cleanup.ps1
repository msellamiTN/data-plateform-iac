$ErrorActionPreference = 'Continue'
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules

Write-Output "=== M05 Cleanup: terraform destroy ==="
& terraform destroy -auto-approve 2>&1

Write-Output ""
Write-Output "=== Verify cleanup ==="
& snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M05_RAW_DEV'" 2>&1
& snow sql -c training -q "SHOW DATABASES LIKE 'APP01SAL_M05_RAW_DEV'" 2>&1
& snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01_M05_ETL_DEV'" 2>&1
& snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01SAL_M05_ETL_DEV'" 2>&1

Write-Output ""
Write-Output "=== CLEANUP COMPLETE ==="
