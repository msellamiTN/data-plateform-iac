variable "snowflake_organization" {
  description = "Organisation Snowflake (ex: ABCDEFG)"
  type        = string
}

variable "snowflake_account" {
  description = "Nom du compte Snowflake (ex: XY12345)"
  type        = string
}

variable "snowflake_user" {
  description = "Utilisateur Snowflake"
  type        = string
}

variable "snowflake_role" {
  description = "Rôle utilisé par Terraform"
  type        = string
  default     = "SYSADMIN"
}
