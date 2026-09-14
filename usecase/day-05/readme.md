# Jour 5 — CI/CD Azure DevOps + Module Registry

Ce dossier represente le depot de deploiement GlobalBank. Les modules Terraform sont consommes depuis un registry Git (Azure DevOps) et non plus copies localement.

## Structure du depot de deploiement

```text
day-05/
├── azure-pipelines.yml      ← CI/CD multi-environnements
├── atelier-globalbank-jour-05.md
├── team-*.md
├── readme.md
└── envs/
    ├── dev/
    └── uat/
```

## Module Registry

Les modules sont stockes dans un autre depot (le "module registry"). L'URL dans `envs/*/main.tf` suit le pattern :

```hcl
# Local lab / VM
source = "git::file:///D:/git-repos/globalbank-modules-<team>//<nom>?ref=v1.0.0"

# Production (Azure DevOps)
source = "git::https://dev.azure.com/data2ai-tn/GlobalBank-DataPlatform/_git/globalbank-modules-<team>//<nom>?ref=v1.0.0"
```

### Procedure de publication d'une version

1. Dans le depot modules, creer et pousser le tag :

```bash
git tag -a v1.0.0 -m "Release initiale modules GlobalBank"
git push origin v1.0.0
```

2. Mettre a jour `?ref=v1.0.0` dans `envs/dev/main.tf` et `envs/uat/main.tf` si vous publiez une nouvelle version.

## Création des repos Azure DevOps

Le projet `data2ai-tn/GlobalBank-DataPlatform` contient **un repo par équipe + un repo de déploiement**.

### 1. Quatre repos de modules (un par équipe)

| Équipe | Repo | Modules poussés |
|---|---|---|
| **Platform** | `globalbank-modules-platform` | `rbac/`, `compute/` |
| **Data Engineering** | `globalbank-modules-data-engineering` | `landing-zone/` |
| **Business Data** | `globalbank-modules-business-data` | `data-domain/` |
| **BI / Analytics** | `globalbank-modules-bi-analytics` | `data-mart/` |

Exemple pour l'équipe **Platform** :

```powershell
git clone https://data2ai-tn@dev.azure.com/data2ai-tn/GlobalBank-DataPlatform/_git/globalbank-modules-platform
cd globalbank-modules-platform
xcopy /E "D:\Data2AI Academy\Snowflake-terraform\courses\initiation\day-04\terraform\modules\rbac"    .\rbac\
xcopy /E "D:\Data2AI Academy\Snowflake-terraform\courses\initiation\day-04\terraform\modules\compute" .\compute\

git add .
git commit -m "Modules GlobalBank v1.0.0"
git tag -a v1.0.0 -m "Release initiale modules GlobalBank"
git push origin main
git push origin v1.0.0
```

Les trois autres équipes font de même avec leur module et leur repo.

### 2. `globalbank-deploy` (le dépôt d'application)

Dans Azure DevOps : **Repos > Nouveau > globalbank-deploy**.

```powershell
git clone https://data2ai-tn@dev.azure.com/data2ai-tn/GlobalBank-DataPlatform/_git/globalbank-deploy
cd globalbank-deploy

xcopy /E "D:\Data2AI Academy\Snowflake-terraform\courses\initiation\day-05\*" .\
Remove-Item .terraform -Recurse -Force -ErrorAction SilentlyContinue

git add .
git commit -m "Initial GlobalBank deploy repo"
git push origin main
```

> Si vous testez depuis le repo `Snowflake-terraform` local, les chemins `workingDirectory` du pipeline doivent être `courses/initiation/day-05/envs/dev` au lieu de `envs/dev`.

## Déroulé pédagogique (12 apprenants)

### Matin — publication des modules (09h00-10h30)

| Horaire | Activité | Équipe |
|---|---|---|
| 09h00-09h15 | Briefing : pourquoi un registry, pourquoi un repo par équipe | Formateur |
| 09h15-09h45 | Créer son repo d'équipe, copier son(s) module(s), taguer `v1.0.0` | Toutes |
| 09h45-10h00 | Configurer variable group, service connection, environments | Platform |
| 10h00-10h30 | Vérifier `terraform init -backend=false` + `validate` en local | Toutes |

### Matin — CI/CD (10h30-12h00)

| Horaire | Activité | Équipe |
|---|---|---|
| 10h30-10h45 | Créer le repo `globalbank-deploy`, copier `day-05/` | Platform |
| 10h45-11h15 | Configurer la pipeline et les permissions | Platform avec formateur |
| 11h15-12h00 | Lancer la pipeline : plan/apply DEV, approbation UAT | Toutes |

## Script de bootstrap

Utilisez `bootstrap-day5.ps1` pour automatiser la création des 5 repos locaux :

```powershell
.\bootstrap-day5.ps1
```

Le script : crée les repos, copie les modules, pose les tags `v1.0.0`, ajoute les remotes, et affiche les commandes `git push` à exécuter manuellement.

## CI/CD

Le pipeline `azure-pipelines.yml` contient 6 stages, exécutés sur un agent `ubuntu-latest` :

1. **Validate** : `terraform fmt -check` + `terraform validate` + `tflint --recursive`
2. **PlanDev** : `terraform plan -out=tfplan` sur `envs/dev`, publication du plan
3. **ApplyDev** : `terraform apply tfplan` automatique sur `envs/dev`
4. **PlanUat** : `terraform plan -out=tfplan` sur `envs/uat`
5. **ApplyUat** : `terraform apply tfplan` avec approbation humaine sur l'environnement `uat`
6. **Audit** : `terraform plan -detailed-exitcode` sur `envs/uat` pour détecter la dérive

### Configuration requise dans Azure DevOps

- Variable group `globalbank-snowflake` avec :
  - `SNOWFLAKE_TOKEN` (secret)
- Service connection `sc-globalbank-tfstate` (identite fedeeree / Azure service principal)
- Environnement Azure DevOps `dev` sans approbation
- Environnement Azure DevOps `uat` avec approbation obligatoire

## Securite — aucun secret local

Les tokens ne sont plus lus depuis `secrets/snowflake_pat.txt`.

- En pipeline : la variable d'environnement `TF_VAR_snowflake_token` est injectee depuis le variable group `globalbank-snowflake`.
- En local : utiliser Azure Key Vault et exporter la valeur :

```powershell
$env:TF_VAR_snowflake_token = (az keyvault secret show --name SnowflakePAT --vault-name kvdata2aitfsecretsmsn --query value -o tsv)
```

Aucun `snowflake_token` ne doit apparaitre dans `.tf`, `.tfvars` ou Git.

## Etapes manuelles

```powershell
# 1. Remplir envs/dev/terraform.tfvars (sauf snowflake_token)
# 2. Recuperer le token depuis Key Vault
$env:TF_VAR_snowflake_token = (az keyvault secret show --name SnowflakePAT --vault-name kvdata2aitfsecretsmsn --query value -o tsv)

# 3. Valider le format
cd courses/initiation/day-05
terraform fmt -check -recursive

# 4. Initialiser et valider sans backend (test rapide)
cd envs/dev
terraform init -backend=false
terraform validate

# 5. Initialiser avec le backend Azure pour de vrai
cd courses/initiation/day-05/envs/dev
terraform init
terraform plan -out=tfplan -input=false
terraform apply tfplan -input=false

# 6. Promouvoir vers UAT
cd ../uat
terraform init
terraform plan -out=tfplan -input=false
terraform apply tfplan -input=false
```
