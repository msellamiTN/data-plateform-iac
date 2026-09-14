# Vos valeurs. Ce fichier est déjà pré-rempli sur votre poste.
# ⚠️ Ne mettez JAMAIS de mot de passe ici.

learner_prefix = "APP04" # ← votre préfixe assigné
environment    = "DEV"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"

# Ma collection de tables (Amal)
tables = {
  accounts     = { name = "ACCOUNTS", comment = "Comptes clients" }
  cards        = { name = "CARDS", comment = "Cartes bancaires" }
  transactions = { name = "TRANSACTIONS", comment = "Flux transactions" }
}
