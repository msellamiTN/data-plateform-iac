# 🧪 Lab J1 — Team PLATFORM · Fares · Mohamed · Sirine

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

> **En tant que** membre de l'équipe Platform
> **Je veux** créer mon warehouse Snowflake, d'abord à la main puis en Terraform
> **Afin de** comprendre pourquoi l'infrastructure en code remplace le clic

### Ma ressource du jour

| Propriétaire | Mon warehouse | Nom final dans Snowflake |
|---|---|---|
| **Fares** | warehouse d'ingestion | `WH_APP01_INGEST_DEV` |
| **Mohamed** | warehouse métier | `WH_APP02_BUSINESS_DEV` |
| **Sirine** | warehouse BI | `WH_APP03_BI_DEV` |

> 🧠 `APP01` est **votre préfixe apprenant** — déjà configuré sur votre poste. Il rend vos ressources uniques : personne ne peut créer un objet avec le même nom.

---

## 🏗️ Le parcours du jour

```
   ①  🖱️  JE CRÉE À LA MAIN      Snowsight, champ par champ
   ②  ⌨️  JE CRÉE MON PROJET      VS Code, 4 fichiers
   ③  🔁  JE L'ÉCRIS EN TERRAFORM le même objet, en code
   ④  ✅  JE VÉRIFIE              terraform plan → apply → Snowsight
   ⑤  🐛  JE PROVOQUE LA DÉRIVE   je modifie à la main → Terraform voit tout
```

---

## 📝 Étape 1 — Créer mon warehouse dans Snowsight

**Besoin :** avant d'automatiser, il faut comprendre ce qu'on automatise.

1. Ouvrez **https://app.snowflake.com** et connectez-vous.
2. Menu **Admin → Warehouses → + Warehouse**.
3. Remplissez le formulaire :

| Champ | Valeur |
|---|---|
| Name | `WH_APP01_INGEST_DEV` *(votre nom final du tableau)* |
| Size | `X-Small` |
| Auto Suspend | `60` secondes |
| Auto Resume | ✅ coché |
| Initially Suspended | ✅ coché |
| Comment | `Managed by Terraform | Training | APP01` |

4. Cliquez **Create Warehouse**.

![Snowsight — le warehouse créé dans la liste](../screenshots/j1-01-warehouse-created.png)

> 🧠 **Retenez les champs que vous venez de remplir.** Dans 10 minutes, vous allez écrire exactement les mêmes en Terraform.

---

## 📝 Étape 2 — Créer mon projet VS Code

**Besoin :** Terraform lit des fichiers `.tf`. Il faut un dossier propre.

1. Dans VS Code : **File → Open Folder** → créez et ouvrez `environments/dev/`.
2. Créez **4 fichiers** (clic droit → New File) :

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
# Les "=" figent les versions : tout le monde a exactement le même moteur.
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
# — vous n'avez RIEN à taper, le fichier est déjà sur votre poste.

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
  description = "Votre préfixe unique (ex: APP01) — déjà assigné"

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

variable "warehouse_size" {
  type        = string
  description = "Taille du warehouse de formation"
  default     = "X-SMALL"

  validation {
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "Training warehouses must be X-SMALL or SMALL."
  }
}
```

### `terraform.tfvars` — copiez tel quel

```hcl
# Vos valeurs. Ce fichier est déjà pré-rempli sur votre poste.
# ⚠️ Ne mettez JAMAIS de mot de passe ici.

learner_prefix         = "APP01"   # ← votre préfixe assigné
environment            = "DEV"
warehouse_size         = "X-SMALL"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"
```

> 🧠 **4 fichiers, 4 rôles.** `versions` = le moteur · `provider` = la connexion · `variables` = les entrées · `tfvars` = vos valeurs.

---

## 📝 Étape 3 — Écrire mon warehouse en Terraform

**Besoin :** reproduire en code ce que vous avez cliqué à l'étape 1.

**Problème :** si j'écris `name = "WH_APP01_INGEST_DEV"` en dur, le code ne marche que pour moi. Demain un collègue le réutilise → collision.

**Solution :** le nom est **calculé** depuis `var.learner_prefix` et `var.environment`.

Créez **`main.tf`** :

```hcl
# Mon warehouse — le même que celui créé à la main à l'étape 1.
# Chaque argument correspond à un champ du formulaire Snowsight.

resource "snowflake_warehouse" "mon_wh" {
  # name = le champ "Name" du formulaire — mais calculé, jamais en dur
  name = "WH_${var.learner_prefix}_INGEST_${var.environment}"
  #            ↑ APP01              ↑ INGEST        ↑ DEV
  #            = WH_APP01_INGEST_DEV

  warehouse_size      = var.warehouse_size   # le champ "Size"
  auto_suspend        = 60                   # "Auto Suspend" : 60 secondes
  auto_resume         = true                 # "Auto Resume" coché
  initially_suspended = true                 # "Initially Suspended" coché
  comment             = "Managed by Terraform | Training | ${var.learner_prefix}"
}
```

> 🧠 **La correspondance :** chaque champ du formulaire Snowsight = un argument du bloc `resource`. Le formulaire n'était qu'une façade.

---

## 📝 Étape 4 — Le cycle de vie Terraform

**Besoin :** transformer le code en vraie ressource Snowflake.

Dans le terminal VS Code (**Ctrl+ù**), depuis `environments/dev/` :

```powershell
terraform init      # 1. télécharge le provider Snowflake (une seule fois)
terraform fmt       # 2. formate le code proprement
terraform validate  # 3. vérifie la syntaxe
terraform plan      # 4. PRÉVISUALISE — ne touche à rien
```

Lisez le plan :

```text
  # snowflake_warehouse.mon_wh will be created
  + name = "WH_APP01_INGEST_DEV"

Plan: 1 to add, 0 to change, 0 to destroy.
```

> 🧠 **`plan` = la prévisualisation.** Terraform compare votre code au state (sa mémoire) et montre ce qu'il va faire — avant de le faire.

```powershell
terraform apply     # 5. APPLIQUE — crée vraiment la ressource
```

Retapez `terraform plan` :

```text
No changes. Your infrastructure matches the configuration.
```

> ✅ **Checkpoint :** `No changes.` = le code et la réalité sont alignés. C'est la preuve que tout est sous contrôle.

![Snowsight — le warehouse WH_APP01_INGEST_DEV visible](../screenshots/j1-02-warehouse-visible.png)

---

## 📝 Étape 5 — La dérive (drift)

**Besoin :** que se passe-t-il si quelqu'un modifie l'objet à la main ?

1. Dans **Snowsight**, éditez votre warehouse : passez le commentaire à `Modifié à la main`.
2. Retournez dans VS Code :

```powershell
terraform plan
```

```text
  # snowflake_warehouse.mon_wh will be updated in-place
  ~ comment = "Modifié à la main" -> "Managed by Terraform | Training | APP01"
```

> 🧠 **Terraform a vu la modification manuelle.** Le `~` jaune = dérive détectée. Le code est la source de vérité.

3. Corrigez :

```powershell
terraform apply    # remet le commentaire du code
```

![Le plan qui détecte la dérive](../screenshots/j1-06-drift-plan.png)

---

## 🐛 Chaos Lab — casser puis réparer

1. Dans `main.tf`, changez `auto_suspend = 60` → `auto_suspend = 10`.
2. `terraform plan` → observez le `~` jaune.
3. **Ne validez pas.** Remettez `60` → `terraform plan` → `No changes.`

> 🧠 Vous venez de simuler un changement sans risque : le plan montre l'impact **avant** l'application.

---

## 🏆 Défi autonome

> Ajoutez un **deuxième** warehouse `WH_<PREFIX>_ADHOC_DEV` dans le même `main.tf`, avec `auto_suspend = 30`.

**Critères :** `Plan: 1 to add` · apply OK · second plan `No changes.`

---

## 🧹 Nettoyage

> 🔴 **Ne faites PAS `terraform destroy`** — vos ressources servent au Jour 2.

---

## 🃏 Anti-sèche

```hcl
resource "snowflake_warehouse" "mon_wh" {
  name                = "WH_${var.learner_prefix}_INGEST_${var.environment}"
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
}
```

| Commande | Rôle |
|---|---|
| `terraform init` | installe le provider (1 fois) |
| `terraform plan` | prévisualise sans toucher |
| `terraform apply` | applique pour de vrai |
| `No changes.` | code = réalité ✅ |
