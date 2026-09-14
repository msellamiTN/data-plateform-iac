# Le même for_each qu'hier — mais les valeurs viennent du module
resource "snowflake_table" "this" {
  for_each = var.tables
  database = var.database
  schema   = var.schema
  name     = each.value.name
  comment  = "${each.value.comment} | ${var.common_comment}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "METRIC"
    type = "VARCHAR(255)"
  }
}
