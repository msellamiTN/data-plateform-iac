# M03 — Variables

| Élément | Valeur |
|---|---|
| **Durée** | 2 h 30 |
| **Prérequis** | [M02 — Cycle de vie](../module-02-cycle-de-vie/lab.md) terminé |
| **Dossier de travail** | `C:\terraform-labs\m03-variables\` |
| **Coût** | Warehouse X-SMALL + 1 database (< $0.01) |

---

## Objectif en une phrase

À la fin de ce module, vous paramétrez vos ressources avec des **variables typées et
validées**, et vous savez qu'une variable modifiée dans `terraform.tfvars` est
détectée par `terraform plan` sans toucher au code.

## Ce que vous allez construire

```
variables.tf   : 6 variables (typées, validées)
main.tf        : 1 warehouse + 1 database, noms paramétrés
terraform.tfvars : vos valeurs
```

> La **règle d'or** : le code (`main.tf`) ne contient **aucune valeur en dur**. Toutes
> les valeurs viennent des variables. Changer une valeur = changer `terraform.tfvars`,
> pas le code.

---

## Étape 0 — Vérifier que je suis prêt

```powershell
terraform version
Test-Path C:\terraform-labs\secrets\snowflake-pat.txt
```

✅ **Checkpoint 0 :** `1.14.5` et `True`.

---

## Étape 1 — Préparer le dossier

Créez `C:\terraform-labs\m03-variables\` et ouvrez-le dans VS Code.

Créez `versions.tf`, `provider.tf` (identiques au M01). Nous allons écrire un
`variables.tf` enrichi et un `main.tf` paramétré.

---

## Étape 2 — Écrire `variables.tf` (variables typées et validées)

Créez `variables.tf` :

```hcl
variable "snowflake_organization" {
  description = "Identifiant d'organisation Snowflake (ex: ABCDEFG)."
  type        = string
}

variable "snowflake_account" {
  description = "Identifiant de compte Snowflake (ex: XY12345)."
  type        = string
}

variable "snowflake_user" {
  description = "Utilisateur Snowflake de l'apprenant (ex: APP01)."
  type        = string
}

variable "snowflake_role" {
  description = "Rôle utilisé par Terraform."
  type        = string
  default     = "SYSADMIN"
}

variable "snowflake_token" {
  description = "PAT Snowflake. Vide en J1-J3 (lu depuis le fichier)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "learner_prefix" {
  description = "Préfixe apprenant unique (APP01 à APP11)."
  type        = string
  validation {
    condition     = can(regex("^APP[0-9]{2}$", var.learner_prefix))
    error_message = "Le préfixe doit respecter le format APPxx (ex: APP01)."
  }
}

variable "environment" {
  description = "Environnement cible."
  type        = string
  default     = "DEV"
  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "L'environnement doit être DEV, UAT ou PROD."
  }
}

variable "warehouse_size" {
  description = "Taille du warehouse. X-SMALL ou SMALL uniquement (FinOps)."
  type        = string
  default     = "X-SMALL"
  validation {
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "warehouse_size doit être X-SMALL ou SMALL. Les tailles supérieures sont interdites en formation."
  }
}

variable "warehouse_auto_suspend" {
  description = "Délai d'auto-suspend en secondes (60 à 600)."
  type        = number
  default     = 60
  validation {
    condition     = var.warehouse_auto_suspend >= 60 && var.warehouse_auto_suspend <= 600
    error_message = "auto_suspend doit être entre 60 et 600 secondes."
  }
}

variable "database_name" {
  description = "Nom de la database (sans le préfixe). Ex: RAW, ANALYTICS."
  type        = string
  default     = "RAW"
}
```

🧠 **Pourquoi — les éléments d'une variable :**

| Élément | Rôle |
|---|---|
| `description` | Documente la variable (visible dans `terraform validate`) |
| `type` | Contraint le type (`string`, `number`, `list`, `map`, `object`) |
| `default` | Valeur si non fournie dans `tfvars` |
| `validation` | Refuse les valeurs hors-standard **avant** le plan |
| `sensitive` | Masque la valeur dans les sorties (logs, plan) — voir encadré ci-dessous |
| `nullable` | `false` interdit la valeur `null` (défaut : `true`) |

> La `validation` est votre **garde-fou FinOps** : elle empêche un `LARGE` ou un
> `auto_suspend = 0` (warehouse jamais suspendu = coûteux) d'atteindre Snowflake.

### 🔒 Données sensibles et le state

`sensitive = true` sur `snowflake_token` masque le PAT dans le terminal et le plan.
**Mais attention** : le fichier `terraform.tfstate` contient les secrets **en
clair**. C'est pourquoi :

- le state local reste hors Git (`.gitignore`) ;
- au M12, le state partira dans un backend Azure **chiffré et verrouillé** ;
- au M16, le PAT quittera même votre poste pour Azure Key Vault.

> Pour aller plus loin : Terraform ≥ 1.10 propose les **variables `ephemeral`** —
> des valeurs qui ne sont **jamais écrites** dans le state. C'est l'horizon
> « zéro secret persistant » ; inutile ici, bon à connaître.

✅ **Checkpoint 1 :** `terraform validate` réussit avec ce `variables.tf`.

---

## Étape 3 — Écrire `terraform.tfvars`

```hcl
snowflake_organization    = "<VOTRE_ORG>"
snowflake_account         = "<VOTRE_COMPTE>"
snowflake_user            = "APP01"
snowflake_role            = "SYSADMIN"
learner_prefix            = "APP01"
environment               = "DEV"
warehouse_size            = "X-SMALL"
warehouse_auto_suspend    = 60
database_name             = "RAW"
```

> Remplacez `<VOTRE_ORG>` et `<VOTRE_COMPTE>` par vos valeurs.

---

## Étape 4 — Écrire `main.tf` (ressources paramétrées)

Créez `main.tf` :

```hcl
resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M03_ETL_${var.environment}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.warehouse_auto_suspend
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL paramétré (M03) pour ${var.learner_prefix}"
}

resource "snowflake_database" "raw" {
  name    = "${var.learner_prefix}_M03_${upper(var.database_name)}_${var.environment}"
  comment = "Database ${var.database_name} paramétrée (M03) pour ${var.learner_prefix}"
}
```

🧠 **Pourquoi :**
- Aucune valeur en dur dans `main.tf` : tout vient des variables.
- `${var.learner_prefix}_M03_${upper(var.database_name)}_${var.environment}` produit
  ex: `APP01_M03_RAW_DEV`. La fonction `upper()` met en majuscules.
- La database est **une nouvelle ressource** : vous réutilisez la boucle clic → SQL →
  HCL. Allez voir `Databases` dans Snowsight pour connaître les champs.

---

## Étape 5 — Init, validate, plan, apply

```powershell
cd C:\terraform-labs\m03-variables
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

👀 **Résultat attendu au plan :**

```
  # snowflake_database.raw will be created
  + resource "snowflake_database" "raw" {
      + name    = "APP01_M03_RAW_DEV"
      + comment = "Database RAW paramétrée (M03) pour APP01"
    }

  # snowflake_warehouse.etl will be created
  + resource "snowflake_warehouse" "etl" {
      + name           = "APP01_M03_ETL_DEV"
      + warehouse_size = "X-SMALL"
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

✅ **Checkpoint 2 :** `Apply complete! Resources: 2 added`. Snowsight montre le
warehouse `APP01_M03_ETL_DEV` et la database `APP01_M03_RAW_DEV`.

---

## Étape 6 — Modifier une variable → plan détecte

### 6.1 Changer `warehouse_auto_suspend` dans `terraform.tfvars`

```hcl
warehouse_auto_suspend = 120
```

### 6.2 Plan

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend = 60 -> 120
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

✅ **Checkpoint 3 :** vous avez changé une **valeur** (pas le code) et Terraform
détecte la différence.

🧠 **Pourquoi :** c'est l'intérêt des variables. Le code (`main.tf`) est **stable** ;
seul `terraform.tfvars` change entre les environnements (DEV, PROD). Au M13, vous
aurez un `tfvars` par environnement.

### 6.3 Appliquer

```powershell
terraform apply
```

---

## Étape 7 — Tester la validation (refus d'une valeur interdite)

### 7.1 Mettre une taille interdite

Dans `terraform.tfvars` :

```hcl
warehouse_size = "LARGE"
```

### 7.2 Plan

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
Error: warehouse_size must être X-SMALL ou SMALL. Les tailles supérieures sont
interdites en formation.
```

✅ **Checkpoint 4 :** le plan **échoue avant d'atteindre Snowflake**. La validation
protège votre compte.

### 7.3 Restaurer

```hcl
warehouse_size = "X-SMALL"
```

```powershell
terraform plan
```

👀 Doit afficher `No changes.` (la valeur est revenue à la valeur appliquée).

---

## Étape 8 — Override en ligne de commande (`-var`)

Sans modifier `terraform.tfvars`, vous pouvez surcharger une variable pour un plan
ponctuel :

```powershell
terraform plan -var="database_name=ANALYTICS"
```

👀 **Résultat attendu :** le plan propose de **créer** `APP01_M03_ANALYTICS_DEV` (et
de détruire `APP01_M03_RAW_DEV` si vous avez déjà appliqué — attention au `-/+`).

> ⚠️ Ne faites **pas** l'apply ici : cela détruirait votre database RAW. Le `-var` est
> utile pour des tests ponctuels, mais `terraform.tfvars` reste la source de vérité.

✅ **Checkpoint 5 :** vous comprenez la priorité : `-var` > `terraform.tfvars` >
`default`.

---

## Casser pour comprendre (5 min)

Mettez `warehouse_auto_suspend = 30` dans `terraform.tfvars` (en dessous du minimum
de 60). `terraform plan` doit échouer avec votre message d'erreur. Restaurer à 60.

---

## Défi autonome (optionnel, 15 min)

**Défi A — commentaire paramétré.** Ajoutez une variable `warehouse_comment`
(string, sans validation) et utilisez-la dans le `comment` du warehouse. Changez sa
valeur dans `tfvars` → `plan` doit montrer un `~` sur `comment`.

**Défi B — precondition sur la ressource (`lifecycle`).** La `validation` de variable
protège l'entrée ; une **`precondition`** protège la **ressource** au moment du plan.
Ajoutez dans `snowflake_warehouse.etl` :

```hcl
resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M03_ETL_${var.environment}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = var.warehouse_auto_suspend
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL paramétré (M03) pour ${var.learner_prefix}"

  lifecycle {
    precondition {
      condition     = var.environment == "PROD" ? var.warehouse_auto_suspend <= 120 : true
      error_message = "En PROD, auto_suspend doit être <= 120 s (FinOps)."
    }
  }
}
```

Testez : `environment = "PROD"` + `warehouse_auto_suspend = 300` → le plan échoue
avec votre message. `DEV` + `300` → le plan passe.

🧠 **Pourquoi :** `validation` (variable) et `precondition` (lifecycle) sont les
**custom conditions** de Terraform — elles expriment des règles métier dans le code.
Le bloc `lifecycle` regroupe les comportements spéciaux d'une ressource (on verra
`prevent_destroy`, `create_before_destroy` en production).

---

## Nettoyage

```powershell
terraform destroy
```

Vérifiez dans Snowsight que `APP01_M03_ETL_DEV` et `APP01_M03_RAW_DEV` ont disparu.

---

## Si ça casse

| Symptôme | Diagnostic | Correction |
|---|---|---|
| `Error: invalid value for warehouse_size` | Vérifiez `terraform.tfvars` | Remettez `X-SMALL` ou `SMALL` |
| `Error: Database already exists` | `SHOW DATABASES LIKE 'APP01_M03%';` dans Snowsight | `DROP DATABASE` dans Snowsight puis `apply` |
| `plan` ignore votre `-var` | Vérifiez la syntaxe : `-var="nom=valeur"` (pas d'espace autour du `=`) | Corrigez la syntaxe |

---

## Reprendre après un crash

- **Apply interrompu :** `terraform plan` puis `terraform apply`.
- **Variable invalide bloquante :** corrigez `terraform.tfvars`, relancez `plan`.
- **Dossier supprimé :** recréez les 5 fichiers, `init`, `apply`.

---

## Ce que j'ai appris

- ✅ Déclarer des variables typées (`string`, `number`) avec `default`.
- ✅ Ajouter des `validation` qui refusent les valeurs hors-standard avant le plan.
- ✅ Séparer le code (`main.tf`, stable) des valeurs (`terraform.tfvars`, variable).
- ✅ Surcharger ponctuellement avec `-var`.
- ✅ Détecter un changement de valeur par `plan` sans modifier le code.
- ✅ `sensitive` masque un secret — mais le **state** le stocke en clair.
- ✅ (Défi) `lifecycle { precondition }` = garde-fou au niveau ressource.

---

## Suite

Passez au [Jour 2 — Le state et les collections](../../day-02/README.md).
