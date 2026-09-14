# Vos valeurs. Ce fichier est déjà pré-rempli sur votre poste.
# ⚠️ Ne mettez JAMAIS de mot de passe ici.

learner_prefix = "APP09" # ← votre préfixe assigné
environment    = "DEV"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"

# Ma collection de tables (Ghassen)
mart_tables = {
  customer_360 = { name = "CUSTOMER_360", comment = "Vue 360 du client" }
  segment_kpi  = { name = "SEGMENT_KPI", comment = "KPIs par segment" }
  churn        = { name = "CHURN_SCORE", comment = "Score d'attrition" }
}
