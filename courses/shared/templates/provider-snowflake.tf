# provider.tf — comment Terraform se connecte à Snowflake.
# Le PAT est lu depuis snowflake-config.txt (jamais commité).

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = trimspace(file("${path.module}/snowflake-config.txt"))
}
