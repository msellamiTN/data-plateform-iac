resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M02_ETL_${var.environment}"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL pour le cycle de vie (M02)"
}
