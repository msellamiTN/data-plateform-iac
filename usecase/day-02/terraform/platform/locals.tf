# Les valeurs calculées UNE SEULE FOIS, réutilisées partout.
# local.xxx se lit comme var.xxx, mais ce n'est pas une entrée — c'est un calcul interne.

locals {
  # Le préfixe complet : "APP01_DEV" (utilisé pour les commentaires, pas les noms)
  prefix_env = "${var.learner_prefix}_${var.environment}"

  # Le commentaire standard de toutes mes ressources
  common_comment = "Managed by Terraform | Training | ${var.learner_prefix}"
}
