# Guide de dépannage

Lire le message d'erreur **en entier** avant de changer plusieurs choses à la fois.

## Diagnostic par couches

| Couche | Symptôme | Diagnostic |
|---|---|---|
| Outil | Commande non reconnue | Vérifier PATH, relancer VS Code |
| Auth Snowflake | `401`, `390144` | Vérifier PAT, connexion `training` |
| Provider | `Provider not found` | `terraform init` dans le bon dossier |
| HCL | `validate` échoue | `terraform fmt`, lire l'erreur |
| State/backend | `State locked` | Vérifier le verrou, attendre ou `force-unlock` |
| Permissions | `Insufficient privileges` | Vérifier le rôle, contacter le formateur |
| Pipeline | Stage échoue | Lire les logs Azure DevOps |

---

## Terraform n'est pas reconnu

```text
terraform : The term 'terraform' is not recognized
```

- Relancer VS Code **après** la modification du PATH.
- Vérifier `C:\Terraform\terraform.exe` existe.
- Dans un **nouveau** PowerShell : `terraform version`.

## Provider not found / Failed to query available provider packages

- Être dans le **bon dossier** (celui qui contient `versions.tf`).
- Lancer `terraform init`.
- Vérifier la connexion Internet (le provider se télécharge).

## Invalid credentials / 390144 / programmatic access token

- Le PAT est injecté via `TF_VAR_snowflake_token` ou lu depuis `secrets/snowflake_pat.txt`.
- Le PAT n'est pas expiré. En recréer un si besoin dans Snowsight.
- `terraform.tfvars` a la bonne organisation, le bon compte et le bon utilisateur.
- Le rôle `SYSADMIN` est autorisé pour cet utilisateur.
- Tester : `snow sql -q 'SELECT 1' -c training`.

## Resource already exists

Snowflake refuse de créer un objet du même nom.

Deux options pédagogiques :

1. Changer le nom dans le code (ajouter votre préfixe/module).
2. Importer l'objet existant (Jour 3, M03).

Ne pas détruire un warehouse partagé sans accord de l'instructeur.

## Error: Inconsistent dependency lock file

```bash
terraform init
```

Si besoin, supprimer le dossier `.terraform` puis relancer `terraform init`. Ne pas supprimer `terraform.tfstate`.

## State lock

Le verrou apparaît si un `apply` a été interrompu ou si un collègue utilise le même state.

- Attendre que plus aucun `terraform` ne tourne.
- Vérifier qui a le lock : lire le champ `Who` et `Created` dans le message.
- En dernier recours, et seulement si l'instructeur le confirme : `terraform force-unlock <LOCK_ID>`.

> 🔴 `force-unlock` est la commande la plus dangereuse. Ne l'utilisez qu'après vérification que le processus est mort.

## Plan shows destroy of everything

Arrêter. Ne pas taper `yes`.

Causes fréquentes :
- mauvais dossier ;
- mauvais fichier `terraform.tfvars` ;
- state distant d'un autre projet ou apprenant.

## Validation warehouse_size

Le provider officiel attend `X-SMALL` ou `SMALL` (majuscules, tiret). Pas `X-Small`.

## Backend Azure inaccessible (Jour 3+)

- Le backend est préconfiguré par le formateur.
- Vérifier que les paramètres dans `.env` correspondent à ceux fournis.
- Si le conteneur n'est pas accessible, contacter le formateur (problème infrastructure).
- Ne pas créer le storage account vous-même.

## Pipeline Azure DevOps (Jour 4)

- Les secrets (PAT, tfvars) sont dans les **variables sécurisées** du pipeline, pas dans Git.
- `terraform init` du pipeline reçoit le backend Azure préconfiguré.
- Si le stage `Validate` échoue : vérifier `terraform fmt -check` et `terraform validate` en local.
- Si le stage `Plan` échoue : vérifier les credentials et le backend.
- L'apply exécute le **même** artefact de plan que celui approuvé.

## Permissions insuffisantes (Jour 5)

- Vérifier le rôle actif : `SHOW ROLE` ou `snow sql -q 'SELECT CURRENT_ROLE()' -c training`.
- Ne pas utiliser `ACCOUNTADMIN` pour résoudre une erreur.
- Contacter le formateur si le rôle de training n'est pas attribué.

## PAT expiré

```bash
# Vérifier la connexion
snow sql -q 'SELECT 1' -c training

# Si échec, régénérer le PAT dans Snowsight
# Account > Security > Tokens > Create new token

# Mettre à jour le PAT dans .env
# Réinitialiser la connexion
terraform init -upgrade
```
