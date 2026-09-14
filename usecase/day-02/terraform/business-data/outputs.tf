# Ce que mon projet EXPOSE aux autres.

output "database_name" {
  description = "Ma database métier"
  value       = snowflake_database.ma_db.name
}

output "schema_name" {
  description = "Mon schema"
  value       = snowflake_schema.mon_schema.name
}

output "table_names" {
  description = "Toutes mes tables — clé → nom réel"
  value       = { for k, t in snowflake_table.collection : k => t.name }
}
