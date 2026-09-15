# ==============================================================================
# Lab M13 — FinOps as Code & Observabilité
# ==============================================================================
# Objectif : Déclarer un Resource Monitor plafonnant la consommation de crédits
# et appliquer les tags de gouvernance des coûts sur les ressources.
# ==============================================================================

# TODO : Déclarer un Resource Monitor
# resource "snowflake_resource_monitor" "training_monitor" {
#   name         = "RM_${var.learner_prefix}_${var.environment}"
#   credit_quota = 5
#   frequency    = "MONTHLY"
#
#   notify_triggers            = [75, 90]
#   suspend_trigger            = 100
#   suspend_immediate_trigger  = 110
# }
