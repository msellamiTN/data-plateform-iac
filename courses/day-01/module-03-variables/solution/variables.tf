variable "snowflake_organization" {
  description = "Identifiant d'organisation Snowflake (ex: ABCDEFG)."
  type        = string
}

variable "snowflake_account" {
  description = "Identifiant de compte Snowflake (ex: XY12345)."
  type        = string
}

variable "snowflake_user" {
  description = "Utilisateur Snowflake de l'apprenant (ex: APP01)."
  type        = string
}

variable "snowflake_role" {
  description = "Rôle utilisé par Terraform."
  type        = string
  default     = "SYSADMIN"
}

variable "snowflake_token" {
  description = "PAT Snowflake. Vide en J1-J3 (lu depuis le fichier)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "learner_prefix" {
  description = "Préfixe apprenant unique (APP01 à APP11)."
  type        = string
  validation {
    condition     = can(regex("^APP[0-9]{2}$", var.learner_prefix))
    error_message = "Le préfixe doit respecter le format APPxx (ex: APP01)."
  }
}

variable "environment" {
  description = "Environnement cible."
  type        = string
  default     = "DEV"
  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "L'environnement doit être DEV, UAT ou PROD."
  }
}

variable "warehouse_size" {
  description = "Taille du warehouse. X-SMALL ou SMALL uniquement (FinOps)."
  type        = string
  default     = "X-SMALL"
  validation {
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "warehouse_size doit être X-SMALL ou SMALL. Les tailles supérieures sont interdites en formation."
  }
}

variable "warehouse_auto_suspend" {
  description = "Délai d'auto-suspend en secondes (60 à 600)."
  type        = number
  default     = 60
  validation {
    condition     = var.warehouse_auto_suspend >= 60 && var.warehouse_auto_suspend <= 600
    error_message = "auto_suspend doit être entre 60 et 600 secondes."
  }
}

variable "database_name" {
  description = "Nom de la database (sans le préfixe). Ex: RAW, ANALYTICS."
  type        = string
  default     = "RAW"
}
