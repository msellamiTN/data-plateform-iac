# Remplacez par vos propres valeurs avant le premier init
snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"

prefix      = "GB"
environment = "UAT"

roles = {
  raw_reader = {
    suffix  = "RAW_READER"
    comment = "Lecture des zones raw"
  }
  engineer = {
    suffix  = "ENGINEER"
    comment = "Equipe Data Engineering"
  }
}

warehouses = {
  ingest = {
    suffix       = "INGEST"
    comment      = "Warehouse d'ingestion"
    auto_suspend = 60
  }
}

raw_tables = {
  transactions = {
    name    = "RAW_TRANSACTIONS"
    comment = "Transactions brutes du simulateur core-banking"
  }
}

domain_tables = {
  customer = {
    name    = "CUSTOMERS"
    comment = "Referentiel client"
  }
}

mart_tables = {
  kpi = {
    name    = "CUSTOMER_KPI"
    comment = "Indicateurs client pour le reseau"
  }
}
