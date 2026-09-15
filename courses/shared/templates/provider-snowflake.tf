# provider.tf — comment Terraform se connecte à Snowflake.
# Le PAT est lu depuis secrets/snowflake_pat.txt (jamais commité).
# Si le fichier manque, fallback sur TF_VAR_snowflake_token.

locals {
  pat_file        = "${path.module}/../../secrets/snowflake_pat.txt"
  snowflake_token = try(trim(file(local.pat_file), "\n\r"), var.snowflake_token, "")
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = local.snowflake_token
}
