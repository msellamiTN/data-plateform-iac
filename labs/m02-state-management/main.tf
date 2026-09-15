# ==============================================================================
# Lab M02 — State Management (State local puis migration backend Azure Blob)
# ==============================================================================
# Objectif : Déployer l'infrastructure, inspecter le state, puis migrer vers
# le backend distant sécurisé et observer le locking.
# ==============================================================================

# TODO : Déclarer la database de state management
# resource "snowflake_database" "raw" {
#   name                        = "${var.learner_prefix}_M02_RAW_${var.environment}"
#   comment                     = "Managed by Terraform | M02 State Management"
#   data_retention_time_in_days = 1
# }

# TODO : Déclarer le schema
# resource "snowflake_schema" "ingestion" {
#   database = snowflake_database.raw.name
#   name     = "INGESTION"
# }

# TODO : Déclarer le warehouse FinOps
# resource "snowflake_warehouse" "etl" {
#   name                = "WH_${var.learner_prefix}_M02_ETL_${var.environment}"
#   warehouse_size      = "X-SMALL"
#   auto_suspend        = 60
#   auto_resume         = true
#   initially_suspended = true
# }
