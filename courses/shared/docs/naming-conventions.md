# Convention de Nommage

Ce document definit les regles de nommage appliquees a toutes les ressources
de la formation.

## Regle Generale

```text
<PREFIXE_APPRENANT>_<ZONE>_<ENVIRONNEMENT>
```

## Prefixe Apprenant

- 3 a 5 caracteres alphanumeriques en majuscules
- Attribue par le formateur en debut de session
- Unique parmi tous les participants
- Exemples : `APP01`, `APP02`, ... `APP11`

> Le prefixe est votre identite dans la plateforme. Il rend vos ressources uniques.

## Zone

| Zone | Role | Couches |
|------|------|---------|
| `RAW` | Ingestion brute | Bronze |
| `ETL` | Transformation | Silver |
| `CURATED` | Aggregation metier | Gold |
| `FINOPS` | Observabilite et couts | Monitoring |
| `SEC` | Securite et gouvernance | RBAC, tags, policies |

## Environnement

| Suffixe | Role |
|---------|------|
| `DEV` | Developpement |
| `UAT` | Validation |
| `PROD` | Production |

## Exemples

| Ressource | Nom |
|-----------|-----|
| Database | `APP01_RAW_DEV` |
| Schema | `APP01_ETL_UAT.SILVER` |
| Warehouse | `WH_APP01_CURATED_PROD` |
| Resource monitor | `RM_APP01_DEV` |
| Storage integration | `SI_APP01_RAW_DEV` |
| Azure storage account | `stabcuratedapp01dev` |

## Cas Particulier des Warehouses

Les warehouses portent le prefixe `WH_` pour les distinguer des bases :

```text
WH_<PREFIXE>_<ZONE>_<ENVIRONNEMENT>
```

Exemples :
- `WH_APP01_INGEST_DEV`
- `WH_APP01_ETL_PROD`

## Cas Particulier des Resource Monitors

```text
RM_<PREFIXE>_<ENVIRONNEMENT>
```

Les resource monitors ne portent pas de zone car ils s'appliquent au compte
ou a un warehouse.

## Regles de Casse

| Type | Casse | Exemple |
|------|-------|---------|
| Snowflake databases, schemas, warehouses | UPPER_SNAKE | `APP01_RAW_DEV` |
| Snowflake roles | UPPER_SNAKE | `ROLE_APP01_DEV` |
| Snowflake users | UPPER_SNAKE | `USER_APP01_SVC` |
| Azure resources | lowercase | `stabcuratedapp01dev` |
| Terraform resources | snake_case | `snowflake_database.raw_dev` |
| Terraform variables | snake_case | `learner_prefix` |
| Terraform locals | snake_case | `database_name` |

## Nommage par Module

Chaque module de lab utilise son propre prefixe dans les noms de ressources :

```text
<PREFIXE>_M<NUMERO>_<ZONE>_<ENVIRONNEMENT>
```

Exemples :
- `APP01_M01_RAW_DEV` (Module 1)
- `APP01_M02_RAW_DEV` (Module 2)
- `APP01_M05_RAW_DEV` (Module 5)

Cela garantit qu'aucune collision ne se produit entre les modules.

## Nommage des Fichiers Terraform

| Fichier | Contenu |
|---------|---------|
| `versions.tf` | Version Terraform et providers |
| `provider.tf` | Configuration du provider Snowflake |
| `variables.tf` | Declaration des variables |
| `terraform.tfvars` | Valeurs des variables (gitignore) |
| `main.tf` | Ressources principales |
| `outputs.tf` | Sorties |
| `locals.tf` | Valeurs calculees |
| `modules/<name>/` | Module reutilisable |

## Verification

Pour verifier le nommage :

```bash
# Lister les ressources Snowflake
SHOW WAREHOUSES LIKE 'APP01_%';
SHOW DATABASES LIKE 'APP01_%';

# Verifier le state Terraform
terraform state list
```
