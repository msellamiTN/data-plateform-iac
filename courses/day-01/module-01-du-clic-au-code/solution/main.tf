resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M01_ETL_${var.environment}"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL créé par Terraform pour ${var.learner_prefix}"
}
