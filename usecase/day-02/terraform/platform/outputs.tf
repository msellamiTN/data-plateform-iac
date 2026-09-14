# Ce que mon projet EXPOSE aux autres.
# terraform output les affiche ; un autre projet pourra les lire.

output "warehouse_name" {
  description = "Mon warehouse du Jour 1"
  value       = snowflake_warehouse.mon_wh.name
}

output "role_names" {
  description = "Tous mes rôles — clé → nom réel"
  value       = { for k, r in snowflake_account_role.access : k => r.name }
}
