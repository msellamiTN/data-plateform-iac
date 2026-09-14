# 🧪 Lab J1 — Team BUSINESS DATA · Manel · Leila · Olfa

| Élément | Valeur |
|---|---|
| **Durée** | 1 h |
| **Prérequis** | Aucun — premier jour |
| **Workspace** | `environments/dev/` |
| **Votre outil** | Snowsight (clic) → VS Code (Terraform) |

---

## 🚀 Pre-Flight — avant de commencer

```powershell
terraform version    # doit afficher 1.14.x
```

✅ **Checkpoint 0 :** Terraform répond et Snowsight est accessible dans le navigateur.

## ✅ Objectifs vérifiables

- [ ] J'ai créé mon objet dans **Snowsight** (clic)
- [ ] J'ai reproduit le même objet en **Terraform** (`plan` → `apply`)
- [ ] `terraform plan` affiche **`No changes.`** après l'apply
- [ ] J'ai modifié l'objet à la main → le plan **détecte la dérive** (`~`)
- [ ] Preuve SQL : `SHOW <OBJECTS> LIKE '<PREFIX>%';` retourne mon objet

---
## 🎯 Mission

> **En tant que** membre de l'équipe Business Data
> **Je veux** créer ma database métier, mon schema et ma table, d'abord à la main puis en Terraform
> **Afin de** comprendre pourquoi l'infrastructure en code remplace le clic

### Mes ressources du jour

| Propriétaire | Ma database | Mon schema | Ma table |
|---|---|---|---|
| **Manel** | `APP06_CUSTOMER_DEV` | `BUSINESS` | `CUSTOMER` |
| **Leila** | `APP07_PRODUCT_DEV` | `BUSINESS` | `PRODUCT` |
| **Olfa** | `APP08_CAMPAIGN_DEV` | `BUSINESS` | `CAMPAIGN` |

> 🧠 `APP06` est **votre préfixe apprenant** — déjà configuré sur votre poste. Il rend vos ressources uniques.

> 🔗 **L'ordre compte :** une table vit dans un schema, un schema vit dans une database. On crée dans l'ordre : **database → schema → table**.

---

## 🏗️ Le parcours du jour

```
   ①  🖱️  JE CRÉE À LA MAIN      Snowsight : database → schema → table
   ②  ⌨️  JE CRÉE MON PROJET      VS Code, 4 fichiers
   ③  🔁  JE L'ÉCRIS EN TERRAFORM les 3 mêmes objets, en code
   ④  ✅  JE VÉRIFIE              terraform plan → apply → Snowsight
   ⑤  🐛  JE PROVOQUE LA DÉRIVE   je modifie à la main → Terraform voit tout
```

---

## 📝 Étape 1 — Créer mes objets dans Snowsight

**Besoin :** avant d'automatiser, il faut comprendre ce qu'on automatise.

### 1a. La database

1. Ouvrez **https://app.snowflake.com** et connectez-vous.
2. Menu **Data → Databases → + Database**.
3. Name : `APP06_CUSTOMER_DEV` *(votre nom du tableau)* → **Create**.

![Snowsight — la database créée](../screenshots/j1-03-database-created.png)

### 1b. Le schema

1. Cliquez sur votre database → **+ Schema**.
2. Name : `BUSINESS` → **Create**.

### 1c. La table

1. Cliquez sur votre schema → **Create → Table**.
2. Name : `CUSTOMER` *(votre table du tableau)*, avec 2 colonnes :

| Colonne | Type |
|---|---|
| `ID` | `NUMBER` |
| `LABEL` | `VARCHAR` |

3. **Create**.

![Snowsight — l'arborescence database → schema → table](../screenshots/j1-04-arborescence.png)

> 🧠 **Retenez les champs remplis.** Dans 10 minutes, vous écrirez exactement les mêmes en Terraform.

---

## 📝 Étape 2 — Créer mon projet VS Code

**Besoin :** Terraform lit des fichiers `.tf`. Il faut un dossier propre.

1. Dans VS Code : **File → Open Folder** → créez et ouvrez `environments/dev/`.
2. Créez **4 fichiers** :

```
environments/dev/
├── versions.tf        → les versions exigées
├── provider.tf        → la connexion Snowflake
├── variables.tf       → les entrées (votre préfixe, l'environnement)
└── terraform.tfvars   → vos valeurs
```

### `versions.tf` — copiez tel quel

```hcl
# Quelle version de Terraform et quel provider on utilise.
terraform {
  required_version = "= 1.14.5"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"  # le provider officiel Snowflake
      version = "= 2.14.0"
    }
  }
}
```

### `provider.tf` — copiez tel quel

```hcl
# Comment Terraform se connecte à Snowflake.
# Le mot de passe (PAT) est lu automatiquement depuis secrets/snowflake_pat.txt
# — vous n'avez RIEN à taper.

locals {
  pat_file        = "${path.module}/../../../../../secrets/snowflake_pat.txt"
  snowflake_token = try(trimspace(file(local.pat_file)), var.snowflake_token, "")
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = local.snowflake_token
}
```

### `variables.tf` — copiez tel quel

```hcl
# Les ENTRÉES du projet. Tout ce qui peut changer est une variable.

variable "snowflake_organization" {
  type        = string
  description = "Organisation Snowflake (fournie)"
}

variable "snowflake_account" {
  type        = string
  description = "Compte Snowflake (fourni)"
}

variable "snowflake_user" {
  type        = string
  description = "Utilisateur Snowflake (fourni)"
}

variable "snowflake_token" {
  type        = string
  description = "PAT — lu depuis secrets/, ne rien mettre ici"
  sensitive   = true
  default     = ""
}

variable "learner_prefix" {
  type        = string
  description = "Votre préfixe unique (ex: APP06) — déjà assigné"

  validation {
    condition     = can(regex("^[A-Z0-9_]{2,12}$", var.learner_prefix))
    error_message = "learner_prefix must be 2-12 uppercase alphanumeric characters or underscore."
  }
}

variable "environment" {
  type        = string
  description = "Environnement de déploiement"
  default     = "DEV"

  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "environment must be DEV, UAT or PROD."
  }
}
```

### `terraform.tfvars` — copiez tel quel

```hcl
# Vos valeurs. Déjà pré-rempli sur votre poste.
# ⚠️ Ne mettez JAMAIS de mot de passe ici.

learner_prefix         = "APP06"   # ← votre préfixe assigné
environment            = "DEV"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"
```

---

## 📝 Étape 3 — Écrire mes 3 objets en Terraform

**Besoin :** reproduire en code ce que vous avez cliqué à l'étape 1.

**Problème :** si j'écris les noms en dur, le code ne marche que pour moi.

**Solution :** les noms sont **calculés** depuis `var.learner_prefix` et `var.environment`.

Créez **`main.tf`** :

```hcl
# 1. La database — le conteneur de tout
resource "snowflake_database" "ma_db" {
  name                        = "${var.learner_prefix}_CUSTOMER_${var.environment}"
  #                             ↑ APP06                  ↑ DEV
  #                             = APP06_CUSTOMER_DEV
  comment                     = "Managed by Terraform | Training | ${var.learner_prefix}"
  data_retention_time_in_days = 1   # FinOps : 1 jour de rétention suffit en formation
}

# 2. Le schema — vit DANS la database
resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.ma_db.name   # ← référence, pas de nom en dur
  name     = "BUSINESS"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"
}

# 3. La table — vit DANS le schema
resource "snowflake_table" "ma_table" {
  database = snowflake_database.ma_db.name
  schema   = snowflake_schema.mon_schema.name   # ← chaîne de dépendances
  name     = "CUSTOMER"
  comment  = "Managed by Terraform | Training | ${var.learner_prefix}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "LABEL"
    type = "VARCHAR(255)"
  }
}
```

> 🧠 **La magie des références :** `snowflake_database.ma_db.name` — Terraform comprend que le schema dépend de la database. Il créera les objets **dans le bon ordre**, tout seul.

---

## 📝 Étape 4 — Le cycle de vie Terraform

Dans le terminal VS Code, depuis `environments/dev/` :

```powershell
terraform init      # 1. télécharge le provider (une seule fois)
terraform fmt       # 2. formate le code
terraform validate  # 3. vérifie la syntaxe
terraform plan      # 4. PRÉVISUALISE
```

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

> 🧠 **3 objets d'un coup.** Terraform a compris l'ordre : database → schema → table.

```powershell
terraform apply     # 5. APPLIQUE
```

Retapez `terraform plan` → `No changes.`

![Snowsight — les 3 objets créés](../screenshots/j1-05-3-objects-created.png)

---

## 📝 Étape 5 — La dérive (drift)

1. Dans **Snowsight**, modifiez le commentaire de votre table : `Modifié à la main`.
2. `terraform plan` :

```text
  ~ comment = "Modifié à la main" -> "Managed by Terraform | Training | APP06"
```

3. `terraform apply` → le code reprend le dessus.

> 🧠 **Terraform voit tout.** Le code est la source de vérité.

![Le plan qui détecte la dérive](../screenshots/j1-06-drift-plan.png)

---

## 🐛 Chaos Lab

1. Dans `main.tf`, changez le nom du schema `BUSINESS` → `FINANCE`.
2. `terraform plan` → observez : le schema sera **remplacé** (`-/+`), et la table aussi (elle dépend du schema).
3. **Ne validez pas.** Remettez `BUSINESS` → `No changes.`

> 🧠 **Changer un nom = détruire et recréer.** Et tout ce qui dépend de l'objet suit. C'est pour ça qu'on ne renomme jamais à la légère — demain vous verrez `moved`.

---

## 🏆 Défi autonome

> Ajoutez une **deuxième table** `SEGMENT` dans le même schema, avec les colonnes `ID` (NUMBER) et `SEGMENT_NAME` (VARCHAR).

**Critères :** `Plan: 1 to add` · apply OK · second plan `No changes.`

---

## 🧹 Nettoyage

> 🔴 **Ne faites PAS `terraform destroy`** — vos ressources servent au Jour 2.

---

## 🃏 Anti-sèche

```hcl
resource "snowflake_database" "ma_db" {
  name = "${var.learner_prefix}_CUSTOMER_${var.environment}"
}

resource "snowflake_schema" "mon_schema" {
  database = snowflake_database.ma_db.name
  name     = "BUSINESS"
}

resource "snowflake_table" "ma_table" {
  database = snowflake_database.ma_db.name
  schema   = snowflake_schema.mon_schema.name
  name     = "CUSTOMER"
  column { name = "ID" type = "NUMBER(38,0)" }
}
```

| Commande | Rôle |
|---|---|
| `terraform init` | installe le provider (1 fois) |
| `terraform plan` | prévisualise sans toucher |
| `terraform apply` | applique pour de vrai |
| `No changes.` | code = réalité ✅ |
