# ðŸ§ª Lab M11 â€” ModÃ¨le RBAC scalable avec Future Grants

> [<- Jour 5](../README.md) Â· [<- Jour 4](../../day-04/README.md) Â· **Module 11** Â· [Module suivant ->](../module-12-capstone/lab.md)

|| Ã‰lÃ©ment | Valeur |
||---|---|
|| **DurÃ©e** | 60 min |
|| **Piste** | `[CORE]` |
|| **Workspace** | `$HOME/Data2AI-Labs/data-platform` (le clone) |
|| **Dossier de travail** | `labs/m11-rbac/` |
|| **CoÃ»t** | Aucun |
|| **Cleanup** | `terraform destroy -auto-approve` Ã  la fin |

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
> Ensuite, rÃ©initialisez le lab pour partir d'un Ã©tat propre :
>
> ```powershell
> .\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M11
> ```
>
> Puis placez-vous dans le dossier du lab et vÃ©rifiez que tout est pret :
>
> ```powershell
> cd "$HOME\Data2AI-Labs\data-platform\labs\m11-rbac"
> ..\..\scripts\Test-TerraformReady.ps1
> ```
>
> Si le pre-flight affiche `READY`, lancez `terraform plan -out "m11.tfplan"`.
> Sinon, suivez les corrections indiquees.

## ðŸŽ¯ 1. Mission MÃ©tier & User Story

L'accÃ¨s aux donnÃ©es doit suivre les fonctions mÃ©tier sans tickets manuels. Vous allez crÃ©er une hiÃ©rarchie de rÃ´les, appliquer le moindre privilÃ¨ge avec des grants ciblÃ©s et configurer des Future Grants pour les nouvelles tables.

> **En tant que :** Data Platform Engineer  
> **Je veux :** crÃ©er une hiÃ©rarchie de rÃ´les Snowflake avec Future Grants  
> **Afin de :** automatiser l'accÃ¨s aux nouvelles tables selon le principe du moindre privilÃ¨ge
> **Votre persona GlobalBank :** appliquez ce lab sur les objets de votre équipe — 🔵 Platform, 🟢 Data Engineering, 🟠 Business Data, 🟣 BI (voir [personas-globalbank.md](../../../shared/docs/personas-globalbank.md)).


---

## ðŸ—ï¸ 2. Architecture & ModÃ¨le Mental

```mermaid
flowchart LR
    M11[M11 â€” RBAC] --> M12[M12 â€” Capstone]
```

```mermaid
flowchart TD
    SYSADMIN --> ROLE_RAW[ROLE_RAW]
    SYSADMIN --> ROLE_CURATED[ROLE_CURATED]
    SYSADMIN --> ROLE_READER[ROLE_READER]
    ROLE_RAW --> GRANT_DB[USAGE on database]
    ROLE_RAW --> GRANT_SCHEMA[USAGE on schema]
    ROLE_RAW --> FUTURE[FUTURE GRANT on tables]
```

## ðŸŽ¯ 3. Objectifs PÃ©dagogiques VÃ©rifiables

- crÃ©er une hiÃ©rarchie de rÃ´les Snowflake avec Terraform;
- accorder des privilÃ¨ges ciblÃ©s par rÃ´le;
- configurer des Future Grants pour les nouvelles tables;
- auditer les grants avec une requÃªte SQL.

## ï¿½ 4. Pre-Flight Diagnostic (VÃ©rification Initiale)

### PrÃ©requis

- [ ] `terraform plan` affiche `No changes` dans `labs/m11-rbac/`.
- [ ] Le dossier `labs/m11-rbac/` contient `provider.tf`, `versions.tf`, `variables.tf` et `terraform.tfvars.example` (fournis).

## ðŸ“ 5. Ã‰tapes d'ImplÃ©mentation Pas-Ã -Pas (80% Hands-On)

### ðŸ“ Ã‰tape 5.1 â€” CrÃ©er le module RBAC

#### CrÃ©er la structure

```bash
cd $HOME/Data2AI-Labs/data-platform/labs/m11-rbac
New-Item -ItemType Directory -Force -Path "modules/rbac" | Out-Null
```

#### CrÃ©er `modules/rbac/variables.tf`

```hcl
variable "learner_prefix" {
  type        = string
  description = "Learner prefix for role naming"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "DEV"
}

variable "database_name" {
  type        = string
  description = "RAW database name"
}

variable "schema_name" {
  type        = string
  description = "Schema name for grants"
  default     = "INGESTION"
}
```

#### CrÃ©er `modules/rbac/main.tf`

```hcl
locals {
  role_raw     = "ROLE_${var.learner_prefix}_M11_RAW_${var.environment}"
  role_curated = "ROLE_${var.learner_prefix}_M11_CUR_${var.environment}"
  role_reader  = "ROLE_${var.learner_prefix}_M11_RDR_${var.environment}"
}

# ------------------------------------------------------------------
# Role hierarchy: SYSADMIN > RAW > CURATED > READER
# ------------------------------------------------------------------

resource "snowflake_account_role" "raw" {
  name    = local.role_raw
  comment = "RAW access role for ${var.learner_prefix} M11"
}

resource "snowflake_account_role" "curated" {
  name    = local.role_curated
  comment = "Curated access role for ${var.learner_prefix} M11"
}

resource "snowflake_account_role" "reader" {
  name    = local.role_reader
  comment = "Read-only role for ${var.learner_prefix} M11"
}

# Grant hierarchy
resource "snowflake_grant_privileges_to_account_role" "curated_to_raw" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.raw.name
  on_account_role   = snowflake_account_role.curated.name
}

resource "snowflake_grant_privileges_to_account_role" "reader_to_curated" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.curated.name
  on_account_role   = snowflake_account_role.reader.name
}

# ------------------------------------------------------------------
# Database and schema grants
# ------------------------------------------------------------------

resource "snowflake_grant_privileges_to_account_role" "raw_db" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.raw.name

  on_schema {
    schema_name = "${var.database_name}.${var.schema_name}"
  }
}

# ------------------------------------------------------------------
# Future Grants: new tables in the schema get SELECT automatically
# ------------------------------------------------------------------

resource "snowflake_grant_privileges_to_account_role" "future_tables" {
  privileges        = ["SELECT", "INSERT", "UPDATE"]
  account_role_name = snowflake_account_role.raw.name

  on_schema_object {
    future {
      database_name = var.database_name
      schema_name   = var.schema_name
      object_type   = "TABLE"
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_future" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.reader.name

  on_schema_object {
    future {
      database_name = var.database_name
      schema_name   = var.schema_name
      object_type   = "TABLE"
    }
  }
}
```

#### CrÃ©er `modules/rbac/outputs.tf`

```hcl
output "role_raw" {
  value = snowflake_account_role.raw.name
}

output "role_curated" {
  value = snowflake_account_role.curated.name
}

output "role_reader" {
  value = snowflake_account_role.reader.name
}
```

#### CrÃ©er `modules/rbac/versions.tf`

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

#### Formater et valider

```bash
cd modules/rbac
terraform fmt
terraform validate
```

### ðŸ“ Ã‰tape 5.2 â€” Appeler le module depuis le lab

#### CrÃ©er la database et le schema dans `main.tf`

Ce lab est autonome : il crÃ©e sa propre database et son schema avant d'appliquer les grants RBAC.

Ã‰ditez `labs/m11-rbac/main.tf` :

```hcl
# ------------------------------------------------------------------
# Database and schema (self-contained for this lab)
# ------------------------------------------------------------------

resource "snowflake_database" "raw" {
  name    = "${var.learner_prefix}_M11_RAW_${var.environment}"
  comment = "RAW database for M11 RBAC lab"
}

resource "snowflake_schema" "ingestion" {
  database = snowflake_database.raw.name
  name     = "INGESTION"
  comment  = "Ingestion schema for M11 RBAC lab"
}

# ------------------------------------------------------------------
# RBAC module
# ------------------------------------------------------------------

module "rbac" {
  source         = "./modules/rbac"
  learner_prefix = var.learner_prefix
  environment    = var.environment
  database_name  = snowflake_database.raw.name
  schema_name    = "INGESTION"
}
```

#### Ajouter les outputs dans `outputs.tf`

```hcl
output "rbac_roles" {
  value = {
    raw     = module.rbac.role_raw
    curated = module.rbac.role_curated
    reader  = module.rbac.role_reader
  }
  description = "RBAC role hierarchy"
}

output "database_name" {
  value = snowflake_database.raw.name
}
```

#### Planifier et appliquer

```bash
cd labs/m11-rbac
terraform fmt
terraform init
terraform validate
terraform plan -out "m11.tfplan"
terraform apply "m11.tfplan"
```

âœ… **Checkpoint** : 3 rÃ´les crÃ©Ã©s + grants + database + schema.

### ðŸ“ Ã‰tape 5.3 â€” Auditer les grants

#### Lister les rÃ´les

```bash
snow sql -c training -q "SHOW ROLES LIKE 'ROLE_APP01_M11_%'"
```

Remplacez `APP01` par votre prÃ©fixe.

#### VÃ©rifier les Future Grants

```bash
snow sql -c training -q "SHOW FUTURE GRANTS IN SCHEMA APP01_M11_RAW_DEV.INGESTION"
```

âœ… **Checkpoint** : des lignes avec `GRANT SELECT` et `GRANT INSERT` pour les futures tables.

#### Tester le Future Grant

CrÃ©ez une table manuellement et vÃ©rifiez que les grants s'appliquent automatiquement :

```bash
snow sql -c training -q "CREATE TABLE APP01_M11_RAW_DEV.INGESTION.TEST_FUTURE (ID INT)"
snow sql -c training -q "SHOW GRANTS ON TABLE APP01_M11_RAW_DEV.INGESTION.TEST_FUTURE"
```

âœ… **Checkpoint** : les grants SELECT et INSERT sont dÃ©jÃ  prÃ©sents grÃ¢ce au Future Grant.

#### Nettoyer la table de test

```bash
snow sql -c training -q "DROP TABLE APP01_M11_RAW_DEV.INGESTION.TEST_FUTURE"
```

### ðŸ“ Ã‰tape 5.4 â€” Principe du moindre privilÃ¨ge

#### VÃ©rifier la sÃ©paration des rÃ´les

| RÃ´le | PrivilÃ¨ges | Usage |
|---|---|---|
| `ROLE_APP01_M11_RAW_DEV` | USAGE schema, INSERT, UPDATE, SELECT | Ingestion ETL |
| `ROLE_APP01_M11_CUR_DEV` | USAGE schema, SELECT | Transformation dbt |
| `ROLE_APP01_M11_RDR_DEV` | USAGE schema, SELECT | Lecture BI |

#### Attribuer le rÃ´le Ã  un utilisateur technique

Ajoutez dans `labs/m11-rbac/main.tf` :

```hcl
# ------------------------------------------------------------------
# Technical user (self-contained for this lab)
# ------------------------------------------------------------------

resource "snowflake_user" "tech" {
  name              = "TF_${var.learner_prefix}_M11_SVC"
  default_role      = module.rbac.role_raw
  default_warehouse = null
  must_change_password = false
}

resource "snowflake_grant_account_role" "tech_raw" {
  role_name = module.rbac.role_raw
  user_name = snowflake_user.tech.name
}
```

#### Planifier et appliquer

```bash
terraform plan -out "m11.tfplan"
terraform apply "m11.tfplan"
```

#### VÃ©rifier

```bash
snow sql -c training -q "SHOW GRANTS TO USER TF_APP01_M11_SVC"
```

âœ… **Checkpoint** : le rÃ´le `ROLE_APP01_M11_RAW_DEV` est attribuÃ© Ã  l'utilisateur technique.

#### Test Interactif des RÃ´les dans Snowflake Snowsight

Pour ressentir concrÃ¨tement l'effet de votre politique de moindre privilÃ¨ge :

1. Ouvrez votre navigateur sur **[app.snowflake.com](https://app.snowflake.com)**.
2. Cliquez sur votre profil en haut Ã  droite et changez de rÃ´le actif : sÃ©lectionnez votre rÃ´le fonctionnel `ROLE_APP01_M11_RAW_DEV` (ou un analyste auquel vous avez hÃ©ritÃ© les droits).
3. Ouvrez une **SQL Worksheet** et exÃ©cutez un test de lecture :
   ```sql
   SELECT * FROM APP01_M11_RAW_DEV.INGESTION.TEST_TABLE LIMIT 5;
   ```
   âœ… **RÃ©sultat attendu :** RequÃªte exÃ©cutÃ©e avec succÃ¨s (droit `SELECT` accordÃ©).
4. Tentez maintenant une opÃ©ration destructive interdite :
   ```sql
   DROP TABLE APP01_M11_RAW_DEV.INGESTION.TEST_TABLE;
   ```
   ðŸ›‘ **RÃ©sultat attendu :** Ã‰chec immÃ©diat avec erreur Snowflake :
   `SQL access control error: Insufficient privileges to operate on table 'TEST_TABLE'`.

---

## ðŸ› 6. Incident ContrÃ´lÃ© (*Chaos Engineering Lab*)

*Une erreur classique en production est d'accorder des droits sur une table ou un schema sans accorder le droit USAGE sur la base de donnÃ©es parente.*

### SymptÃ´me & Injection

Dans votre code Terraform `main.tf`, commentez temporairement le bloc attribuant le privilÃ¨ge `USAGE` sur la database :

```hcl
# PrivilÃ¨ge USAGE commentÃ©
```

Appliquez la modification :

```powershell
terraform apply -auto-approve
```

### Diagnostic & Observation

Dans Snowsight, basculez sur le rÃ´le utilisateur. Bien que le rÃ´le possÃ¨de encore des droits sur les tables, la base de donnÃ©es entiÃ¨re a disparu de l'arborescence graphique !

*Principe Snowflake : Sans USAGE sur le conteneur parent, aucun objet enfant n'est accessible.*

### RemÃ©diation

DÃ©commentez le grant `USAGE`, appliquez avec `terraform apply`, et vÃ©rifiez la rÃ©apparition instantanÃ©e de la base dans Snowsight.

---

## ðŸ¤– 7. Validation AutomatisÃ©e (*Check My Progress*)

ExÃ©cutez le script d'auto-Ã©valuation pour vÃ©rifier la conformitÃ© de votre modÃ¨le RBAC :

```powershell
.\scripts\SelfPacedLab.ps1 -Module 11 -All -Report
```

âœ… **RÃ©sultat attendu :**
```text
[PASS] T1 Access roles declared (AR_*)
[PASS] T2 Functional roles declared (FR_*)
[PASS] T3 Future grants defined
[PASS] T4 terraform fmt & validate passed
[PASS] T5 Least privilege compliance verified
Result: 5/5 Tasks Passed.
```

---

## ðŸ† 8. DÃ©fi Autonome (*Unguided Challenge*)

> **ScÃ©nario :** Ajoutez un rÃ´le `ROLE_APP01_M11_ADMIN_DEV` qui a le droit de crÃ©er des schemas dans la database, et attribuez-le Ã  un utilisateur `ADMIN_APP01_M11`.
> **Contraintes :**
> - `terraform plan` crÃ©e le rÃ´le et le grant;
> - `SHOW GRANTS TO USER ADMIN_APP01_M11` affiche le rÃ´le;
> - le rÃ´le peut crÃ©er un schema de test.

| CritÃ¨re d'Ã‰valuation | Points |
|---|---:|
| Syntaxe HCL et respect des standards | 30 pts |
| Preuve d'exÃ©cution fonctionnelle | 30 pts |
| Idempotence (`0 to add, 0 to change, 0 to destroy`) | 20 pts |
| Respect des budgets FinOps & SÃ©curitÃ© | 20 pts |
| **Total** | **100 pts** |

## ðŸ§¹ 9. Nettoyage ContrÃ´lÃ© (*FinOps Teardown*)

DÃ©truisez toutes les ressources crÃ©Ã©es dans ce lab :

```bash
cd labs/m11-rbac
terraform destroy -auto-approve
```

> Vous pouvez aussi utiliser `.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M11` depuis la racine du clone pour nettoyer automatiquement.

---

## Navigation

[<- Lab M10](../module-10-security-auth/lab.md) Â· [<- Jour 5](../README.md) Â· **Lab M11** Â· [Lab M12 ->](../module-12-capstone/lab.md)
