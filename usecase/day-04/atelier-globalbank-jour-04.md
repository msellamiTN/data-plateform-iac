# 🏦 Atelier GlobalBank — Jour 4

## *Un state partagé, un composant réutilisable, deux environnements*

> **Formation Terraform + provider Snowflake** · ODDO BHF · **Jour 4**
> **Durée :** 5 h · **Prérequis :** Jours 1 à 3 terminés, `No changes.` sur les onze postes
> **Outils :** navigateur (Snowsight + portail Azure) + VS Code

---

## 1. Où nous en sommes

Trois jours. **La plateforme existe, elle est gouvernée, elle est décrite en code.**

```
   🔵  3 warehouses · 3 monitors · 9 rôles · 3 warehouses de service · les grants
   🟢  GB_RAW_DB · GB_CORE_DB  + schemas + 6 tables + file formats + tasks
   🟠  3 databases de domaine + 9 tables + vues + grants
   🟣  3 data marts + 9 tables + vues + grants
```

**Mais elle tient sur onze ordinateurs portables.**

```
   ┌──────────────────────────────────────────────────────────────┐
   │  De : Sofia Almeida — Head of Data Platform                  │
   │  Le : vendredi, 08 h 50                                      │
   │                                                              │
   │  « L'Inspection Générale m'a posé trois questions hier.      │
   │    Je n'ai su répondre à aucune.                             │
   │                                                              │
   │    1. Où est l'état de la plateforme ? Sur le poste de       │
   │       chaque personne. Si un portable tombe, la plateforme   │
   │       devient orpheline. Inacceptable.                       │
   │                                                              │
   │    2. Onze projets qui se ressemblent, zéro composant        │
   │       partagé. Le douzième domaine arrive en novembre :      │
   │       on recopie encore ?                                    │
   │                                                              │
   │    3. Tout est en production. Il n'y a ni DEV ni UAT.        │
   │       On teste directement sur les données réelles. »        │
   └──────────────────────────────────────────────────────────────┘
```

> 🎯 **Les trois questions ont la même réponse technique**, et c'est le programme de la journée : **backend distant**, **module**, **environnements**.

---

## 2. Les 5 fondements de la journée

| Étape | Ce que je fais | 🧠 Le fondement que j'apprends |
|:---:|---|---|
| **1** | Je déplace mon state sur Azure Blob Storage | **Le backend distant** — et le verrou |
| **2** | J'extrais mon code dans `modules/…` | **Le module** — un composant, un contrat |
| **3** | J'appelle mon module sans rien détruire | **`moved` vers un module** — la suite du Jour 3 |
| **4** | Je type et je valide les entrées du module | **Le contrat de module** — `object({…})` |
| **5** | Je crée mon environnement **UAT** | **Une racine par environnement** |

> 🧠 **La règle du parcours ne change pas : jamais une ligne de Terraform avant d'avoir vu l'objet à la main.** Aujourd'hui, le « à la main » se passe dans le **portail Azure** avant de se passer en HCL.

---

## 3. Le déroulé — personne n'attend

### Phase 1 — commune (09 h 15 – 11 h 00)

| Créneau | 🎤 Le formateur démontre | 👥 Les onze font |
|---|---|---|
| **09 h 15 – 09 h 30** | Le problème du state local *(démo : le portable perdu)* | *(observent)* |
| **09 h 30 – 10 h 00** | Étape ① le conteneur Azure, puis `backend "azurerm"` | **Migrent leur state** |
| **10 h 00 – 10 h 30** | *(circule)* | **Vérifient le blob, le verrou, le `serial`** |
| **10 h 30 – 10 h 45** | ☕ Pause | |
| **10 h 45 – 11 h 00** | Étape ② l'anatomie d'un module | *(observent)* |

### Phase 2 — le module et l'environnement (11 h 00 – 16 h 00)

| Créneau | Ce que chacun fait |
|---|---|
| **11 h 00 – 12 h 30** | Étapes ② et ③ — extraire son module, l'appeler, `0 to destroy` |
| **12 h 30 – 13 h 30** | 🍽️ Déjeuner |
| **13 h 30 – 14 h 30** | Étape ④ — le contrat typé du module |
| **14 h 30 – 15 h 15** | Étape ⑤ — la racine `uat/`, backend isolé |
| **15 h 15 – 15 h 30** | 🐛 Chaos Lab — le **state lock** *(par binômes)* |
| **15 h 30 – 16 h 00** | ⚖️ **Convergence des modules** — trois versions, une seule retenue |

### Le plan de charge — les onze

| | Mon module | Ce qu'il crée | Ma racine DEV | Ma racine UAT |
|---|---|---|---|---|
| 🔵 **Fares** | `modules/rbac/` | rôles d'accès + grants | rôles actuels | `GB_RAW_READER_UAT`… |
| 🔵 **Mohamed** | `modules/rbac/` | rôles fonctionnels | rôles actuels | `GB_ENGINEER_UAT`… |
| 🔵 **Sirine** | `modules/compute/` | warehouses de service | warehouses actuels | `GB_FINANCE_WH_UAT`… |
| 🟢 **Amal** | `modules/landing-zone/` | database + schema + tables | `GB_RAW_DB` | `GB_RAW_DB_UAT` |
| 🟢 **Lara** | `modules/landing-zone/` | database + schema + tables | `GB_CORE_DB` | `GB_CORE_DB_UAT` |
| 🟠 **Manel** | `modules/data-domain/` | database + schema + tables + vue | `GB_CUSTOMER_DB` | `GB_CUSTOMER_DB_UAT` |
| 🟠 **Leila** | `modules/data-domain/` | idem | `GB_PRODUCT_DB` | `GB_PRODUCT_DB_UAT` |
| 🟠 **Olfa** | `modules/data-domain/` | idem | `GB_CAMPAIGN_DB` | `GB_CAMPAIGN_DB_UAT` |
| 🟣 **Ghassen** | `modules/data-mart/` | mart + schema + tables | `GB_CUSTOMER_MART` | `GB_CUSTOMER_MART_UAT` |
| 🟣 **Adem** | `modules/data-mart/` | idem | `GB_FINANCE_MART` | `GB_FINANCE_MART_UAT` |
| 🟣 **Hadhemi** | `modules/data-mart/` | idem | `GB_TRANSACTION_MART` | `GB_TRANSACTION_MART_UAT` |

> 💰 **En UAT, aucune équipe métier ne crée de warehouse.** Le stockage d'une database vide ne coûte rien ; un warehouse allumé, si. Seule Sirine crée du compute en UAT, et il est `initially_suspended`.

---
---

# ÉTAPE 1 — Le backend distant

> **Commune aux onze.** 09 h 30 – 10 h 30.

## Le problème, d'abord

Ouvrez votre `terraform.tfstate`. **Ce fichier est le seul endroit au monde** qui sait que `snowflake_table.raw_tables["accounts"]` correspond à `GB_RAW_DB|LANDING|ACCOUNTS`.

| Si… | Alors… |
|---|---|
| Votre portable tombe en panne | Personne ne peut plus gérer vos objets par Terraform |
| Un collègue veut appliquer à votre place | Il n'a pas votre state — il recréerait tout |
| Deux personnes appliquent en même temps | Les deux states divergent — **corruption silencieuse** |
| Un pipeline CI veut appliquer | Il n'a aucun state — il repart de zéro |

> 🎯 **C'est la question n°1 de l'Inspection.** Un state local est un point de défaillance unique, et il interdit tout travail à plusieurs. **La CI de lundi ne peut pas exister sans backend distant.**

## ① 🖱️ D'abord, à la main — dans le portail Azure

> 🎤 **Le formateur a créé le compte de stockage** avant la session. Vous le regardez, vous ne le créez pas — mais **regardez-le vraiment**, c'est la moitié de la leçon.

**portal.azure.com → Storage accounts → `sadata2aitfstatemsn`**

```
   ┌─ Compte de stockage ────────────────────────────────┐
   │   Resource group    rg-data2ai-tf-state     ──── ①
   │   Nom               sadata2aitfstatemsn       ──── ②
   │   Réplication       LRS (local)                     │
   │   Conteneurs        tfstate                   ──── ③
   │                                                     │
   │   ▸ Data protection  Versioning : Activé      ──── ④
   │   ▸ Encryption       Microsoft-managed keys   ──── ⑤
   └─────────────────────────────────────────────────────┘
```

| Élément | Pourquoi il est là |
|---|---|
| ③ Le **conteneur** `tfstate` | Un seul conteneur pour toute la salle — chacun aura **sa propre clé** dedans |
| ④ Le **versioning** | Chaque écriture crée une version. Un state écrasé se restaure. |
| ⑤ Le **chiffrement au repos** | Obligatoire : le state contient tous vos attributs en clair *(Jour 3)* |

**Ouvrez le conteneur `tfstate`.** Il est vide, ou il contient déjà les clés de vos voisins.

## ② 🔍 Ma clé — mon emplacement dans le conteneur

| Je m'appelle | Ma clé en DEV | Ma clé en UAT *(étape 5)* |
|---|---|---|
| **Fares** | `fares/dev.tfstate` | `fares/uat.tfstate` |
| **Mohamed** | `mohamed/dev.tfstate` | `mohamed/uat.tfstate` |
| **Sirine** | `sirine/dev.tfstate` | `sirine/uat.tfstate` |
| **Amal** | `amal/dev.tfstate` | `amal/uat.tfstate` |
| **Lara** | `lara/dev.tfstate` | `lara/uat.tfstate` |
| **Manel** | `manel/dev.tfstate` | `manel/uat.tfstate` |
| **Leila** | `leila/dev.tfstate` | `leila/uat.tfstate` |
| **Olfa** | `olfa/dev.tfstate` | `olfa/uat.tfstate` |
| **Ghassen** | `ghassen/dev.tfstate` | `ghassen/uat.tfstate` |
| **Adem** | `adem/dev.tfstate` | `adem/uat.tfstate` |
| **Hadhemi** | `hadhemi/dev.tfstate` | `hadhemi/uat.tfstate` |

> 🔒 **Une clé par personne et par environnement.** Deux projets qui partagent une clé partagent un state — c'est exactement l'accident que le Chaos Lab de 15 h 15 va provoquer volontairement.

## ③ 🔁 La correspondance

| Dans le portail Azure | Dans le backend Terraform |
|---|---|
| Resource group `rg-data2ai-tf-state` | `resource_group_name` |
| Compte de stockage `sadata2aitfstatemsn` | `storage_account_name` |
| Conteneur `tfstate` | `container_name` |
| *(le nom du blob que je vais créer)* | `key` |
| *(mon identité Azure)* | `use_azuread_auth = true` |

## ④ ⌨️ Le bloc `backend`

**Créez `backend.tf`** à la racine de votre projet :

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-data2ai-tf-state"
    storage_account_name = "sadata2aitfstatemsn"
    container_name       = "tfstate"
    key                  = "fares/dev.tfstate"
    use_azuread_auth     = true
  }
}
```

> 🔒 **Aucun secret dans ce bloc.** `use_azuread_auth = true` dit à Terraform d'utiliser **votre identité Azure**, pas une clé de compte de stockage. C'est la règle non négociable du parcours : **jamais de clé dans un fichier versionné**.

**L'unique commande de terminal de la semaine** — une fois, dans le terminal intégré de VS Code :

```
az login
```

<details>
<summary>🔧 <b>Si <code>az login</code> échoue derrière le proxy</b></summary>

Repli accepté pour la session : le formateur distribue la clé d'accès du compte de stockage, et **chacun la pose en variable d'environnement de sa machine** *(Windows : Paramètres → Variables d'environnement)* :

```
ARM_ACCESS_KEY = <clé fournie par le formateur>
```

Puis retirez `use_azuread_auth = true` du bloc `backend`.

> ⚠️ **Cette clé ne va JAMAIS dans un fichier du projet.** Elle vit dans l'environnement de la machine, et elle sera révoquée en fin de semaine.
</details>

<details>
<summary>🔧 <b>Si le portail Azure n'est pas disponible du tout</b></summary>

La journée se poursuit **sans backend distant** : gardez votre state local et sautez à l'étape 2. Vous perdez la démonstration du verrou — le formateur la fera au vidéoprojecteur — mais **les modules et les environnements fonctionnent à l'identique**.

Notez la ligne dans votre carnet : *« backend distant : à refaire au bureau »*. C'est la première chose à mettre en place sur un vrai projet.
</details>

## La migration

**Ctrl+Shift+B → `2 · Initialiser`**

```text
Initializing the backend...

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend
  to the newly configured "azurerm" backend. An existing non-empty state
  already exists in the new backend. The two states have been saved to
  temporary files...

  Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

**Répondez `yes`.**

```text
Successfully configured the backend "azurerm"! Terraform will automatically
use this backend unless the backend configuration changes.
```

> 🧠 **Ce que Terraform vient de faire :** il a lu votre `terraform.tfstate` local, l'a écrit dans le blob, et **ne lira plus jamais le fichier local**.

### 🧪 Trois vérifications

**1. Le blob existe.** Portail Azure → conteneur `tfstate` → votre dossier → votre `dev.tfstate`. **Ouvrez-le dans le navigateur** : c'est le même JSON qu'hier.

**2. Le fichier local est devenu inerte.** Il est toujours sur votre disque, mais Terraform ne s'en sert plus. **Renommez-le** en `terraform.tfstate.old`, puis **4 · Prévisualiser** → `No changes.` Terraform ne l'a même pas cherché.

**3. Le state est verrouillé pendant l'opération.** Lancez **5 · Appliquer** et, **pendant qu'il tourne**, rafraîchissez le conteneur dans le portail : le blob affiche `Lease state: Leased`. Dès la fin, il repasse à `Available`.

## ⑤ 🧠 Le fondement de l'étape

```
   AVANT                          APRÈS
   ┌──────────────┐               ┌──────────────┐        ┌─────────────────┐
   │  mon-projet/ │               │  mon-projet/ │        │  Azure Blob     │
   │   *.tf       │               │   *.tf       │ ─────► │  tfstate/       │
   │   tfstate ◄──┘ le state       │   backend.tf │        │   fares/        │
   └──────────────┘  vit DANS      └──────────────┘        │    dev.tfstate  │
                     le dossier      le code seul          └─────────────────┘
                                                            le state vit AILLEURS
```

| Fondement | En une phrase |
|---|---|
| **Le backend découple le code du state** | Le dossier ne contient plus que du code. Vous pouvez le déplacer, le renommer, le cloner — **le state ne bouge pas**. |
| **La `key` est l'identité du state** | Deux projets avec la même `key` partagent le même state. C'est voulu, ou c'est un accident. |
| **Le verrou (*lease*)** | Azure Blob pose un bail pendant `apply`. **Un seul écrivain à la fois.** |
| **`init -migrate-state`** | La migration est une opération explicite, jamais automatique. |
| 🔒 **Le chiffrement et le versioning** | Le state est un secret : chiffré au repos, versionné, jamais dans Git. |

> 🎯 **C'est la réponse n°1 à l'Inspection.** Et c'est aussi ce qui rend le reste de la journée possible : **maintenant que le state ne vit plus dans le dossier, vous pouvez réorganiser le dossier librement.** C'est exactement ce que fait l'étape 2.

---
---

# 🎯 À vous — dépliez le bloc de VOTRE équipe

---
---
<details>
<summary><b>🔵 TEAM 1 — PLATFORM · Fares · Mohamed · Sirine</b></summary>

<br/>

---

## 📝 Étape 2 — J'extrais mon module

### Mon module

| Je m'appelle | Mon module | Ce qu'il crée |
|---|---|---|
| **Fares** | `modules/rbac/` | des rôles d'accès + leurs grants |
| **Mohamed** | `modules/rbac/` | des rôles fonctionnels |
| **Sirine** | `modules/compute/` | des warehouses de service |

### ① 🖱️ D'abord, le geste manuel équivalent

**Il n'y en a pas.** Un module n'existe pas dans Snowsight : c'est une notion **purement Terraform**.

> 🧠 **C'est la première fois de la semaine que le miroir ClickOps s'arrête**, et c'est un signal important : le module ne crée aucun objet nouveau. Il **réorganise le code** qui décrit les objets que vous avez déjà. Snowflake ne verra strictement aucune différence — et c'est exactement ce que le plan devra prouver à l'étape 3.

### ② 🔍 L'anatomie d'un module

**Un module, c'est un dossier avec quatre fichiers.** Vous les connaissez tous les quatre.

```
   modules/rbac/
   ├── versions.tf     ← de quel provider j'ai besoin
   ├── variables.tf    ← CE QUE J'ACCEPTE EN ENTRÉE   ⬅️ le contrat
   ├── main.tf         ← les ressources
   └── outputs.tf      ← CE QUE JE PUBLIE EN SORTIE   ⬅️ le contrat
```

| Fichier | Son rôle dans un module |
|---|---|
| `variables.tf` | **Les paramètres.** Ce que l'appelant doit ou peut fournir. |
| `main.tf` | **L'implémentation.** Personne d'autre n'a besoin de la lire. |
| `outputs.tf` | **Le résultat.** Ce que l'appelant peut réutiliser. |
| `versions.tf` | **Les exigences.** Le module déclare ses providers, pas ses credentials. |

> 🔒 **Un module ne contient JAMAIS de bloc `provider` ni de bloc `backend`.** Ils appartiennent à la racine qui l'appelle. Un module qui déclare son propre provider est inutilisable dans un autre contexte.

### ③ 🔁 La correspondance — de la racine vers le module

| Dans mon `main.tf` d'aujourd'hui | Dans le module |
|---|---|
| `var.platform_prefix` | devient une **variable du module** |
| `local.owner_tag` | reste un `local` **interne** au module |
| `var.roles` | devient une **variable du module** |
| `resource "snowflake_account_role" "access_roles"` | **déplacé tel quel** dans `modules/rbac/main.tf` |
| `output "access_roles"` | devient un **output du module** |

### ④ ⌨️ Je crée le module

**`modules/rbac/versions.tf`**

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

**`modules/rbac/variables.tf`**

```hcl
variable "prefix" {
  type        = string
  description = "Préfixe de la plateforme"
}

variable "environment" {
  type        = string
  description = "Environnement cible — dev ou uat"
}

variable "roles" {
  type = map(object({
    suffix  = string
    comment = string
  }))
  description = "Rôles gérés par ce module"
}
```

**`modules/rbac/main.tf`** — *copiez votre bloc actuel, puis remplacez `var.platform_prefix` par `var.prefix`*

```hcl
locals {
  suffix    = var.environment == "dev" ? "" : "_${upper(var.environment)}"
  owner_tag = "owner: platform-team | env: ${var.environment}"
}

resource "snowflake_account_role" "access_roles" {
  for_each = var.roles

  name    = "${var.prefix}_${each.value.suffix}${local.suffix}"
  comment = "${each.value.comment} | ${local.owner_tag}"
}
```

> 🧠 **La ligne qui fait tout le travail :**
> ```hcl
> suffix = var.environment == "dev" ? "" : "_${upper(var.environment)}"
> ```
> En `dev`, le suffixe est **vide** — vos rôles gardent **exactement** leurs noms actuels. En `uat`, ils deviennent `GB_RAW_READER_UAT`. **C'est ce qui permet à l'étape 3 de ne rien détruire.**

**`modules/rbac/outputs.tf`**

```hcl
output "role_names" {
  value       = { for k, v in var.roles : k => snowflake_account_role.access_roles[k].name }
  description = "Noms réels des rôles créés"
}
```

<details>
<summary>🔵 <b>Sirine</b> — votre module <code>compute/</code></summary>

**`modules/compute/variables.tf`**

```hcl
variable "prefix" { type = string }
variable "environment" { type = string }

variable "warehouse_size" {
  type    = string
  default = "X-SMALL"

  validation {
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "Politique FinOps : seules les tailles X-SMALL et SMALL sont autorisées."
  }
}

variable "warehouses" {
  type = map(object({
    suffix       = string
    comment      = string
    auto_suspend = number
  }))
}
```

**`modules/compute/main.tf`**

```hcl
locals {
  suffix    = var.environment == "dev" ? "" : "_${upper(var.environment)}"
  owner_tag = "owner: platform-team | env: ${var.environment}"
}

resource "snowflake_warehouse" "service" {
  for_each = var.warehouses

  name                = "${var.prefix}_${each.value.suffix}${local.suffix}"
  warehouse_size      = var.warehouse_size
  comment             = "${each.value.comment} | ${local.owner_tag}"
  auto_resume         = true
  auto_suspend        = each.value.auto_suspend
  initially_suspended = true
}
```

> 💰 **`initially_suspended = true` est non négociable en UAT.** Vous allez créer trois warehouses de plus cet après-midi : aucun ne doit démarrer.
</details>

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un module est un dossier** | Rien de plus. Pas d'installation, pas de registre obligatoire. |
| **`variables.tf` + `outputs.tf` = le contrat** | C'est tout ce qu'un utilisateur du module a besoin de lire. |
| **`main.tf` = l'implémentation** | Elle peut changer sans casser l'appelant, tant que le contrat tient. |
| 🔒 **Ni `provider` ni `backend` dans un module** | Ils appartiennent à la racine. |

---

## 📝 Étape 3 — J'appelle mon module sans rien détruire

### ① 🖱️ Ce que Snowflake doit voir

**Rien.** Aucun changement. C'est la seule preuve qui compte à cette étape.

### ④ ⌨️ Le bloc `module`

Dans votre `main.tf` **de racine**, **supprimez** le bloc `resource` que vous venez de déplacer, et mettez à la place :

```hcl
module "rbac" {
  source = "./modules/rbac"

  prefix      = var.platform_prefix
  environment = "dev"
  roles       = var.roles
}
```

**Ctrl+Shift+B → `2 · Initialiser`**

```text
Initializing modules...
- rbac in modules/rbac
```

> 🧠 **`init` est obligatoire après l'ajout d'un module.** Terraform doit d'abord aller le chercher — même quand il est dans le dossier d'à côté.

**4 · Prévisualiser** →

```text
  # snowflake_account_role.access_roles["core_reader"] will be destroyed
  # snowflake_account_role.access_roles["mart_reader"] will be destroyed
  # snowflake_account_role.access_roles["raw_reader"] will be destroyed
  # module.rbac.snowflake_account_role.access_roles["core_reader"] will be created
  # …

Plan: 3 to add, 0 to change, 3 to destroy.
```

> 🔴 **Encore l'adresse.** `snowflake_account_role.access_roles["raw_reader"]` est devenue `module.rbac.snowflake_account_role.access_roles["raw_reader"]`. **Le préfixe `module.rbac.` fait partie de l'adresse.**
>
> 🧠 **Vous savez déjà quoi faire.** Le Jour 3 vous a donné l'outil, et l'anti-sèche du Jour 3 le mentionnait déjà : *« Déplacer vers un module : `role.access` → `module.rbac.role.access` »*.

### Le bloc `moved`

Ajoutez **en haut** de votre `main.tf` de racine :

```hcl
moved {
  from = snowflake_account_role.access_roles
  to   = module.rbac.snowflake_account_role.access_roles
}
```

**4 · Prévisualiser** →

```text
  # snowflake_account_role.access_roles["raw_reader"] has moved to
  #   module.rbac.snowflake_account_role.access_roles["raw_reader"]
  # … (3 fois)

Plan: 0 to add, 0 to change, 0 to destroy.
```

> 🏆 **`0 to destroy`.** Vous venez de refactorer trois jours de travail en composant réutilisable **sans qu'un seul objet Snowflake ne bouge**.

**5 · Appliquer** → `3 resources have been moved.` → **supprimez le bloc `moved`** → **4 · Prévisualiser** → `No changes.`

**Preuve dans Snowsight :**

```sql
SHOW ROLES LIKE 'GB_%';
```

Mêmes rôles, mêmes noms, même date de création. **Snowflake n'a rien vu.**

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **L'adresse inclut le chemin du module** | `module.<nom>.<type>.<nom_local>` — le préfixe fait partie de l'identité. |
| **`moved` traverse les modules** | C'est le seul outil qui permet de moduler un projet vivant. |
| **Refactorer ≠ recréer** | Un refactoring réussi affiche `0 to add, 0 to change, 0 to destroy`. |
| **`init` après tout ajout de module** | Sinon : `Module not installed`. |

---

## 📝 Étape 4 — Le contrat typé du module

### Le problème

Votre module accepte `roles = var.roles`. **Que se passe-t-il si quelqu'un lui passe une liste au lieu d'une map ? Ou oublie `comment` ?**

### ④ ⌨️ Je durcis le contrat

**`modules/rbac/variables.tf`** — enrichissez :

```hcl
variable "environment" {
  type        = string
  description = "Environnement cible"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environnement invalide : dev, uat ou prod."
  }
}

variable "roles" {
  type = map(object({
    suffix  = string
    comment = string
  }))
  description = "Rôles gérés par ce module — la clé sert d'identité dans le state"

  validation {
    condition     = length(var.roles) > 0
    error_message = "Le module rbac doit recevoir au moins un rôle."
  }
}
```

### 🧪 Testez le contrat

Dans votre racine, passez `environment = "recette"` puis **4 · Prévisualiser** :

```text
Error: Invalid value for variable
  on main.tf line 4, in module "rbac":
   4:   environment = "recette"

Environnement invalide : dev, uat ou prod.
```

> 🛡️ **Le module s'est défendu tout seul.** L'appelant n'a pas eu besoin de lire l'implémentation pour savoir qu'il se trompait. **C'est cela, un contrat.**

Remettez `environment = "dev"`.

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un type est une documentation exécutable** | `map(object({…}))` dit plus qu'un paragraphe de README. |
| **`validation` dans un module protège tous ses appelants** | Écrite une fois, appliquée partout. |
| **Message d'erreur = message au collègue** | Il doit dire quoi faire, pas seulement ce qui ne va pas. |

---

## 📝 Étape 5 — Ma racine UAT

### Le principe

**Un environnement = une racine = un state.** Le même module, appelé deux fois, avec des valeurs différentes.

```
   mon-projet/
   ├── modules/
   │   └── rbac/            ← écrit UNE fois
   └── envs/
       ├── dev/             ← key = fares/dev.tfstate
       └── uat/             ← key = fares/uat.tfstate
```

### ④ ⌨️ Je réorganise, puis je crée UAT

**1. Déplacez** vos fichiers de racine (`backend.tf`, `providers.tf`, `main.tf`, `variables.tf`, `terraform.tfvars`, `outputs.tf`) dans `envs/dev/`.

> 🧠 **Vous pouvez déplacer le dossier sans crainte** — c'est le cadeau du backend distant de ce matin. Le state est sur Azure, il ne bouge pas.

**2. Corrigez le `source`** dans `envs/dev/main.tf` : le module est maintenant deux niveaux plus haut.

```hcl
module "rbac" {
  source = "../../modules/rbac"
  # … inchangé
}
```

**3. Copiez `envs/dev/` en `envs/uat/`**, puis modifiez **trois choses** :

**`envs/uat/backend.tf`**

```hcl
    key = "fares/uat.tfstate"
```

**`envs/uat/main.tf`**

```hcl
module "rbac" {
  source = "../../modules/rbac"

  prefix      = var.platform_prefix
  environment = "uat"          # ← la seule vraie différence
  roles       = var.roles
}
```

**`envs/uat/`** — supprimez le fichier `terraform.tfstate*` s'il a été copié.

**Ouvrez `envs/uat/` dans VS Code**, puis **2 · Initialiser** → **4 · Prévisualiser** :

```text
  # module.rbac.snowflake_account_role.access_roles["raw_reader"] will be created
  #   name = "GB_RAW_READER_UAT"
  # …

Plan: 3 to add, 0 to change, 0 to destroy.
```

**5 · Appliquer** → ✅ `3 added`

**Preuve :**

```sql
SHOW ROLES LIKE 'GB_%';
```

Six rôles maintenant : trois sans suffixe *(DEV)*, trois en `_UAT`.

### 🧪 La preuve d'isolation

Revenez dans `envs/dev/` → **4 · Prévisualiser** → `No changes.`

> 🏆 **Vous avez créé trois objets dans UAT sans que DEV ne s'en aperçoive.** Deux states, deux clés, zéro interférence. **C'est la réponse n°3 à l'Inspection.**

### ⑤ 🧠 Le fondement de l'étape

```
   envs/dev/main.tf  ──┐
                       ├──►  modules/rbac/   ← UN seul code
   envs/uat/main.tf  ──┘

   deux states                 une implémentation
   deux jeux d'objets          un contrat
```

| Fondement | En une phrase |
|---|---|
| **Une racine par environnement** | Chacune a **son backend, sa clé, son state**. |
| **Le module est partagé, jamais dupliqué** | Corriger un bug = le corriger une fois. |
| **Aucun nom d'environnement en dur** | Il arrive par **une variable**, jamais dans une ressource. |
| **Promotion = même code, autres valeurs** | DEV et UAT ne diffèrent que par `terraform.tfvars`. |

> 📅 **Lundi**, le pipeline appliquera `envs/dev/` automatiquement, et `envs/uat/` **après approbation humaine**. La structure d'aujourd'hui est exactement ce dont il a besoin.

</details>

---
---

<details>
<summary><b>🟢 TEAM 2 — DATA ENGINEERING · Amal · Lara</b></summary>

<br/>

---

## 📝 Étape 2 — J'extrais mon module

### Mon module

| Je m'appelle | Mon module | Ce qu'il crée |
|---|---|---|
| **Amal** | `modules/landing-zone/` | database + schema + tables d'atterrissage |
| **Lara** | `modules/landing-zone/` | database + schema + tables de dimension |

> 🟢 **Vous écrivez le même module, chacune de votre côté.** À 16 h, vous comparerez : ce sera la meilleure conversation de la journée.

### ① 🖱️ D'abord, le geste manuel équivalent

**Il n'y en a pas.** Un module n'existe pas dans Snowsight : c'est une notion **purement Terraform**. Il ne crée aucun objet nouveau — il réorganise le code. **Snowflake ne doit voir aucune différence**, et le plan de l'étape 3 devra le prouver.

### ② 🔍 L'anatomie d'un module

```
   modules/landing-zone/
   ├── versions.tf     ← de quel provider j'ai besoin
   ├── variables.tf    ← CE QUE J'ACCEPTE EN ENTRÉE   ⬅️ le contrat
   ├── main.tf         ← les ressources
   └── outputs.tf      ← CE QUE JE PUBLIE EN SORTIE   ⬅️ le contrat
```

> 🔒 **Un module ne contient JAMAIS de bloc `provider` ni de bloc `backend`.** Ils appartiennent à la racine qui l'appelle.

### ③ 🔁 La correspondance — de la racine vers le module

| Dans mon `main.tf` d'aujourd'hui | Dans le module |
|---|---|
| `var.platform_prefix` | variable du module |
| `var.tables`, `var.audit_column` | variables du module |
| `local.db_name`, `local.owner_tag` | `locals` **internes** au module |
| les 3 `resource` *(database, schema, tables)* | déplacés tels quels |
| `output "database_name"` | output du module |

### ④ ⌨️ Je crée le module

**`modules/landing-zone/versions.tf`**

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

**`modules/landing-zone/variables.tf`**

```hcl
variable "prefix" {
  type        = string
  description = "Préfixe de la plateforme"
}

variable "environment" {
  type        = string
  description = "Environnement cible — dev ou uat"
}

variable "zone" {
  type        = string
  description = "Nom de la zone — RAW ou CORE"
}

variable "schema_name" {
  type        = string
  description = "Schema de la zone — LANDING ou DIM"
}

variable "audit_column" {
  type    = string
  default = "LOAD_TS"

  validation {
    condition     = can(regex("_TS$", var.audit_column))
    error_message = "Politique de gouvernance : la colonne d'audit doit se terminer par _TS."
  }
}

variable "tables" {
  type = map(object({
    name    = string
    comment = string
  }))
  description = "Tables de la zone"
}
```

**`modules/landing-zone/main.tf`**

```hcl
locals {
  suffix    = var.environment == "dev" ? "" : "_${upper(var.environment)}"
  db_name   = "${var.prefix}_${var.zone}_DB${local.suffix}"
  owner_tag = "owner: data-engineering | env: ${var.environment}"
}

resource "snowflake_database" "this" {
  name    = local.db_name
  comment = "Zone ${var.zone} | ${local.owner_tag}"
}

resource "snowflake_schema" "this" {
  database = snowflake_database.this.name
  name     = var.schema_name
  comment  = "Schema ${var.schema_name} | ${local.owner_tag}"
}

resource "snowflake_table" "tables" {
  for_each = var.tables

  database = snowflake_database.this.name
  schema   = snowflake_schema.this.name
  name     = each.value.name
  comment  = "${each.value.comment} | ${local.owner_tag}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "PAYLOAD"
    type = "VARIANT"
  }
  column {
    name = var.audit_column
    type = "TIMESTAMP_NTZ(9)"
  }
}
```

> 🧠 **La ligne qui fait tout le travail :**
> ```hcl
> suffix = var.environment == "dev" ? "" : "_${upper(var.environment)}"
> ```
> En `dev`, le suffixe est **vide** — `GB_RAW_DB` garde **exactement** son nom actuel. En `uat`, il devient `GB_RAW_DB_UAT`. **C'est ce qui permet à l'étape 3 de ne rien détruire.**

**`modules/landing-zone/outputs.tf`**

```hcl
output "database_name" {
  value       = snowflake_database.this.name
  description = "Database créée — consommée par Business Data et par les grants"
}

output "schema_name" {
  value = snowflake_schema.this.name
}

output "table_names" {
  value = { for k, v in var.tables : k => snowflake_table.tables[k].name }
}
```

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un module est un dossier** | Rien de plus. Pas d'installation, pas de registre obligatoire. |
| **`variables.tf` + `outputs.tf` = le contrat** | C'est tout ce qu'un utilisateur du module a besoin de lire. |
| **`main.tf` = l'implémentation** | Elle peut changer sans casser l'appelant. |
| **`this` comme nom local** | Convention : quand un module ne crée **qu'une** database, on l'appelle `this`. |
| 🔒 **Ni `provider` ni `backend` dans un module** | Ils appartiennent à la racine. |

---

## 📝 Étape 3 — J'appelle mon module sans rien détruire

### ① 🖱️ Ce que Snowflake doit voir

**Rien.** Aucun changement. C'est la seule preuve qui compte.

### ④ ⌨️ Le bloc `module`

Dans votre `main.tf` **de racine**, **supprimez** les trois blocs `resource` déplacés, et mettez à la place :

```hcl
module "landing_zone" {
  source = "./modules/landing-zone"

  prefix       = var.platform_prefix
  environment  = "dev"
  zone         = "RAW"
  schema_name  = "LANDING"
  audit_column = var.audit_column
  tables       = var.tables
}
```

<details>
<summary>🟢 <b>Lara</b> — votre appel</summary>

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  prefix       = var.platform_prefix
  environment  = "dev"
  zone         = "CORE"
  schema_name  = "DIM"
  audit_column = var.audit_column
  tables       = var.tables
}
```

> 🧠 **Le même module, deux zones.** C'est précisément la démonstration : `RAW` et `CORE` ne sont plus deux codes, mais **deux jeux de valeurs**.
</details>

**Ctrl+Shift+B → `2 · Initialiser`** → `Initializing modules...`

> 🧠 **`init` est obligatoire après l'ajout d'un module**, même quand il est dans le dossier d'à côté.

**4 · Prévisualiser** →

```text
  # snowflake_database.raw will be destroyed
  # snowflake_schema.landing will be destroyed
  # snowflake_table.raw_tables["accounts"] will be destroyed
  # …
  # module.landing_zone.snowflake_database.this will be created
  # …

Plan: 5 to add, 0 to change, 5 to destroy.
```

> 🔴 **5 destructions — dont vos trois tables.** Le préfixe `module.landing_zone.` fait partie de l'adresse. **N'appliquez surtout pas.**
>
> 🧠 **Vous savez déjà quoi faire.** L'anti-sèche du Jour 3 le mentionnait : *« Déplacer vers un module »*.

### Les blocs `moved`

Ajoutez **en haut** de votre `main.tf` de racine — **un par ressource déplacée** :

```hcl
moved {
  from = snowflake_database.raw
  to   = module.landing_zone.snowflake_database.this
}

moved {
  from = snowflake_schema.landing
  to   = module.landing_zone.snowflake_schema.this
}

moved {
  from = snowflake_table.raw_tables
  to   = module.landing_zone.snowflake_table.tables
}
```

> 🧠 **Le troisième bloc déplace les trois tables d'un coup.** `moved` accepte une ressource `for_each` entière : les clés (`accounts`, `cards`, `transactions`) sont conservées.

**4 · Prévisualiser** →

```text
Plan: 0 to add, 0 to change, 0 to destroy.
```

> 🏆 **`0 to destroy`.** Trois jours de travail refactorés en composant réutilisable, **sans qu'une seule ligne de donnée ne bouge**.

**5 · Appliquer** → `5 resources have been moved.` → **supprimez les blocs `moved`** → **4 · Prévisualiser** → `No changes.`

**Preuve dans Snowsight :**

```sql
SHOW TABLES IN SCHEMA GB_RAW_DB.LANDING;
```

Mêmes tables, mêmes dates de création. **Snowflake n'a rien vu.**

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **L'adresse inclut le chemin du module** | `module.<nom>.<type>.<nom_local>`. |
| **`moved` traverse les modules** | Le seul outil qui permet de moduler un projet **vivant**. |
| **`moved` sur une ressource `for_each`** | Un seul bloc suffit — les clés sont conservées. |
| **Refactorer ≠ recréer** | Un refactoring réussi affiche `0 to add, 0 to change, 0 to destroy`. |

---

## 📝 Étape 4 — Le contrat typé du module

### ④ ⌨️ Je durcis le contrat

**`modules/landing-zone/variables.tf`** — enrichissez :

```hcl
variable "environment" {
  type        = string
  description = "Environnement cible"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environnement invalide : dev, uat ou prod."
  }
}

variable "zone" {
  type        = string
  description = "Nom de la zone — RAW, CORE ou STAGING"

  validation {
    condition     = can(regex("^[A-Z]+$", var.zone))
    error_message = "Le nom de zone doit être en MAJUSCULES, sans séparateur."
  }
}
```

### 🧪 Testez le contrat

Dans votre racine, passez `zone = "raw"` *(minuscules)* puis **4 · Prévisualiser** :

```text
Error: Invalid value for variable
  on main.tf line 5, in module "landing_zone":
   5:   zone = "raw"

Le nom de zone doit être en MAJUSCULES, sans séparateur.
```

> 🛡️ **Le module s'est défendu tout seul.** L'appelant n'a pas eu à lire l'implémentation pour savoir qu'il se trompait. **C'est cela, un contrat.**

Remettez `RAW` *(ou `CORE` pour Lara)*.

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un type est une documentation exécutable** | `map(object({…}))` dit plus qu'un paragraphe de README. |
| **`validation` dans un module protège tous ses appelants** | Écrite une fois, appliquée partout. |
| **Message d'erreur = message au collègue** | Il doit dire quoi faire. |

---

## 📝 Étape 5 — Ma racine UAT

### Le principe

**Un environnement = une racine = un state.** Le même module, appelé deux fois, avec des valeurs différentes.

```
   mon-projet/
   ├── modules/
   │   └── landing-zone/    ← écrit UNE fois
   └── envs/
       ├── dev/             ← key = amal/dev.tfstate
       └── uat/             ← key = amal/uat.tfstate
```

### ④ ⌨️ Je réorganise, puis je crée UAT

**1. Déplacez** vos fichiers de racine dans `envs/dev/`.

> 🧠 **Vous pouvez déplacer le dossier sans crainte** — c'est le cadeau du backend distant de ce matin. Le state est sur Azure, il ne bouge pas.

**2. Corrigez le `source`** : `source = "../../modules/landing-zone"`.

**3. Copiez `envs/dev/` en `envs/uat/`**, puis modifiez **deux choses** :

**`envs/uat/backend.tf`**

```hcl
    key = "amal/uat.tfstate"
```

**`envs/uat/main.tf`**

```hcl
module "landing_zone" {
  source = "../../modules/landing-zone"

  prefix       = var.platform_prefix
  environment  = "uat"          # ← la seule vraie différence
  zone         = "RAW"
  schema_name  = "LANDING"
  audit_column = var.audit_column
  tables       = var.tables
}
```

**Ouvrez `envs/uat/` dans VS Code**, puis **2 · Initialiser** → **4 · Prévisualiser** :

```text
  # module.landing_zone.snowflake_database.this will be created
  #   name = "GB_RAW_DB_UAT"
  # …

Plan: 5 to add, 0 to change, 0 to destroy.
```

**5 · Appliquer** → ✅ `5 added`

**Preuve :**

```sql
SHOW DATABASES LIKE 'GB_%';
SHOW TABLES IN SCHEMA GB_RAW_DB_UAT.LANDING;
```

> 💰 **Une database et des tables vides ne coûtent rien** — le stockage se facture aux octets réellement écrits. **Aucun warehouse n'a été créé en UAT.**

### 🧪 La preuve d'isolation

Revenez dans `envs/dev/` → **4 · Prévisualiser** → `No changes.`

> 🏆 **Vous avez créé cinq objets dans UAT sans que DEV ne s'en aperçoive.** Deux states, deux clés, zéro interférence. **C'est la réponse n°3 à l'Inspection.**

### ⑤ 🧠 Le fondement de l'étape

```
   envs/dev/main.tf  ──┐
                       ├──►  modules/landing-zone/   ← UN seul code
   envs/uat/main.tf  ──┘

   deux states                 une implémentation
   deux jeux d'objets          un contrat
```

| Fondement | En une phrase |
|---|---|
| **Une racine par environnement** | Chacune a **son backend, sa clé, son state**. |
| **Le module est partagé, jamais dupliqué** | Corriger un bug = le corriger une fois. |
| **Aucun nom d'environnement en dur** | Il arrive par **une variable**. |
| **Promotion = même code, autres valeurs** | DEV et UAT ne diffèrent que par `terraform.tfvars`. |

> 📅 **Lundi**, le pipeline appliquera `envs/dev/` automatiquement et `envs/uat/` **après approbation humaine**.

</details>
---
---

<details>
<summary><b>🟠 TEAM 3 — BUSINESS DATA · Manel · Leila · Olfa</b></summary>

<br/>

---

## 📝 Étape 2 — J'extrais mon module

### Mon module

| Je m'appelle | Mon module | Mon domaine |
|---|---|---|
| **Manel** | `modules/data-domain/` | `CUSTOMER` |
| **Leila** | `modules/data-domain/` | `PRODUCT` |
| **Olfa** | `modules/data-domain/` | `CAMPAIGN` |

> 🟠 **Vous écrivez trois fois le même module.** C'est voulu : à 16 h, vous comparerez vos trois versions et vous n'en garderez qu'une. **C'est exactement ce qui se passe dans une vraie équipe plateforme.**

### ① 🖱️ D'abord, le geste manuel équivalent

**Il n'y en a pas.** Un module n'existe pas dans Snowsight : c'est une notion **purement Terraform**. Il ne crée aucun objet nouveau — il réorganise le code. **Snowflake ne doit voir aucune différence.**

### ② 🔍 L'anatomie d'un module

```
   modules/data-domain/
   ├── versions.tf     ← de quel provider j'ai besoin
   ├── variables.tf    ← CE QUE J'ACCEPTE EN ENTRÉE   ⬅️ le contrat
   ├── main.tf         ← les ressources
   └── outputs.tf      ← CE QUE JE PUBLIE EN SORTIE   ⬅️ le contrat
```

> 🔒 **Un module ne contient JAMAIS de bloc `provider` ni de bloc `backend`.**

### ③ 🔁 La correspondance — de la racine vers le module

| Dans mon `main.tf` d'aujourd'hui | Dans le module |
|---|---|
| `var.platform_prefix`, `var.classification` | variables du module |
| `local.domain`, `local.owner_tag` | `locals` **internes** au module |
| database + schema + tables + vue | déplacés tels quels |
| `output "domain_contract"` | output du module |

### ④ ⌨️ Je crée le module

**`modules/data-domain/versions.tf`**

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

**`modules/data-domain/variables.tf`**

```hcl
variable "prefix" {
  type        = string
  description = "Préfixe de la plateforme"
}

variable "environment" {
  type        = string
  description = "Environnement cible — dev ou uat"
}

variable "domain" {
  type        = string
  description = "Nom du domaine métier — CUSTOMER, PRODUCT ou CAMPAIGN"
}

variable "classification" {
  type    = string
  default = "INTERNE"

  validation {
    condition     = contains(["PUBLIC", "INTERNE", "CONFIDENTIEL", "SECRET"], var.classification)
    error_message = "Classification invalide : PUBLIC, INTERNE, CONFIDENTIEL ou SECRET."
  }
}

variable "tables" {
  type = map(object({
    name    = string
    comment = string
  }))
  description = "Tables métier du domaine"
}
```

**`modules/data-domain/main.tf`**

```hcl
locals {
  suffix    = var.environment == "dev" ? "" : "_${upper(var.environment)}"
  db_name   = "${var.prefix}_${var.domain}_DB${local.suffix}"
  owner_tag = "owner: business-data | domain: ${lower(var.domain)} | classification: ${var.classification}"
}

resource "snowflake_database" "this" {
  name    = local.db_name
  comment = "Domaine ${var.domain} | ${local.owner_tag}"
}

resource "snowflake_schema" "this" {
  database = snowflake_database.this.name
  name     = "BUSINESS"
  comment  = "Schema métier | ${local.owner_tag}"
}

resource "snowflake_table" "tables" {
  for_each = var.tables

  database = snowflake_database.this.name
  schema   = snowflake_schema.this.name
  name     = each.value.name
  comment  = "${each.value.comment} | ${local.owner_tag}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "LABEL"
    type = "VARCHAR(255)"
  }
  column {
    name = "UPDATED_TS"
    type = "TIMESTAMP_NTZ(9)"
  }
}
```

> 🧠 **La ligne qui fait tout le travail :**
> ```hcl
> suffix = var.environment == "dev" ? "" : "_${upper(var.environment)}"
> ```
> En `dev`, le suffixe est **vide** — `GB_CUSTOMER_DB` garde **exactement** son nom actuel. En `uat`, il devient `GB_CUSTOMER_DB_UAT`. **C'est ce qui permet à l'étape 3 de ne rien détruire.**

**`modules/data-domain/outputs.tf`**

```hcl
output "database_name" {
  value       = snowflake_database.this.name
  description = "Database du domaine — consommée par BI"
}

output "domain_contract" {
  value = {
    database       = snowflake_database.this.name
    schema         = snowflake_schema.this.name
    domain         = lower(var.domain)
    classification = var.classification
    environment    = var.environment
  }
  description = "Contrat du data product"
}
```

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un module est un dossier** | Rien de plus. |
| **`variables.tf` + `outputs.tf` = le contrat** | Tout ce qu'un utilisateur du module doit lire. |
| **`main.tf` = l'implémentation** | Elle peut changer sans casser l'appelant. |
| **`this` comme nom local** | Convention pour l'objet principal d'un module. |
| 🔒 **Ni `provider` ni `backend` dans un module** | Ils appartiennent à la racine. |

---

## 📝 Étape 3 — J'appelle mon module sans rien détruire

### ① 🖱️ Ce que Snowflake doit voir

**Rien.** C'est la seule preuve qui compte.

### ④ ⌨️ Le bloc `module`

Dans votre `main.tf` **de racine**, **supprimez** les blocs `resource` déplacés :

```hcl
module "domain" {
  source = "./modules/data-domain"

  prefix         = var.platform_prefix
  environment    = "dev"
  domain         = "CUSTOMER"
  classification = var.classification
  tables         = var.tables
}
```

> 🟠 **Leila :** `domain = "PRODUCT"` · **Olfa :** `domain = "CAMPAIGN"`.

**Ctrl+Shift+B → `2 · Initialiser`** → `Initializing modules...`

> 🧠 **`init` est obligatoire après l'ajout d'un module.**

**4 · Prévisualiser** →

```text
  # snowflake_database.customer will be destroyed
  # snowflake_schema.business will be destroyed
  # snowflake_table.customer_tables["customer"] will be destroyed
  # …
  # module.domain.snowflake_database.this will be created
  # …

Plan: 5 to add, 0 to change, 5 to destroy.
```

> 🔴 **N'appliquez pas.** Le préfixe `module.domain.` fait partie de l'adresse.

### Les blocs `moved`

```hcl
moved {
  from = snowflake_database.customer
  to   = module.domain.snowflake_database.this
}

moved {
  from = snowflake_schema.business
  to   = module.domain.snowflake_schema.this
}

moved {
  from = snowflake_table.customer_tables
  to   = module.domain.snowflake_table.tables
}
```

> 🧠 **Le troisième bloc déplace les trois tables d'un coup.** `moved` accepte une ressource `for_each` entière : les clés sont conservées.

**4 · Prévisualiser** → `Plan: 0 to add, 0 to change, 0 to destroy.`

> 🏆 **`0 to destroy`.** Vos trois data products sont devenus un composant réutilisable **sans qu'une ligne de donnée ne bouge**.

**5 · Appliquer** → **supprimez les blocs `moved`** → **4 · Prévisualiser** → `No changes.`

**Preuve :** `SHOW TABLES IN SCHEMA GB_CUSTOMER_DB.BUSINESS;` — mêmes tables, mêmes dates.

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **L'adresse inclut le chemin du module** | `module.<nom>.<type>.<nom_local>`. |
| **`moved` traverse les modules** | Le seul outil qui permet de moduler un projet **vivant**. |
| **`moved` sur une ressource `for_each`** | Un seul bloc, les clés conservées. |
| **Refactorer ≠ recréer** | `0 to add, 0 to change, 0 to destroy`. |

---

## 📝 Étape 4 — Le contrat typé du module

### ④ ⌨️ Je durcis le contrat

```hcl
variable "environment" {
  type        = string
  description = "Environnement cible"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environnement invalide : dev, uat ou prod."
  }
}

variable "domain" {
  type        = string
  description = "Nom du domaine métier"

  validation {
    condition     = can(regex("^[A-Z]+$", var.domain))
    error_message = "Le nom de domaine doit être en MAJUSCULES, sans séparateur."
  }
}
```

### 🧪 Testez le contrat

Passez `classification = "PRIVE"` dans votre racine, puis **4 · Prévisualiser** :

```text
Error: Invalid value for variable
Classification invalide : PUBLIC, INTERNE, CONFIDENTIEL ou SECRET.
```

> 🛡️ **La politique de classification est maintenant DANS le module.** Tous ses appelants — présents et futurs — en héritent. **Écrite une fois, appliquée partout.**

Remettez `INTERNE`.

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un type est une documentation exécutable** | `map(object({…}))` dit plus qu'un README. |
| **`validation` dans un module protège tous ses appelants** | La gouvernance devient héritable. |
| **Message d'erreur = message au collègue** | Il doit dire quoi faire. |

---

## 📝 Étape 5 — Ma racine UAT

### Le principe

**Un environnement = une racine = un state.**

```
   mon-projet/
   ├── modules/
   │   └── data-domain/     ← écrit UNE fois
   └── envs/
       ├── dev/             ← key = manel/dev.tfstate
       └── uat/             ← key = manel/uat.tfstate
```

### ④ ⌨️ Je réorganise, puis je crée UAT

**1. Déplacez** vos fichiers de racine dans `envs/dev/`.

> 🧠 **Vous pouvez déplacer le dossier sans crainte** — le state est sur Azure depuis ce matin, il ne bouge pas.

**2. Corrigez le `source`** : `source = "../../modules/data-domain"`.

**3. Copiez `envs/dev/` en `envs/uat/`**, puis modifiez **deux choses** :

**`envs/uat/backend.tf`**

```hcl
    key = "manel/uat.tfstate"
```

**`envs/uat/main.tf`**

```hcl
module "domain" {
  source = "../../modules/data-domain"

  prefix         = var.platform_prefix
  environment    = "uat"          # ← la seule vraie différence
  domain         = "CUSTOMER"
  classification = var.classification
  tables         = var.tables
}
```

**Ouvrez `envs/uat/`**, puis **2 · Initialiser** → **4 · Prévisualiser** :

```text
  # module.domain.snowflake_database.this will be created
  #   name = "GB_CUSTOMER_DB_UAT"

Plan: 5 to add, 0 to change, 0 to destroy.
```

**5 · Appliquer** → ✅ `5 added`

**Preuve :** `SHOW DATABASES LIKE 'GB_%';` — votre domaine apparaît deux fois, une fois par environnement.

### 🧪 La preuve d'isolation

Revenez dans `envs/dev/` → **4 · Prévisualiser** → `No changes.`

> 🏆 **Vous avez créé cinq objets dans UAT sans que DEV ne s'en aperçoive.** **C'est la réponse n°3 à l'Inspection.**

### ⑤ 🧠 Le fondement de l'étape

```
   envs/dev/main.tf  ──┐
                       ├──►  modules/data-domain/   ← UN seul code
   envs/uat/main.tf  ──┘
```

| Fondement | En une phrase |
|---|---|
| **Une racine par environnement** | Chacune a **son backend, sa clé, son state**. |
| **Le module est partagé, jamais dupliqué** | Corriger un bug = le corriger une fois. |
| **Aucun nom d'environnement en dur** | Il arrive par **une variable**. |
| **Promotion = même code, autres valeurs** | DEV et UAT ne diffèrent que par `terraform.tfvars`. |

> 🎯 **Et le douzième domaine de novembre ?** Trois lignes dans un `envs/dev/main.tf`. **C'est la réponse n°2 à l'Inspection.**

</details>

---
---

<details>
<summary><b>🟣 TEAM 4 — BI / ANALYTICS · Ghassen · Adem · Hadhemi</b></summary>

<br/>

---

## 📝 Étape 2 — J'extrais mon module

### Mon module

| Je m'appelle | Mon module | Mon mart |
|---|---|---|
| **Ghassen** | `modules/data-mart/` | `CUSTOMER` |
| **Adem** | `modules/data-mart/` | `FINANCE` |
| **Hadhemi** | `modules/data-mart/` | `TRANSACTION` |

> 🟣 **Trois marts, un seul module.** À 16 h, vous comparerez vos trois versions — et vous verrez que la vôtre gère un cas que celle du voisin a oublié.

### ① 🖱️ D'abord, le geste manuel équivalent

**Il n'y en a pas.** Un module n'existe pas dans Snowsight : c'est une notion **purement Terraform**. Il réorganise le code, pas les objets. **Snowflake ne doit voir aucune différence.**

### ② 🔍 L'anatomie d'un module

```
   modules/data-mart/
   ├── versions.tf     ← de quel provider j'ai besoin
   ├── variables.tf    ← CE QUE J'ACCEPTE EN ENTRÉE   ⬅️ le contrat
   ├── main.tf         ← les ressources
   └── outputs.tf      ← CE QUE JE PUBLIE EN SORTIE   ⬅️ le contrat
```

> 🔒 **Un module ne contient JAMAIS de bloc `provider` ni de bloc `backend`.**

### ③ 🔁 La correspondance — de la racine vers le module

| Dans mon `main.tf` d'aujourd'hui | Dans le module |
|---|---|
| `var.platform_prefix`, `var.audience` | variables du module |
| `local.mart_name`, `local.owner_tag` | `locals` **internes** au module |
| mart + schema + tables + vues | déplacés tels quels |
| `output "mart_contract"` | output du module |

### ④ ⌨️ Je crée le module

**`modules/data-mart/versions.tf`**

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

**`modules/data-mart/variables.tf`**

```hcl
variable "prefix" {
  type        = string
  description = "Préfixe de la plateforme"
}

variable "environment" {
  type        = string
  description = "Environnement cible — dev ou uat"
}

variable "mart" {
  type        = string
  description = "Nom du mart — CUSTOMER, FINANCE ou TRANSACTION"
}

variable "audience" {
  type    = string
  default = "RESEAU"

  validation {
    condition     = contains(["RESEAU", "FINANCE", "RISK", "DIRECTION"], var.audience)
    error_message = "Audience invalide : RESEAU, FINANCE, RISK ou DIRECTION."
  }
}

variable "mart_tables" {
  type = map(object({
    name    = string
    comment = string
  }))
  description = "Tables du data mart"
}
```

**`modules/data-mart/main.tf`**

```hcl
locals {
  suffix    = var.environment == "dev" ? "" : "_${upper(var.environment)}"
  db_name   = "${var.prefix}_${var.mart}_MART${local.suffix}"
  owner_tag = "owner: bi-analytics | mart: ${lower(var.mart)} | audience: ${var.audience}"
}

resource "snowflake_database" "this" {
  name    = local.db_name
  comment = "Data mart ${var.mart} | ${local.owner_tag}"
}

resource "snowflake_schema" "this" {
  database = snowflake_database.this.name
  name     = "MART"
  comment  = "Schema de restitution | ${local.owner_tag}"
}

resource "snowflake_table" "tables" {
  for_each = var.mart_tables

  database = snowflake_database.this.name
  schema   = snowflake_schema.this.name
  name     = each.value.name
  comment  = "${each.value.comment} | ${local.owner_tag}"

  column {
    name = "ID"
    type = "NUMBER(38,0)"
  }
  column {
    name = "METRIC"
    type = "VARCHAR(255)"
  }
  column {
    name = "VALUE"
    type = "NUMBER(38,4)"
  }
  column {
    name = "AS_OF_DATE"
    type = "DATE"
  }
}
```

> 🧠 **La ligne qui fait tout le travail :**
> ```hcl
> suffix = var.environment == "dev" ? "" : "_${upper(var.environment)}"
> ```
> En `dev`, le suffixe est **vide** — `GB_CUSTOMER_MART` garde **exactement** son nom actuel. **C'est ce qui permet à l'étape 3 de ne rien détruire.**

**`modules/data-mart/outputs.tf`**

```hcl
output "database_name" {
  value       = snowflake_database.this.name
  description = "Data mart — consommé par Power BI"
}

output "mart_contract" {
  value = {
    database    = snowflake_database.this.name
    schema      = snowflake_schema.this.name
    mart        = lower(var.mart)
    audience    = var.audience
    environment = var.environment
  }
  description = "Contrat du data mart — pilote les grants"
}
```

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un module est un dossier** | Rien de plus. |
| **`variables.tf` + `outputs.tf` = le contrat** | Tout ce qu'un utilisateur doit lire. |
| **`main.tf` = l'implémentation** | Elle peut changer sans casser l'appelant. |
| **`this` comme nom local** | Convention pour l'objet principal. |
| 🔒 **Ni `provider` ni `backend` dans un module** | Ils appartiennent à la racine. |

---

## 📝 Étape 3 — J'appelle mon module sans rien détruire

### ① 🖱️ Ce que Snowflake doit voir

**Rien.**

### ④ ⌨️ Le bloc `module`

```hcl
module "mart" {
  source = "./modules/data-mart"

  prefix      = var.platform_prefix
  environment = "dev"
  mart        = "CUSTOMER"
  audience    = var.audience
  mart_tables = var.mart_tables
}
```

> 🟣 **Adem :** `mart = "FINANCE"` · **Hadhemi :** `mart = "TRANSACTION"`.

**Ctrl+Shift+B → `2 · Initialiser`** → `Initializing modules...`

**4 · Prévisualiser** → `Plan: 5 to add, 0 to change, 5 to destroy.`

> 🔴 **N'appliquez pas.** Sur un mart branché à un rapport Power BI, ces cinq destructions font tomber le dashboard.

### Les blocs `moved`

```hcl
moved {
  from = snowflake_database.customer_mart
  to   = module.mart.snowflake_database.this
}

moved {
  from = snowflake_schema.mart
  to   = module.mart.snowflake_schema.this
}

moved {
  from = snowflake_table.customer_mart_tables
  to   = module.mart.snowflake_table.tables
}
```

**4 · Prévisualiser** → `Plan: 0 to add, 0 to change, 0 to destroy.`

> 🏆 **`0 to destroy`.** Le rapport Power BI n'a pas cligné des yeux.

**5 · Appliquer** → **supprimez les blocs `moved`** → **4 · Prévisualiser** → `No changes.`

**Preuve :** `SHOW TABLES IN SCHEMA GB_CUSTOMER_MART.MART;`

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **L'adresse inclut le chemin du module** | `module.<nom>.<type>.<nom_local>`. |
| **`moved` traverse les modules** | Le seul outil qui permet de moduler un projet **vivant**. |
| **`moved` sur une ressource `for_each`** | Un seul bloc, les clés conservées. |
| **Refactorer ≠ recréer** | `0 to add, 0 to change, 0 to destroy`. |

---

## 📝 Étape 4 — Le contrat typé du module

### ④ ⌨️ Je durcis le contrat

```hcl
variable "environment" {
  type        = string
  description = "Environnement cible"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environnement invalide : dev, uat ou prod."
  }
}

variable "mart" {
  type        = string
  description = "Nom du data mart"

  validation {
    condition     = can(regex("^[A-Z]+$", var.mart))
    error_message = "Le nom du mart doit être en MAJUSCULES, sans séparateur."
  }
}
```

### 🧪 Testez le contrat

Passez `audience = "TOUS"` dans votre racine, puis **4 · Prévisualiser** :

```text
Error: Invalid value for variable
Audience invalide : RESEAU, FINANCE, RISK ou DIRECTION.
```

> 🛡️ **La règle d'audience vit maintenant DANS le module.** Le douzième mart en héritera sans que personne n'ait à y penser.

Remettez votre audience : `RESEAU` *(Ghassen)*, `FINANCE` *(Adem)*, `RISK` *(Hadhemi)*.

### ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Un type est une documentation exécutable** | `map(object({…}))` dit plus qu'un README. |
| **`validation` dans un module protège tous ses appelants** | La gouvernance devient héritable. |
| **Message d'erreur = message au collègue** | Il doit dire quoi faire. |

---

## 📝 Étape 5 — Ma racine UAT

### Le principe

**Un environnement = une racine = un state.**

```
   mon-projet/
   ├── modules/
   │   └── data-mart/       ← écrit UNE fois
   └── envs/
       ├── dev/             ← key = ghassen/dev.tfstate
       └── uat/             ← key = ghassen/uat.tfstate
```

### ④ ⌨️ Je réorganise, puis je crée UAT

**1. Déplacez** vos fichiers de racine dans `envs/dev/`.

> 🧠 **Le state est sur Azure depuis ce matin** — déplacer le dossier ne lui fait rien.

**2. Corrigez le `source`** : `source = "../../modules/data-mart"`.

**3. Copiez `envs/dev/` en `envs/uat/`**, puis modifiez **deux choses** :

**`envs/uat/backend.tf`**

```hcl
    key = "ghassen/uat.tfstate"
```

**`envs/uat/main.tf`**

```hcl
module "mart" {
  source = "../../modules/data-mart"

  prefix      = var.platform_prefix
  environment = "uat"          # ← la seule vraie différence
  mart        = "CUSTOMER"
  audience    = var.audience
  mart_tables = var.mart_tables
}
```

**Ouvrez `envs/uat/`**, puis **2 · Initialiser** → **4 · Prévisualiser** :

```text
  # module.mart.snowflake_database.this will be created
  #   name = "GB_CUSTOMER_MART_UAT"

Plan: 5 to add, 0 to change, 0 to destroy.
```

**5 · Appliquer** → ✅ `5 added`

**Preuve :** `SHOW DATABASES LIKE 'GB_%MART%';`

### 🧪 La preuve d'isolation

Revenez dans `envs/dev/` → **4 · Prévisualiser** → `No changes.`

> 🏆 **Un mart de recette, un mart de production, un seul code.** Vous pouvez enfin tester une nouvelle métrique **sans toucher au rapport que la Direction consulte le lundi matin.**

### ⑤ 🧠 Le fondement de l'étape

```
   envs/dev/main.tf  ──┐
                       ├──►  modules/data-mart/   ← UN seul code
   envs/uat/main.tf  ──┘
```

| Fondement | En une phrase |
|---|---|
| **Une racine par environnement** | Chacune a **son backend, sa clé, son state**. |
| **Le module est partagé, jamais dupliqué** | Corriger un bug = le corriger une fois. |
| **Aucun nom d'environnement en dur** | Il arrive par **une variable**. |
| **Promotion = même code, autres valeurs** | DEV et UAT ne diffèrent que par `terraform.tfvars`. |

</details>

---
---

# 🐛 Le Chaos Lab — le verrou de state

> **15 h 15 – 15 h 30 · par binômes.** Constituez cinq binômes ; le onzième rejoint le formateur.

## Le scénario

Deux ingénieurs appliquent **au même moment** sur le **même** environnement. Sans verrou, les deux states s'écrasent et la plateforme devient impossible à réconcilier.

## ① Provoquez la collision

**Le binôme B** modifie temporairement son `envs/uat/backend.tf` pour pointer sur la clé du **binôme A** :

```hcl
    key = "<prénom du binôme A>/uat.tfstate"   # ← TEMPORAIRE
```

**2 · Initialiser** *(répondez `no` à la copie du state)*.

**Puis, simultanément :** A lance **5 · Appliquer**, et B lance **4 · Prévisualiser** dans la seconde qui suit.

```text
Error: Error acquiring the state lock

Error message: state blob is already locked
Lock Info:
  ID:        f4a1c9d2-8b3e-4c71-9a05-6d2e3f8b1c40
  Path:      tfstate/fares/uat.tfstate
  Operation: OperationTypeApply
  Who:       fares@oddo-bhf.com
  Created:   2026-09-11 15:32:07 UTC

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time.
```

> 🏆 **Terraform vient de vous protéger.** Sans backend distant, ces deux opérations se seraient déroulées en parallèle et **le dernier à écrire aurait effacé le travail de l'autre, sans le moindre message.**

## ② Lisez le message — il dit tout

| Champ | Ce qu'il vous apprend |
|---|---|
| `Who` | **Qui** détient le verrou — allez lui parler, c'est la vraie solution |
| `Operation` | Ce qu'il fait — un `apply` en cours ne s'interrompt pas |
| `Created` | Depuis quand — un verrou de 3 secondes n'est pas un verrou de 3 heures |
| `ID` | L'identifiant, **seulement** utile pour `force-unlock` |

## ③ `force-unlock` — et pourquoi on ne l'utilise presque jamais

```
terraform force-unlock f4a1c9d2-8b3e-4c71-9a05-6d2e3f8b1c40
```

> 🔴 **Ne le lancez pas maintenant.** Cette commande retire le verrou **sans savoir** si l'opération protégée est terminée. Si l'`apply` du collègue tourne encore, vous ouvrez la porte à l'écrasement que le verrou empêchait.
>
> **La bonne séquence, dans cet ordre :**
>
> | # | Question | Action |
> |:---:|---|---|
> | 1 | Le `Who` est-il joignable ? | **Lui demander.** 90 % des cas s'arrêtent ici. |
> | 2 | Son opération est-elle terminée ? | Attendre — un `apply` finit toujours. |
> | 3 | Le processus est-il mort *(machine éteinte, CI tuée)* ? | **Alors seulement** `force-unlock`. |

## ④ Remettez tout en ordre

**Le binôme B remet sa vraie clé** dans `envs/uat/backend.tf`, puis **2 · Initialiser** → **4 · Prévisualiser** → `No changes.`

## 🧠 Ce que le Chaos Lab a prouvé

| Constat | Conséquence |
|---|---|
| Le verrou est **automatique** | Aucune configuration à activer — le backend `azurerm` le fait nativement |
| Deux clés identiques = **un seul state** | La `key` est l'identité du state, pas le nom du dossier |
| Le message d'erreur nomme le coupable | La résolution est **humaine** avant d'être technique |
| `force-unlock` est un dernier recours | Il retire une protection, il ne répare rien |

---
---

# ⚖️ La convergence des modules — 15 h 30

> **Le moment le plus important de la journée.** Rassemblez-vous par équipe, un seul écran par équipe.

## Le constat

**Vous êtes trois à avoir écrit `data-domain`. Deux à avoir écrit `landing-zone`. Trois à avoir écrit `data-mart`.**

```
   CE MATIN                              MAINTENANT
   11 projets qui se ressemblent   →     11 modules qui se ressemblent
   ────────────────────────────          ─────────────────────────────
   la duplication est dans          la duplication a juste
   les racines                      changé d'étage
```

> 🛑 **Onze modules n'est pas un découpage métier — c'est de la duplication déguisée.** Le vrai découpage, vous l'avez déjà : c'est votre **matrice de propriété par type de ressource**. Elle donne **cinq** modules, pas onze.

## Le catalogue cible

| Module | Mainteneur *(l'auteur retenu)* | Consommateurs |
|---|---|---|
| `rbac/` | 🔵 **Fares** et **Mohamed** | toute la salle |
| `compute/` | 🔵 **Sirine** | toute la salle |
| `landing-zone/` | 🟢 **Amal** et **Lara** | 2 racines |
| `data-domain/` | 🟠 **Manel**, **Leila**, **Olfa** | 3 racines |
| `data-mart/` | 🟣 **Ghassen**, **Adem**, **Hadhemi** | 3 racines |

> 🧠 **11 personnes · 5 composants · 14 racines** *(11 en DEV, 3 en UAT)*. **Le rapport entre le code écrit et les objets créés vient de s'inverser.** C'est la démonstration de la journée.

## ⚖️ L'arbitrage — 20 minutes, par équipe

**Ouvrez vos versions côte à côte.** Aucune n'est « la bonne » : la version retenue sera **meilleure que les trois**, parce qu'elle prendra le meilleur de chacune.

### La grille d'arbitrage

| # | Question à poser à chaque version | Ce qui gagne |
|:---:|---|---|
| **1** | Les **types** sont-ils complets ? *(`map(object({…}))` et pas `map(any)`)* | Le plus typé |
| **2** | Combien de **`validation`** ? Que protègent-elles ? | Celui qui protège l'appelant, pas celui qui l'ennuie |
| **3** | Quelles variables ont un **`default`** ? | Le moins de variables obligatoires possible |
| **4** | Les **`description`** sont-elles utiles à quelqu'un qui n'a pas écrit le module ? | Celui qu'on peut utiliser sans lire `main.tf` |
| **5** | Les **outputs** exposent-ils ce dont les autres ont besoin ? | Celui qui publie un contrat, pas des détails |
| **6** | Y a-t-il un **nom en dur** qui devrait être une variable ? | Celui qui n'en a aucun |
| **7** | Le module gère-t-il le cas **`tables = {}`** *(collection vide)* ? | Celui qui ne plante pas |

### La règle de décision

> 🗣️ **On ne vote pas. On argumente ligne par ligne, et on écrit le module final ensemble à l'écran.**
>
> Chaque personne doit pouvoir dire, à la fin : *« cette ligne vient de ma version »*. Si quelqu'un n'a rien apporté, l'arbitrage a été mal mené — reprenez la grille.

## 📄 Le `README.md` du module — obligatoire

Le module retenu porte un `README.md`, et il nomme ses auteurs.

```markdown
# module `data-domain`

Crée un domaine métier GlobalBank : une database, un schema `BUSINESS`,
et ses tables.

| Entrée | Type | Obligatoire | Description |
|---|---|:---:|---|
| `prefix` | string | ✅ | Préfixe de la plateforme |
| `environment` | string | ✅ | `dev`, `uat` ou `prod` |
| `domain` | string | ✅ | Nom du domaine, en MAJUSCULES |
| `classification` | string | ❌ | Par défaut `INTERNE` |
| `tables` | map(object) | ✅ | Tables du domaine |

| Sortie | Description |
|---|---|
| `database_name` | Database créée — consommée par BI |
| `domain_contract` | Contrat du data product |

## Exemple

    module "domain" {
      source      = "../../modules/data-domain"
      prefix      = "GB"
      environment = "dev"
      domain      = "CUSTOMER"
      tables      = var.tables
    }

**Mainteneurs :** Manel Manai · Leila Sammoud · Olfa Ben Mahfoudh
```

> 🧠 **Si le code devient anonyme, la responsabilité disparaît avec.** Le nom des mainteneurs n'est pas de la vanité : c'est **à eux qu'on demandera l'autorisation** avant de modifier le module. 📅 **Lundi, cette règle deviendra une politique de branche dans Azure DevOps.**

## 🧪 La preuve de la convergence

**Chaque membre de l'équipe remplace son module par celui qui a été retenu**, puis, dans `envs/dev/` :

**2 · Initialiser** → **4 · Prévisualiser** →

```text
No changes. Your infrastructure matches the configuration.
```

> 🏆 **Trois personnes viennent d'adopter le code d'une quatrième sans qu'un seul objet Snowflake ne bouge.** C'est la définition même d'un composant réutilisable : **le contrat tient, l'implémentation change.**
>
> ⚠️ **Si votre plan affiche des changements**, le module retenu ne produit pas exactement les mêmes noms que le vôtre. **Ne l'appliquez pas** : c'est une divergence de contrat, et c'est précisément le sujet à traiter — corrigez le module, pas vos objets.

## ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Le découpage suit les types de ressources, pas les personnes** | Cinq modules pour onze personnes — c'est le bon rapport. |
| **Un module a un mainteneur nommé** | Sans propriétaire, un composant partagé pourrit en six mois. |
| **Le `README.md` fait partie du module** | Un module qu'on doit ouvrir pour comprendre n'est pas réutilisable. |
| **`No changes.` après substitution** | La seule preuve qu'un contrat tient vraiment. |
| **La revue vaut mieux que le vote** | Le module final est meilleur que chacune de ses sources. |

> 📅 **Lundi**, ces cinq modules quitteront vos dossiers pour un **dépôt Git commun**, versionné par tags. Vos racines les appelleront par `source = "git::…?ref=v1.0.0"` — et vous découvrirez ce qu'est un **breaking change**.

---
---

# 🔎 La preuve collective — 15 h 50

## Toute la plateforme, en trois requêtes

```sql
SHOW DATABASES LIKE 'GB_%';
SHOW WAREHOUSES LIKE 'GB_%';
SHOW ROLES LIKE 'GB_%';
```

```
   ── DEV ────────────────────────    ── UAT ────────────────────────
   GB_RAW_DB                          GB_RAW_DB_UAT
   GB_CORE_DB                         GB_CORE_DB_UAT
   GB_CUSTOMER_DB                     GB_CUSTOMER_DB_UAT
   GB_PRODUCT_DB                      GB_PRODUCT_DB_UAT
   GB_CAMPAIGN_DB                     GB_CAMPAIGN_DB_UAT
   GB_CUSTOMER_MART                   GB_CUSTOMER_MART_UAT
   GB_FINANCE_MART                    GB_FINANCE_MART_UAT
   GB_TRANSACTION_MART                GB_TRANSACTION_MART_UAT
   GB_INGEST_WH · GB_BUSINESS_WH …    GB_FINANCE_WH_UAT …
   GB_RAW_READER · GB_ENGINEER …      GB_RAW_READER_UAT …
```

**Puis, dans le portail Azure — conteneur `tfstate` :**

```
   tfstate/
   ├── fares/     dev.tfstate  uat.tfstate
   ├── mohamed/   dev.tfstate  uat.tfstate
   ├── sirine/    dev.tfstate  uat.tfstate
   ├── amal/      dev.tfstate  uat.tfstate
   …                                          22 blobs · 11 personnes · 2 environnements
```

## Les trois constats à faire dire à la salle

| # | Le constat | La question de l'Inspection à laquelle il répond |
|:---:|---|---|
| **1** | Aucun state n'est plus sur un portable | *« Où est l'état de la plateforme ? »* |
| **2** | **Cinq** modules décrivent **quatorze** racines | *« Le douzième domaine, on recopie encore ? »* |
| **3** | DEV et UAT coexistent, isolés | *« Il n'y a ni DEV ni UAT. »* |

## Les 5 fondements de la journée

| # | Fondement | La phrase à retenir |
|:---:|---|---|
| **1** | **Le backend distant** | Le state quitte le dossier — le code devient déplaçable, partageable, automatisable. |
| **2** | **Le module** | Un dossier, un contrat : `variables.tf` en entrée, `outputs.tf` en sortie. |
| **3** | **`moved` vers un module** | Refactorer un projet vivant sans rien détruire. |
| **4** | **Le contrat typé** | `type` + `validation` = une gouvernance qui s'hérite. |
| **5** | **Une racine par environnement** | Même code, autre `tfvars`, autre `key`. |
| **⚖️** | **La convergence** | Cinq modules maintenus valent mieux que onze modules orphelins. |

---

## 🃏 Anti-sèche

```hcl
# ── Backend distant Azure ────────────────────────────────
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-data2ai-tf-state"
    storage_account_name = "sadata2aitfstatemsn"
    container_name       = "tfstate"
    key                  = "<prenom>/<env>.tfstate"   # ← l'identité du state
    use_azuread_auth     = true                       # ← aucun secret dans le code
  }
}
# migration : init  →  répondre "yes"

# ── Appeler un module ────────────────────────────────────
module "<nom_local>" {
  source = "../../modules/<dossier>"    # chemin relatif à CE fichier
  # … les variables du module
}
# init OBLIGATOIRE après tout ajout ou changement de source

# ── Déplacer vers un module sans détruire ────────────────
moved {
  from = <type>.<nom>
  to   = module.<nom_local>.<type>.<nom>
}

# ── Le suffixe d'environnement ───────────────────────────
suffix = var.environment == "dev" ? "" : "_${upper(var.environment)}"

# ── Le verrou ────────────────────────────────────────────
# "Error acquiring the state lock" → lire le champ Who → aller lui parler
# force-unlock <ID> = DERNIER recours, jamais par défaut
```

---

## 🔧 Si ça coince

| Symptôme | Cause probable | Correction |
|---|---|---|
| `Module not installed` | `init` non relancé après l'ajout du module | **2 · Initialiser** |
| `Unreadable module directory` | Mauvais `source` après le déplacement dans `envs/dev/` | `../../modules/<nom>` |
| `Backend configuration changed` | La `key` a été modifiée | **2 · Initialiser**, puis lire la question avant de répondre |
| `Error acquiring the state lock` | Quelqu'un applique — ou une clé partagée par erreur | Lire `Who` · vérifier sa propre `key` |
| Le plan veut tout recréer en DEV | Le suffixe n'est pas vide en `dev` | Vérifier la ligne `suffix = var.environment == "dev" ? "" : …` |
| `AuthorizationPermissionMismatch` | Rôle Azure manquant sur le conteneur | Le formateur accorde *Storage Blob Data Contributor* |
| `Error: Invalid value for variable` | 🛡️ **Ce n'est pas une panne** — votre `validation` a fonctionné | Corriger la valeur |

---

## 🔮 La suite

| Jour | Ce qui arrive |
|:---:|---|
| **J5** | Le **catalogue de modules** part dans un dépôt Git versionné · le **pipeline Azure DevOps** applique `envs/dev/` tout seul et `envs/uat/` après approbation · l'identité de service **JWT** remplace le PAT · les **future grants** · le **FinOps** avec dbt · le **capstone** |

> 🎯 **Ce que vous avez construit aujourd'hui est exactement ce que le pipeline attend :** un state qu'il peut atteindre, un catalogue de modules qu'il peut cloner, et deux environnements qu'il peut promouvoir l'un après l'autre.

---

*Jour 4 — GlobalBank Data Platform · ODDO BHF*
