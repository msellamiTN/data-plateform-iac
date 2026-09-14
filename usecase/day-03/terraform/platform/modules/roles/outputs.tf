output "role_names" {
  value = { for k, r in snowflake_account_role.this : k => r.name }
}
