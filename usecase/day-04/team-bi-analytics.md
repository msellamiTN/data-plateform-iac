# 🟣 TEAM 4 — BI / ANALYTICS · Ghassen · Adem · Hadhemi
## Jour 4 — *un state partagé, un composant réutilisable, deux environnements*

<br/>

### Ma journée

| Propriétaire | `LEARNER_PREFIX` | ② Mon module | ③ Je déplace | ⑤ Ma racine UAT |
|---|:---:|---|---|---|
| **Ghassen** | `APP09` | `modules/data-mart/` | mart + schema + `customer_mart_tables` | `GB_CUSTOMER_MART_UAT` |
| **Adem** | `APP10` | `modules/data-mart/` | mart + schema + `finance_mart_tables` | `GB_FINANCE_MART_UAT` |
| **Hadhemi** | `APP11` | `modules/data-mart/` | mart + schema + `tx_mart_tables` | `GB_TRANSACTION_MART_UAT` |

> 🟣 **Un mart de recette, un mart de production, un seul code.** Vous pourrez enfin tester une nouvelle métrique sans toucher au rapport que la Direction consulte le lundi matin.
> 💰 **Aucun warehouse en UAT.**

---

## ÉTAPE 1 — Le backend distant

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

## ② 🔍 Mon identité et ma clé — ce que `Learner-Login.ps1` a déjà fait

**Vous vous connectez depuis lundi avec le script fourni :**

```powershell
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01
```

**Ouvrez un terminal PowerShell dans VS Code et regardez ce qu'il a posé :**

```powershell
$env:ARM_SUBSCRIPTION_ID
$env:ARM_RESOURCE_GROUP
$env:ARM_STORAGE_ACCOUNT
$env:ARM_CONTAINER
$env:LEARNER_PREFIX
```

| Variable | D'où elle vient | À quoi elle sert **aujourd'hui** |
|---|---|---|
| `ARM_CLIENT_ID` · `ARM_CLIENT_SECRET` | Key Vault → service principal partagé | **L'authentification du backend** — Terraform les lit tout seul |
| `ARM_TENANT_ID` · `ARM_SUBSCRIPTION_ID` | Key Vault | Idem |
| `ARM_RESOURCE_GROUP` · `ARM_STORAGE_ACCOUNT` · `ARM_CONTAINER` | `config/shared.env` | **Les coordonnées du backend** |
| `TF_VAR_snowflake_token` | Key Vault → `SnowflakePAT` | Votre provider Snowflake, depuis lundi |
| `LEARNER_PREFIX` | l'argument du script | **Votre espace de nommage dans le conteneur de states** |

> 🧠 **Vous utilisez `TF_VAR_snowflake_token` depuis le premier jour sans le savoir.** Terraform lit automatiquement toute variable d'environnement préfixée `TF_VAR_` et la mappe sur la variable du même nom. **C'est pour cela qu'aucun jeton n'a jamais eu besoin de figurer dans un fichier de votre projet.**

### Ma clé dans le conteneur

| Je m'appelle | `LEARNER_PREFIX` | Ma clé en DEV | Ma clé en UAT *(étape 5)* |
|---|:---:|---|---|
| **Fares** | `APP01` | `APP01/dev.tfstate` | `APP01/uat.tfstate` |
| **Mohamed** | `APP02` | `APP02/dev.tfstate` | `APP02/uat.tfstate` |
| **Sirine** | `APP03` | `APP03/dev.tfstate` | `APP03/uat.tfstate` |
| **Amal** | `APP04` | `APP04/dev.tfstate` | `APP04/uat.tfstate` |
| **Lara** | `APP05` | `APP05/dev.tfstate` | `APP05/uat.tfstate` |
| **Manel** | `APP06` | `APP06/dev.tfstate` | `APP06/uat.tfstate` |
| **Leila** | `APP07` | `APP07/dev.tfstate` | `APP07/uat.tfstate` |
| **Olfa** | `APP08` | `APP08/dev.tfstate` | `APP08/uat.tfstate` |
| **Ghassen** | `APP09` | `APP09/dev.tfstate` | `APP09/uat.tfstate` |
| **Adem** | `APP10` | `APP10/dev.tfstate` | `APP10/uat.tfstate` |
| **Hadhemi** | `APP11` | `APP11/dev.tfstate` | `APP11/uat.tfstate` |

> 🧠 **Deux préfixes, deux rôles bien distincts — ne les confondez jamais :**
>
> | | `LEARNER_PREFIX` = `APP01` | `platform_prefix` = `GB` |
> |---|---|---|
> | Où il vit | Le **chemin du state** dans Azure | Le **nom des objets** dans Snowflake |
> | Ce qu'il isole | Vos états les uns des autres | Rien — il est **partagé**, c'est voulu |
> | Pourquoi | Onze personnes, un conteneur | Onze personnes, **une seule** plateforme |

> 🔒 **Une clé par personne et par environnement.** Deux projets qui partagent une clé partagent un state — c'est exactement l'accident que le Chaos Lab de 15 h 15 va provoquer volontairement.

## ③ 🔁 La correspondance

| Dans le portail Azure | Dans la configuration du backend | D'où vient la valeur |
|---|---|---|
| Resource group | `resource_group_name` | `$env:ARM_RESOURCE_GROUP` |
| Compte de stockage | `storage_account_name` | `$env:ARM_STORAGE_ACCOUNT` |
| Conteneur `tfstate` | `container_name` | `$env:ARM_CONTAINER` |
| *(le blob que je vais créer)* | `key` | **je l'écris moi-même** |
| *(l'identité qui écrit)* | *(rien à déclarer)* | `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET` |

## ④ ⌨️ Le bloc `backend` — et la contrainte qui surprend tout le monde

**Créez `backend.tf`** à la racine de votre projet :

```hcl
terraform {
  backend "azurerm" {
    key = "APP01/dev.tfstate"
  }
}
```

> 🛑 **Pourquoi une seule ligne ?** Essayez d'écrire `storage_account_name = var.storage_account` :
>
> ```text
> Error: Variables not allowed
>   on backend.tf line 3, in terraform:
>    3:     storage_account_name = var.storage_account
>
> Variables may not be used here.
> ```
>
> 🧠 **Le bloc `backend` n'accepte ni variable, ni `local`, ni fonction.** C'est la seule partie de Terraform où l'interpolation est interdite — et pour une bonne raison : **le backend est lu avant tout le reste**, avant même que les variables existent. Terraform ne sait pas encore où est son state ; il ne peut donc rien évaluer.

### La configuration partielle — la réponse à cette contrainte

Ce qu'on ne peut pas interpoler, on le fournit **au moment du `init`**. Créez `backend.hcl` **à côté** de `backend.tf` :

```hcl
resource_group_name  = "rg-data2ai-tf-state"
storage_account_name = "sadata2aitfstatemsn"
container_name       = "tfstate"
```

Puis, dans `.vscode/tasks.json`, la tâche **`2 · Initialiser`** devient :

```
terraform init -backend-config=backend.hcl
```

> 🧠 **C'est la *partial backend configuration*.** Le `key` reste dans le code — il identifie **votre** projet. Le reste vient d'un fichier d'environnement, différent chez le client, différent dans la CI. **Le même code fonctionne partout.**

<details>
<summary>🔧 <b>La variante sans fichier — directement depuis vos variables d'environnement</b></summary>

Si vous préférez ne rien écrire en dur du tout, la tâche peut lire ce que `Learner-Login.ps1` a déjà posé :

```powershell
terraform init `
  -backend-config="resource_group_name=$env:ARM_RESOURCE_GROUP" `
  -backend-config="storage_account_name=$env:ARM_STORAGE_ACCOUNT" `
  -backend-config="container_name=$env:ARM_CONTAINER" `
  -backend-config="key=$env:LEARNER_PREFIX/dev.tfstate"
```

> 🎯 **C'est la forme utilisée par la CI de vendredi** : le pipeline pose les mêmes variables depuis Key Vault et lance exactement cette commande. **Aucune valeur d'environnement ne traîne dans le dépôt.**
</details>

> 🔒 **Aucun secret nulle part.** `backend.hcl` ne contient que des **noms de ressources Azure** — ce ne sont pas des secrets. L'authentification, elle, vient des variables `ARM_CLIENT_*` posées en mémoire par le script de connexion. **Rien de sensible n'est écrit dans un fichier du projet.**

<details>
<summary>🔧 <b>Si le <code>init</code> échoue en <code>AuthorizationPermissionMismatch</code> ou <code>AuthenticationFailed</code></b></summary>

**Dans 9 cas sur 10, la session Azure a expiré.** Relancez la connexion dans le même terminal :

```powershell
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01
```

**Si le script bascule en mode secours et échoue aussi**, vérifiez que le service principal possède bien le rôle *Storage Blob Data Contributor* sur le conteneur `tfstate` — c'est un rôle de **plan de données**, distinct de *Contributor*. Le formateur l'accorde en trente secondes.

> ⚠️ **Un piège connu du script :** dès que `secrets/shared-sp.txt` et `secrets/snowflake_pat.txt` existent, il **saute Key Vault** et réutilise ces fichiers. Si un secret a été renouvelé côté Key Vault, vous continuerez d'utiliser l'ancien — avec une erreur d'authentification incompréhensible. **Le correctif : supprimer le dossier `secrets/` et relancer le script.**
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
| **Le bloc `backend` n'accepte aucune variable** | Il est lu avant tout le reste — d'où la **configuration partielle** `-backend-config`. |
| **L'authentification vient de l'environnement** | `ARM_CLIENT_*` posés par `Learner-Login.ps1`, jamais un fichier du projet. |
| 🔒 **Le chiffrement et le versioning** | Le state est un secret : chiffré au repos, versionné, jamais dans Git. |

> 🎯 **C'est la réponse n°1 à l'Inspection.** Et c'est aussi ce qui rend le reste de la journée possible : **maintenant que le state ne vit plus dans le dossier, vous pouvez réorganiser le dossier librement.** C'est exactement ce que fait l'étape 2.

---

---

## ÉTAPE 2 — J'extrais mon module

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
  required_version = ">= 1.9.0"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.0"
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

## ÉTAPE 3 — J'appelle mon module sans rien détruire

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

## ÉTAPE 4 — Le contrat typé du module

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

## ÉTAPE 5 — Ma racine UAT

### Le principe

**Un environnement = une racine = un state.**

```
   mon-projet/
   ├── modules/
   │   └── data-mart/       ← écrit UNE fois
   └── envs/
       ├── dev/             ← key = APP09/dev.tfstate
       └── uat/             ← key = APP09/uat.tfstate
```

### ④ ⌨️ Je réorganise, puis je crée UAT

**1. Déplacez** vos fichiers de racine dans `envs/dev/`.

> 🧠 **Le state est sur Azure depuis ce matin** — déplacer le dossier ne lui fait rien.

**2. Corrigez le `source`** : `source = "../../modules/data-mart"`.

**3. Copiez `envs/dev/` en `envs/uat/`**, puis modifiez **deux choses** :

**`envs/uat/backend.tf`**

```hcl
    key = "APP09/uat.tfstate"
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

---
---

# 🐛 Le Chaos Lab — le verrou de state

> **15 h 15 – 15 h 30 · par binômes.** Constituez cinq binômes ; le onzième rejoint le formateur.

## Le scénario

Deux ingénieurs appliquent **au même moment** sur le **même** environnement. Sans verrou, les deux states s'écrasent et la plateforme devient impossible à réconcilier.

## ① Provoquez la collision

**Le binôme B** modifie temporairement son `envs/uat/backend.tf` pour pointer sur la clé du **binôme A** :

```hcl
    key = "<LEARNER_PREFIX du binôme A>/uat.tfstate"   # ← TEMPORAIRE
```

**2 · Initialiser** *(répondez `no` à la copie du state)*.

**Puis, simultanément :** A lance **5 · Appliquer**, et B lance **4 · Prévisualiser** dans la seconde qui suit.

```text
Error: Error acquiring the state lock

Error message: state blob is already locked
Lock Info:
  ID:        f4a1c9d2-8b3e-4c71-9a05-6d2e3f8b1c40
  Path:      tfstate/APP01/uat.tfstate
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
   ├── APP01/     dev.tfstate  uat.tfstate      (Fares)
   ├── APP02/     dev.tfstate  uat.tfstate      (Mohamed)
   ├── APP03/     dev.tfstate  uat.tfstate      (Sirine)
   ├── APP04/     dev.tfstate  uat.tfstate      (Amal)
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
| **1** | **Le backend distant** | Le state quitte le dossier — le code devient déplaçable, partageable, automatisable. Ses coordonnées arrivent par `-backend-config`, ses identifiants par l'environnement. |
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
    key = "<LEARNER_PREFIX>/<env>.tfstate"   # ← l'identité du state
  }
}
# le reste NE PEUT PAS être interpolé  →  configuration partielle :
#   terraform init -backend-config=backend.hcl
# authentification : ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID
#                    posés par  .\scripts\Learner-Login.ps1 -LearnerPrefix APPxx
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
| `AuthorizationPermissionMismatch` | Session expirée, ou rôle *Storage Blob Data Contributor* manquant | Relancer `Learner-Login.ps1` · sinon voir le formateur |
| `Variables may not be used here` | 🛡️ **Ce n'est pas une panne** — le bloc `backend` n'accepte aucune interpolation | Passer en configuration partielle : `-backend-config=backend.hcl` |
| Authentification qui échoue après un renouvellement de secret | Le script réutilise `secrets/` en cache | **Supprimer le dossier `secrets/`** puis relancer `Learner-Login.ps1` |
| `Error: Invalid value for variable` | 🛡️ **Ce n'est pas une panne** — votre `validation` a fonctionné | Corriger la valeur |

---

## 🔮 La suite

| Jour | Ce qui arrive |
|:---:|---|
| **J5** | Le **catalogue de modules** part dans un dépôt Git versionné · le **pipeline Azure DevOps** applique `envs/dev/` tout seul et `envs/uat/` après approbation · l'identité de service **JWT** remplace le PAT · les **future grants** · le **FinOps** avec dbt · le **capstone** |

> 🎯 **Ce que vous avez construit aujourd'hui est exactement ce que le pipeline attend :** un state qu'il peut atteindre, un catalogue de modules qu'il peut cloner, et deux environnements qu'il peut promouvoir l'un après l'autre.

---

*Jour 4 — GlobalBank Data Platform · ODDO BHF*