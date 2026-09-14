$ErrorActionPreference = 'Continue'
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules

Write-Output "=== Adding lab variables to variables.tf ==="
$extraVars = @'

variable "warehouse_size" {
  type        = string
  description = "Warehouse size"
  default     = "X-SMALL"

  validation {
    condition     = contains(["X-SMALL", "SMALL", "MEDIUM"], var.warehouse_size)
    error_message = "warehouse_size must be X-SMALL, SMALL or MEDIUM."
  }
}

variable "data_retention_days" {
  type        = number
  description = "Time travel retention in days"
  default     = 1

  validation {
    condition     = var.data_retention_days >= 0 && var.data_retention_days <= 90
    error_message = "data_retention_days must be between 0 and 90."
  }
}

variable "auto_suspend_seconds" {
  type        = number
  description = "Warehouse auto-suspend in seconds"
  default     = 60

  validation {
    condition     = var.auto_suspend_seconds >= 60 && var.auto_suspend_seconds <= 3600
    error_message = "auto_suspend_seconds must be between 60 and 3600."
  }
}
'@
Add-Content -Path variables.tf -Value $extraVars -Encoding UTF8

Write-Output "=== Fix outputs.tf (typo: warehouse not arehouse) ==="
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
  value       = snowflake_warehouse.etl.name
  description = "ETL warehouse name"
}
'@
Set-Content -Path outputs.tf -Value $outputsContent -Encoding UTF8

Write-Output "=== terraform fmt ==="
& terraform fmt 2>&1

Write-Output ""
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
