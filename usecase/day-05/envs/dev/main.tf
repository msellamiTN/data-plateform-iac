# Assemblage du puzzle GlobalBank — DEV
# Les modules sont consommes depuis le registry Git / Azure DevOps.

module "rbac" {
  source = "git::file:///D:/git-repos/globalbank-modules-platform//rbac?ref=v1.0.0"

  prefix      = var.prefix
  environment = var.environment
  roles       = var.roles
}

module "compute" {
  source = "git::file:///D:/git-repos/globalbank-modules-platform//compute?ref=v1.0.0"

  prefix         = var.prefix
  environment    = var.environment
  warehouse_size = "X-SMALL"
  warehouses     = var.warehouses
}

module "landing_zone" {
  source = "git::file:///D:/git-repos/globalbank-modules-data-engineering//landing-zone?ref=v1.0.0"

  prefix       = var.prefix
  environment  = var.environment
  zone         = "RAW"
  schema_name  = "LANDING"
  audit_column = "LOAD_TS"
  tables       = var.raw_tables
}

module "data_domain" {
  source = "git::file:///D:/git-repos/globalbank-modules-business-data//data-domain?ref=v1.0.0"

  prefix         = var.prefix
  environment    = var.environment
  domain         = "CUSTOMER"
  classification = "INTERNE"
  tables         = var.domain_tables
}

module "data_mart" {
  source = "git::file:///D:/git-repos/globalbank-modules-bi-analytics//data-mart?ref=v1.0.0"

  prefix      = var.prefix
  environment = var.environment
  mart        = "CUSTOMER"
  audience    = "RESEAU"
  mart_tables = var.mart_tables
}
