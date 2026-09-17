# M03 — Sorties attendues

## `terraform plan` (premier — 2 ressources)

```
  # snowflake_database.raw will be created
  + resource "snowflake_database" "raw" {
      + comment = "Database RAW paramétrée (M03) pour APP01"
      + name    = "APP01_M03_RAW_DEV"
    }

  # snowflake_warehouse.etl will be created
  + resource "snowflake_warehouse" "etl" {
      + auto_resume         = true
      + auto_suspend        = 60
      + comment             = "Warehouse ETL paramétré (M03) pour APP01"
      + initially_suspended = true
      + name                = "APP01_M03_ETL_DEV"
      + warehouse_size      = "X-SMALL"
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

## Après changement de `warehouse_auto_suspend` (60 → 120)

```
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend = 60 -> 120
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

## Validation refusée (`warehouse_size = "LARGE"`)

```
Error: warehouse_size must être X-SMALL ou SMALL. Les tailles supérieures sont
interdites en formation.
```

## `terraform plan -var="database_name=ANALYTICS"`

```
  # snowflake_database.raw must be replaced
-/+ resource "snowflake_database" "raw" {
      ~ name = "APP01_M03_RAW_DEV" -> "APP01_M03_ANALYTICS_DEV" # forces replacement
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

> Ne pas appliquer : cela détruirait la database RAW.
