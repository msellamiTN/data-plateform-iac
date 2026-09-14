# Ce que mon projet EXPOSE aux autres.

output "role_names" {
  description = "Tous mes rôles — via le module"
  value       = module.mes_roles.role_names
}

output "database_lue" {
  description = "La database Data Eng que j'ai lue (sans la gérer)"
  value       = data.snowflake_database.raw.name
}
