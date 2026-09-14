# 🏦 Atelier GlobalBank — Jour 1

## *Ma première ressource : du clic Snowsight au fichier Terraform*

> **Formation Terraform + provider Snowflake** · ODDO BHF · **Jour 1**
> **Durée :** 4 TP × 1 h · **Prérequis Terraform : aucun**
> **Outils :** navigateur (Snowsight) + VS Code. **Aucun script, aucun PowerShell.**

---

## 1. Ce que nous construisons ensemble

GlobalBank migre son datawarehouse vers Snowflake. Le prédécesseur a tout construit **à la main**. L'Inspection Générale demande qui a créé quoi, quand, et pourquoi. Personne ne peut répondre.

**Notre mission : reconstruire la plateforme en tant que code.**

```
                    GLOBALBANK DATA PLATFORM
                              │
   ┌──────────────┬───────────┼──────────────┬──────────────┐
   ▼              ▼           ▼              ▼              ▼
🔵 PLATFORM   🟢 DATA ENG  🟠 BUSINESS DATA  🟣 BI
le compute    les zones     un domaine       un mart
et les rôles  techniques    = une database   = une database
```

> 🧠 **Une seule plateforme, onze constructeurs.** Chacun sur son périmètre, personne sur celui d'un autre. C'est ce qui permet de travailler **tous en parallèle, dès la première minute**.

---

## 2. Chaque équipe crée SES types de ressources

**C'est la règle qui structure toute la semaine.**

| Équipe | Membres | Types de ressources **qu'elle seule** crée |
|---|---|---|
| 🔵 **Platform / DevOps** | Fares · Mohamed · Sirine | `WAREHOUSE` · `ROLE` · `GRANT` · `RESOURCE MONITOR` |
| 🟢 **Data Engineering** | Amal · Lara | `DATABASE` · `SCHEMA` · `TABLE` · `FILE FORMAT` · `STAGE` · `STREAM` · `TASK` |
| 🟠 **Business Data** | Manel · Leila · Olfa | `DATABASE` · `SCHEMA` · `TABLE` · `VIEW` · `FUNCTION` · `SHARE` · `GRANT` |
| 🟣 **BI / Analytics** | Ghassen · Adem · Hadhemi | `DATABASE (mart)` · `SCHEMA` · `TABLE` · `VIEW` · `MATERIALIZED VIEW` · `SHARE` |

> 🔵 **Platform fournit le compute à toute la plateforme.** Personne d'autre ne crée de warehouse. C'est un **service** — et la première séparation des responsabilités que l'Inspection viendra vérifier.

---

## 3. Ma ressource du Jour 1

**Trouvez votre ligne.** C'est l'objet que vous allez créer aujourd'hui, à la main puis en Terraform.

| Équipe | Propriétaire | 🎯 Ma ressource du Jour 1 | Type |
|---|---|---|---|
| 🔵 **Platform** | **Fares Azzabi** | `WH_APP01_INGEST_DEV` | warehouse |
| 🔵 **Platform** | **Mohamed Laifi** | `WH_APP02_BUSINESS_DEV` | warehouse |
| 🔵 **Platform** | **Sirine Dorgham** | `WH_APP03_BI_DEV` | warehouse |
| 🟢 **Data Eng** | **Amal Nouioui** | `APP04_RAW_DEV` | database |
| 🟢 **Data Eng** | **Lara Hannachi** | `APP05_CORE_DEV` | database |
| 🟠 **Business Data** | **Manel Manai** | `APP06_CUSTOMER_DEV` | database |
| 🟠 **Business Data** | **Leila Sammoud** | `APP07_PRODUCT_DEV` | database |
| 🟠 **Business Data** | **Olfa Ben Mahfoudh** | `APP08_CAMPAIGN_DEV` | database |
| 🟣 **BI** | **Ghassen Khabou** | `APP09_CUSTOMER_MART_DEV` | database |
| 🟣 **BI** | **Adem Gaied** | `APP10_FINANCE_MART_DEV` | database |
| 🟣 **BI** | **Hadhemi Boughanmi** | `APP11_TRANSACTION_MART_DEV` | database |

> ⚠️ **Règle n°1 de la semaine : je ne crée que l'objet de ma ligne, du type de mon équipe.**
>
> 🧠 **Pourquoi personne n'attend personne aujourd'hui :** dans Snowflake, un **warehouse** ne connaît aucune database, et une **database** n'a besoin d'aucun warehouse pour exister. Le compute et le stockage sont deux mondes indépendants. **Onze objets, zéro dépendance.**

**Mon objet du jour :** `______________________`

---

## 4. Les 4 fondements de la journée

Vous créez **une seule ressource**, en quatre étapes. Chaque étape ajoute **un** fondement.

| Étape | Ce que je fais | 🧠 Le fondement que j'apprends |
|:---:|---|---|
| **1** | Je crée mon objet **à la main** et je lis le SQL généré | **Le formulaire n'est qu'une façade** — la table de correspondance |
| **2** | Je l'écris en Terraform et j'applique | **`resource`, le workflow, et le state** |
| **3** | Je remplace le nom en dur par une variable | **`variable` et l'interpolation** |
| **4** | Quelqu'un modifie mon objet dans Snowsight | **La dérive et le diff** |

> 🧠 **La règle du parcours : jamais une ligne de Terraform avant d'avoir cliqué le même objet dans Snowsight.**

```
   ①  🖱️  JE LE FAIS À LA MAIN         Snowsight, champ par champ
   ②  🔍  JE VOIS LE SQL GÉNÉRÉ        le formulaire est une façade
   ③  🔁  JE FAIS LA CORRESPONDANCE     champ → SQL → argument Terraform
   ④  ⌨️  JE L'ÉCRIS EN TERRAFORM       dans VS Code
   ⑤  🧠  J'APPRENDS UN FONDEMENT       un seul concept par étape
```

---

## 5. Le poste de travail — 15 minutes, une seule fois

| # | Action | Où |
|:---:|---|---|
| 1 | Installer **VS Code** + l'extension **HashiCorp Terraform** | marketplace VS Code |
| 2 | Vérifier **Terraform** | `terraform version` |
| 3 | Créer mon dossier | `environments/dev/` |
| 4 | Générer un jeton Snowflake | Snowsight → avatar → *Settings → Authentication* |
| 5 | Déposer `.vscode/tasks.json` | fourni par le formateur |

> ⚠️ **Le jeton ne s'affiche qu'une fois.** Copiez-le immédiatement.

### Les commandes au clic — `Ctrl+Shift+B`

```
   ▸ 1 · Formater        ▸ 2 · Initialiser      ▸ 3 · Vérifier
   ▸ 4 · Prévisualiser   ▸ 5 · Appliquer        ▸ 9 · Supprimer
```

> 💡 Vous ne taperez **aucune commande** de la journée.

### `versions.tf` — identique pour les onze

```hcl
terraform {
  required_version = "= 1.14.5"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.14.0"
    }
  }
}
```

### `provider.tf` — la connexion Snowflake

```hcl
# Le mot de passe (PAT) est lu automatiquement depuis secrets/snowflake_pat.txt
# — vous n'avez RIEN à taper, le fichier est déjà sur votre poste.

locals {
  pat_file        = "${path.module}/../../../../../secrets/snowflake_pat.txt"
  snowflake_token = try(trimspace(file(local.pat_file)), var.snowflake_token, "")
}

variable "snowflake_organization" { type = string }
variable "snowflake_account" { type = string }
variable "snowflake_user" { type = string }

variable "snowflake_token" {
  type      = string
  sensitive = true
  default   = ""
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = local.snowflake_token
}
```

> 🧠 **Deux blocs, deux rôles.** `terraform { }` = **le contrat** (quelle version, quel plugin). `provider "snowflake" { }` = **le badge d'accès** (quel compte, quelle identité).

### `terraform.tfvars` — la seule ligne qui vous distingue

```hcl
learner_prefix         = "APP01"   # ← REMPLACEZ par le vôtre (APP01…APP11)
environment            = "DEV"
warehouse_size         = "X-SMALL"

snowflake_organization = "ZVFXOZW"
snowflake_account      = "PM71247"
snowflake_user         = "DATA2AI"
```

> 🎯 **C'est la seule fois de la semaine où vous saisissez vos identifiants.** Le `learner_prefix` est déjà assigné sur votre poste.

✅ **Checkpoint 0 :** `terraform init` depuis `environments/dev/` → `Terraform has been successfully initialized!`

---
---

## 6. Le déroulé de la journée — personne n'attend

La journée a **deux phases**. La première est **commune aux onze** : mêmes étapes, même rythme, mais **chacun sur son propre objet**. La seconde spécialise chaque équipe sur ses types de ressources.

```
   PHASE 1 — INITIATION COMMUNE          PHASE 2 — SPÉCIALISATION
   09 h 15 → 12 h 30                     13 h 30 → 16 h 00
   ──────────────────────────            ──────────────────────────
   Les 4 fondements                      Chaque équipe approfondit
   Tout le monde au même rythme          avec SES types de ressources
   Chacun sur SON objet                  Chacun sur SON périmètre
```

### Phase 1 — le rythme « démo puis reproduction »

> 🎤 **La règle d'animation :** le formateur démontre **une étape** au vidéoprojecteur sur un objet neutre `DEMO_WH`, puis **chacun la refait immédiatement sur son propre objet**. Jamais plus de 5 minutes de démonstration d'affilée.

| Créneau | 🎤 Le formateur démontre | 👥 Les onze font, sur LEUR objet |
|---|---|---|
| **09 h 15 – 09 h 25** | Étape ① ClickOps sur `DEMO_WH` | *(observent)* |
| **09 h 25 – 09 h 50** | *(circule et débloque)* | **Créent leur objet dans Snowsight** |
| **09 h 50 – 10 h 00** | Étape ② `GET_DDL` + la correspondance | *(observent)* |
| **10 h 00 – 10 h 45** | *(circule)* | **Lisent leur DDL, remplissent leur table de correspondance** |
| **10 h 45 – 11 h 00** | ☕ Pause — 🔵 Platform annonce ses 3 warehouses | |
| **11 h 00 – 11 h 15** | Étape ③ le `main.tf` et l'erreur `already exists` | *(observent)* |
| **11 h 15 – 12 h 00** | *(circule)* | **Écrivent leur `main.tf`, appliquent, découvrent le state** |
| **12 h 00 – 12 h 30** | Étape ④ la variable | **Paramètrent leur nom → `No changes.`** |
| **12 h 30 – 13 h 30** | 🍽️ Déjeuner | |

✅ **Fin de Phase 1 : les onze ont vu `No changes.` au moins une fois.** C'est le seul objectif non négociable de la journée.

### Phase 2 — la spécialisation par équipe

| Créneau | Ce que chacun fait |
|---|---|
| **13 h 30 – 14 h 00** | La dérive : chacun modifie son objet dans Snowsight et observe le diff |
| **14 h 00 – 15 h 00** | **La tâche de spécialisation de mon équipe** *(voir votre fichier `team-*.md`)* |
| **15 h 00 – 15 h 15** | ☕ Pause |
| **15 h 15 – 15 h 45** | Créez un objet dans Snowsight (à la main, hors Terraform) — matière première de jeudi |
| **15 h 45 – 16 h 00** | Point de convergence en plénière |

---

## 7. Le plan de charge — les onze, créneau par créneau

> 🎯 **Aucun membre n'est sans tâche à aucun moment de la journée.** Ce tableau est votre contrôle d'animation.

| | 09 h 25 → 12 h 30 · **Phase 1** | 13 h 30 – 14 h 00 · **Dérive** | 14 h 00 → 15 h 00 · **Spécialisation** |
|---|---|---|---|
| 🔵 **Fares Azzabi** | `WH_APP01_INGEST_DEV` | drift sur le commentaire | Phase 2 de votre `team-platform.md` |
| 🔵 **Mohamed Laifi** | `WH_APP02_BUSINESS_DEV` | drift sur le commentaire | Phase 2 de votre `team-platform.md` |
| 🔵 **Sirine Dorgham** | `WH_APP03_BI_DEV` | drift sur le commentaire | Phase 2 de votre `team-platform.md` |
| 🟢 **Amal Nouioui** | `APP04_RAW_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-data-engineering.md` |
| 🟢 **Lara Hannachi** | `APP05_CORE_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-data-engineering.md` |
| 🟠 **Manel Manai** | `APP06_CUSTOMER_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-business-data.md` |
| 🟠 **Leila Sammoud** | `APP07_PRODUCT_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-business-data.md` |
| 🟠 **Olfa Ben Mahfoudh** | `APP08_CAMPAIGN_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-business-data.md` |
| 🟣 **Ghassen Khabou** | `APP09_CUSTOMER_MART_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-bi-analytics.md` |
| 🟣 **Adem Gaied** | `APP10_FINANCE_MART_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-bi-analytics.md` |
| 🟣 **Hadhemi Boughanmi** | `APP11_TRANSACTION_MART_DEV` + schema + table | drift sur le commentaire | Phase 2 de votre `team-bi-analytics.md` |

> 🟢 **Data Engineering crée 3 objets liés :** database → schema → table. L'ordre compte — Terraform le gère tout seul grâce aux références.

> 💡 **Le premier qui termine une étape aide son voisin d'équipe avant de passer à la suivante.** Avec onze participants et un formateur, ces relais sont ce qui fait tenir la salle.

---
---

# 🎯 À vous — ouvrez le fichier de VOTRE équipe

> Chaque fichier contient votre ticket, vos valeurs Snowsight, votre SQL, votre table de correspondance et votre `main.tf`.
> **Remplacez `APP0X` par VOTRE `learner_prefix` partout.**

| Équipe | Membres | Fichier | Ce que vous créez |
|---|---|---|---|
| 🔵 **Platform** | Fares · Mohamed · Sirine | [`team-platform.md`](team-platform.md) | 1 warehouse + paramétrage + dérive |
| 🟢 **Data Engineering** | Amal · Lara | [`team-data-engineering.md`](team-data-engineering.md) | 1 database + 1 schema + 1 table |
| 🟠 **Business Data** | Manel · Leila · Olfa | [`team-business-data.md`](team-business-data.md) | 1 database + 1 schema + 1 table |
| 🟣 **BI / Analytics** | Ghassen · Adem · Hadhemi | [`team-bi-analytics.md`](team-bi-analytics.md) | 1 data mart + 1 schema + 1 table |

> 🔗 **Ouvrez uniquement le fichier de VOTRE équipe.** Suivez les étapes pas à pas.

---
---

# 🔎 Le point de convergence — 15 minutes en plénière

## La plateforme après une journée

Le formateur projette une worksheet :

```sql
SHOW WAREHOUSES LIKE 'WH_%';
SHOW DATABASES  LIKE 'APP%';
```

```
   🔵  WH_APP01_INGEST_DEV · WH_APP02_BUSINESS_DEV · WH_APP03_BI_DEV   3 warehouses

   🟢  APP04_RAW_DEV · APP05_CORE_DEV                                   2 databases
   🟠  APP06_CUSTOMER_DEV · APP07_PRODUCT_DEV · APP08_CAMPAIGN_DEV      3 databases
   🟣  APP09_CUSTOMER_MART_DEV · APP10_FINANCE_MART_DEV · APP11_TRANSACTION_MART_DEV

   ➡️  11 objets · 11 propriétaires · 11 fichiers main.tf
```

> 🏆 **Personne n'a construit cela seul.** Chacun pointe son objet à l'écran et nomme le fichier `.tf` qui le décrit. **C'est le squelette de la plateforme. Demain, on met la chair.**

## Les trois constats à faire dire à la salle

1. **Les onze `main.tf` ont la même forme** — un bloc `resource`, quelques arguments. Seules les valeurs changent.
2. **Huit databases sur onze objets ont un bloc quasi identique**, à deux valeurs près.
3. **Chaque `auto_suspend` de Platform a une justification métier** — 60 pour les rafales, 120 pour les sessions et les vagues. **Aucun n'est un défaut.**

> 🎯 **Le constat 2 justifiera les `locals` et le `for_each` demain, et les modules vendredi.**

## Les 4 fondements de la journée

| # | Fondement | Étape | En une phrase |
|:---:|---|:---:|---|
| 1 | **Le formulaire est une façade** | 1 | Chaque champ produit une clause SQL. Terraform écrit la même chose, versionnée. |
| 2 | **`resource`, workflow, state** | 2 | Un bloc décrit un objet. `init → plan → apply`. Ce que Terraform n'a pas créé n'existe pas pour lui. |
| 3 | **`variable` et interpolation** | 3 | Un paramètre déclaré une fois, inséré partout avec `${…}`. |
| 4 | **La dérive** | 4 | Un écart entre le réel et le code. Le code fait autorité — sauf décision motivée. |
| 5 | **La 2ᵉ ressource** | 5 | Un projet peut décrire plusieurs objets. Quand l'un référence l'autre, Terraform en déduit **l'ordre tout seul**. |

---

## ⚠️ Avant de partir — la matière première de jeudi

> 🎯 **Créez un dernier objet dans Snowsight, à la main, et NE le mettez PAS en Terraform.**
>
> **Nom :** un objet du type de votre équipe (un warehouse pour Platform, une database pour les autres) — avec un nom qui **n'utilise pas** votre `learner_prefix`.
>
> C'est le « legs du prédécesseur ». **Jeudi, votre voisin l'importera dans son code** sans l'avoir jamais créé.

**Notez au tableau :** votre prénom, le nom de l'objet, son type.

> 🔴 **Aucun `destroy` avant vendredi.**

---

## 🃏 Anti-sèche

```hcl
# ── La structure d'un bloc ───────────────────────────────
resource "TYPE" "NOM_LOCAL" {
  argument = valeur
}
#   TYPE       → imposé par le provider  (snowflake_warehouse, snowflake_database)
#   NOM_LOCAL  → choisi par vous, interne à Terraform
#   name       → le nom RÉEL dans Snowflake

# ── Une variable et son interpolation ────────────────────
variable "learner_prefix" {
  type    = string
}
name = "${var.learner_prefix}_RAW_DEV"   # → "APP04_RAW_DEV"

# ── Mes fichiers ─────────────────────────────────────────
versions.tf        les versions exigées
provider.tf        la connexion Snowflake
variables.tf       les entrées (votre préfixe, l'environnement)
terraform.tfvars   vos valeurs
```

| Commande | Rôle |
|---|---|
| `terraform init` | installe le provider (1 fois) |
| `terraform plan` | prévisualise sans toucher |
| `terraform apply` | applique pour de vrai |
| `No changes.` | code = réalité ✅

**Symboles du plan :** `+` créer · `~` modifier · `-` détruire 🔴 · `-/+` recréer 🔴🔴

**SQL en worksheet :**

```sql
SELECT GET_DDL('WAREHOUSE', 'WH_APP01_INGEST_DEV');
SELECT GET_DDL('DATABASE',  'APP04_RAW_DEV');
SHOW WAREHOUSES LIKE 'WH_%';
SHOW DATABASES  LIKE 'APP%';
```

---

## 🔧 Si ça coince

| Message | Cause | Solution |
|---|---|---|
| `Object already exists` | L'objet créé à la main est encore là | Drop dans Snowsight — c'est la leçon de l'étape 2 |
| `Invalid account identifier` | Organisation ou compte erroné | Vérifiez `terraform.tfvars` |
| `token is empty` | Jeton non dans `secrets/snowflake_pat.txt` | Vérifiez le chemin dans `provider.tf` |
| `Insufficient privileges` | Rôle sans droit de création | Vérifiez votre rôle actif dans Snowsight |
| Terraform demande une valeur au clavier | Une variable n'a pas de valeur | Complétez `terraform.tfvars` |
| `learner_prefix must be 2-12 uppercase or underscore` | Préfixe mal formé | Majuscules, chiffres, underscore, ex. `APP07` |
| J'ai créé un objet d'un autre type | Sortie du périmètre de mon équipe | Consultez §2 et §3, supprimez, prévenez |
| `Reference to undeclared resource` | Nom local mal orthographié | Comparez avec votre bloc `resource` |
| `Unsupported argument` | Nom d'argument erroné | Comparez avec votre table de correspondance |

---

## 🔮 Demain — Jour 2

Vous avez **une** ressource. Demain, chacun en ajoute **plusieurs** — dans son propre périmètre.

| Équipe | Ce que j'ajoute demain |
|---|---|
| 🔵 Platform | Mes **rôles** et **warehouses** en `for_each` |
| 🟢 Data Eng | Mes **schemas** et mes **tables** en `for_each` |
| 🟠 Business Data | Mon **schema BUSINESS** et mes **tables** en `for_each` |
| 🟣 BI | Mon **schema MART** et mes **tables** en `for_each` |

**Trois questions restent sans réponse :**

- ❓ Comment créer **trois tables** sans écrire trois blocs identiques ?
- ❓ Comment centraliser la convention de nommage au lieu de la répéter ?
- ❓ Comment empêcher quelqu'un de saisir une valeur interdite ?

**Demain :** `locals`, `validation`, `for_each`, `output`.

---

*Atelier GlobalBank — Jour 1 · ODDO BHF, salle Carthage*
