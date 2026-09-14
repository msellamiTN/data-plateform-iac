# 🏦 Atelier GlobalBank — Jour 5

## *Pipeline, sécurité, gouvernance, FinOps et capstone*

> **Formation Terraform + provider Snowflake** · GlobalBank · **Jour 5**
> **Durée :** 6 h · **Prérequis :** Jours 1 à 4 terminés, `backend "azurerm"` et racines `dev/` + `uat/` opérationnels
> **Outils :** Azure DevOps, VS Code, Snowsight, dbt

---

## 1. Où nous en sommes

Quatre jours. **La plateforme est décrite en code, le state vit dans Azure Blob, les modules sont extraits, les environnements DEV et UAT existent côte à côte.**

```
   🔵  9 rôles · 6 warehouses de service · resource monitors · grants
   🟢  GB_RAW_DB / UAT · GB_CORE_DB / UAT · schemas · tables · file formats · tasks
   🟠  3 databases de domaine / UAT · tables · vues · grants
   🟣  3 data marts / UAT · tables · vues · grants
```

**Mais l'Inspection Générale n'est pas satisfaite.**

```
   ┌──────────────────────────────────────────────────────────────┐
   │  De : Sofia Almeida — Head of Data Platform                  │
   │  Le : vendredi, 08 h 30                                      │
   │                                                              │
   │  « Lundi, on va en production. J'ai trois conditions :       │
   │                                                              │
   │    1. Aucun `apply` ne part sans relecture et sans preuve.   │
   │    2. Les clés et les jetons ne voyagent plus sur Slack.     │
   │    3. On doit pouvoir justifier chaque crédit consommé.      │
   │                                                              │
   │    Et à 17 h, je veux une démonstration : la plateforme      │
   │    entière, recréée d'un seul `apply`, sans dérive. »        │
   └──────────────────────────────────────────────────────────────┘
```

> 🎯 **Les six fondements de la journée** répondent à ces trois exigences : **pipeline CI/CD**, **identité technique (JWT)**, **RBAC as Code**, **ingestion avancée**, **FinOps/dbt/Data Products**, **capstone zero-drift**.

---

## 2. Les 6 fondements de la journée

| Étape | Ce que je fais | 🧠 Le fondement que j'apprends | Module officiel |
|:---:|---|---|---|
| **1** | Je configure une pipeline Azure DevOps qui planifie sur PR et applique sur `main` | **CI/CD GitOps** | M07 — Pipeline CI/CD |
| **2** | Je remplace le PAT par une clé RSA stockée dans Azure Key Vault | **Identité technique JWT** | M10 — Security & Key Vault |
| **3** | Je modélise les rôles et grants dans Terraform | **RBAC as Code** | M11 — RBAC |
| **4** | J'ajoute un stage externe et un file format | **Ingestion avancée** | M09 — Snowflake advanced |
| **5** | Je connecte dbt pour surveiller les coûts et publier un data product | **FinOps & Data Products** | M13 — FinOps, M14 — Data Products |
| **6** | J'assemble tous les modules et je prouve le `No changes.` | **Capstone zero-drift** | M12 — Capstone |

> 🧠 **La règle du parcours reste la même : jamais une ligne de Terraform avant d'avoir vu l'objet à la main.** Aujourd'hui, le « à la main » se passe dans **Azure DevOps**, **Key Vault** et **Snowsight**.

---

## 3. Le déroulé — personne n'attend

### Phase 1 — commune (09 h 00 – 10 h 30)

| Créneau | 🎤 Le formateur démontre | 👥 Les onze font |
|---|---|---|
| **09 h 00 – 09 h 15** | Le pipeline cible : `fmt` → `validate` → `plan` → approbation → `apply` | *(observent)* |
| **09 h 15 – 09 h 45** | Créer les 5 repos Azure DevOps et pousser les modules avec `v1.0.0` | **Chaque équipe pousse son/ses module(s) dans son repo** |
| **09 h 45 – 10 h 00** | Configurer variable group, service connection, environments | **Platform configure la pipeline squelette** |
| **10 h 00 – 10 h 30** | *(circule)* | **Valident `terraform init -backend=false` + `validate` localement** |

### Phase 2 — sécurité et gouvernance (10 h 45 – 12 h 30)

| Créneau | 👥 Ce que chacun fait |
|---|---|
| **10 h 45 – 11 h 30** | 🔵 **Platform** : génération d'une clé RSA, stockage dans Key Vault, connexion JWT |
| **11 h 30 – 12 h 30** | 🔵 **Platform** : modélisation des rôles et `future grants` en Terraform |

### Phase 3 — ingestion et data products (13 h 30 – 15 h 30)

| Créneau | 👥 Ce que chacun fait |
|---|---|
| **13 h 30 – 14 h 30** | 🟢 **Data Eng** : stage externe Azure, `file format` CSV, `copy into` |
| **14 h 30 – 15 h 30** | 🟠🟣 **Business & BI** : modèle dbt FinOps, vue materialisée, data product gouverné |

### Phase 4 — capstone (15 h 45 – 17 h 00)

| Créneau | 👥 Ce que chacun fait |
|---|---|
| **15 h 45 – 16 h 30** | Toutes les équipes : assemblage du capstone, `terraform plan -detailed-exitcode` |
| **16 h 30 – 17 h 00** | 🏆 Démonstration de la plateforme complète, `No changes.`, teardown contrôlé |

---

## 4. Distribution du travail par équipe

| Équipe | Membres | Responsabilité Jour 5 | Livrable |
|---|---|---|---|
| 🔵 **Platform / DevOps** | Fares · Mohamed · Sirine | Pipeline, JWT/Key Vault, RBAC as Code | `azure-pipelines.yml`, `modules/security/`, `modules/rbac/` |
| 🟢 **Data Engineering** | Amal · Lara | Ingestion Azure, stages, file formats, COPY | `modules/ingestion/`, fichiers de test dans `samples/` |
| 🟠 **Business Data** | Manel · Leila · Olfa | Domaines, vues, data products business | `modules/data-domain/` enrichi, modèle dbt |
| 🟣 **BI / Analytics** | Ghassen · Adem · Hadhemi | Marts, materialized views, FinOps | `modules/data-mart/` enrichi, modèle dbt |

> 🧠 **Toutes les équipes dépendent de Platform aujourd'hui :** sans la pipeline, le JWT et les rôles, aucun `apply` de l'après-midi ne peut être sûr.

---

---

# ÉTAPE 1 — Pipeline CI/CD Azure DevOps

> **Commune aux onze.** 09 h 00 – 10 h 30.

## Le problème, d'abord

Cette semaine, chacun a fait `terraform apply` depuis son poste. **Lundi, personne n'aura le droit de le faire.**

| Si… | Alors… |
|---|---|
| Quelqu'un `apply` à 23 h sans relecture | On ne sait pas qui a changé quoi |
| Un plan n'est pas conservé | On ne peut pas prouver que ce qu'on a approuvé est ce qui a été appliqué |
| Le PAT est dans un pipeline YAML | Toute la plateforme est compromise si le YAML fuite |
| On ne teste pas en UAT | On découvre l'erreur en production |

> 🎯 **La pipeline n'est pas un luxe : c'est la condition de la mise en production de lundi.**

## ① 🖱️ D'abord, dans Azure DevOps

**Aller sur `dev.azure.com/data2ai-tn` → projet `GlobalBank-DataPlatform`.**

Créer **cinq repositories** (un par équipe + le déploiement) :

1. **`globalbank-modules-platform`** : `rbac/`, `compute/` (Team Platform)
2. **`globalbank-modules-data-engineering`** : `landing-zone/` (Team Data Engineering)
3. **`globalbank-modules-business-data`** : `data-domain/` (Team Business Data)
4. **`globalbank-modules-bi-analytics`** : `data-mart/` (Team BI / Analytics)
5. **`globalbank-deploy`** : `azure-pipelines.yml` + `envs/dev` + `envs/uat`

Puis créer les ressources Azure DevOps requises :

1. **Variable group** `globalbank-snowflake` :
   - `SNOWFLAKE_TOKEN` (secret du PAT Snowflake)

2. **Service connection** `sc-globalbank-tfstate` :
   - Fédération d'identité Azure / service principal.
   - **Aucun secret client** dans le YAML.

3. **Environments** `dev` et `uat` :
   - `dev` : pas d'approbation.
   - `uat` : approbation requise avant `ApplyUat`.

> 🔒 **Aucune valeur secrète n'est collée dans le YAML.** Le service principal a accès au Key Vault ; la pipeline lit ce que seul Azure peut voir.

> Pour le détail des commandes `git clone` + `xcopy` + `git tag`, voir `readme.md` § "Création des deux repos Azure DevOps".

## ② ⌨️ `azure-pipelines.yml` à la racine du projet

Le pipeline CI/CD est prêt à l'emploi dans `azure-pipelines.yml`. Voici son contenu complet :

```yaml
trigger:
  branches:
    include: [main]
  paths:
    include:
      - envs/**

pr:
  branches:
    include: [main]
  paths:
    include:
      - envs/**

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: globalbank-snowflake
  - name: TF_IN_AUTOMATION
    value: 'true'
  - name: TERRAFORM_VERSION
    value: '1.14.5'

stages:
  - stage: Validate
    displayName: 'Validate'
    jobs:
      - job: lint_validate
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '$(TERRAFORM_VERSION)'
          - script: |
              set -e
              terraform fmt -check -recursive
            displayName: 'Format check'
          - script: |
              set -e
              terraform init -backend=false
              terraform validate
            workingDirectory: envs/dev
            displayName: 'Validate dev'
          - script: |
              set -e
              curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
              tflint --version
              tflint --recursive
            workingDirectory: envs/dev
            displayName: 'tflint'

  - stage: PlanDev
    displayName: 'Plan on DEV'
    dependsOn: Validate
    condition: or(eq(variables['Build.Reason'], 'PullRequest'), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: plan_dev
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '$(TERRAFORM_VERSION)'
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'sc-globalbank-tfstate'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                set -e
                terraform init
                terraform plan -out=tfplan -input=false
                terraform show -no-color tfplan > plan.txt
              workingDirectory: envs/dev
              addSpnToEnvironment: true
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_TOKEN)
          - publish: envs/dev/tfplan
            artifact: tfplan-dev
          - publish: envs/dev/plan.txt
            artifact: plan-lisible-dev

  - stage: ApplyDev
    displayName: 'Apply on DEV'
    dependsOn: PlanDev
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - deployment: apply_dev
        environment: dev
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@1
                  inputs:
                    terraformVersion: '$(TERRAFORM_VERSION)'
                - download: current
                  artifact: tfplan-dev
                - task: AzureCLI@2
                  inputs:
                    azureSubscription: 'sc-globalbank-tfstate'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      set -e
                      terraform init
                      terraform apply tfplan -input=false
                    workingDirectory: envs/dev
                    addSpnToEnvironment: true
                  env:
                    TF_VAR_snowflake_token: $(SNOWFLAKE_TOKEN)

  - stage: PlanUat
    displayName: 'Plan on UAT'
    dependsOn: ApplyDev
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - job: plan_uat
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '$(TERRAFORM_VERSION)'
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'sc-globalbank-tfstate'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                set -e
                terraform init
                terraform plan -out=tfplan -input=false
                terraform show -no-color tfplan > plan.txt
              workingDirectory: envs/uat
              addSpnToEnvironment: true
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_TOKEN)
          - publish: envs/uat/tfplan
            artifact: tfplan-uat
          - publish: envs/uat/plan.txt
            artifact: plan-lisible-uat

  - stage: ApplyUat
    displayName: 'Apply on UAT'
    dependsOn: PlanUat
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - deployment: apply_uat
        environment: uat
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformInstaller@1
                  inputs:
                    terraformVersion: '$(TERRAFORM_VERSION)'
                - download: current
                  artifact: tfplan-uat
                - task: AzureCLI@2
                  inputs:
                    azureSubscription: 'sc-globalbank-tfstate'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      set -e
                      terraform init
                      terraform apply tfplan -input=false
                    workingDirectory: envs/uat
                    addSpnToEnvironment: true
                  env:
                    TF_VAR_snowflake_token: $(SNOWFLAKE_TOKEN)

  - stage: Audit
    displayName: 'Drift detection'
    dependsOn: ApplyUat
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    jobs:
      - job: drift_check
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '$(TERRAFORM_VERSION)'
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'sc-globalbank-tfstate'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                set -e
                terraform init
                terraform plan -detailed-exitcode -input=false || [ $? -eq 2 ]
              workingDirectory: envs/uat
              addSpnToEnvironment: true
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_TOKEN)
```

> 🧠 **Les trois règles d'une pipeline Terraform :**
> - `plan` et `apply` ne reçoivent pas la même plan si on modifie le code entre-temps.
> - L'`apply` passe par un environnement avec approbation.
> - Aucun secret n'est dans le YAML, seulement des noms de variables.

## ③ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Plan sur PR, apply sur `main`** | On discute du plan avant de merger ; on applique ce qui a été mergé. |
| **Artefact `tfplan`** | Le plan approuvé est immuable. On n'applique pas un autre plan. |
| **Approbation Azure DevOps** | Un humain lit et approuve avant `apply`. |
| 🔒 **Fédération d'identité / variables groups** | Pas de secret dans Git, pas de secret dans le YAML. |

---

---

# ÉTAPE 2 — Identité technique et Key Vault

> **🔵 Team Platform — Mohamed.** 10 h 45 – 11 h 30.

## Le problème, d'abord

Le PAT utilisé cette semaine expire ce soir. **Il ne peut pas être celui qui exécute la pipeline.**

| Si… | Alors… |
|---|---|
| On conserve le PAT dans la CI | Toute rotation devient une panne |
| On stocke la clé privée dans Git | N'importe qui peut devenir `SYSADMIN` |
| On crée un `snowflake_user` avec mot de passe | On retourne au click-ops |

> 🎯 **La solution est une clé RSA 2048 stockée dans Azure Key Vault, utilisée par un service principal via fédération d'identité.**

## ① 🖱️ Générer la clé (OpenSSL)

Dans un terminal local, **une seule fois** :

```bash
openssl genrsa -out tf-svc-globalbank.p8 2048
openssl rsa -in tf-svc-globalbank.p8 -pubout -out tf-svc-globalbank.pub
```

**La clé privée `.p8` reste sur votre poste pendant 5 minutes.** Elle va directement dans Key Vault.

## ② 🖱️ Créer la clé dans Azure Key Vault

**Portail Azure → Key Vault `kvdata2aitfsecretsmsn` → Secrets → `SnowflakePAT`**

Collez le contenu du fichier `.p8`.

> 🔒 **La clé publique `.pub` va dans Snowflake pour le user technique `TF_SVC_GLOBALBANK`.**

## ③ ⌨️ Créer l'utilisateur technique et le user dans Snowflake

Dans Snowsight (formateur ou user avec `USERADMIN` pour l'instant) :

```sql
CREATE OR REPLACE USER TF_SVC_GLOBALBANK
  LOGIN_NAME = 'TF_SVC_GLOBALBANK'
  RSA_PUBLIC_KEY = '<contenu de tf-svc-globalbank.pub>'
  DEFAULT_ROLE = 'SYSADMIN'
  COMMENT = 'Technical user for Terraform CI';
```

## ④ ⌨️ Module `modules/security/`

`modules/security/variables.tf` :

```hcl
variable "svc_username" {
  type    = string
  default = "TF_SVC_GLOBALBANK"
}

variable "public_key" {
  type      = string
  sensitive = true
}
```

`modules/security/main.tf` :

```hcl
resource "snowflake_user" "tf_svc" {
  name         = var.svc_username
  login_name   = var.svc_username
  rsa_public_key = var.public_key
  default_role = "SYSADMIN"
  comment      = "Technical user for Terraform CI"
}
```

`modules/security/outputs.tf` :

```hcl
output "svc_username" {
  value = snowflake_user.tf_svc.name
}
```

> 🧠 **La clé privée reste dans Key Vault. Terraform n'a jamais besoin de la lire :** le provider Snowflake utilisera un `authenticator` et un `private_key_path` dans la pipeline.

## ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **JWT key-pair** | Terraform s'authentifie avec une clé privée, Snowflake vérifie la clé publique. |
| **Key Vault** | La clé privée vit dans Azure, jamais dans Git, jamais dans un `.tfvars`. |
| **Service user dédié** | Le compte de la CI est distinct des utilisateurs humains. |

---

---

# ÉTAPE 3 — RBAC as Code

> **🔵 Team Platform — Fares.** 11 h 30 – 12 h 30.

## Le problème, d'abord

Cette semaine, les rôles ont été créés « au besoin ». **Lundi, l'auditrice veut un graphe des privilèges : qui peut lire `GB_RAW_DB` ? qui ne le peut pas ?**

| Si… | Alors… |
|---|---|
| On crée des rôles à la main dans Snowsight | On ne peut pas versionner les droits |
| On donne `OWNERSHIP` sans `USAGE` | L'utilisateur ne peut pas consulter |
| On oublie les `FUTURE GRANTS` | Chaque nouvelle table est inaccessible |

> 🎯 **Les rôles et leurs grants doivent être décrits dans Terraform.**

## ① 🖱️ Les rôles cible de GlobalBank

```
   GB_RAW_READER       -- lecture de RAW
   GB_RAW_LOADER       -- écriture dans RAW
   GB_CURATED_READER   -- lecture de CURATED
   GB_MART_READER      -- lecture des data marts
   GB_ADMIN            -- administration des ressources
```

## ② ⌨️ Module `modules/rbac/` (extension du Jour 4)

Ajouter dans `modules/rbac/main.tf` :

```hcl
resource "snowflake_account_role" "functional" {
  for_each = var.roles
  name     = "${var.prefix}_${each.key}_${var.environment}"
  comment  = each.value.comment
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each  = var.database_grants
  role_name = snowflake_account_role.functional[each.value.role_key].name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = each.value.database
  }
}

resource "snowflake_grant_privileges_to_account_role" "schema_usage" {
  for_each  = var.schema_grants
  role_name = snowflake_account_role.functional[each.value.role_key].name
  privileges = ["USAGE"]
  on_schema {
    schema_name = "${each.value.database}.${each.value.schema}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "future_tables" {
  for_each = var.future_grants
  role_name = snowflake_account_role.functional[each.value.role_key].name
  all_privileges = false
  privileges     = each.value.privileges
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${each.value.database}.${each.value.schema}"
    }
  }
}
```

## ③ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **RBAC as Code** | Les rôles, les grants et les `FUTURE GRANTS` sont versionnés. |
| **Rôles fonctionnels vs rôles d'accès** | `GB_RAW_READER` = ce que je fais ; `GB_RAW_LOADER` = ce que je charge. |
| **Future grants** | Chaque nouvelle table hérite automatiquement des droits. |

---

---

# ÉTAPE 4 — Ingestion avancée

> **🟢 Team Data Engineering — Amal · Lara.** 13 h 30 – 14 h 30.

## Le problème, d'abord

Les fichiers de transactions arrivent chaque nuit sur Azure Data Lake. **Aujourd'hui, on les charge manuellement avec `PUT` et `COPY`.** Lundi, on veut que le stage et le format de fichier soient définis dans Terraform.

## ① 🖱️ D'abord, dans Snowsight

1. **Admin → Storage → Stages → `+`**
2. Créer un stage externe `GB_RAW_STAGE` pointant vers `azure://stglobalbankraw.blob.core.windows.net/raw/`
3. Créer un `file format` `GB_CSV` de type CSV.
4. Exécuter `COPY INTO GB_RAW_DB.LANDING.TRANSACTIONS FROM @GB_RAW_STAGE/transactions/ FILE_FORMAT = 'GB_CSV';`

## ② ⌨️ Module `modules/ingestion/`

`modules/ingestion/variables.tf` :

```hcl
variable "prefix" { type = string }
variable "environment" { type = string }
variable "storage_account_url" { type = string }
variable "container_name" { type = string }
```

`modules/ingestion/main.tf` :

```hcl
resource "snowflake_stage" "raw" {
  name        = "${var.prefix}_RAW_STAGE_${var.environment}"
  database    = "${var.prefix}_RAW_${var.environment}"
  schema      = "LANDING"
  url         = "${var.storage_account_url}/${var.container_name}"
  storage_integration = snowflake_storage_integration.azure_raw.name
}

resource "snowflake_file_format" "csv" {
  name     = "${var.prefix}_CSV_${var.environment}"
  database = "${var.prefix}_RAW_${var.environment}"
  schema   = "LANDING"
  format_type = "CSV"
  field_delimiter = ","
  skip_header = 1
  null_if = ["NULL", "N/A"]
}
```

> 🧠 **Le stage et le file format sont de la configuration. Le `COPY INTO` reste une opération SQL exécutée après l'apply.**

## ③ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Stage externe** | Terraform décrit le point d'entrée du cloud ; le data engineer exécute le `COPY`. |
| **File format** | Le contrat CSV/JSON/Parquet est versionné. |
| **Storage integration** | L'identité Azure autorise Snowflake à lire le container. |

---

---

# ÉTAPE 5 — FinOps et Data Products

> **🟠🟣 Teams Business & BI — Manel · Leila · Olfa · Ghassen · Adem · Hadhemi.** 14 h 30 – 15 h 30.

## Le problème, d'abord

Wei a oublié son `DS_WH` allumé toute la nuit. **Il a consommé 47 crédits.** Nadia ne sait pas si son `BI_WH` est utilisé. **Personne ne suit les coûts par zone.**

> 🎯 **On veut un data product qui expose la consommation par warehouse, par équipe et par environnement.**

## ① ⌨️ Resource monitor et warehouse cost

`modules/compute/main.tf` (extension) :

```hcl
resource "snowflake_resource_monitor" "team" {
  name         = "RM_${var.prefix}_${var.environment}"
  credit_quota = var.environment == "PROD" ? 100 : 10

  notify_triggers = [75, 90]
  suspend_trigger = 100
}
```

## ② ⌨️ Vue FinOps avec dbt

`models/finops/warehouse_spend.sql` :

```sql
{{ config(
    materialized='view',
    database=env_var('DBT_FINOPS_DATABASE'),
    schema='MONITORING'
) }}

SELECT
    warehouse_name,
    start_time,
    credits_used,
    LEFT(warehouse_name, 5) AS team_prefix,
    SPLIT_PART(warehouse_name, '_', -1) AS environment
FROM {{ source('snowflake', 'warehouse_metering_history') }}
WHERE start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP)
```

> 🧠 **dbt lit `warehouse_metering_history`, un object Account Usage standard. Aucune donnée sensible n'est copiée.**

## ③ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Resource monitor** | Coupure ou alerte automatique en cas de dépassement de crédits. |
| **dbt + Account Usage** | Le FinOps devient un data product requêtable. |
| **Data product gouverné** | Une vue materialisée, documentée, dans une base dédiée. |

---

---

# ÉTAPE 6 — Capstone : assembler la plateforme

> **Toutes les équipes.** 15 h 45 – 17 h 00.

## Le défi

Sofia veut une **preuve unique** : la plateforme entière peut être recréée à partir du dépôt, sans modification inattendue.

## ① ⌨️ Racine `capstone/`

```
capstone/
├── main.tf          ← appelle tous les modules du projet
├── variables.tf
├── terraform.tfvars
├── backend.tf       ← backend azurerm
└── outputs.tf
```

`capstone/main.tf` (même contenu qu'envs/dev/main.tf) :

```hcl
# Assemblage du puzzle GlobalBank — DEV
# Les modules sont consommes depuis le registry Git / Azure DevOps.

module "rbac" {
  source = "git::file:///D:/git-repos/globalbank-modules-platform//rbac?ref=v1.0.0"

  prefix      = var.prefix
  environment = var.environment
  roles       = var.roles
}

module "compute" {
  source = "git::file:///D:/git-repos/globalbank-modules-platform//compute?ref=v1.0.0"

  prefix         = var.prefix
  environment    = var.environment
  warehouse_size = "X-SMALL"
  warehouses     = var.warehouses
}

module "landing_zone" {
  source = "git::file:///D:/git-repos/globalbank-modules-data-engineering//landing-zone?ref=v1.0.0"

  prefix       = var.prefix
  environment  = var.environment
  zone         = "RAW"
  schema_name  = "LANDING"
  audit_column = "LOAD_TS"
  tables       = var.raw_tables
}

module "data_domain" {
  source = "git::file:///D:/git-repos/globalbank-modules-business-data//data-domain?ref=v1.0.0"

  prefix         = var.prefix
  environment    = var.environment
  domain         = "CUSTOMER"
  classification = "INTERNE"
  tables         = var.domain_tables
}

module "data_mart" {
  source = "git::file:///D:/git-repos/globalbank-modules-bi-analytics//data-mart?ref=v1.0.0"

  prefix      = var.prefix
  environment = var.environment
  mart        = "CUSTOMER"
  audience    = "RESEAU"
  mart_tables = var.mart_tables
}
```

> Pour `envs/uat/main.tf`, le contenu est identique. Seuls `backend.tf` (`key = "APP01/uat.tfstate"`) et `terraform.tfvars` (`environment = "UAT"`) changent.

## ② 🧪 Preuve zero-drift

```bash
cd capstone
terraform init
terraform plan -detailed-exitcode
```

| Exit code | Signification |
|---|---|
| **0** | `No changes.` — la plateforme est alignée. |
| **1** | Erreur. Ne pas appliquer. |
| **2** | Des changements sont encore nécessaires. Analyser. |

## ③ 🧹 Teardown contrôlé

Une fois le capstone validé, chaque apprenant exécute dans son environnement :

```bash
terraform destroy -auto-approve
```

> 💰 **Vérifier que tous les warehouses sont suspendus et que les resource monitors ne déclenchent plus d'alerte.**

---

## 4. Livrables du Jour 5

| Équipe | Livrable |
|---|---|
| 🔵 **Platform** | Pipeline Azure DevOps, user technique `TF_SVC_GLOBALBANK`, modules `security/` et `rbac/` |
| 🟢 **Data Engineering** | Module `ingestion/` avec stage + file format |
| 🟠 **Business Data** | Vues et data products métiers, grants |
| 🟣 **BI** | Modèles dbt FinOps, materialized views |
| **Tous** | Capstone `No changes.`, teardown vérifié |

---

## 5. Navigation

- [<- Jour 4](../day-04/atelier-globalbank-jour-04.md)
- [Architecture cible](../docs/architecture.md)
- [Conventions de nommage](../docs/naming-conventions.md)
