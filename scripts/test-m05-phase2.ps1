$ErrorActionPreference = 'Continue'
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules

Write-Output "=== PHASE 2: Extract module ==="

Write-Output "=== Create module directory ==="
New-Item -ItemType Directory -Force -Path "modules/landing-zone" | Out-Null

Write-Output "=== Create modules/landing-zone/variables.tf ==="
$modVars = @'
variable "learner_prefix" {
  type        = string
  description = "Unique uppercase prefix assigned to the learner"

  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2,9}$", var.learner_prefix))
    error_message = "learner_prefix must contain 3-10 uppercase letters or digits."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "DEV"

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "environment must be DEV, UAT or PROD."
  }
}

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
Set-Content -Path "modules/landing-zone/variables.tf" -Value $modVars -Encoding UTF8

Write-Output "=== Create modules/landing-zone/main.tf ==="
$modMain = @'
locals {
  database_name  = "${var.learner_prefix}_M05_RAW_${var.environment}"
  schema_name    = "INGESTION"
  warehouse_name = "WH_${var.learner_prefix}_M05_ETL_${var.environment}"
  common_comment = "Managed by Terraform | Landing Zone | ${var.learner_prefix}"
}

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
Set-Content -Path "modules/landing-zone/main.tf" -Value $modMain -Encoding UTF8

Write-Output "=== Create modules/landing-zone/outputs.tf ==="
$modOutputs = @'
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
Set-Content -Path "modules/landing-zone/outputs.tf" -Value $modOutputs -Encoding UTF8

Write-Output "=== Create modules/landing-zone/versions.tf ==="
$modVersions = @'
terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.14.0"
    }
  }
}
'@
Set-Content -Path "modules/landing-zone/versions.tf" -Value $modVersions -Encoding UTF8

Write-Output "=== Init module ==="
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules\modules\landing-zone
& terraform init 2>&1
& terraform fmt 2>&1
& terraform validate 2>&1

Write-Output ""
Write-Output "=== PHASE 3: Call module from root main.tf ==="
Set-Location C:\Data2AI-Labs\data-platform\labs\m05-modules

Write-Output "=== Rewrite main.tf with module call + moved blocks ==="
$rootMain = @'
moved {
  from = snowflake_database.raw
  to   = module.landing_zone.snowflake_database.raw
}

moved {
  from = snowflake_schema.ingestion
  to   = module.landing_zone.snowflake_schema.ingestion
}

moved {
  from = snowflake_warehouse.etl
  to   = module.landing_zone.snowflake_warehouse.etl
}

module "landing_zone" {
  source               = "./modules/landing-zone"
  learner_prefix       = var.learner_prefix
  environment          = var.environment
  warehouse_size       = var.warehouse_size
  data_retention_days  = var.data_retention_days
  auto_suspend_seconds = var.auto_suspend_seconds
}

module "landing_zone_sales" {
  source               = "./modules/landing-zone"
  learner_prefix       = "${var.learner_prefix}SAL"
  environment          = var.environment
  warehouse_size       = "X-SMALL"
  data_retention_days  = var.data_retention_days
  auto_suspend_seconds = var.auto_suspend_seconds
}
'@
Set-Content -Path main.tf -Value $rootMain -Encoding UTF8

Write-Output "=== Remove locals.tf ==="
Remove-Item locals.tf -Force -ErrorAction SilentlyContinue

Write-Output "=== Rewrite outputs.tf ==="
$rootOutputs = @'
output "database_name" {
  value       = module.landing_zone.database_name
  description = "RAW database name"
}

output "schema_name" {
  value       = module.landing_zone.schema_name
  description = "Ingestion schema name"
}

output "warehouse_name" {
  value       = module.landing_zone.warehouse_name
  description = "ETL warehouse name"
}

output "resource_summary" {
  value = {
    database  = module.landing_zone.database_name
    schema    = module.landing_zone.schema_name
    warehouse = module.landing_zone.warehouse_name
  }
}

output "sales_database_name" {
  value       = module.landing_zone_sales.database_name
  description = "Sales RAW database name"
}
'@
Set-Content -Path outputs.tf -Value $rootOutputs -Encoding UTF8

Write-Output "=== terraform fmt + init ==="
& terraform fmt 2>&1
& terraform init 2>&1

Write-Output ""
Write-Output "=== terraform plan (expect: 3 to add for Sales, 0 changes for existing) ==="
& terraform plan -out m05-phase3.tfplan 2>&1

Write-Output ""
Write-Output "=== terraform apply ==="
& terraform apply m05-phase3.tfplan 2>&1

Write-Output ""
Write-Output "=== Verify Sales resources in Snowflake ==="
& snow sql -c training -q "SHOW DATABASES LIKE 'APP01SAL_M05_RAW_DEV'" 2>&1
& snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01SAL_M05_ETL_DEV'" 2>&1

Write-Output ""
Write-Output "=== M05 PHASE 2+3 COMPLETE ==="
