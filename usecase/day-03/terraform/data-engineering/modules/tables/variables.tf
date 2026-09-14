# Ce que l'appelant doit fournir au module
variable "tables" {
  type = map(object({
    name    = string
    comment = string
  }))
}

variable "database" {
  type = string # la database cible
}

variable "schema" {
  type = string # le schema cible
}

variable "common_comment" {
  type = string
}
