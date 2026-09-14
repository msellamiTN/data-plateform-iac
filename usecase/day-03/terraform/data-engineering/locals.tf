# Les valeurs calculées UNE SEULE FOIS, réutilisées partout.

locals {
  # Le préfixe complet : "APP04_DEV"
  prefix_env = "${var.learner_prefix}_${var.environment}"

  # Le commentaire standard de toutes mes ressources
  common_comment = "Managed by Terraform | Training | ${var.learner_prefix}"
}
