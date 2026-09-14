# Mon warehouse — le même que celui créé à la main dans Snowsight.
# Chaque argument correspond à un champ du formulaire Snowsight.

resource "snowflake_warehouse" "mon_wh" {
  # name = le champ "Name" du formulaire — mais calculé, jamais en dur
  name = "WH_${var.learner_prefix}_INGEST_${var.environment}"
  #            ↑ APP01              ↑ INGEST        ↑ DEV
  #            = WH_APP01_INGEST_DEV

  warehouse_size      = var.warehouse_size # le champ "Size"
  auto_suspend        = 60                 # "Auto Suspend" : 60 secondes
  auto_resume         = true               # "Auto Resume" coché
  initially_suspended = true               # "Initially Suspended" coché
  comment             = "Managed by Terraform | Training | ${var.learner_prefix}"
}
