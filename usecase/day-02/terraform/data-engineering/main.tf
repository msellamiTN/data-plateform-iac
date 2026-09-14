# Mes objets du Jour 1 — commentaires via le local
resource "snowflake_database" "ma_db" {
  name                        = "${var.learner_prefix}_RAW_${var.environment}"
  comment                     = local.common_comment
  data_retention_time_in_days = 1
}

resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.ma_db.name
  name     = "LANDING"
  comment  = local.common_comment
}

# UN bloc → TROIS tables. for_each boucle sur la map.
resource "snowflake_table" "collection" {
  for_each = var.tables # ← la boucle

  database = snowflake_database.ma_db.name
  schema   = snowflake_schema.mon_schema.name
  name     = each.value.name # ← le nom vient de la map
  comment  = "${each.value.comment} | ${local.common_comment}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "PAYLOAD"
    type = "VARIANT"
  }
}
