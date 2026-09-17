# M02 — Sorties attendues

## `terraform plan` (modification en place — `~`)

```
  # snowflake_warehouse.etl will be updated in-place
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend = 60 -> 120
      ~ comment      = "Warehouse ETL pour le cycle de vie (M02)" -> "Warehouse ETL modifié (M02 — auto_suspend 120)"
        name         = "APP01_M02_ETL_DEV"
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

## `terraform plan` (recréation — `-/+`)

```
  # snowflake_warehouse.etl must be replaced
-/+ resource "snowflake_warehouse" "etl" {
      ~ name = "APP01_M02_ETL_DEV" -> "APP01_M02_ETL_RENAMED_DEV" # forces replacement
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

## `terraform plan -destroy`

```
  # snowflake_warehouse.etl will be destroyed
  - resource "snowflake_warehouse" "etl" {
      - auto_suspend        = 120 -> null
      - name                = "APP01_M02_ETL_DEV" -> null
      - warehouse_size      = "X-SMALL" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

## `terraform destroy`

```
snowflake_warehouse.etl: Destroying...
snowflake_warehouse.etl: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.
```

## Après recréation

```
No changes. Your infrastructure matches the configuration.
```
