# Architecture de référence (formation simplifiée)

## Initiation (Jours 1 à 3)

```text
[VS Code]  -->  [Terraform CLI]
                      |
                      | provider snowflake + PAT
                      v
               [Compte Snowflake]
                      |
        warehouses, databases, schemas, modules (selon le lab)

State = fichier local terraform.tfstate (Jours 1-2)
      puis backend Azure Blob préconfiguré (Jour 3)
        (jamais dans Git)
```

Un apprenant = un projet = des noms d'objets **personnels** (préfixe + module dans le nom).

## Avancé (Jours 4 et 5)

```text
[Git / Azure Repos]
        |
        v
[Azure Pipeline] ---- terraform validate / plan / apply
        |                  (projet + agent préconfigurés)
        +--> [Azure Blob]  = terraform.tfstate distant (préconfiguré)
        |
        v
[Snowflake]  PAT (formation) puis JWT (production)
             RBAC as code + grants + future grants
             stages + COPY INTO (external stage Azure préconfiguré)
```

| Sujet | Initiation | Avancé |
|---|---|---|
| Cloud Azure | non (préconfiguré) | backend + pipeline + external stage (préconfigurés) |
| State | fichier local (J1-J2) puis Blob (J3) | Blob Storage, une clé par environnement |
| Auth Snowflake | PAT | PAT puis RSA/JWT |
| Travail | individuel | toujours individuel, DEV puis UAT puis PROD |
| Pipeline | non | Azure DevOps (validate → plan → apply) |

## Objets Snowflake utilisés

| Objet | Jours | Rôle pédagogique |
|---|---|---|
| Warehouse | 1–5 | première ressource, boucles, modules, capstone |
| Database | 1–5 | second type de ressource, capstone |
| Schema | 1–5 | collections, modules, capstone |
| Stage + File format | 5 | ingestion, connectivité |
| Role + Grants | 5 | RBAC as code, future grants |

## Règle FinOps

Tous les warehouses de formation :

- taille `X-SMALL` ou `SMALL` ;
- `auto_suspend` court (60 secondes) ;
- `initially_suspended = true`.

## Périmètre Azure (préconfiguré, non administré par l'apprenant)

| Ressource | Usage | Préparée par |
|---|---|---|
| Resource Group + Storage Account + Container | Backend state (J3+) | Formateur |
| Service Principal + RBAC | Auth backend | Formateur |
| Azure DevOps Project + Agent + Service Connection | Pipeline (J4) | Formateur |
| Storage Account pour external stage | Stage Snowflake (J5, M9) | Formateur |
| Entra ID / identité technique | JWT (J5, M10) | Formateur |

> L'apprenant consomme les paramètres fournis dans `.env.example`. Il ne crée aucune de ces ressources.
