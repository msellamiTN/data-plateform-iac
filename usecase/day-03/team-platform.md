# 🧪 Lab J3 — Team PLATFORM · Fares · Mohamed · Sirine

| Élément | Valeur |
|---|---|
| **Durée** | 1 h |
| **Prérequis** | Jour 2 terminé — `No changes.` obtenu |
| **Workspace** | `environments/dev/` (le même) |
| **Aujourd'hui** | Terraform uniquement |

---

## 🚀 Pre-Flight — avant de commencer

```powershell
terraform version    # 1.14.x
terraform plan       # doit afficher "No changes." (le code d'hier est aligné)
```

✅ **Checkpoint 0 :** `No changes.` — sinon, corrigez avant de continuer.

## ✅ Objectifs vérifiables

- [ ] `moved` → le plan affiche **`has moved to`**, 0 destroy
- [ ] `import` → `terraform state list` montre l'objet **legacy**
- [ ] `module` → `terraform init` puis `apply` via le module
- [ ] `data` source → `terraform output` affiche l'objet **lu** (non géré)
- [ ] Preuve SQL : `SHOW <OBJECTS> LIKE '<PREFIX>%';` retourne mes objets

---
## 🎯 Mission

> **En tant que** membre de l'équipe Platform
> **Je veux** corriger, adopter et factoriser mon code en **module réutilisable**
> **Afin de** transformer ma collection en brique de plateforme

### Ma ressource de travail

| Propriétaire | Ma collection (J2) | Mon objet legacy (J1, créé à la main) |
|---|---|---|
| **Fares** | `roles` → 3 rôles | `WH_APP01_LEGACY` (warehouse) |
| **Mohamed** | `roles` → 3 rôles | `WH_APP02_LEGACY` (warehouse) |
| **Sirine** | `warehouses` → 3 warehouses | `WH_APP03_LEGACY` (warehouse) |

---

## 🏗️ Le parcours du jour — 4 problèmes, 4 fondements

| Étape | Le problème | 🧠 Le fondement |
|:---:|---|---|
| **1** | Renommer un objet = le détruire | **`moved`** — déplacer sans détruire |
| **2** | Un objet existe hors Terraform | **`import`** — l'adopter sans le recréer |
| **3** | Onze équipes écrivent le même code | **`module`** — factoriser une fois |
| **4** | Lire ce que l'autre a créé | **`data` source** — le SELECT de Terraform |

---

## 📝 Étape 1 — `moved` : renommer sans détruire

**Problème :** je veux renommer mon bloc `snowflake_account_role.access` en `snowflake_account_role.collection`. Si je change juste le nom du bloc, Terraform voit : *« détruire `access`, créer `collection` »* → les rôles sont détruits puis recréés. En production, c'est un incident.

**Solution :** le bloc `moved` dit à Terraform *« c'est le même objet, juste une nouvelle adresse »*.

Dans **`main.tf`**, renommez le bloc ET ajoutez le `moved` :

```hcl
# AVANT : resource "snowflake_account_role" "access"
# APRÈS : le bloc s'appelle "collection"
resource "snowflake_account_role" "collection" {
  for_each = var.roles
  name     = "${var.learner_prefix}_${each.value.suffix}_${var.environment}"
  comment  = "${each.value.comment} | ${local.common_comment}"
}

# Je dis à Terraform : "access" et "collection" sont LE MÊME objet
moved {
  from = snowflake_account_role.access
  to   = snowflake_account_role.collection
}
```

```powershell
terraform plan
```

```text
  # snowflake_account_role.access["raw_reader"] has moved to
  # snowflake_account_role.collection["raw_reader"]

Plan: 0 to add, 0 to change, 0 to destroy.
```

> 🧠 **`moved` met à jour la mémoire de Terraform sans toucher Snowflake.** L'objet réel n'est ni détruit ni recréé. Zéro perte.

> 📷 **[CAPTURE]** Le plan has moved to — 0 destroy — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 2 — `import` : adopter un objet existant

**Problème :** au Jour 1, j'ai créé `WH_APP01_LEGACY` **à la main** dans Snowsight. Il existe dans Snowflake mais pas dans mon code. C'est une **ressource orpheline** — Terraform ne la connaît pas.

**Solution :** `import` ajoute l'objet existant dans la mémoire de Terraform, **sans le recréer**.

### 2a. Déclarez le bloc dans `main.tf`

```hcl
# L'objet legacy — je déclare ce qui existe déjà dans Snowflake
resource "snowflake_warehouse" "legacy" {
  name           = "WH_${var.learner_prefix}_LEGACY"
  comment        = "Warehouse legacy — adopté par import"
  warehouse_size = "X-SMALL"
}
```

### 2b. Importez l'objet réel

```powershell
terraform import snowflake_warehouse.legacy WH_APP01_LEGACY
```

```text
Import successful!
snowflake_warehouse.legacy: Import prepared!
snowflake_warehouse.legacy: Refreshing state...
```

```powershell
terraform plan
```

```text
No changes.   # ← le code correspond à l'objet réel
```

> 🧠 **`import` = adoption.** L'objet était orphelin, il est maintenant sous gestion Terraform. Rien n'a été détruit.

> 📷 **[CAPTURE]** terraform state list montrant legacy — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 3 — `module` : factoriser ma collection

**Problème :** les onze apprenants ont écrit **la même structure** — un `for_each` sur une map. Pourquoi l'écrire onze fois ?

**Solution :** un **module** = le code écrit une fois, appelé N fois. **Votre code du Jour 2 devient le module — sans le réécrire.**

### 3a. Créez le dossier du module

```
environments/dev/
└── modules/
    └── roles/
        ├── main.tf        → les resources (votre code du J2)
        ├── variables.tf   → les entrées du module
        └── outputs.tf     → les sorties du module
```

### 3b. `modules/roles/variables.tf` — les entrées

```hcl
# Ce que l'appelant doit fournir au module
variable "roles" {
  type = map(object({
    suffix  = string
    comment = string
  }))
}

variable "prefix_env" {
  type = string   # ex: "APP01_DEV"
}

variable "common_comment" {
  type = string
}
```

### 3c. `modules/roles/main.tf` — votre code du J2, tel quel

```hcl
# Le même for_each qu'hier — mais les valeurs viennent du module
resource "snowflake_account_role" "this" {
  for_each = var.roles
  name     = "${var.learner_prefix}_${each.value.suffix}_${var.environment}"
  comment  = "${each.value.comment} | ${var.common_comment}"
}
```

### 3d. `modules/roles/outputs.tf` — les sorties

```hcl
output "role_names" {
  value = { for k, r in snowflake_account_role.this : k => r.name }
}
```

### 3e. Dans `main.tf` racine — remplacez le bloc `resource` par l'appel

```hcl
# Je ne crée plus les rôles moi-même — j'APPELLE le module
module "mes_roles" {
  source = "./modules/roles"   # ← où est le module

  roles          = var.roles            # entrée : ma collection
  prefix_env     = local.prefix_env     # entrée : mon préfixe
  common_comment = local.common_comment # entrée : mon commentaire
}
```

```powershell
terraform init    # ← OBLIGATOIRE : Terraform découvre le module
terraform plan
```

```text
  # module.mes_roles.snowflake_account_role.this["raw_reader"] will be created
  # snowflake_account_role.collection["raw_reader"] will be destroyed
```

> ⚠️ **Le module change l'adresse** → ajoutez un `moved` par clé, ou laissez recréer (des rôles vides, pas de données).

```powershell
terraform apply
```

> 🧠 **Un module = une fonction.** Entrées (`variables`), traitement (`main.tf`), sorties (`outputs`). Écrit une fois, appelé N fois.

> 📷 **[CAPTURE]** L'arborescence modules/ dans VS Code — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 4 — `data` source : lire ce que je n'ai pas créé

**Problème :** Platform doit connaître la database de Data Eng pour préparer les grants. Mais je ne l'ai pas créée — je ne peux pas la mettre dans un `resource` (sinon je la gère).

**Solution :** `data` source = **lire** une ressource existante sans la gérer.

Dans **`main.tf`**, ajoutez :

```hcl
# Je LIS la database d'Amal — je ne la crée pas, je ne la gère pas
data "snowflake_database" "raw" {
  name = "APP04_RAW_DEV"   # la database de l'équipe Data Eng
}
```

Et dans **`outputs.tf`** :

```hcl
output "database_lue" {
  description = "La database Data Eng que j'ai lue (sans la gérer)"
  value       = data.snowflake_database.raw.name
}
```

```powershell
terraform plan    # → No changes (une data source ne crée rien)
terraform apply
terraform output database_lue
```

```text
"APP04_RAW_DEV"
```

> 🧠 **`resource` = je crée et je gère. `data` = je lis seulement.** C'est le `SELECT` de Terraform.

> 📷 **[CAPTURE]** terraform output montrant la database lue — voir `usecase/screenshots/MANIFEST.md`

---

## 🐛 Chaos Lab — casser le module

1. Dans `modules/roles/variables.tf`, changez le type de `roles` en `string` (au lieu de `map(object(...))`).
2. `terraform plan` → erreur : l'appelant envoie une map, le module attend une string.
3. Corrigez → `No changes.`

> 🧠 **Les variables du module sont son contrat.** Les casser casse tous les appelants — c'est pourquoi on versionne les modules.

---

## 🏆 Défi autonome

> Ajoutez un rôle `compliance_reader` via `terraform.tfvars` — **sans toucher au module ni à `main.tf`**.

**Critères :** `Plan: 1 to add` · `modules/` non modifié · second plan `No changes.`

---

## 🧹 Nettoyage

> 🔴 **Ne faites PAS `terraform destroy`.**

---

## 🃏 Anti-sèche

```hcl
# moved — renommer sans détruire
moved {
  from = snowflake_account_role.access
  to   = snowflake_account_role.collection
}

# import — adopter un objet existant
# terraform import snowflake_warehouse.legacy WH_APP01_LEGACY

# module — appeler du code factorisé
module "mes_roles" {
  source = "./modules/roles"
  roles  = var.roles
}

# data — lire sans gérer
data "snowflake_database" "raw" {
  name = "APP04_RAW_DEV"
}
```

| Fondement | En une phrase |
|---|---|
| `moved` | Renomme dans le state, sans détruire |
| `import` | Adopte un objet existant |
| `module` | Code écrit une fois, appelé N fois |
| `data` | Lit ce que je n'ai pas créé |
