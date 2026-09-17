> _Fichier genere a partir de `courses/day-XX/module-YY/` — les liens relatifs internes pointent vers l'arborescence source._

# Résultat attendu — M14

> [<- Jour 5](../README.md) · [<- Module precedent](../module-12-capstone/lab.md) · **Module 14** · [Fin ->](../../README.md)

## Terraform

```text
Apply complete!
Outputs:
data_products = {
  "FINANCE" = { ... }
  "SALES" = { ... }
}
```

## Snowflake

Pour chaque domaine :

- `DB_{DOMAIN}_DEV` ;
- schemas `RAW`, `SILVER`, `GOLD` ;
- stage `STG_{DOMAIN}_RAW_DEV` ;
- rôles `RL_{DOMAIN}_PRODUCER_DEV` et `RL_{DOMAIN}_READER_DEV` ;
- Future Grants SELECT au rôle lecteur.

Après Snow CLI, les vues GOLD sont interrogeables et un nouveau `terraform plan` indique `No changes`.

