# Les ENTRÉES du projet. Tout ce qui peut changer est une variable.

variable "snowflake_organization" {
  type        = string
  description = "Organisation Snowflake (fournie)"
}

variable "snowflake_account" {
  type        = string
  description = "Compte Snowflake (fourni)"
}

variable "snowflake_user" {
  type        = string
  description = "Utilisateur Snowflake (fourni)"
}

variable "snowflake_token" {
  type        = string
  description = "PAT — lu depuis secrets/, ne rien mettre ici"
  sensitive   = true
  default     = ""
}

variable "learner_prefix" {
  type        = string
  description = "Votre préfixe unique (ex: APP01) — déjà assigné"

  validation {
    condition     = can(regex("^[A-Z0-9_]{2,12}$", var.learner_prefix))
    error_message = "learner_prefix must be 2-12 uppercase alphanumeric characters or underscore."
  }
}

variable "environment" {
  type        = string
  description = "Environnement de déploiement"
  default     = "DEV"

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "environment must be DEV, UAT or PROD."
  }
}

variable "warehouse_size" {
  type        = string
  description = "Taille du warehouse de formation"
  default     = "X-SMALL"

  validation {
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "Training warehouses must be X-SMALL or SMALL."
  }
}

# La liste de mes tables — une map : clé → objet
variable "tables" {
  type = map(object({
    name    = string # le nom réel de la table
    comment = string # la description métier
  }))
  description = "Mes tables"
}
