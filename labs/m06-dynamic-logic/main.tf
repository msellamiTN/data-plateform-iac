# ==============================================================================
# Lab M06 — Logique Dynamique (for_each, maps & collections)
# ==============================================================================
# Objectif : Piloter la création de multiples schémas et warehouses à partir
# d'une map de métadonnées sans copier-coller de code.
# ==============================================================================

# TODO : Déclarer la création dynamique avec for_each
# resource "snowflake_schema" "dynamic_schemas" {
#   for_each = var.schemas
#
#   database = snowflake_database.raw.name
#   name     = each.key
#   comment  = each.value.comment
# }
