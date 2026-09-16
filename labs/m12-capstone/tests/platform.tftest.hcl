# ==============================================================================
# Lab M12 — Tests de la plateforme capstone (terraform test)
# ==============================================================================
# Lancez : terraform test
# command = plan => valide la logique sans rien deployer (zero cout).
# mock_provider remplace le provider Snowflake par des valeurs simulees :
# aucun credential reel n'est requis pour executer les tests.
#
# Le run "configuration_is_valid" fonctionne sur le squelette de depart.
# Quand vos ressources capstone existent, decommentez et adaptez le run
# "naming_convention" pour verifier vos conventions de nommage.
# ==============================================================================

mock_provider "snowflake" {}

# Smoke test : la configuration doit se compiler et planifier sans erreur.
run "configuration_is_valid" {
  command = plan

  variables {
    snowflake_organization = "TESTORG"
    snowflake_account      = "TESTACCOUNT"
    snowflake_user         = "TEST_USER"
    snowflake_token        = "mock-token"
    learner_prefix         = "APP01"
    environment            = "DEV"
  }

  assert {
    condition     = can(regex("^[A-Z][A-Z0-9]{2,4}$", var.learner_prefix))
    error_message = "learner_prefix doit respecter la convention APPxx."
  }
}

# ------------------------------------------------------------------------------
# TODO (etape 5.5) : decommentez et adaptez a vos ressources/module capstone.
# Exemple avec un module "landing_zone" exposant database_name et warehouse_names.
# ------------------------------------------------------------------------------
# run "naming_convention" {
#   command = plan
#
#   variables {
#     snowflake_organization = "TESTORG"
#     snowflake_account      = "TESTACCOUNT"
#     snowflake_user         = "TEST_USER"
#     snowflake_token        = "mock-token"
#     learner_prefix         = "APP01"
#     environment            = "DEV"
#   }
#
#   assert {
#     condition     = module.landing_zone.database_name == "APP01_M12_RAW_DEV"
#     error_message = "La database ne suit pas la convention PREFIX_M12_RAW_ENV."
#   }
#
#   assert {
#     condition = alltrue([
#       for name in values(module.landing_zone.warehouse_names) :
#       can(regex("^WH_APP01_M12_", name))
#     ])
#     error_message = "Un warehouse ne respecte pas le prefixe WH_APP01_M12_."
#   }
# }
