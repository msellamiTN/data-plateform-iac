# ðŸ§ª Lab M5 â€” Module Landing Zone rÃ©utilisable

> [<- Jour 3](../README.md) Â· [<- Jour 2](../../day-02/README.md) Â· **Module 05** Â· [Module suivant ->](../module-06-dynamic-logic/lab.md)

| Ã‰lÃ©ment | Valeur |
|---|---|
| **DurÃ©e** | 60 min |
| **Piste** | `[CORE]` |
| **Workspace** | `$HOME/Data2AI-Labs/data-platform` (le clone) |
| **Dossier de travail** | `labs/m05-modules/` |
| **CoÃ»t** | Warehouses X-SMALL |
| **Cleanup** | `terraform destroy -auto-approve` Ã  la fin |

> `[IMPORTANT]` Avant de commencer, vous devez etre dans la racine du clone
> et avoir execute `Learner-Login.ps1 -SnowflakeOnly` dans **cette session** :
>
> ```powershell
> cd "$HOME\Data2AI-Labs\data-platform"
> .\scripts\Learner-Login.ps1 -LearnerPrefix APP01 -SnowflakeOnly
> ```
>
> Cela set `TF_VAR_snowflake_token` (depuis `secrets/snowflake_pat.txt`)
> et `LEARNER_PREFIX`. Aucun login Azure n'est requis pour ce lab (state local).
>
> RÃ©initialisez le lab pour partir d'un Ã©tat propre :
>
> ```powershell
> .\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M05
> ```
>
> Puis placez-vous dans le dossier du lab et verifiez que tout est pret :
>
> ```powershell
> cd labs\m05-modules
> ..\..\scripts\Test-TerraformReady.ps1
> ```
>
> Si le pre-flight affiche `READY`, lancez `terraform plan -out "m05.tfplan"`.
> Sinon, suivez les corrections indiquees.

## ðŸŽ¯ 1. Mission MÃ©tier & User Story

Les domaines Data ont besoin d'une plateforme cohÃ©rente sans copier des centaines de ressources. Vous allez d'abord crÃ©er les ressources directement, puis les extraire dans un module rÃ©utilisable `landing-zone`, et enfin appeler ce module pour un second domaine.

> **En tant que :** Data Platform Engineer  
> **Je veux :** extraire les ressources Snowflake dans un module Terraform rÃ©utilisable  
> **Afin de :** provisionner plusieurs domaines Data sans duplication de code
> **Votre persona GlobalBank :** appliquez ce lab sur les objets de votre équipe — 🔵 Platform, 🟢 Data Engineering, 🟠 Business Data, 🟣 BI (voir [personas-globalbank.md](../../../shared/docs/personas-globalbank.md)).


---

## ðŸ—ï¸ 2. Architecture & ModÃ¨le Mental

```mermaid
flowchart LR
    M4[M4 â€” Contrats typÃ©s] --> M5[M5 â€” Module Landing Zone]
    M5 --> M6[M6 â€” Metadata-driven IaC]
```

```mermaid
flowchart TD
    ENV[labs/m05-modules/main.tf] -->|module call| MOD[modules/landing-zone/]
    MOD --> DB[snowflake_database]
    MOD --> SC[snowflake_schema]
    MOD --> WH[snowflake_warehouse]
```

## ðŸŽ¯ 3. Objectifs PÃ©dagogiques VÃ©rifiables

- crÃ©er un module Terraform avec une interface typÃ©e;
- crÃ©er les ressources directement, puis les extraire dans un module;
- appeler le module depuis `labs/m05-modules/`;
- versionner le module avec un `README.md` et des `outputs`;
- rÃ©utiliser le module pour un second domaine.

## ï¿½ 4. Pre-Flight Diagnostic (VÃ©rification Initiale)

### PrÃ©requis

- [ ] Jour 0 terminÃ© : `Toolchain status: READY`;
- [ ] `snow sql -q 'SELECT 1' -c training` rÃ©ussit;
- [ ] le clone `data-platform-starter` existe sous `$HOME/Data2AI-Labs/data-platform`.

## ðŸ“ 5. Ã‰tapes d'ImplÃ©mentation Pas-Ã -Pas (80% Hands-On)

### ðŸ“ Ã‰tape 5.0 â€” PrÃ©parer le dossier du lab

#### DÃ©couvrir les fichiers fournis

Le dossier `labs/m05-modules/` contient dÃ©jÃ  les fichiers de base :

| Fichier | RÃ´le |
|---|---|
| `provider.tf` | Provider Snowflake (lit le PAT depuis `../../secrets/`) |
| `versions.tf` | Contraintes de version Terraform et provider |
| `variables.tf` | Variables de base (snowflake_*, learner_prefix, environment) |
| `terraform.tfvars.example` | ModÃ¨le de fichier tfvars Ã  copier |
| `main.tf` | Vide â€” crÃ©Ã© par l'apprenant |
| `outputs.tf` | Vide â€” crÃ©Ã© par l'apprenant |

#### CrÃ©er `terraform.tfvars`

Copiez le modÃ¨le et adaptez les valeurs :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
cd "$HOME\Data2AI-Labs\data-platform\labs\m05-modules"
Copy-Item terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
cd $HOME/Data2AI-Labs/data-platform/labs/m05-modules
cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```
</details>

```hcl
learner_prefix         = "APP01"
environment            = "DEV"

# Snowflake connection (from .env)
snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"
```

Remplacez `APP01` par votre prÃ©fixe apprenant.

#### Ajouter les variables spÃ©cifiques au lab

Dans `variables.tf`, ajoutez Ã  la fin du fichier :

```hcl
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

### ðŸ“ Ã‰tape 5.1 â€” CrÃ©er les ressources directement

Avant d'extraire un module, vous allez crÃ©er les ressources directement dans `main.tf`. Cela vous permettra de voir exactement ce que le module encapsulera.

#### CrÃ©er `locals.tf`

```hcl
locals {
  database_name  = "${var.learner_prefix}_M05_RAW_${var.environment}"
  schema_name    = "INGESTION"
  warehouse_name = "WH_${var.learner_prefix}_M05_ETL_${var.environment}"
  common_comment = "Managed by Terraform | Landing Zone | ${var.learner_prefix}"
}
```

> ðŸ’¡ **Note** : Le prÃ©fixe `M05` dans les noms isole les ressources de ce lab de celles des autres labs.

#### CrÃ©er `main.tf`

```hcl
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

#### CrÃ©er `outputs.tf`

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

#### Formater, valider, planifier

```bash
terraform fmt
terraform init
terraform validate
terraform plan -out "m05.tfplan"
```

âœ… **Checkpoint** : `Plan: 3 to add, 0 to change, 0 to destroy.`

#### Appliquer

```bash
terraform apply m05.tfplan
```

âœ… **Checkpoint** : `Apply complete! Resources: 3 added, 0 changed, 0 destroyed.`

#### VÃ©rifier dans Snowflake

```powershell
snow sql -c training -q "SHOW DATABASES LIKE 'APP01_M05_RAW_DEV'"
snow sql -c training -q "SHOW WAREHOUSES LIKE 'WH_APP01_M05_ETL_DEV'"
```

> Remplacez `APP01` par votre prÃ©fixe.

### ðŸ“ Ã‰tape 5.2 â€” Extraire les ressources dans un module

Maintenant que les ressources existent, vous allez les extraire dans un module rÃ©utilisable.

#### CrÃ©er les dossiers

```bash
New-Item -ItemType Directory -Force -Path "modules/landing-zone" | Out-Null
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
  default     = "DEV"

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

> ðŸ’¡ **Note** : La validation du module accepte jusqu'Ã  10 caractÃ¨res pour `learner_prefix`,
> afin de permettre des prÃ©fixes composÃ©s comme `APP01SAL` (domaine Sales).

#### CrÃ©er `modules/landing-zone/main.tf`

```hcl
locals {
  database_name  = "${var.learner_prefix}_M05_RAW_${var.environment}"
  schema_name    = "INGESTION"
  warehouse_name = "WH_${var.learner_prefix}_M05_ETL_${var.environment}"
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

#### CrÃ©er `modules/landing-zone/README.md`

```markdown
# landing-zone

Creates a RAW database, an INGESTION schema and an ETL warehouse.

## Usage

\`\`\`hcl
module "landing_zone" {
  source             = "./modules/landing-zone"
  learner_prefix     = "ABC"
  environment        = "DEV"
  warehouse_size     = "X-SMALL"
}
\`\`\`

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| learner_prefix | string | â€” | 3-10 uppercase letters |
| environment | string | DEV | DEV, UAT or PROD |
| warehouse_size | string | X-SMALL | Warehouse size |
| data_retention_days | number | 1 | Time travel days |
| auto_suspend_seconds | number | 60 | Auto-suspend seconds |

## Outputs

| Name | Description |
|---|---|
| database_name | RAW database name |
| schema_name | Ingestion schema name |
| warehouse_name | ETL warehouse name |
```

#### Initialiser, formater et valider le module

> `[IMPORTANT]` Vous devez crÃ©er **tous les fichiers du module** (variables.tf, main.tf,
> outputs.tf, versions.tf) **avant** cette Ã©tape. Si un fichier manque, `terraform validate`
> Ã©chouera avec des erreurs de rÃ©fÃ©rence.

```bash
cd modules/landing-zone
terraform init
terraform fmt
terraform validate
```

âœ… **Checkpoint** : `The configuration is valid.`

> ðŸ’¡ **Note** : Un module n'a pas de `provider` block ni de `backend` block. Il dÃ©clare seulement les contraintes et les ressources. `terraform init` tÃ©lÃ©charge le provider pour permettre la validation.

> âš ï¸ **IMPORTANT** : Ne lancez **pas** `terraform init` dans `labs/m05-modules/` tant que
> la Partie 3 n'est pas terminÃ©e. Un module incomplet rÃ©fÃ©rencÃ© depuis `main.tf`
> provoquera des erreurs `Reference to undeclared resource`.

### ðŸ“ Ã‰tape 5.3 â€” Appeler le module depuis main.tf

> `[IMPORTANT]` Cette partie modifie `main.tf`, `locals.tf` ET `outputs.tf`.
> Vous devez faire **toutes les Ã©tapes 3.1 Ã  3.3** avant de lancer `terraform init`.
> Si vous lancez `terraform init` aprÃ¨s seulement l'Ã©tape 3.1, Terraform dÃ©tectera
> le module mais les anciens outputs rÃ©fÃ©renceront des ressources qui n'existent plus.

#### RÃ©Ã©crire `main.tf`

**Remplacez tout le contenu** de `main.tf` par :

```hcl
module "landing_zone" {
  source               = "./modules/landing-zone"
  learner_prefix       = var.learner_prefix
  environment          = var.environment
  warehouse_size       = var.warehouse_size
  data_retention_days  = var.data_retention_days
  auto_suspend_seconds = var.auto_suspend_seconds
}
```

#### Ajouter les blocs `moved`

Sans blocs `moved`, Terraform verrait les ressources du module comme **nouvelles** et proposerait de dÃ©truire puis recrÃ©er la database, le schema et le warehouse (`3 to add, 3 to destroy`). Ajoutez en haut de `main.tf` pour dÃ©placer les ressources existantes dans le state sans les recrÃ©er :

```hcl
moved {
  from = snowflake_database.raw
  to   = module.landing_zone.snowflake_database.raw
}

moved {
  from = snowflake_schema.ingestion
  to   = module.landing_zone.snowflake_schema.ingestion
}

moved {
  from = snowflake_warehouse.etl
  to   = module.landing_zone.snowflake_warehouse.etl
}
```

> Les ressources (database, schema, warehouse) sont maintenant dans le module.
> `main.tf` ne contient plus que l'appel du module et les blocs `moved`.
> Une fois le move appliquÃ© (`terraform apply`), vous pouvez supprimer les blocs `moved`.

#### Supprimer `locals.tf`

Les locals n'Ã©taient utilisÃ©s que par les ressources directes qui sont maintenant dans le module.

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
Remove-Item locals.tf
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
rm locals.tf
```
</details>

#### Remplacer `outputs.tf`

**Remplacez tout le contenu** de `outputs.tf` par :

```hcl
output "database_name" {
  value       = module.landing_zone.database_name
  description = "RAW database name"
}

output "schema_name" {
  value       = module.landing_zone.schema_name
  description = "Ingestion schema name"
}

output "warehouse_name" {
  value       = module.landing_zone.warehouse_name
  description = "ETL warehouse name"
}

output "resource_summary" {
  value = {
    database  = module.landing_zone.database_name
    schema    = module.landing_zone.schema_name
    warehouse = module.landing_zone.warehouse_name
  }
}
```

#### Formater et initialiser

```bash
cd ..
terraform fmt
terraform init
```

Terraform tÃ©lÃ©charge le module local.

#### Planifier

```bash
terraform plan
```

âœ… **Checkpoint** : `No changes.` â€” les ressources existent dÃ©jÃ  et le module produit la mÃªme configuration.

> ðŸ’¡ **Note** : Si Terraform propose de recrÃ©er les ressources, c'est que les noms ou attributs diffÃ¨rent. VÃ©rifiez vos variables.

### ðŸ“ Ã‰tape 5.4 â€” RÃ©utiliser le module pour un second domaine

#### Ajouter un second appel dans `main.tf`

```hcl
module "landing_zone_sales" {
  source               = "./modules/landing-zone"
  learner_prefix       = "${var.learner_prefix}SAL"
  environment          = var.environment
  warehouse_size       = "X-SMALL"
  data_retention_days  = var.data_retention_days
  auto_suspend_seconds = var.auto_suspend_seconds
}
```

#### Ajouter les outputs

```hcl
output "sales_database_name" {
  value       = module.landing_zone_sales.database_name
  description = "Sales RAW database name"
}
```

#### Planifier

```bash
terraform fmt
terraform plan
```

âœ… **Checkpoint** : `3 to add` â€” le second module crÃ©e une nouvelle database, un nouveau schema et un nouveau warehouse.

#### Appliquer

```bash
terraform apply
```

âœ… **Checkpoint** : `3 added, 0 changed, 0 destroyed.`

#### VÃ©rification Non-Destructive dans Snowflake Snowsight

1. Ouvrez **[app.snowflake.com](https://app.snowflake.com)** avec vos identifiants apprenant.
2. Naviguez dans **Data > Databases** et vÃ©rifiez que vos bases originales (crÃ©Ã©es au M01/M04) existent toujours intactes Ã  cÃ´tÃ© de la nouvelle base `SALES`.
3. Le refactoring en module n'a provoquÃ© aucune recrÃ©ation : la migration de code ne dÃ©truit rien si les adresses de ressources sont correctement gÃ©rÃ©es.

---

## ðŸ› 6. Incident ContrÃ´lÃ© (*Chaos Engineering Lab*)

*Que se passe-t-il quand vous modifiez un output dans un module sans adapter l'appelant ?*

### SymptÃ´me & Injection

Dans `modules/landing-zone/outputs.tf`, renommez `database_name` en `db_name` :

```hcl
output "db_name" {  # â† renommÃ©
  value = snowflake_database.raw.name
}
```

### Diagnostic & Observation

Lancez `terraform validate` :

```text
Error: Unsupported attribute
  module.landing_zone.database_name is not defined
```

Le contrat d'interface d'un module est un engagement. Modifier un output casse les appelants en cascade. Utilisez `moved` pour les renommages progressifs.

### RemÃ©diation

Restaurez le nom original `database_name` et constatez le retour Ã  la normale.

---

## ðŸ¤– 7. Validation AutomatisÃ©e (*Check My Progress*)

```powershell
.\scripts\SelfPacedLab.ps1 -Module 5 -All -Report
```

âœ… **RÃ©sultat attendu :**
```text
[PASS] T1 Module directory structure
[PASS] T2 Module inputs/outputs contract
[PASS] T3 Root module instantiation
[PASS] T4 terraform fmt & validate
[PASS] T5 Multiple module instances
Result: 5/5 Tasks Passed.
```

---

## ðŸ† 8. DÃ©fi Autonome (*Unguided Challenge*)

> **ScÃ©nario :** Ajoutez une variable `schemas` (list of strings) au module qui crÃ©e plusieurs schemas dans la mÃªme database avec `for_each`.
> **Contraintes :**
> - `terraform validate` rÃ©ussit;
> - `terraform plan` crÃ©e les schemas supplÃ©mentaires;
> - le module reste rÃ©utilisable sans modification de l'appelant existant.

| CritÃ¨re d'Ã‰valuation | Points |
|---|---:|
| Syntaxe HCL et respect des standards | 30 pts |
| Preuve d'exÃ©cution fonctionnelle | 30 pts |
| Idempotence (`0 to add, 0 to change, 0 to destroy`) | 20 pts |
| Respect des budgets FinOps & SÃ©curitÃ© | 20 pts |
| **Total** | **100 pts** |

## ðŸ§¹ 9. Nettoyage ContrÃ´lÃ© (*FinOps Teardown*)

DÃ©truisez toutes les ressources crÃ©Ã©es dans ce lab (domaine principal + domaine Sales) :

```bash
terraform destroy -auto-approve
```

âœ… **Checkpoint** : `Destroy complete! Resources: 6 destroyed.`

> ðŸ’¡ **Note** : Vous pouvez aussi utiliser `.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M05`
> pour nettoyer automatiquement.

---

## Navigation

[<- Lab M4](../../day-01/module-04-variables-outputs/lab.md) Â· [<- Jour 3](../README.md) Â· **Lab M5** Â· [Lab M6 ->](../module-06-dynamic-logic/lab.md)
