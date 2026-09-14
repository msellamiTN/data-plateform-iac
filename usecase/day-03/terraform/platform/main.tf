# ── Étape 1 : moved — renommer sans détruire ─────────────
# "access" (J2) devient module.mes_roles...this — même objet, nouvelle adresse
moved {
  from = snowflake_account_role.access
  to   = module.mes_roles.snowflake_account_role.this
}

# ── Étape 2 : import — adopter l'objet legacy ────────────
# terraform import snowflake_warehouse.legacy WH_APP01_LEGACY
resource "snowflake_warehouse" "legacy" {
  name           = "WH_${var.learner_prefix}_LEGACY"
  comment        = "Warehouse legacy — adopté par import"
  warehouse_size = "X-SMALL"
}

# ── Étape 3 : module — j'appelle le code factorisé ───────
module "mes_roles" {
  source = "./modules/roles"

  roles          = var.roles
  learner_prefix = var.learner_prefix
  environment    = var.environment
  common_comment = local.common_comment
}

# ── Étape 4 : data — lire ce que je n'ai pas créé ────────
data "snowflake_database" "raw" {
  name = "APP04_RAW_DEV" # la database de l'équipe Data Eng
}
