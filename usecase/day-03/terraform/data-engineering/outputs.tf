# Ce que mon projet EXPOSE aux autres.

output "database_name" {
  description = "Ma database"
  value       = snowflake_database.ma_db.name
}

output "table_names" {
  description = "Toutes mes tables — via le module"
  value       = module.mes_tables.table_names
}

output "warehouse_lu" {
  description = "Le warehouse Platform que j'ai lu (sans le gérer)"
  value       = data.snowflake_warehouses.ingest.warehouses[0].show_output[0].name
}
