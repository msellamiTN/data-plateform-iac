# Mon warehouse du Jour 1 — le nom vient maintenant du local
resource "snowflake_warehouse" "mon_wh" {
  name                = "WH_${var.learner_prefix}_INGEST_${var.environment}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = local.common_comment
}

# UN bloc → TROIS rôles. for_each boucle sur la map.
resource "snowflake_account_role" "access" {
  for_each = var.roles # ← la boucle

  # each.key   = "raw_reader"     (la clé de la map)
  # each.value = { suffix = "RAW_READER", comment = "..." }
  name = "${var.learner_prefix}_${each.value.suffix}_${var.environment}"
  #        = APP01_RAW_READER_DEV
  comment = "${each.value.comment} | ${local.common_comment}"
}
