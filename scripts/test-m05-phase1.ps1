$ErrorActionPreference = 'Stop'
Set-Location C:\Data2AI-Labs\data-platform

Write-Output "=== STEP 1: Learner-Login ==="
& .\scripts\Learner-Login.ps1 -LearnerPrefix APP01 2>&1

Write-Output ""
Write-Output "=== STEP 2: Reset Lab M05 ==="
& .\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M05 2>&1

Write-Output ""
Write-Output "=== STEP 3: Test Terraform Ready ==="
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules
& ..\..\scripts\Test-TerraformReady.ps1 2>&1

Write-Output ""
Write-Output "=== STEP 4: Create terraform.tfvars ==="
Copy-Item terraform.tfvars.example terraform.tfvars -Force
$content = Get-Content terraform.tfvars -Raw
$content = $content -replace 'APP01', 'APP01'
Set-Content terraform.tfvars $content -Encoding UTF8

Write-Output ""
Write-Output "=== STEP 5: Create locals.tf ==="
$localsContent = @'
locals {
  database_name  = "${var.learner_prefix}_M05_RAW_${var.environment}"
  schema_name    = "INGESTION"
  warehouse_name = "WH_${var.learner_prefix}_M05_ETL_${var.environment}"
  common_comment = "Managed by Terraform | Landing Zone | ${var.learner_prefix}"
}
'@
Set-Content -Path locals.tf -Value $localsContent -Encoding UTF8

Write-Output "=== STEP 6: Create main.tf (direct resources) ==="
$mainContent = @'
resource "snowflake_database" "raw" {
  name                        = local.database_name
  comment                     = local.common_comment
  data_retention_time_in_days = var.data_retention_days
}

resource "snowflake_schema" "ingestion" {
  database = snowflake_database.raw.name
  name     = local.schema_name
  comment  = local.common_comment
}

resource "snowflake_warehouse" "etl" {
  name                = local.warehouse_name
  comment             = local.common_comment
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.auto_suspend_seconds
  auto_resume         = true
  initially_suspended = true
}
'@
Set-Content -Path main.tf -Value $mainContent -Encoding UTF8

Write-Output "=== STEP 7: Create outputs.tf ==="
$outputsContent = @'
output "database_name" {
  value       = snowflake_database.raw.name
  description = "RAW database name"
}

output "schema_name" {
  value       = snowflake_schema.ingestion.name
  description = "Ingestion schema name"
}

output "warehouse_name" {
  value       = snowflake_arehouse.etl.name
  description = "ETL warehouse name"
}
'@
Set-Content -Path outputs.tf -Value $outputsContent -Encoding UTF8

Write-Output "=== STEP 8: terraform fmt + init + validate ==="
& terraform fmt 2>&1
& terraform init 2>&1
& terraform validate 2>&1

Write-Output ""
Write-Output "=== STEP 9: terraform plan ==="
& terraform plan -out m05.tfplan 2>&1

Write-Output ""
Write-Output "=== STEP 10: terraform apply ==="
& terraform apply m05.tfplan 2>&1

Write-Output ""
Write-Output "=== STEP 11: Verify in Snowflake ==="
& snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M05_RAW_DEV'" 2>&1
& snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01_M05_ETL_DEV'" 2>&1

Write-Output ""
Write-Output "=== M05 PHASE 1 COMPLETE ==="
