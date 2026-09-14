# Mes 3 objets — les mêmes que ceux créés à la main dans Snowsight.
# L'ordre compte : database → schema → table (chaîne de dépendances).

# 1. La database — le conteneur de tout
resource "snowflake_database" "ma_db" {
  name = "${var.learner_prefix}_CUSTOMER_${var.environment}"
  #      ↑ APP06                  ↑ DEV
  #      = APP06_CUSTOMER_DEV
  comment                     = "Managed by Terraform | Training | ${var.learner_prefix}"
  data_retention_time_in_days = 1 # FinOps : 1 jour de rétention suffit en formation
}

# 2. Le schema — vit DANS la database
resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.ma_db.name # ← référence, pas de nom en dur
  name     = "BUSINESS"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"
}

# 3. La table — vit DANS le schema
resource "snowflake_table" "ma_table" {
  database = snowflake_database.ma_db.name
  schema   = snowflake_schema.mon_schema.name # ← chaîne de dépendances
  name     = "CUSTOMER"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "LABEL"
    type = "VARCHAR(255)"
  }
}
