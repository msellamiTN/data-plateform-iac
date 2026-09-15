# ==============================================================================
# Lab M01 — Premier projet IaC Snowflake
# ==============================================================================
# Objectif : Déclarer 3 ressources Snowflake fondamentales en HCL.
# 1. snowflake_database   (base de données de votre zone)
# 2. snowflake_schema     (schéma technique rattaché à la base)
# 3. snowflake_warehouse  (entrepôt virtuel de calcul avec garde-fous FinOps)
# ==============================================================================

# ------------------------------------------------------------------------------
# Étape 1 : Base de données
# ------------------------------------------------------------------------------
# TODO : Déclarer la ressource snowflake_database "raw"
# resource "snowflake_database" "raw" {
#   name                        = "${var.learner_prefix}_RAW_${var.environment}"
#   comment                     = "Managed by Terraform for ${var.learner_prefix}"
#   data_retention_time_in_days = 1
# }

# ------------------------------------------------------------------------------
# Étape 2 : Schéma (Dépendance implicite vers la base)
# ------------------------------------------------------------------------------
# TODO : Déclarer la ressource snowflake_schema "ingestion"
# resource "snowflake_schema" "ingestion" {
#   database = snowflake_database.raw.name
#   name     = "INGESTION"
#   comment  = "Schema d'ingestion technique"
# }

# ------------------------------------------------------------------------------
# Étape 3 : Entrepôt virtuel de calcul (FinOps : X-Small, auto-suspend 60s)
# ------------------------------------------------------------------------------
# TODO : Déclarer la ressource snowflake_warehouse "etl"
# resource "snowflake_warehouse" "etl" {
#   name                = "WH_${var.learner_prefix}_ETL_${var.environment}"
#   comment             = "Warehouse de traitement ETL"
#   warehouse_size      = var.warehouse_size
#   auto_suspend        = 60
#   auto_resume         = true
#   initially_suspended = true
# }
