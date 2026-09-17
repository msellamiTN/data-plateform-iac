# M02 — Troubleshooting

## 1. `terraform destroy` échoue avec `Warehouse is in use`

**Symptôme :** le destroy échoue parce que le warehouse a des sessions actives.

**Diagnostic :** dans Snowsight, exécutez :

```sql
SELECT * FROM TABLE(SNOWFLAKE.INFORMATION_SCHEMA.WAREHOUSE_LOAD_HISTORY(
  WAREHOUSE_NAME => 'APP01_M02_ETL_DEV'));
```

**Correction :** fermez les worksheets qui utilisent le warehouse (ou changez leur
warehouse dans Snowsight), puis relancez `terraform destroy`.

## 2. `plan` affiche `-/+` alors que vous vouliez un `~`

**Symptôme :** vous vouliez modifier un attribut, mais le plan propose une recréation.

**Diagnostic :** cherchez la ligne `# forces replacement` dans le plan. Elle indique
quel attribut déclenche la recréation (ex: `name`, `warehouse_size` sur certains
providers).

**Correction :** restaurez l'attribut fautif à sa valeur précédente. Pour changer la
taille d'un warehouse, `warehouse_size` est modifiable en place (`~`), mais `name`
ne l'est pas.

## 3. `terraform.tfstate` est corrompu ou supprimé

**Symptôme :** `terraform plan` propose de tout recréer alors que les ressources
existent.

**Diagnostic :** `terraform state list` ne retourne rien.

**Correction :** ne recréez pas immédiatement. Utilisez `terraform import` (vu au M08)
pour réassocier chaque ressource au state. Pour ce module, le plus simple est de
`DROP` le warehouse dans Snowsight puis `terraform apply` pour le recréer proprement.
