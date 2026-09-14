# Ce que mon projet EXPOSE aux autres.

output "database_name" {
  description = "Mon mart"
  value       = snowflake_database.mon_mart.name
}

output "table_names" {
  description = "Toutes mes tables — via le module"
  value       = module.mes_tables.table_names
}

output "database_lue" {
  description = "La database Business Data que j'ai lue (sans la gérer)"
  value       = data.snowflake_database.customer.name
}
