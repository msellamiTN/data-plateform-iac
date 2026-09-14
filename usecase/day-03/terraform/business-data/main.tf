# ── Mes objets du Jour 2 — database + schema ─────────────
resource "snowflake_database" "ma_db" {
  name                        = "${var.learner_prefix}_CUSTOMER_${var.environment}"
  comment                     = local.common_comment
  data_retention_time_in_days = 1
}

resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.ma_db.name
  name     = "BUSINESS"
  comment  = local.common_comment
}

# ── Étape 1 : moved — renommer sans détruire ─────────────
# "collection" (J2) devient module.mes_tables...this — même objet, nouvelle adresse
moved {
  from = snowflake_table.collection
  to   = module.mes_tables.snowflake_table.this
}

# ── Étape 2 : import — adopter l'objet legacy ────────────
# terraform import snowflake_database.legacy APP06_LEGACY
resource "snowflake_database" "legacy" {
  name    = "${var.learner_prefix}_LEGACY"
  comment = "Database legacy — adoptée par import"
}

# ── Étape 3 : module — j'appelle le code factorisé ───────
module "mes_tables" {
  source = "./modules/tables"

  tables         = var.tables
  database       = snowflake_database.ma_db.name
  schema         = snowflake_schema.mon_schema.name
  common_comment = local.common_comment
}

# ── Étape 4 : data — lire ce que je n'ai pas créé ────────
data "snowflake_database" "raw" {
  name = "APP04_RAW_DEV" # la database de l'équipe Data Eng
}
