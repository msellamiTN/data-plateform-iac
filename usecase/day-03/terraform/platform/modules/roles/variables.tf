# Ce que l'appelant doit fournir au module
variable "roles" {
  type = map(object({
    suffix  = string
    comment = string
  }))
}

variable "learner_prefix" {
  type = string # ex: "APP01"
}

variable "environment" {
  type = string # ex: "DEV"
}

variable "common_comment" {
  type = string
}
