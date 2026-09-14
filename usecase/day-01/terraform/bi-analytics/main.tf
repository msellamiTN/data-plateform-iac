# Mes 3 objets — les mêmes que ceux créés à la main dans Snowsight.
# L'ordre compte : database → schema → table (chaîne de dépendances).

# 1. La database — mon mart
resource "snowflake_database" "mon_mart" {
  name = "${var.learner_prefix}_CUSTOMER_MART_${var.environment}"
  #      ↑ APP09                       ↑ DEV
  #      = APP09_CUSTOMER_MART_DEV
  comment                     = "Managed by Terraform | Training | ${var.learner_prefix}"
  data_retention_time_in_days = 1 # FinOps : 1 jour de rétention suffit en formation
}

# 2. Le schema — vit DANS la database
resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.mon_mart.name # ← référence, pas de nom en dur
  name     = "MART"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"
}

# 3. La table — vit DANS le schema
resource "snowflake_table" "ma_table" {
  database = snowflake_database.mon_mart.name
  schema   = snowflake_schema.mon_schema.name # ← chaîne de dépendances
  name     = "CUSTOMER_360"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "METRIC"
    type = "VARCHAR(255)"
  }
}
