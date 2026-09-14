# Quelle version de Terraform et quel provider on utilise.
# Les "=" figent les versions : tout le monde a exactement le même moteur.
terraform {
  required_version = "= 1.14.5"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake" # le provider officiel Snowflake
      version = "= 2.14.0"
    }
  }
}
