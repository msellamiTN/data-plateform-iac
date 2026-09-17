# M01 — Troubleshooting

## 1. `Error: Warehouse 'APP01_M01_ETL_DEV' already exists`

**Symptôme :** le `apply` échoue parce que le warehouse existe déjà dans Snowflake.

**Cause probable :** un `apply` précédent a été interrompu après la création mais
avant l'écriture du state, ou vous avez créé le warehouse à la main.

**Diagnostic (non destructif) :**

Dans Snowsight, exécutez :

```sql
SHOW WAREHOUSES LIKE 'APP01_M01%';
```

**Correction :**

- Si le warehouse existe et que vous voulez le **gérer** avec Terraform : voir le M08
  (`terraform import`).
- Si le warehouse existe et que vous voulez le **recréer** proprement :

```sql
DROP WAREHOUSE APP01_M01_ETL_DEV;
```

Puis relancez `terraform apply`.

## 2. `terraform plan` affiche `1 to destroy` alors que vous n'avez rien supprimé

**Symptôme :** le plan montre une destruction inattendue.

**Diagnostic :** comparez votre `main.tf` avec la solution. Un argument modifié
(ex: `name` changé) provoque un `-/+` (recréation).

**Correction :** restaurez `main.tf` à partir de la solution
(`solution/main.tf`), puis `terraform plan` doit afficher `No changes.`

## 3. `Error: 401 Unauthorized` ou `Invalid token`

Voir [M00 troubleshooting](../../day-00/module-00-installation/troubleshooting.md)
entrée 2. Le PAT est probablement expiré ou parasite.
