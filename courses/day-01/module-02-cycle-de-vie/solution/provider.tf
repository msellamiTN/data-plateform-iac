provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = try(trimspace(file("${path.module}/../secrets/snowflake-pat.txt")), var.snowflake_token, "")
}
