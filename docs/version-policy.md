# Politique de versions — Formation Terraform × Snowflake

Ce document définit les versions de référence utilisées dans l'ensemble des labs
et la procédure d'upgrade encadrée (lien avec l'objectif « gérer les versions,
le lock file et les upgrades »).

## Versions de référence

| Outil | Version | Pourquoi |
|---|---|:---:|---|
| Terraform | `= 1.14.5` | Version exacte validée pour tous les labs (tests `.tftest.hcl`, `check` blocks, `mock_provider` requièrent ≥ 1.7). |
| Provider Snowflake | `= 2.14.0` | Épinglage exact : reproductibilité garantie pour les 11 apprenants. |
| OpenSSL | latest | Génération des clés RSA (lab M10) — outil auxiliaire, version non critique. |
| Azure CLI | latest | Uniquement Jours 4–5 (backend distant, Key Vault). |

Tous les `versions.tf` des starters (`labs/m*`) appliquent :

```hcl
terraform {
  required_version = "= 1.14.5"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.14.0"
    }
  }
}
```

## Fichier de verrouillage `.terraform.lock.hcl`

- Généré par `terraform init`, il enregistre les **hashes** des providers
  réellement installés.
- **Il se commit dans Git** : toute l'équipe (et le pipeline CI/CD) utilise
  exactement les mêmes binaires de providers.
- `terraform init` vérifie les hashes ; une divergence = rejet explicite.

## Procédure d'upgrade (exercice M02)

1. Modifier `version` dans `versions.tf` (ex. `= 2.15.0`).
2. `terraform init -upgrade` — met à jour le provider **et** le lock file.
3. `terraform plan` — vérifier qu'aucun changement inattendu n'apparaît.
4. Commiter `versions.tf` **et** `.terraform.lock.hcl` ensemble.
5. En cas de problème : revenir à la version précédente et relancer
   `terraform init -upgrade`.

## Mise à jour du binaire Terraform

- Vérifier la version installée : `terraform version`.
- Le binaire se remplace simplement (un seul exécutable) ; sur la VM de
  formation il est pré-installé — en entreprise, utiliser un gestionnaire de
  versions (ex. `tfenv`, `tenv`) ou l'image CI épinglée.
- Après upgrade : rejouer `terraform init -upgrade` puis `terraform validate`
  sur chaque workspace avant tout `apply`.
