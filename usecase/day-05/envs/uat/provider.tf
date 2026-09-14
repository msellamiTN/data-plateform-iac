# Comment Terraform se connecte a Snowflake.
# Le token est injecte via la variable d'environnement TF_VAR_snowflake_token
# (Azure DevOps variable group) ou lue depuis Azure Key Vault a la main.
# Aucun secret n'est commit dans les fichiers .tf ou .tfvars.

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = var.snowflake_token

  preview_features_enabled = ["snowflake_table_resource"]
}
