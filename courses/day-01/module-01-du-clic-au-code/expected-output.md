# M01 — Sorties attendues

## `terraform init`

```
Initializing the backend...
Initializing provider plugins...
- Finding snowflakedb/snowflake versions matching "= 2.14.0"...
- Installing snowflakedb/snowflake v2.14.0...
- Installed snowflakedb/snowflake v2.14.0
Terraform has been successfully initialized!
```

## `terraform validate`

```
Success! The configuration is valid.
```

## `terraform plan` (premier)

```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # snowflake_warehouse.etl will be created
  + resource "snowflake_warehouse" "etl" {
      + auto_resume         = true
      + auto_suspend        = 60
      + comment             = "Warehouse ETL créé par Terraform pour APP01"
      + initially_suspended = true
      + name                = "APP01_M01_ETL_DEV"
      + warehouse_size      = "X-SMALL"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

## `terraform apply`

```
snowflake_warehouse.etl: Creating...
snowflake_warehouse.etl: Creation complete after 2s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## `terraform plan` (second — idempotence)

```
No changes. Your infrastructure matches the configuration.
```

## Après dérive manuelle (Auto Suspend 60 → 300)

```
  # snowflake_warehouse.etl has changed
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend = 300 -> 60
        name         = "APP01_M01_ETL_DEV"
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

## Vérification Snowsight

Admin → Warehouses : `APP01_M01_ETL_DEV` présent, statut *Suspended*, taille
*X-Small*, Auto Suspend *60*.
