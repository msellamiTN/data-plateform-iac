# Ce que mon projet EXPOSE aux autres.

output "database_name" {
  description = "Ma database métier"
  value       = snowflake_database.ma_db.name
}

output "table_names" {
  description = "Toutes mes tables — via le module"
  value       = module.mes_tables.table_names
}

output "database_lue" {
  description = "La database Data Eng que j'ai lue (sans la gérer)"
  value       = data.snowflake_database.raw.name
}
