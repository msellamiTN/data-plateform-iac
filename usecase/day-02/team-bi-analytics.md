# 🧪 Lab J2 — Team BI / ANALYTICS · Ghassen · Adem · Hadhemi

| Élément | Valeur |
|---|---|
| **Durée** | 1 h |
| **Prérequis** | Jour 1 terminé — `No changes.` obtenu |
| **Workspace** | `environments/dev/` (le même qu'hier) |
| **Aujourd'hui** | Terraform uniquement — plus de clic Snowsight |

---

## 🚀 Pre-Flight — avant de commencer

```powershell
terraform version    # 1.14.x
terraform plan       # doit afficher "No changes." (le code d'hier est aligné)
```

✅ **Checkpoint 0 :** `No changes.` — sinon, corrigez avant de continuer.

## ✅ Objectifs vérifiables

- [ ] `locals.tf` introduit → `plan` = **`No changes.`** (refactoring réussi)
- [ ] `validation` testée → `plan` **échoue** avec une valeur invalide
- [ ] 3 objets créés via **`for_each`** → `Plan: 3 to add`
- [ ] `terraform output` affiche mon **contrat** (noms des objets)
- [ ] Preuve SQL : `SHOW <OBJECTS> LIKE '<PREFIX>%';` retourne mes 3 objets

---
## 🎯 Mission

> **En tant que** membre de l'équipe BI / Analytics
> **Je veux** passer de 1 table à une **collection** de tables de mart
> **Afin de** produire du code industrialisable : factorisé, validé, multiplié, exposé

### Ma collection du jour

| Propriétaire | Mes 3 tables | Dans |
|---|---|---|
| **Ghassen** | `CUSTOMER_360` · `SEGMENT_KPI` · `CHURN_SCORE` | `APP09_CUSTOMER_MART_DEV.MART` |
| **Adem** | `PNL_MONTHLY` · `BALANCE_SHEET` · `MARGIN_BY_PRODUCT` | `APP10_FINANCE_MART_DEV.MART` |
| **Hadhemi** | `TX_DAILY` · `TX_BY_CHANNEL` · `TX_ANOMALY` | `APP11_TRANSACTION_MART_DEV.MART` |

---

## 🏗️ Le parcours du jour — 4 problèmes, 4 fondements

| Étape | Le problème | 🧠 Le fondement |
|:---:|---|---|
| **1** | Je répète `${var.learner_prefix}` partout | **`locals`** — calculer une fois |
| **2** | Une faute de frappe passe au plan | **`validation`** — bloquer avant |
| **3** | Je copie-colle le même bloc 3 fois | **`for_each`** — multiplier proprement |
| **4** | Personne ne connaît mes noms d'objets | **`output`** — exposer le contrat |

---

## 📝 Étape 1 — `locals` : arrêter de se répéter

**Problème :** hier, j'ai répété `snowflake_database.mon_mart.name` et le commentaire partout. Si je crée 3 tables, je répète 3 fois.

**Solution :** un `local` calcule la valeur **une fois**, et tout le monde la réutilise.

Créez **`locals.tf`** :

```hcl
# Les valeurs calculées UNE SEULE FOIS, réutilisées partout.

locals {
  # Le préfixe complet : "APP09_DEV"
  prefix_env = "${var.learner_prefix}_${var.environment}"

  # Le commentaire standard de toutes mes ressources
  common_comment = "Managed by Terraform | Training | ${var.learner_prefix}"
}
```

Dans **`main.tf`**, remplacez les commentaires en dur :

```hcl
resource "snowflake_database" "mon_mart" {
  name    = "${var.learner_prefix}_CUSTOMER_MART_${var.environment}"
  comment = local.common_comment   # ← avant : "Managed by Terraform | ..."
  # ... le reste inchangé
}
```

```powershell
terraform plan
```

```text
No changes.   # ← refactoring réussi
```

> 🧠 **`No changes.` = refactoring réussi.**

> 📷 **[CAPTURE]** Le plan No changes. après l'introduction du local — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 2 — `validation` : bloquer les erreurs avant le plan

**Problème :** une faute de frappe dans `environment` passe au plan et crée un objet au mauvais nom.

**Solution :** le bloc `validation` vérifie la valeur **avant** tout contact avec Snowflake.

Votre `variables.tf` a déjà la validation sur `environment` — **testez le garde-fou** : dans `terraform.tfvars`, mettez `environment = "developement"` → `terraform plan` :

```text
╷ Error: Invalid value for variable
╵ environment must be DEV, UAT or PROD.
```

> 🧠 **L'erreur arrive AVANT.** Remettez `DEV` → `plan` → `No changes.`

> 📷 **[CAPTURE]** L'erreur de validation dans le terminal — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 3 — `for_each` : multiplier sans copier-coller

**Problème :** je dois créer 3 tables de mart. Copier-coller le bloc `resource` 3 fois = 3 blocs à maintenir.

**Solution :** `for_each` boucle sur une **map** — un seul bloc, N objets.

### 3a. Déclarez la collection dans `variables.tf`

```hcl
# La liste de mes tables — une map : clé → objet
variable "mart_tables" {
  type = map(object({
    name    = string   # le nom réel de la table
    comment = string   # la description métier
  }))
  description = "Mes tables de mart"
}
```

### 3b. Donnez les valeurs dans `terraform.tfvars`

```hcl
# Ghassen — ajoutez à la fin du fichier :
mart_tables = {
  customer_360 = { name = "CUSTOMER_360", comment = "Vue 360 du client" }
  segment_kpi  = { name = "SEGMENT_KPI",  comment = "KPIs par segment" }
  churn        = { name = "CHURN_SCORE",  comment = "Score d'attrition" }
}
```

*(Adem : `pnl`/`balance`/`margin` → `PNL_MONTHLY`, `BALANCE_SHEET`, `MARGIN_BY_PRODUCT` · Hadhemi : `daily`/`by_channel`/`anomaly` → `TX_DAILY`, `TX_BY_CHANNEL`, `TX_ANOMALY`)*

### 3c. Un seul bloc dans `main.tf`

```hcl
# UN bloc → TROIS tables. for_each boucle sur la map.
resource "snowflake_table" "collection" {
  for_each = var.mart_tables     # ← la boucle

  database = snowflake_database.mon_mart.name
  schema   = snowflake_schema.mon_schema.name
  name     = each.value.name     # ← le nom vient de la map
  comment  = "${each.value.comment} | ${local.common_comment}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "METRIC"
    type = "VARCHAR(255)"
  }
}
```

```powershell
terraform plan
```

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

> 🧠 **Pour ajouter une 4ᵉ table demain :** une ligne dans `terraform.tfvars`. Zéro ligne de code.

> 📷 **[CAPTURE]** Snowsight — les 3 tables créées — voir `usecase/screenshots/MANIFEST.md`

---

## 📝 Étape 4 — `output` : exposer mon contrat

**Problème :** les autres équipes auront besoin de mes noms de mart/schema. Comment les partager ?

**Solution :** `output` publie les valeurs — c'est le **contrat** de mon projet.

Créez **`outputs.tf`** :

```hcl
# Ce que mon projet EXPOSE aux autres.

output "database_name" {
  description = "Mon mart"
  value       = snowflake_database.mon_mart.name
}

output "schema_name" {
  description = "Mon schema"
  value       = snowflake_schema.mon_schema.name
}

output "table_names" {
  description = "Toutes mes tables — clé → nom réel"
  value       = { for k, t in snowflake_table.collection : k => t.name }
}
```

```powershell
terraform apply    # crée les tables
terraform output   # affiche le contrat
```

```text
database_name = "APP09_CUSTOMER_MART_DEV"
schema_name   = "MART"
table_names = {
  "churn"        = "CHURN_SCORE"
  "customer_360" = "CUSTOMER_360"
  "segment_kpi"  = "SEGMENT_KPI"
}
```

> 🧠 **`output` = ce que je promets aux autres équipes.**

> 📷 **[CAPTURE]** terraform output dans le terminal — voir `usecase/screenshots/MANIFEST.md`

---

## 🐛 Chaos Lab — casser le `for_each`

1. Dans `terraform.tfvars`, mettez **deux clés identiques** dans `mart_tables`.
2. `terraform plan` → Terraform refuse : les clés d'une map sont uniques.
3. Corrigez → `No changes.`

> 🧠 **La map garantit l'unicité.**

---

## 🏆 Défi autonome

> Ajoutez une 4ᵉ table `NPS_SCORE` **uniquement** en modifiant `terraform.tfvars`.

**Critères :** `Plan: 1 to add` · `main.tf` non modifié · second plan `No changes.`

---

## 🧹 Nettoyage

> 🔴 **Ne faites PAS `terraform destroy`** — vos ressources servent au Jour 3.

---

## 🃏 Anti-sèche

```hcl
# locals.tf — calculé une fois
locals { prefix_env = "${var.learner_prefix}_${var.environment}" }

# variables.tf — la collection
variable "mart_tables" { type = map(object({ name = string, comment = string })) }

# main.tf — un bloc, N objets
resource "snowflake_table" "collection" {
  for_each = var.mart_tables
  database = snowflake_database.mon_mart.name
  schema   = snowflake_schema.mon_schema.name
  name     = each.value.name
}

# outputs.tf — le contrat
output "table_names" {
  value = { for k, t in snowflake_table.collection : k => t.name }
}
```

| Fondement | En une phrase |
|---|---|
| `locals` | Calculé une fois, réutilisé partout |
| `validation` | Erreur bloquée **avant** le plan |
| `for_each` | Un bloc + une map = N objets |
| `output` | Ce que je publie aux autres |
