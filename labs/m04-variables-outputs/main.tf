# ==============================================================================
# Lab M04 — Variables, Locals & Outputs
# ==============================================================================
# Objectif : Déclarer les ressources Snowflake en utilisant les noms calculés
# depuis locals.tf et les variables validées depuis variables.tf.
# ==============================================================================

# TODO : Déclarer la database en utilisant local.database_name
# resource "snowflake_database" "raw" {
#   name                        = local.database_name
#   comment                     = local.common_comment
#   data_retention_time_in_days = 1
# }

# TODO : Déclarer le schema en utilisant local.schema_name
# resource "snowflake_schema" "ingestion" {
#   database = snowflake_database.raw.name
#   name     = local.schema_name
#   comment  = local.common_comment
# }

# TODO : Déclarer le warehouse en utilisant local.warehouse_name
# resource "snowflake_warehouse" "etl" {
#   name                = local.warehouse_name
#   comment             = local.common_comment
#   warehouse_size      = var.warehouse_size
#   auto_suspend        = 60
#   auto_resume         = true
#   initially_suspended = true
# }
