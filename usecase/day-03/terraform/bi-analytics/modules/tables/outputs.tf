output "table_names" {
  value = { for k, t in snowflake_table.this : k => t.name }
}
