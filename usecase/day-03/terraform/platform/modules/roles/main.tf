# Le même for_each qu'hier — mais les valeurs viennent du module
resource "snowflake_account_role" "this" {
  for_each = var.roles
  name     = "${var.learner_prefix}_${each.value.suffix}_${var.environment}"
  comment  = "${each.value.comment} | ${var.common_comment}"
}
