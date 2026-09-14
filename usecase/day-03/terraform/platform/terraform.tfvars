# Vos valeurs. Ce fichier est déjà pré-rempli sur votre poste.
# ⚠️ Ne mettez JAMAIS de mot de passe ici.

learner_prefix = "APP01" # ← votre préfixe assigné
environment    = "DEV"
warehouse_size = "X-SMALL"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"

# Ma collection de rôles (Fares)
roles = {
  raw_reader  = { suffix = "RAW_READER", comment = "Lecture zone RAW" }
  core_reader = { suffix = "CORE_READER", comment = "Lecture zone CORE" }
  mart_reader = { suffix = "MART_READER", comment = "Lecture marts BI" }
}
