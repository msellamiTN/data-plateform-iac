# ðŸ§ª Lab M8 â€” Gestion multi-environnements : DEV, UAT, PROD

> [<- Jour 4](../README.md) Â· [<- Module precedent](../module-07-cicd-pipeline/lab.md) Â· **Module 08** Â· [Jour 5 ->](../../day-05/README.md)

| Ã‰lÃ©ment | Valeur |
|---|---|
| **DurÃ©e** | 50 min |
| **Piste** | `[CORE]` |
| **Workspace** | `$HOME/Data2AI-Labs/data-platform` (le clone) |
| **Dossier de travail** | `labs/m08-environments/dev/`, `labs/m08-environments/uat/`, `labs/m08-environments/prod/` |
| **CoÃ»t** | Warehouses X-SMALL en DEV/UAT, SMALL en PROD |
| **Cleanup** | `terraform destroy -auto-approve` pour chaque environnement |

> `[IMPORTANT]` Avant de commencer, vous devez etre dans la racine du clone
> et avoir execute `Learner-Login.ps1` dans **cette session** :
>
> ```powershell
> cd "$HOME\Data2AI-Labs\data-platform"
> .\scripts\Learner-Login.ps1 -LearnerPrefix APP01
> ```
>
> Cela set `TF_VAR_snowflake_token` (depuis `secrets/snowflake_pat.txt`)
> et les variables `ARM_*` pour Terraform.
>
> RÃ©initialisez le lab pour partir d'un Ã©tat propre :
>
> ```powershell
> .\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M08
> ```
>
> Puis placez-vous dans le dossier du lab et verifiez que tout est pret :
>
> ```powershell
> cd labs\m08-environments
> ..\..\scripts\Test-TerraformReady.ps1
> ```
>
> Si le pre-flight affiche `READY`, vous pouvez commencer.
> Sinon, suivez les corrections indiquees.

## ðŸŽ¯ 1. Mission MÃ©tier & User Story

DEV, UAT et PROD ont des risques, coÃ»ts et rythmes diffÃ©rents. Vous allez crÃ©er un module `landing-zone`, puis le dÃ©ployer dans les trois environnements avec une isolation de state et de nommage.

> **En tant que :** Data Platform Engineer  
> **Je veux :** dÃ©ployer un module Terraform dans DEV, UAT et PROD avec isolation de state  
> **Afin de :** garantir qu'aucune modification d'un environnement n'impacte les autres

---

## ðŸ—ï¸ 2. Architecture & ModÃ¨le Mental

```mermaid
flowchart LR
    M7[M7 â€” Pipeline GitOps] --> M8[M8 â€” Environnements isolÃ©s]
    M8 --> M9[M9 â€” Ingestion Snowflake]
```

```mermaid
flowchart TD
    DEV[labs/m08-environments/dev] -->|training/APP01/m08-dev/terraform.tfstate| AZURE[(Azure Blob)]
    UAT[labs/m08-environments/uat] -->|training/APP01/m08-uat/terraform.tfstate| AZURE
    PROD[labs/m08-environments/prod] -->|training/APP01/m08-prod/terraform.tfstate| AZURE
    DEV --> MOD[modules/landing-zone]
    UAT --> MOD
    PROD --> MOD
```

## ðŸŽ¯ 3. Objectifs PÃ©dagogiques VÃ©rifiables

- crÃ©er un module `landing-zone` rÃ©utilisable;
- dÃ©ployer le module dans DEV, UAT et PROD;
- isoler le state par environnement avec des clÃ©s distinctes;
- dÃ©finir une matrice de paramÃ¨tres par environnement;
- comprendre la diffÃ©rence entre workspaces et directories.

## ï¿½ 4. Pre-Flight Diagnostic (VÃ©rification Initiale)

### PrÃ©requis

- [ ] Jour 0 terminÃ© : `Toolchain status: READY`;
- [ ] `snow sql -q 'SELECT 1' -c training` rÃ©ussit;
- [ ] le clone `data-platform-starter` existe sous `$HOME/Data2AI-Labs/data-platform`.

## ðŸ“ 5. Ã‰tapes d'ImplÃ©mentation Pas-Ã -Pas (80% Hands-On)

### ðŸ“ Ã‰tape 5.0 â€” CrÃ©er le module landing-zone

#### CrÃ©er la structure de dossiers

```bash
cd "$HOME/Data2AI-Labs/data-platform/labs/m08-environments"
New-Item -ItemType Directory -Force -Path "modules/landing-zone" | Out-Null
New-Item -ItemType Directory -Force -Path "dev", "uat", "prod" | Out-Null
```

#### CrÃ©er `modules/landing-zone/variables.tf`

```hcl
variable "learner_prefix" {
  type        = string
  description = "Unique uppercase prefix assigned to the learner"

  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2,4}$", var.learner_prefix))
    error_message = "learner_prefix must contain 3-5 uppercase letters or digits."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "environment must be DEV, UAT or PROD."
  }
}

variable "warehouse_size" {
  type        = string
  description = "Warehouse size"
  default     = "X-SMALL"

  validation {
    condition     = contains(["X-SMALL", "SMALL", "MEDIUM"], var.warehouse_size)
    error_message = "warehouse_size must be X-SMALL, SMALL or MEDIUM."
  }
}

variable "data_retention_days" {
  type        = number
  description = "Time travel retention in days"
  default     = 1

  validation {
    condition     = var.data_retention_days >= 0 && var.data_retention_days <= 90
    error_message = "data_retention_days must be between 0 and 90."
  }
}

variable "auto_suspend_seconds" {
  type        = number
  description = "Warehouse auto-suspend in seconds"
  default     = 60

  validation {
    condition     = var.auto_suspend_seconds >= 60 && var.auto_suspend_seconds <= 3600
    error_message = "auto_suspend_seconds must be between 60 and 3600."
  }
}
```

#### CrÃ©er `modules/landing-zone/main.tf`

```hcl
locals {
  database_name  = "${var.learner_prefix}_M08_RAW_${var.environment}"
  schema_name    = "INGESTION"
  warehouse_name = "WH_${var.learner_prefix}_M08_ETL_${var.environment}"
  common_comment = "Managed by Terraform | Landing Zone | ${var.learner_prefix}"
}

resource "snowflake_database" "raw" {
  name                        = local.database_name
  comment                     = local.common_comment
  data_retention_time_in_days = var.data_retention_days
}

resource "snowflake_schema" "ingestion" {
  database = snowflake_database.raw.name
  name     = local.schema_name
  comment  = local.common_comment
}

resource "snowflake_warehouse" "etl" {
  name                = local.warehouse_name
  comment             = local.common_comment
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.auto_suspend_seconds
  auto_resume         = true
  initially_suspended = true
}
```

#### CrÃ©er `modules/landing-zone/outputs.tf`

```hcl
output "database_name" {
  value       = snowflake_database.raw.name
  description = "RAW database name"
}

output "schema_name" {
  value       = snowflake_schema.ingestion.name
  description = "Ingestion schema name"
}

output "warehouse_name" {
  value       = snowflake_warehouse.etl.name
  description = "ETL warehouse name"
}
```

#### CrÃ©er `modules/landing-zone/versions.tf`

```hcl
terraform {
  required_version = ">= 1.14.0, < 2.0.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.14.0"
    }
  }
}
```

#### Valider le module

```bash
cd modules/landing-zone
terraform init
terraform fmt
terraform validate
```

âœ… **Checkpoint** : `The configuration is valid.`

### ðŸ“ Ã‰tape 5.1 â€” Configurer DEV

#### CrÃ©er les fichiers Terraform dans `dev/`

```bash
cd ../dev
```

CrÃ©ez `versions.tf` :

```hcl
terraform {
  required_version = "= 1.14.5"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.14.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-data-platform-tfstate"
    storage_account_name = "stdataplatformtfstate"
    container_name       = "tfstate"
    key                  = "training/APP01/m08-dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

> ðŸ’¡ **Note** : La clÃ© `training/APP01/m08-dev/terraform.tfstate` isole le state DEV
> des states UAT et PROD. Remplacez `APP01` par votre prÃ©fixe.

CrÃ©ez `provider.tf` :

```hcl
locals {
  # From labs/m08-environments/dev/, ../../../ = project root
  pat_file = "${path.module}/../../../secrets/snowflake_pat.txt"
  snowflake_token = try(trim(file(local.pat_file), "\n\r"), var.snowflake_token, "")
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = local.snowflake_token
}
```

> âš ï¸ **IMPORTANT** : Depuis `labs/m08-environments/dev/`, le chemin vers `secrets/`
> est `../../../secrets/` (trois niveaux vers le haut). Adaptez le chemin si votre
> structure diffÃ¨re.

CrÃ©ez `variables.tf` :

```hcl
variable "snowflake_organization" {
  type        = string
  description = "Snowflake organization name (from .env)"
}

variable "snowflake_account" {
  type        = string
  description = "Snowflake account name (from .env)"
}

variable "snowflake_user" {
  type        = string
  description = "Snowflake user name (from .env)"
}

variable "snowflake_token" {
  type        = string
  description = "Snowflake PAT (passed via TF_VAR_snowflake_token)"
  sensitive   = true
  default     = ""
}

variable "learner_prefix" {
  type        = string
  description = "Unique uppercase prefix assigned to the learner"

  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2,4}$", var.learner_prefix))
    error_message = "learner_prefix must contain 3-5 uppercase letters or digits."
  }
}
```

CrÃ©ez `main.tf` :

```hcl
module "landing_zone" {
  source               = "../modules/landing-zone"
  learner_prefix       = var.learner_prefix
  environment          = "DEV"
  warehouse_size       = "X-SMALL"
  data_retention_days  = 1
  auto_suspend_seconds = 60
}
```

CrÃ©ez `outputs.tf` :

```hcl
output "database_name" {
  value = module.landing_zone.database_name
}

output "warehouse_name" {
  value = module.landing_zone.warehouse_name
}
```

CrÃ©ez `terraform.tfvars` :

```hcl
snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"
learner_prefix         = "APP01"
```

Remplacez `APP01` par votre prÃ©fixe apprenant.

#### Initialiser et planifier

```bash
terraform fmt
terraform init
terraform validate
terraform plan -out "m08-dev.tfplan"
```

âœ… **Checkpoint** : `3 to add` â€” database, schema et warehouse DEV.

#### Appliquer

```bash
terraform apply m08-dev.tfplan
```

#### VÃ©rifier dans Snowflake

```powershell
snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M08_RAW_DEV'"
```

> Remplacez `APP01` par votre prÃ©fixe.

### ðŸ“ Ã‰tape 5.2 â€” Configurer UAT

#### CrÃ©er les fichiers dans `uat/`

```bash
cd ../uat
```

RÃ©pÃ©tez la mÃªme structure que DEV avec ces diffÃ©rences :

**`versions.tf`** â€” clÃ© backend diffÃ©rente :

```hcl
  backend "azurerm" {
    resource_group_name  = "rg-data-platform-tfstate"
    storage_account_name = "stdataplatformtfstate"
    container_name       = "tfstate"
    key                  = "training/APP01/m08-uat/terraform.tfstate"
    use_azuread_auth     = true
  }
```

**`provider.tf`** â€” identique Ã  DEV (chemin `../../../secrets/`).

**`variables.tf`** â€” identique Ã  DEV.

**`main.tf`** â€” paramÃ¨tres UAT :

```hcl
module "landing_zone" {
  source               = "../modules/landing-zone"
  learner_prefix       = var.learner_prefix
  environment          = "UAT"
  warehouse_size       = "X-SMALL"
  data_retention_days  = 7
  auto_suspend_seconds = 120
}
```

**`outputs.tf`** â€” identique Ã  DEV.

**`terraform.tfvars`** â€” identique Ã  DEV.

#### Initialiser, planifier, appliquer

```bash
terraform fmt
terraform init
terraform validate
terraform plan -out "m08-uat.tfplan"
terraform apply m08-uat.tfplan
```

âœ… **Checkpoint** : `3 to add` â€” database, schema et warehouse UAT.

#### VÃ©rifier dans Snowflake

```powershell
snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M08_RAW_UAT'"
```

### ðŸ“ Ã‰tape 5.3 â€” Configurer PROD

#### CrÃ©er les fichiers dans `prod/`

```bash
cd ../prod
```

RÃ©pÃ©tez la mÃªme structure avec ces diffÃ©rences :

**`versions.tf`** â€” clÃ© backend diffÃ©rente :

```hcl
  backend "azurerm" {
    resource_group_name  = "rg-data-platform-tfstate"
    storage_account_name = "stdataplatformtfstate"
    container_name       = "tfstate"
    key                  = "training/APP01/m08-prod/terraform.tfstate"
    use_azuread_auth     = true
  }
```

**`main.tf`** â€” paramÃ¨tres PROD :

```hcl
module "landing_zone" {
  source               = "../modules/landing-zone"
  learner_prefix       = var.learner_prefix
  environment          = "PROD"
  warehouse_size       = "SMALL"
  data_retention_days  = 30
  auto_suspend_seconds = 300
}
```

#### Initialiser, planifier, appliquer

```bash
terraform fmt
terraform init
terraform validate
terraform plan -out "m08-prod.tfplan"
terraform apply m08-prod.tfplan
```

#### VÃ©rifier

```powershell
snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M08_RAW_PROD'"
snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01_M08_ETL_PROD'"
```

### ðŸ“ Ã‰tape 5.4 â€” Matrice de paramÃ¨tres

#### Comparer les environnements

| ParamÃ¨tre | DEV | UAT | PROD |
|---|---|---|---|
| Warehouse size | X-SMALL | X-SMALL | SMALL |
| Data retention | 1 jour | 7 jours | 30 jours |
| Auto-suspend | 60s | 120s | 300s |
| State key | `training/APP01/m08-dev/terraform.tfstate` | `training/APP01/m08-uat/terraform.tfstate` | `training/APP01/m08-prod/terraform.tfstate` |
| Database | `APP01_M08_RAW_DEV` | `APP01_M08_RAW_UAT` | `APP01_M08_RAW_PROD` |
| Warehouse | `WH_APP01_M08_ETL_DEV` | `WH_APP01_M08_ETL_UAT` | `WH_APP01_M08_ETL_PROD` |

#### VÃ©rifier l'isolation du state

```bash
az storage blob list \
    --account-name "$ARM_STORAGE_ACCOUNT" \
    --container-name "$ARM_CONTAINER" \
    --auth-mode login \
    --query "[].name" -o tsv
```

âœ… **Checkpoint** :

```text
training/APP01/m08-dev/terraform.tfstate
training/APP01/m08-uat/terraform.tfstate
training/APP01/m08-prod/terraform.tfstate
```

### ðŸ“ Ã‰tape 5.5 â€” Workspaces vs directories

#### Comprendre les deux approches

| CritÃ¨re | Workspaces | Directories |
|---|---|---|
| State | MÃªme backend, workspace diffÃ©rent | Backends avec clÃ©s diffÃ©rentes |
| Code | Un seul dossier | Un dossier par environnement |
| Variables | `terraform.workspace` | Fichiers `.tfvars` sÃ©parÃ©s |
| RecommandÃ© pour | ExpÃ©rimentation | Production |

#### Pourquoi directories ici

L'approche par directories (utilisÃ©e dans ce lab) est prÃ©fÃ©rÃ©e pour la production car :

- chaque environnement a son propre backend key;
- les variables sont explicites dans des fichiers sÃ©parÃ©s;
- le code est auditable indÃ©pendamment;
- pas de risque de workspace confusion.

#### VÃ©rification Azure Portal & Snowsight

**Portail Microsoft Azure (`portal.azure.com`) :**
1. Naviguez vers votre compte de stockage > Conteneurs > `tfstate`.
2. VÃ©rifiez la prÃ©sence des **trois fichiers de state distincts** :
   - `training/APP01/m08-dev/terraform.tfstate`
   - `training/APP01/m08-uat/terraform.tfstate`
   - `training/APP01/m08-prod/terraform.tfstate`
3. Les trois fichiers sont physiquement sÃ©parÃ©s : aucune modification ne peut cascader d'un environnement Ã  l'autre.

**Snowflake Snowsight (`app.snowflake.com`) :**
1. Naviguez dans **Data > Databases**.
2. Constatez la coexistence des objets DEV, UAT et PROD avec des prÃ©fixes distincts et des configurations adaptÃ©es (taille de warehouse, durÃ©e de rÃ©tention).

---

## ðŸ› 6. Incident ContrÃ´lÃ© (*Chaos Engineering Lab*)

*DÃ©montrez que modifier DEV ne peut jamais impacter PROD :*

### SymptÃ´me & Injection

Dans le dossier `dev/`, modifiez le commentaire du warehouse ou un attribut quelconque.

### Diagnostic & Observation

Depuis le dossier `prod/`, lancez :

```powershell
terraform plan
```

RÃ©sultat attendu : `No changes. Your infrastructure matches the configuration.` Le state PROD est totalement isolÃ© du state DEV.

### RemÃ©diation & Enseignement

L'approche par rÃ©pertoires dÃ©diÃ©s garantit une isolation de production qui serait impossible avec les workspaces Terraform.

---

## ðŸ¤– 7. Validation AutomatisÃ©e (*Check My Progress*)

```powershell
.\scripts\SelfPacedLab.ps1 -Module 8 -All -Report
```

âœ… **RÃ©sultat attendu :**
```text
[PASS] T1 Directory-based layout (dev/uat/prod)
[PASS] T2 Isolated backend keys
[PASS] T3 Environment-specific variables
[PASS] T4 terraform fmt & validate
[PASS] T5 Cross-environment isolation verified
Result: 5/5 Tasks Passed.
```

---

## ðŸ† 8. DÃ©fi Autonome (*Unguided Challenge*)

> **ScÃ©nario :** Auditez l'isolation des trois environnements et prouvez qu'aucune quatriÃ¨me clÃ© de state n'est crÃ©Ã©e.
> **Contraintes :**
> - `terraform init` rÃ©ussit dans `dev/`, `uat/` et `prod/`;
> - chaque backend contient `use_azuread_auth = true`;
> - la liste Azure Blob, obtenue avec `--auth-mode login`, contient uniquement les clÃ©s `training/APP01/m08-dev|uat|prod/terraform.tfstate` attendues;
> - les databases s'appellent `APP01_M08_RAW_DEV`, `APP01_M08_RAW_UAT` et `APP01_M08_RAW_PROD`.

| CritÃ¨re d'Ã‰valuation | Points |
|---|---:|
| Syntaxe HCL et respect des standards | 30 pts |
| Preuve d'exÃ©cution fonctionnelle | 30 pts |
| Idempotence (`0 to add, 0 to change, 0 to destroy`) | 20 pts |
| Respect des budgets FinOps & SÃ©curitÃ© | 20 pts |
| **Total** | **100 pts** |

## ðŸ§¹ 9. Nettoyage ContrÃ´lÃ© (*FinOps Teardown*)

DÃ©truisez les ressources de chaque environnement, du plus risquÃ© au moins risquÃ© :

```bash
cd prod
terraform destroy -auto-approve

cd ../uat
terraform destroy -auto-approve

cd ../dev
terraform destroy -auto-approve
```

âœ… **Checkpoint** : `Destroy complete!` pour chaque environnement.

> ðŸ’¡ **Note** : Vous pouvez aussi utiliser `.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M08`
> pour nettoyer automatiquement les ressources DEV. Pour UAT et PROD, utilisez
> `.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M08 -Environment UAT` et
> `.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M08 -Environment PROD`.

---

## Navigation

[<- Lab M7](../module-07-cicd-pipeline/lab.md) Â· [<- Jour 4](../README.md) Â· **Lab M8** Â· [Lab M9 ->](../../day-05/module-09-snowflake-advanced/lab.md)
