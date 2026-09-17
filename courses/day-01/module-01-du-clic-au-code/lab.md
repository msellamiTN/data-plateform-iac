# M01 — Du clic au code

| Élément | Valeur |
|---|---|
| **Durée** | 2 h |
| **Prérequis** | [M00 — Installation minimale](../../day-00/module-00-installation/lab.md) terminé |
| **Dossier de travail** | `C:\terraform-labs\m01-du-clic-au-code\` |
| **Coût** | Warehouse X-SMALL, initialement suspendu (< $0.01) |

---

## Objectif en une phrase

À la fin de ce module, vous avez créé un warehouse Snowflake **à la main** (clic),
**lu** sa définition en SQL, puis **recréé** un warehouse équivalent **en Terraform** —
et vous comprenez pourquoi les trois vues (formulaire, SQL, HCL) décrivent le même
objet.

## Ce que vous allez construire

```
Étape 1 (clic)    : APP01_MANUEL_WH    → créé dans Snowsight
Étape 2 (SQL)     : SHOW WAREHOUSES    → vous lisez la définition
Étape 3 (HCL)     : APP01_M01_ETL_DEV  → créé par Terraform (même type d'objet)
Étape 4 (preuve)  : No changes.        → Terraform et Snowflake d'accord
```

> La boucle « ① cliquer → ② lire en SQL → ③ écrire en HCL → ④ plan/apply → ⑤ No
> changes. » est le **fil directeur** de toute la formation. Vous la réutiliserez à
> chaque nouveau type d'objet.

---

## Étape 0 — Vérifier que je suis prêt

Ouvrez un terminal VS Code et vérifiez :

```powershell
terraform version
```

👀 Doit afficher `1.14.5`.

Vérifiez que votre PAT existe :

```powershell
Test-Path C:\terraform-labs\secrets\snowflake-pat.txt
```

👀 Doit afficher `True`.

✅ **Checkpoint 0 :** les deux commandes réussissent.

---

## Étape 1 — Cliquer : créer un warehouse dans Snowsight

Vous allez d'abord créer un warehouse **à la main** pour voir les champs du
formulaire. C'est la **Règle 1** : jamais une ligne de Terraform avant d'avoir cliqué.

### 1.1 Ouvrir Snowsight

1. Navigateur → `https://app.snowflake.com` → connectez-vous (`APP01`).
2. Vérifiez le rôle en haut à droite : **SYSADMIN**. Si ce n'est pas le cas, cliquez
   sur le sélecteur de rôle et choisissez **SYSADMIN**.

### 1.2 Créer le warehouse

1. Menu de gauche → **Admin** → **Warehouses**.
2. Cliquez sur le bouton **+ Warehouse** (en haut à droite).
3. Remplissez le formulaire :

| Champ | Valeur |
|---|---|
| **Name** | `APP01_MANUEL_WH` |
| **Size** | `X-Small` |
| **Auto Suspend** | `60` (secondes) |
| **Resume Automatically** | coché |
| **Initially Suspended** | coché |

4. Cliquez sur **Create Warehouse**.

✅ **Checkpoint 1 :** le warehouse `APP01_MANUEL_WH` apparaît dans la liste, avec le
statut *Suspended*.

🧠 **Pourquoi :** vous venez de faire du **ClickOps**. C'est rapide, mais il n'y a
aucune trace écrite de *qui* a créé *quoi*, *quand*, *pourquoi*. C'est exactement le
problème que Terraform résout.

---

## Étape 2 — Lire : la définition en SQL

Avant d'écrire du HCL, lisez ce que Snowflake sait de votre warehouse.

### 2.1 Ouvrir une worksheet

1. Dans Snowsight, cliquez sur **+ Worksheet** (en haut à gauche, ou Projects →
   Worksheets → +).
2. Une worksheet SQL s'ouvre.

### 2.2 Lister les warehouses

Tapez et exécutez (bouton **▶ Run** en haut à droite, ou `Ctrl+Enter`) :

```sql
SHOW WAREHOUSES LIKE 'APP01%';
```

👀 **Résultat attendu :** une ligne avec `APP01_MANUEL_WH`, `X-Small`, et une colonne
`AUTO_SUSPEND` à `60`.

### 2.3 Décrire le warehouse

```sql
DESC WAREHOUSE APP01_MANUEL_WH;
```

👀 **Résultat attendu :** un tableau de propriétés : `WAREHOUSE_SIZE = X-Small`,
`AUTO_SUSPEND = 60`, `AUTO_RESUME = true`, `INITIALLY_SUSPENDED = true`.

✅ **Checkpoint 2 :** vous voyez en SQL les mêmes valeurs que vous avez saisies dans
le formulaire.

🧠 **Pourquoi :** le SQL `SHOW` et `DESC` révèle les **noms exacts** des champs. Ces
noms (en majuscules, avec `_`) sont presque les mêmes que les arguments HCL (en
minuscules, avec `_`). Le SQL est le pont entre le clic et le code.

---

## Étape 3 — Écrire : créer le dossier et les fichiers Terraform

Maintenant, vous allez créer un **autre** warehouse (nom différent, pour ne pas
collisionner avec le manuel) **en Terraform**.

### 3.1 Créer le dossier de travail

Dans l'Explorateur de fichiers, créez `C:\terraform-labs\m01-du-clic-au-code\`.

Dans VS Code : **Fichier** → **Ouvrir un dossier…** → `m01-du-clic-au-code`.

### 3.2 Créer `versions.tf`

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

### 3.3 Créer `provider.tf`

```hcl
provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = "PROGRAMMATIC_ACCESS_TOKEN"
  token             = try(trimspace(file("${path.module}/../secrets/snowflake-pat.txt")), var.snowflake_token, "")
}
```

### 3.4 Créer `variables.tf`

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
```

### 3.5 Créer `terraform.tfvars`

```hcl
snowflake_organization = "<VOTRE_ORG>"
snowflake_account      = "<VOTRE_COMPTE>"
snowflake_user         = "APP01"
snowflake_role         = "SYSADMIN"
learner_prefix         = "APP01"
environment            = "DEV"
```

> Remplacez `<VOTRE_ORG>` et `<VOTRE_COMPTE>` par les valeurs de votre fiche apprenant.

✅ **Checkpoint 3 :** les 4 fichiers existent dans `m01-du-clic-au-code\`.

---

## Étape 4 — Écrire `main.tf` (la ressource)

Créez `main.tf` et collez :

```hcl
resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M01_ETL_${var.environment}"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL créé par Terraform pour ${var.learner_prefix}"
}
```

🧠 **Pourquoi — la correspondance formulaire ↔ SQL ↔ HCL :**

| Champ Snowsight | Colonne SQL (SHOW/DESC) | Argument HCL |
|---|---|---|
| Name | `name` | `name` |
| Size | `WAREHOUSE_SIZE` | `warehouse_size` |
| Auto Suspend | `AUTO_SUSPEND` | `auto_suspend` |
| Resume Automatically | `AUTO_RESUME` | `auto_resume` |
| Initially Suspended | `INITIALLY_SUSPENDED` | `initially_suspended` |
| (commentaire) | `COMMENT` | `comment` |

Chaque champ du formulaire = une colonne SQL = un argument HCL. C'est la règle.

---

## Étape 5 — Initialiser et valider

Dans le terminal VS Code :

```powershell
cd C:\terraform-labs\m01-du-clic-au-code
terraform init
```

👀 **Résultat attendu :** `Terraform has been successfully initialized!`

```powershell
terraform fmt
```

👀 **Résultat attendu :** (rien, ou les noms de fichiers reformattés).

```powershell
terraform validate
```

👀 **Résultat attendu :** `Success! The configuration is valid.`

✅ **Checkpoint 4 :** `init`, `fmt`, `validate` réussissent.

---

## Étape 6 — Plan : lire le plan avant d'appliquer

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # snowflake_warehouse.etl will be created
  + resource "snowflake_warehouse" "etl" {
      + auto_resume         = true
      + auto_suspend        = 60
      + comment             = "Warehouse ETL créé par Terraform pour APP01"
      + initially_suspended = true
      + name                 = "APP01_M01_ETL_DEV"
      + warehouse_size      = "X-SMALL"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

🧠 **Pourquoi lire le plan :**
- `+` (vert) = création. C'est ce qu'on attend ici.
- `~` (jaune) = modification en place.
- `-` (rouge) = destruction.
- `-/+` (rouge/vert) = destruction puis recréation. **Dangereux.**
Avant tout `apply`, vous devez savoir ce que Terraform va faire.

✅ **Checkpoint 5 :** le plan affiche `1 to add` et le nom `APP01_M01_ETL_DEV`.

---

## Étape 7 — Apply : créer le warehouse

```powershell
terraform apply
```

Tapez `yes` quand demandé.

👀 **Résultat attendu :**

```
snowflake_warehouse.etl: Creating...
snowflake_warehouse.etl: Creation complete after 2s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### Vérifier dans Snowsight

1. Snowsight → **Admin** → **Warehouses**.
2. Vous devez voir `APP01_M01_ETL_DEV` (à côté du `APP01_MANUEL_WH` de l'Étape 1).

✅ **Checkpoint 6 :** le warehouse `APP01_M01_ETL_DEV` est visible dans Snowsight.

---

## Étape 8 — Preuve d'idempotence : un second plan

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
No changes. Your infrastructure matches the configuration.
```

✅ **Checkpoint 7 :** `No changes.` — Terraform et Snowflake sont d'accord.

🧠 **Pourquoi :** c'est la **preuve d'idempotence**. Terraform a créé la ressource, et
relancer `plan` ne trouve rien à faire. C'est la signature d'une infrastructure
maîtrisée par le code.

---

## Casser pour comprendre (10 min)

### Injecter une dérive manuelle

1. Snowsight → **Admin** → **Warehouses** → cliquez sur `APP01_M01_ETL_DEV`.
2. Cliquez sur **Edit** (en haut à droite).
3. Changez **Auto Suspend** de `60` à `300`.
4. Cliquez sur **Save**.

### Détecter la dérive

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
  # snowflake_warehouse.etl has changed
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend        = 300 -> 60
    }
```

Terraform voit que Snowflake a `300` mais le code dit `60`. C'est la **dérive**.

### Réparer

```powershell
terraform apply
```

Tapez `yes`. Terraform remet `auto_suspend` à `60`.

✅ **Checkpoint 8 :** un second `terraform plan` affiche `No changes.`

🧠 **Pourquoi :** c'est le **chaos lab** fondamental. Quelqu'un (ou vous) modifie
Snowflake à la main → Terraform le détecte → `apply` réaligne. C'est l'intérêt
principal d'IaC : la **vérité du code** gagne sur la vérité de la console.

---

## Défi autonome (optionnel, 10 min)

Ajoutez un **second warehouse** `APP01_M01_REPORTING_DEV` dans `main.tf` (même taille,
`auto_suspend = 120`). Objectif : `Plan: 2 to add` (le premier existe déjà, donc
`1 to add` en réalité — mais vous devez voir les deux ressources).

<details>
<summary>Indice</summary>

Copiez le bloc `resource "snowflake_warehouse" "etl"`, renommez l'étiquette locale en
`reporting`, changez le nom et `auto_suspend`.
</details>

---

## Nettoyage

⚠️ **Ne détruisez pas encore** si vous voulez enchaîner sur M02 (qui réutilise ce
warehouse). Si vous arrêtez ici :

```powershell
terraform destroy
```

Tapez `yes`. Puis détruisez aussi le warehouse manuel dans Snowsight :

1. Snowsight → Admin → Warehouses → `APP01_MANUEL_WH` → **...** → **Drop**.
2. Confirmez.

Vérifiez :

```powershell
terraform plan
```

👀 Doit afficher `No changes.` (tout est détruit, le code ne décrit plus rien
d'existant — attention, `plan` peut afficher `1 to add` car le code existe encore ;
c'est normal. Pour un état vraiment vide, supprimez `main.tf` ou le dossier).

---

## Si ça casse

| Symptôme | Diagnostic (non destructif) | Correction |
|---|---|---|
| `Error: Warehouse already exists` au `apply` | `SHOW WAREHOUSES LIKE 'APP01_M01%';` dans Snowsight | Le warehouse existe déjà (apply interrompu). `terraform import` (vu au M08) ou `DROP` dans Snowsight puis `apply` |
| `Error: 401 Unauthorized` | Vérifiez `secrets\snowflake-pat.txt` | Regénérez le PAT (M00 Étape 4) |
| `terraform plan` montre `1 to destroy` inattendu | Vérifiez que `main.tf` n'a pas été modifié par erreur | Restaurez `main.tf` depuis la solution |

---

## Reprendre après un crash

- **Apply interrompu :** relancez `terraform plan` puis `terraform apply`.
- **PAT expiré :** regénérez-le, recollez-le dans `secrets\snowflake-pat.txt`.
- **Dossier supprimé :** recréez les 5 fichiers (Étapes 3-4). Le PAT n'est pas touché.
- **Warehouse manuel supprimé par erreur :** pas grave, il n'est pas géré par
  Terraform. Recréez-le dans Snowsight si vous voulez refaire l'Étape 1.

---

## Ce que j'ai appris

- ✅ Créer un warehouse à la main (ClickOps) et voir ses limites (pas de trace).
- ✅ Lire un objet en SQL (`SHOW`, `DESC`) pour connaître les noms exacts des champs.
- ✅ Écrire la ressource équivalente en HCL (`snowflake_warehouse`).
- ✅ Lire un plan (`+` = create) et prouver l'idempotence (`No changes.`).
- ✅ Détecter et réparer une dérive manuelle (chaos lab).

---

## Suite

Passez au [M02 — Le cycle de vie Terraform](../module-02-cycle-de-vie/lab.md).
