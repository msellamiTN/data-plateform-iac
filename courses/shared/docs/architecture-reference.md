# Architecture de référence (formation simplifiée)

## Initiation (jours 1 à 3)

```text
[VS Code]  -->  [Terraform CLI]
                      |
                      | provider snowflake + PAT
                      v
               [Compte Snowflake]
                      |
        warehouses, databases, rôles (selon le lab)

State = fichier local terraform.tfstate
        (dans le dossier du projet, jamais Git)
```

Un apprenant = un projet = des noms d'objets **personnels** (initiales dans le nom).

## Avancé (jours 4 et 5)

```text
[Git / Azure Repos]
        |
        v
[Azure Pipeline] ---- terraform plan / apply
        |
        +--> [Azure Blob]  = terraform.tfstate distant
        |
        v
[Snowflake]  JWT (service user) + RBAC as code
```

| Sujet | Initiation | Avancé |
|---|---|---|
| Cloud Azure | non | backend + pipeline |
| State | fichier local | Blob Storage, une clé par environnement |
| Auth Snowflake | PAT dans un fichier local | utilisateur technique + JWT |
| Travail | individuel | toujours individuel, DEV puis PROD |

## Objets Snowflake utilisés

| Objet | Jours | Rôle pédagogique |
|---|---|---|
| Warehouse | 1–5 | première ressource, boucles, modules |
| Database | 3, 5 | second type de ressource, capstone |
| Account role + grants | 5 | sécurité |

## Règle FinOps

Tous les warehouses de formation :

- taille `X-SMALL` ou `SMALL` ;
- `auto_suspend` court (60 secondes) ;
- `initially_suspended = true`.
