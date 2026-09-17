resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M03_ETL_${var.environment}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.warehouse_auto_suspend
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL paramétré (M03) pour ${var.learner_prefix}"

  lifecycle {
    precondition {
      condition     = var.environment == "PROD" ? var.warehouse_auto_suspend <= 120 : true
      error_message = "En PROD, auto_suspend doit être <= 120 s (FinOps)."
    }
  }
}

resource "snowflake_database" "raw" {
  name    = "${var.learner_prefix}_M03_${upper(var.database_name)}_${var.environment}"
  comment = "Database ${var.database_name} paramétrée (M03) pour ${var.learner_prefix}"
}
