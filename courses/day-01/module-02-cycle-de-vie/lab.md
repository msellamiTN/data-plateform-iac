# M02 — Le cycle de vie Terraform

| Élément | Valeur |
|---|---|
| **Durée** | 1 h 30 |
| **Prérequis** | [M01 — Du clic au code](../module-01-du-clic-au-code/lab.md) terminé |
| **Dossier de travail** | `C:\terraform-labs\m02-cycle-de-vie\` |
| **Coût** | Warehouse X-SMALL, initialement suspendu (< $0.01) |

---

## Objectif en une phrase

À la fin de ce module, vous maîtrisez le **cycle complet** d'une ressource Terraform :
`init → fmt → validate → plan → apply → modifier → plan → apply → destroy`, et vous
savez lire les quatre symboles d'un plan (`+ ~ - -/+`).

## Ce que vous allez faire

```
init → plan → apply      : créer un warehouse
modifier main.tf → plan   : voir un ~ (modification en place)
apply                     : appliquer la modification
destroy                   : détruire proprement
recréer                   : repartir de zéro
```

> Ce module est **autonome** : il crée son propre warehouse dans son propre dossier.
> Vous n'avez pas besoin du dossier de M01.

---

## Étape 0 — Vérifier que je suis prêt

```powershell
terraform version
Test-Path C:\terraform-labs\secrets\snowflake-pat.txt
```

✅ **Checkpoint 0 :** `1.14.5` et `True`.

---

## Étape 1 — Préparer le dossier et les fichiers de base

### 1.1 Créer le dossier

Créez `C:\terraform-labs\m02-cycle-de-vie\` et ouvrez-le dans VS Code.

### 1.2 Créer les 4 fichiers de base

Ce sont les mêmes qu'au M01. Créez `versions.tf`, `provider.tf`, `variables.tf`,
`terraform.tfvars` en recopiant depuis M01 (ou depuis
[`../../shared/templates/`](../../shared/templates/)).

<details>
<summary>Rappel des contenus (cliquez pour déplier)</summary>

**`versions.tf`** — voir [M01 Étape 3.2](../module-01-du-clic-au-code/lab.md).
**`provider.tf`** — voir [M01 Étape 3.3](../module-01-du-clic-au-code/lab.md).
**`variables.tf`** — voir [M01 Étape 3.4](../module-01-du-clic-au-code/lab.md).
**`terraform.tfvars`** — voir [M01 Étape 3.5](../module-01-du-clic-au-code/lab.md).

</details>

✅ **Checkpoint 1 :** les 4 fichiers existent.

---

## Étape 2 — Écrire `main.tf`

Créez `main.tf` :

```hcl
resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M02_ETL_${var.environment}"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL pour le cycle de vie (M02)"
}
```

---

## Étape 3 — Le cycle complet : init → fmt → validate → plan → apply

```powershell
cd C:\terraform-labs\m02-cycle-de-vie
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Tapez `yes` au `apply`.

✅ **Checkpoint 2 :** `Apply complete! Resources: 1 added`. Snowsight montre
`APP01_M02_ETL_DEV`.

🧠 **Pourquoi — les 5 commandes dans l'ordre :**

| Commande | Rôle | Modifie-t-elle Snowflake ? |
|---|---|---|
| `init` | Télécharge le provider, prépare le dossier | Non |
| `fmt` | Reformate les fichiers `.tf` (indentation) | Non |
| `validate` | Vérifie la syntaxe et les types | Non |
| `plan` | Simule et affiche ce qui va changer | Non |
| `apply` | Exécute réellement | **Oui** |

Les 4 premières sont **sans risque**. Vous pouvez les relancer autant de fois que
vous voulez. Seul `apply` (et `destroy`) touche Snowflake.

---

## Étape 4 — Modifier : voir un `~` (modification en place)

### 4.1 Modifier `main.tf`

Changez le `comment` et `auto_suspend` dans `main.tf` :

```hcl
resource "snowflake_warehouse" "etl" {
  name                = "${var.learner_prefix}_M02_ETL_${var.environment}"
  warehouse_size      = "X-SMALL"
  auto_suspend        = 120
  auto_resume         = true
  initially_suspended = true
  comment             = "Warehouse ETL modifié (M02 — auto_suspend 120)"
}
```

### 4.2 Lire le plan

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
  # snowflake_warehouse.etl will be updated in-place
  ~ resource "snowflake_warehouse" "etl" {
      ~ auto_suspend = 60 -> 120
      ~ comment      = "Warehouse ETL pour le cycle de vie (M02)" -> "Warehouse ETL modifié (M02 — auto_suspend 120)"
        name         = "APP01_M02_ETL_DEV"
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

🧠 **Pourquoi :** le `~` (jaune) signifie **modification en place** — la ressource
reste la même, seuls des attributs changent. C'est l'opération la plus sûre. Notez
que `name` n'a pas de symbole : il ne change pas.

### 4.3 Appliquer

```powershell
terraform apply
```

Tapez `yes`.

✅ **Checkpoint 3 :** `Apply complete! Resources: 0 added, 1 changed, 0 destroyed`.
Snowsight montre `auto_suspend = 120`.

---

## Étape 5 — Le symbole `-/+` (recréation destructrice)

### 5.1 Modifier le `name`

Changez le `name` dans `main.tf` :

```hcl
  name = "${var.learner_prefix}_M02_ETL_RENAMED_${var.environment}"
```

### 5.2 Lire le plan

```powershell
terraform plan
```

👀 **Résultat attendu :**

```
  # snowflake_warehouse.etl must be replaced
-/+ resource "snowflake_warehouse" "etl" {
      ~ name = "APP01_M02_ETL_DEV" -> "APP01_M02_ETL_RENAMED_DEV" # forces replacement
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

🧠 **Pourquoi :** le `-/+` (rouge/vert) signifie **destroy then create**. Changer le
`name` d'un warehouse force sa recréation (Snowflake ne permet pas de renommer en
place). C'est **dangereux** : si le warehouse contenait des données ou des sessions
actives, elles seraient perdues. Lisez toujours le plan avant d'appliquer.

### 5.3 Ne pas appliquer — restaurer

**Restaurez** le `name` original :

```hcl
  name = "${var.learner_prefix}_M02_ETL_${var.environment}"
```

```powershell
terraform plan
```

👀 Doit afficher `No changes.`

✅ **Checkpoint 4 :** vous avez vu un `-/+` et choisi de **ne pas** l'appliquer.
C'est la Règle 2 en action.

---

## Étape 6 — Destroy : détruire proprement

### 6.1 Lire le plan de destruction

```powershell
terraform plan -destroy
```

👀 **Résultat attendu :**

```
  # snowflake_warehouse.etl will be destroyed
  - resource "snowflake_warehouse" "etl" {
      - auto_suspend        = 120 -> null
      - name                = "APP01_M02_ETL_DEV" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

🧠 **Pourquoi :** `plan -destroy` montre ce que `destroy` va faire **sans l'exécuter**.
Tous les attributs passent à `null` (suppression). C'est la Règle 2 : jamais de
`destroy` sans avoir lu le plan.

### 6.2 Détruire

```powershell
terraform destroy
```

Tapez `yes`.

✅ **Checkpoint 5 :** `Destroy complete! Resources: 1 destroyed`. Snowsight ne montre
plus `APP01_M02_ETL_DEV`.

---

## Étape 7 — Recréer : repartir de zéro

```powershell
terraform plan
terraform apply
```

Tapez `yes`.

✅ **Checkpoint 6 :** le warehouse est recréé. `terraform plan` → `No changes.`

🧠 **Pourquoi :** c'est la **reproductibilité**. Le code décrit l'objet ; `destroy` le
supprime ; `apply` le recrée à l'identique. Vous pouvez détruire et recréer 100 fois,
le résultat est le même. C'est impossible en ClickOps.

---

## Casser pour comprendre (5 min)

Supprimez **manuellement** le warehouse dans Snowsight (Admin → Warehouses → `...` →
Drop). Puis :

```powershell
terraform plan
```

👀 **Résultat attendu :** `1 to add` — Terraform voit que le warehouse a disparu et
propose de le recréer.

```powershell
terraform apply
```

✅ Le warehouse revient. C'est la **self-healing** : la vérité du code restaure
l'infrastructure.

---

## Défi autonome (optionnel, 10 min)

Ajoutez un output `warehouse_id` qui affiche l'identifiant du warehouse créé. Indice :
les ressources Snowflake ont un attribut `id`.

<details>
<summary>Solution</summary>

```hcl
output "warehouse_id" {
  value = snowflake_warehouse.etl.id
}
```

</details>

---

## Nettoyage

```powershell
terraform destroy
```

Vérifiez dans Snowsight que `APP01_M02_ETL_DEV` a disparu.

---

## Si ça casse

| Symptôme | Diagnostic | Correction |
|---|---|---|
| `terraform destroy` échoue (`warehouse in use`) | Une worksheet Snowsight utilise le warehouse | Fermez la worksheet ou changez de warehouse dans Snowsight, puis relancez `destroy` |
| `plan` affiche `-/+` inattendu | Vous avez modifié un attribut qui force la recréation (ex: `name`) | Restaurez l'attribut original |
| `state` désynchronisé après suppression manuelle | `terraform plan` montre `1 to add` | `terraform apply` recrée |

---

## Reprendre après un crash

- **Apply interrompu :** `terraform plan` puis `terraform apply`.
- **Destroy interrompu :** `terraform plan -destroy` puis `terraform destroy`.
- **Warehouse supprimé à la main :** `terraform apply` le recrée.
- **Dossier supprimé :** recréez les 5 fichiers, `terraform init`, `terraform apply`.

---

## Ce que j'ai appris

- ✅ Les 5 commandes du cycle (`init/fmt/validate/plan/apply`) et leur niveau de risque.
- ✅ Lire les 4 symboles d'un plan (`+ ~ - -/+`).
- ✅ Distinguer modification en place (`~`) et recréation destructrice (`-/+`).
- ✅ Détruire proprement avec `plan -destroy` puis `destroy`.
- ✅ Recréer à l'identique (reproductibilité).

---

## Suite

Passez au [M03 — Variables](../module-03-variables/lab.md).
