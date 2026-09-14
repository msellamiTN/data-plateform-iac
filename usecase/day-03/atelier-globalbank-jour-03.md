# 🏦 Atelier GlobalBank — Jour 3

## *La plateforme : `moved`, `import`, `modules`, `data` sources, remote state*

> **Formation Terraform + provider Snowflake** · ODDO BHF · **Jour 3**
> **Durée :** 4 TP × 1 h · **Prérequis :** Jour 2 terminé, avec `No changes.`
> **Outils :** VS Code (Terraform uniquement)

---

## 1. Où nous en sommes

Hier, chacun a écrit **une collection** — `for_each` sur une map, `locals` pour le nommage, `validation` pour les garde-fous, `output` pour le contrat.

```
   🔵  3 rôles + 3 warehouses (Fares, Mohamed, Sirine)
   🟢  3 tables LANDING + 3 tables DIM (Amal, Lara)
   🟠  3 tables BUSINESS × 3 domaines (Manel, Leila, Olfa)
   🟣  3 tables MART × 3 marts (Ghassen, Adem, Hadhemi)
```

**Trois constats de hier :**

1. Les onze `main.tf` ont **exactement la même forme** — `for_each` sur une map.
2. Les onze projets ont les **mêmes six fichiers**.
3. Le passage en `for_each` a **détruit** un objet — l'adresse a changé.

```
   ┌──────────────────────────────────────────────────────────────┐
   │  De : Sofia Almeida — Head of Data Platform                  │
   │  Le : jeudi, 09 h 05                                         │
   │                                                              │
   │  « Trois problèmes ouverts :                                 │
   │                                                              │
   │    1. Le passage en for_each a détruit un objet.             │
   │       Sur une table avec des données, c'est un incident.     │
   │       Comment l'éviter ?                                      │
   │                                                              │
   │    2. Votre objet legacy existe dans Snowflake            │
   │       mais pas dans votre code. Comment l'adopter            │
   │       sans le détruire ?                                     │
   │                                                              │
   │    3. Platform doit accorder des droits sur les databases    │
   │       des autres équipes. Comment référencer ce que          │
   │       je n'ai pas créé ?                                     │
   │                                                              │
   │  Et un constat : onze personnes écrivent la même             │
   │  structure. Pourquoi l'écrire onze fois ? »                  │
   └──────────────────────────────────────────────────────────────┘
```

---

## 2. Les 4 fondements de la journée

Vous avez quatre problèmes. Chaque étape résout **un** problème avec **un** fondement.

| Étape | Ce que je fais | 🧠 Le fondement que j'apprends |
|:---:|---|---|
| **1** | Je corrige le `1 to destroy` de hier | **`moved`** — déplacer sans détruire |
| **2** | J'adopte mon objet legacy | **`import`** — adopter une ressource existante |
| **3** | Je factorise mon `for_each` dans un module | **`module`** — réutiliser la même structure |
| **4** | Je lis une ressource que je n'ai pas créée | **`data` source** — le `SELECT` de Terraform |

> 🧠 **Aujourd'hui, on ne clique plus dans Snowsight.** On corrige, on factorise, on connecte. C'est le jour où l'infrastructure devient une **plateforme**.

### La structure de projet passe de 6 à 7 fichiers

```
   HIER (Jour 2)                     AUJOURD'HUI (Jour 3)
   ─────────────────                 ─────────────────────────────
   versions.tf                       versions.tf
   provider.tf                       provider.tf
   variables.tf                      variables.tf
   locals.tf                         locals.tf
   main.tf                           main.tf          → appelle des modules
   outputs.tf                        outputs.tf
   terraform.tfvars                  terraform.tfvars
                                     modules/         → vos modules réutilisables
```

> 🧠 **Le `main.tf` ne contient plus de `resource`.** Il contient des **appels de modules**. Les resources vivent **dans** les modules.

---

## 3. Ma mission du Jour 3

**Trouvez votre ligne.** Chacun applique les 4 étapes sur **une seule ressource basique**.

| Équipe | Propriétaire | 🎯 Ma ressource basique | Ma mission du Jour 3 |
|---|---|---|---|
| 🔵 **Platform** | **Fares** | `WH_APP01_LEGACY` (warehouse) | `moved` · `import` · `module` · `data` |
| 🔵 **Platform** | **Mohamed** | `WH_APP02_LEGACY` (warehouse) | `moved` · `import` · `module` · `data` |
| 🔵 **Platform** | **Sirine** | `WH_APP03_LEGACY` (warehouse) | `moved` · `import` · `module` · `data` |
| 🟢 **Data Eng** | **Amal** | `ACCOUNTS` (table) | `moved` · `import` · `module` · `data` |
| 🟢 **Data Eng** | **Lara** | `DIM_CUSTOMER` (table) | `moved` · `import` · `module` · `data` |
| 🟠 **Business** | **Manel** | `CUSTOMER` (table) | `moved` · `import` · `module` · `data` |
| 🟠 **Business** | **Leila** | `PRODUCT` (table) | `moved` · `import` · `module` · `data` |
| 🟠 **Business** | **Olfa** | `CAMPAIGN` (table) | `moved` · `import` · `module` · `data` |
| 🟣 **BI** | **Ghassen** | `CUSTOMER_360` (table) | `moved` · `import` · `module` · `data` |
| 🟣 **BI** | **Adem** | `PNL_MONTHLY` (table) | `moved` · `import` · `module` · `data` |
| 🟣 **BI** | **Hadhemi** | `TX_DAILY` (table) | `moved` · `import` · `module` · `data` |

> ⚠️ **Règle inchangée : je ne crée que les types de ressources de mon équipe.**
> 🧠 **Aujourd'hui, on connecte les équipes.** Platform lit les outputs des autres pour accorder les droits. C'est la première **dépendance entre équipes**.

---

## 4. Le déroulé — personne n'attend

### Phase 1 — initiation commune (09 h 15 – 12 h 30)

> 🎤 **Même règle :** le formateur démontre **une étape** au vidéoprojecteur, puis **chacun la refait immédiatement**.

| Créneau | 🎤 Le formateur démontre | 👥 Les onze font, sur LEUR périmètre |
|---|---|---|
| **09 h 15 – 09 h 30** | Rappel du Jour 2 · le `1 to destroy` | *(observent)* |
| **09 h 30 – 10 h 15** | *(circule)* | **Étape ① `moved` — corrigent le destroy** |
| **10 h 15 – 10 h 30** | Étape ② `import` | *(observent)* |
| **10 h 30 – 10 h 45** | *(circule)* | **Importent leur objet legacy** |
| **10 h 45 – 11 h 00** | ☕ Pause | |
| **11 h 00 – 11 h 15** | Étape ③ `module` | *(observent)* |
| **11 h 15 – 12 h 00** | *(circule)* | **Factorisent leur for_each en module** |
| **12 h 00 – 12 h 30** | Étape ④ `data` source | *(observent)* |
| **12 h 30 – 13 h 30** | 🍽️ Déjeuner | |

### Phase 2 — approfondissement (13 h 30 – 16 h 00)

| Créneau | Ce que chacun fait |
|---|---|
| **13 h 30 – 14 h 15** | Étape ④ `data` source — je lis les ressources des autres équipes |
| **14 h 15 – 15 h 00** | 🐛 Chaos Lab — je casse un module et je le répare |
| **15 h 00 – 15 h 15** | ☕ Pause |
| **15 h 15 – 15 h 45** | 🏆 Défi — j'ajoute un 5ᵉ objet via le module SANS toucher au module |
| **15 h 45 – 16 h 00** | Point de convergence en plénière |

### Le plan de charge — les onze

| | Phase 1 · matin | Phase 2 · 13 h 30 | Chaos Lab · 14 h 15 | Défi · 15 h 15 |
|---|---|---|---|---|
| 🔵 **Fares** | moved + import + module sur `WH_APP01_LEGACY` | `data` sur les databases | casse un module | + `WH_APP01_COMPLIANCE_DEV` via module |
| 🔵 **Mohamed** | moved + import + module sur `WH_APP02_LEGACY` | `data` sur les databases | casse un module | + `WH_APP02_REPORTING_DEV` via module |
| 🔵 **Sirine** | moved + import + module sur `WH_APP03_LEGACY` | `data` sur les databases | casse un module | + `WH_APP03_ADHOC_DEV` via module |
| 🟢 **Amal** | moved + import + module sur `ACCOUNTS` | `data` sur les schemas | casse un module | + `WIRE_TRANSFERS` via module |
| 🟢 **Lara** | moved + import + module sur `DIM_CUSTOMER` | `data` sur les schemas | casse un module | + `DIM_CURRENCY` via module |
| 🟠 **Manel** | moved + import + module sur `CUSTOMER` | `data` sur les schemas | casse un module | + `CUSTOMER_SCORE` via module |
| 🟠 **Leila** | moved + import + module sur `PRODUCT` | `data` sur les schemas | casse un module | + `PRODUCT_STOCK` via module |
| 🟠 **Olfa** | moved + import + module sur `CAMPAIGN` | `data` sur les schemas | casse un module | + `CAMPAIGN_ROI` via module |
| 🟣 **Ghassen** | moved + import + module sur `CUSTOMER_360` | `data` sur les schemas | casse un module | + `NPS_SCORE` via module |
| 🟣 **Adem** | moved + import + module sur `PNL_MONTHLY` | `data` sur les schemas | casse un module | + `FORECAST_REVENUE` via module |
| 🟣 **Hadhemi** | moved + import + module sur `TX_DAILY` | `data` sur les schemas | casse un module | + `TX_FRAUD` via module |

> 💡 **Le premier qui termine aide son voisin d'équipe avant de passer à la suite.**

---
---

# 🎯 À vous — ouvrez le fichier de VOTRE équipe

| Équipe | Fichier |
|---|---|
| 🔵 **Platform** · Fares · Mohamed · Sirine | [`team-platform.md`](team-platform.md) |
| 🟢 **Data Engineering** · Amal · Lara | [`team-data-engineering.md`](team-data-engineering.md) |
| 🟠 **Business Data** · Manel · Leila · Olfa | [`team-business-data.md`](team-business-data.md) |
| 🟣 **BI / Analytics** · Ghassen · Adem · Hadhemi | [`team-bi-analytics.md`](team-bi-analytics.md) |

---

# 🐛 Le Chaos Lab — casser un module

> *Le module est une boîte noire. Que se passe-t-il quand on change une variable à l'intérieur ?* **14 h 15 – 15 h 00**

## Cassez une variable de votre module

1. Dans `modules/<votre-module>/variables.tf`, **changez le `default`** d'une variable (par exemple, mettez `warehouse_size = "LARGE"` au lieu de `"X-SMALL"`).
2. **4 · Prévisualiser** depuis la racine.

```text
  # module.tables.snowflake_table.collection["accounts"] will be updated in-place
  ~ warehouse_size = "X-SMALL" → "LARGE"
```

> 🛑 **Le module a propagé le changement à toutes les ressources.** Une seule variable, trois ressources impactées.

3. **Ne validez pas.** Remettez la valeur correcte.
4. **4 · Prévisualiser** → `No changes.`

> 🧠 **Le module est un contrat.** Ses variables sont son **interface**. Changer une variable à l'intérieur affecte **tous les appelants** — c'est pourquoi le versioning des modules existe en entreprise.

---

# 🏆 Le défi — 15 h 15

```
   ┌──────────────────────────────────────────────────────────────┐
   │  De : Sofia Almeida                                          │
   │  Le : jeudi, 15 h 15                                        │
   │                                                              │
   │  « Ajoutez un cinquième objet à votre collection —           │
   │    via le module, SANS modifier le module.                   │
   │                                                              │
   │  Si vous devez toucher à modules/, c'est que votre           │
   │  module n'est pas assez paramétré. »                        │
   └──────────────────────────────────────────────────────────────┘
```

| Propriétaire | Sa 5ᵉ entrée |
|---|---|
| 🔵 Fares | `compliance_reader = { suffix = "COMPLIANCE_READER", comment = "Lecture Conformité" }` |
| 🔵 Mohamed | `reporting = { suffix = "REPORTING", comment = "Rôle Reporting" }` |
| 🔵 Sirine | `adhoc = { suffix = "ADHOC_WH", comment = "Compute — requêtes adhoc", auto_suspend = 60 }` |
| 🟢 Amal | `wire_transfers = { name = "WIRE_TRANSFERS", comment = "Flux virements" }` |
| 🟢 Lara | `currency = { name = "DIM_CURRENCY", comment = "Dimension Devise" }` |
| 🟠 Manel | `score = { name = "CUSTOMER_SCORE", comment = "Score client" }` |
| 🟠 Leila | `stock = { name = "PRODUCT_STOCK", comment = "Stock produit" }` |
| 🟠 Olfa | `roi = { name = "CAMPAIGN_ROI", comment = "ROI de campagne" }` |
| 🟣 Ghassen | `nps = { name = "NPS_SCORE", comment = "Net Promoter Score" }` |
| 🟣 Adem | `forecast = { name = "FORECAST_REVENUE", comment = "Prévision revenus" }` |
| 🟣 Hadhemi | `fraud = { name = "TX_FRAUD", comment = "Transactions frauduleuses" }` |

**Critères :** `Plan: 1 to add, 0 to change, 0 to destroy.` · `modules/` **non modifié** · second plan `No changes.`

> 🏆 **Un module bien paramétré absorbe une nouvelle entrée sans modification.** C'est la définition d'un module réutilisable.

---

# 🔎 Le point de convergence — 15 h 45

```sql
SHOW ROLES LIKE 'APP%';
SHOW WAREHOUSES LIKE 'WH_%';
SHOW TABLES IN DATABASE APP04_RAW_DEV;
SHOW TABLES IN DATABASE APP06_CUSTOMER_DEV;
SHOW TABLES IN DATABASE APP09_CUSTOMER_MART_DEV;
```

```
   ➡️  ~15 objets · 11 propriétaires · 4 modules réutilisables
       et la première lecture croisée via data source
```

## Les trois constats à faire dire à la salle

1. **Chacun a factorisé son `for_each` dans un module.** Le `main.tf` ne contient plus de `resource` — seulement des appels de modules.
2. **`moved` a évité la destruction.** L'objet renommé a été préservé — zéro perte de données.
3. **Chacun lit les ressources des autres équipes via `data` source.** C'est la première **connexion entre équipes**.

> 🎯 **Le constat 3 est le plus important.** Demain, en production, c'est ainsi que les équipes se coordonnent : pas de réunions, pas de tickets — **un `data` source qui lit ce que l'autre a créé**.

## Les 4 fondements de la journée

| # | Fondement | Étape | En une phrase |
|:---:|---|:---:|---|
| 1 | **`moved`** | 1 | Déplace une adresse dans le state **sans détruire**. C'est ce qui sauve les données. |
| 2 | **`import`** | 2 | Adopte une ressource existante **sans la recréer**. C'est le pont vers le brownfield. |
| 3 | **`module`** | 3 | Factorise une structure répétée. Le `main.tf` devient un **appelant**, pas un auteur. |
| 4 | **`data` source** | 4 | Lit une ressource que **quelqu'un d'autre a créée**. C'est le `SELECT` de Terraform. |

---

## ⚠️ Avant de partir

> 🎯 **Vérifiez que vos objets legacy sont maintenant dans votre state Terraform.**
> ```bash
> terraform state list | findstr LEGACY
> ```
> **Ils sont adoptés — plus de ressources orphelines.**

> 🔴 **Aucun `destroy` avant vendredi.**

---

## 🃏 Anti-sèche

```hcl
# ── moved : déplacer sans détruire ────────────────────────
moved {
  from = snowflake_table.accounts
  to   = snowflake_table.landing["accounts"]
}

# ── import : adopter une ressource existante ─────────────
terraform import snowflake_warehouse.legacy WH_APP01_LEGACY

# ── module : appeler un module ────────────────────────────
module "tables" {
  source = "./modules/snowflake-tables"

  database   = local.db_name
  schema     = local.schema_name
  tables     = var.tables
  owner_tag  = local.owner_tag
}

# ── data source : lire ce que je n'ai pas créé ───────────
data "snowflake_database" "raw" {
  name = "APP04_RAW_DEV"
}
```

| | `resource` | `data` source |
|---|---|---|
| Je crée | ✅ | ❌ |
| Je lis | ❌ | ✅ |
| Dans le state | ✅ (je gère) | ❌ (je consulte) |
| Référence | `snowflake_database.raw.name` | `data.snowflake_database.raw.name` |

| | `moved` | `import` |
|---|---|---|
| Quand | après un renommage | ressource existe sans code |
| Action | bloc dans `.tf` | commande CLI |
| Effet | met à jour le state | ajoute au state |
| Détruit | ❌ | ❌ |

---

## 🔧 Si ça coince

| Message | Cause | Solution |
|---|---|---|
| `moved block: source address does not exist` | L'ancienne adresse n'est pas dans le state | Vérifiez `terraform state list` |
| `Cannot import to non-existent resource` | Le bloc `resource` n'existe pas encore | Créez le bloc d'abord, puis importez |
| `Module not found` | Le chemin `source =` est incorrect | Vérifiez le chemin relatif depuis la racine |
| `data source: no matching object found` | La ressource n'existe pas dans Snowflake | Vérifiez le nom exact |
| `remote state: unsupported backend` | Le backend n'est pas configuré | Utilisez `local` pour le lab |
| `1 to destroy` après `moved` | Le `moved` est mal placé | Le bloc `moved` doit être dans le **bon** fichier |
| Le module veut tout recréer | Les variables du module ne matchent pas le state | Vérifiez que les valeurs passées correspondent |

---

## 🔮 La suite

Vous savez :
- Écrire du code paramétré, validé, qui multiplie (Jour 2)
- Factoriser en modules, adopter le brownfield, connecter les équipes (Jour 3)

**Prochaine étape : le CI/CD.** Ces modules, ces outputs, ces contrats — ils doivent vivre dans un pipeline, pas sur un laptop.

---

*Atelier GlobalBank — Jour 3 · ODDO BHF, salle Carthage*
