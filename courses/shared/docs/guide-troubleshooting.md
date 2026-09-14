# Guide de dépannage

Lire le message d'erreur **en entier** avant de changer plusieurs choses à la fois.

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

- Le fichier s'appelle bien `snowflake-config.txt` et est **dans le même dossier** que `provider.tf`.
- Le fichier contient **uniquement** le token, une seule ligne.
- `terraform.tfvars` a la bonne organisation, le bon compte et le bon utilisateur.
- Le PAT n'est pas expiré. En recréer un si besoin.
- Le rôle `SYSADMIN` est autorisé pour cet utilisateur.

## Resource already exists

Snowflake refuse de créer un objet du même nom.

Deux options pédagogiques :

1. Changer le nom dans le code (ajouter vos initiales).
2. Importer l'objet existant (module M06).

Ne pas détruire un warehouse partagé sans accord de l'instructeur.

## Error: Inconsistent dependency lock file

```text
terraform init
```

Si besoin, supprimer le dossier `.terraform` puis relancer `terraform init`. Ne pas supprimer `terraform.tfstate`.

## State lock

En initiation, le state est **local**. Un verrou apparaît surtout si un `apply` a été interrompu.

- Attendre que plus aucun `terraform` ne tourne.
- En dernier recours, et seulement si l'instructeur le confirme : `terraform force-unlock <LOCK_ID>`.

## Plan shows destroy of everything

Arrêter. Ne pas taper `yes`.

Causes fréquentes :

- mauvais dossier ;
- mauvais fichier `terraform.tfvars` ;
- state distant d'un autre projet (parcours avancé).

## Validation warehouse_size

Le provider officiel attend `X-SMALL` ou `SMALL` (majuscules, tiret). Pas `X-Small`.

## Azure backend (jours 4–5 seulement)

- Le compte de stockage et le conteneur existent.
- Vous êtes connecté : `az login`.
- Le nom du compte de stockage est unique et exact (minuscules).

## Pipeline Azure DevOps

- Les secrets (PAT, tfvars) sont dans les **variables sécurisées** du pipeline, pas dans Git.
- `terraform init` du pipeline doit recevoir le backend Azure (jours 4–5).
