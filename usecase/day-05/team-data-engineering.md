# 🧪 Lab J5 — Team DATA ENGINEERING · Amal · Lara
## 🎯 Mission

*industrialiser, sécuriser, démontrer*

<br/>

### Ma journée

| Propriétaire | ⑤ Ma ressource avancée | Le fondement |
|---|---|---|
| **Amal** | **storage integration** + **external stage** vers ADLS Gen2 | l'identité de confiance entre deux clouds |
| **Lara** | **file format** + **stream** + **task** | la chaîne de traitement déclarée |

> 🟢 **Votre chaîne d'ingestion touche enfin le stockage Azure.** Et sans qu'une seule clé ne soit échangée : Snowflake s'authentifie auprès d'Azure avec une identité applicative.
> 💰 **`started = false` sur toute task**, et `WHEN SYSTEM$STREAM_HAS_DATA` pour ne consommer que s'il y a du travail.

---

## 📝 Étape 1 — Le catalogue de modules versionné

> **Commune aux onze.** 09 h 15 – 10 h 00.

## Le problème

Hier, chaque équipe a arbitré et retenu **un** module. Mais ce module a ensuite été **copié** dans le dossier de chacun.

```
   manel/mon-projet/modules/data-domain/   ← copie
   leila/mon-projet/modules/data-domain/   ← copie
   olfa/mon-projet/modules/data-domain/    ← copie
```

| Question | Réponse aujourd'hui |
|---|---|
| Manel corrige un bug dans le module. Qui en profite ? | **Personne.** Il faut recopier chez Leila et chez Olfa. |
| Qui a le droit de modifier `data-domain` ? | **Tout le monde, chacun chez soi.** |
| Quelle version Leila utilise-t-elle ? | **Aucune idée.** Il n'y a pas de version. |
| Le pipeline peut-il cloner le module ? | Il clonerait onze copies différentes. |

> 🛑 **Un module copié n'est pas un module partagé.** Tant qu'il vit dans onze dossiers, c'est de la duplication avec une bonne conscience.

## ① 🖱️ D'abord, à la main — dans Azure DevOps

**dev.azure.com → projet `GlobalBank-DataPlatform` → Repos → dépôt `globalbank-modules`**

> 🎤 **Le formateur a créé le dépôt et y a poussé les cinq modules retenus hier.** Vous, vous allez le **lire**, le **tagger** et le **consommer**.

```
   globalbank-modules/            ← UN dépôt, cinq composants
   ├── rbac/           README.md  variables.tf  main.tf  outputs.tf  versions.tf
   ├── compute/        …
   ├── landing-zone/   …
   ├── data-domain/    …
   ├── data-mart/      …
   └── CODEOWNERS
```

**Ouvrez `CODEOWNERS` :**

```
/rbac/           @fares.azzabi   @mohamed.laifi
/compute/        @sirine.dorgham
/landing-zone/   @amal.nouioui   @lara.hannachi
/data-domain/    @manel.manai    @leila.sammoud   @olfa.ben-mahfoudh
/data-mart/      @ghassen.khabou @adem.gaied      @hadhemi.boughanmi
```

> 🧠 **La règle du mainteneur d'hier vient de devenir exécutable.** Combinée à une **politique de branche** *(Repos → Branches → `main` → Branch policies → Automatically include code reviewers)*, une modification de `data-domain` **ne peut plus être fusionnée sans l'accord de Manel, Leila ou Olfa.**

**Puis créez le tag — Repos → Tags → `New tag` :**

```
   ┌─ Create tag ────────────────────────────────────────┐
   │   Name          v1.0.0                        ──── ①
   │   Based on      main                                │
   │   Description   Catalogue initial — J4        ──── ②
   │                              [ Cancel ] [ Create ]  │
   └─────────────────────────────────────────────────────┘
```

## ② 🔍 Qu'est-ce qu'un tag, au juste ?

**Un tag est un nom fixe posé sur un commit.** Une branche avance ; un tag, jamais.

```
   main   ──●──●──●──●──●──►   la branche AVANCE
               │        │
             v1.0.0   v1.1.0   les tags ne bougent PLUS JAMAIS
```

| | Une branche | Un tag |
|---|---|---|
| Évolue dans le temps | ✅ à chaque commit | ❌ jamais |
| Reproductible | ❌ `main` d'hier ≠ `main` d'aujourd'hui | ✅ `v1.0.0` sera identique dans deux ans |
| À utiliser comme `ref` | 🔴 **jamais en production** | ✅ **toujours** |

> 🔒 **Un `source` sans `ref` pointe sur la branche par défaut.** Votre `plan` d'aujourd'hui et celui de la CI de ce soir peuvent alors porter sur **deux codes différents** — sans qu'aucun de vous n'ait rien changé. **C'est la définition d'un build non reproductible.**

## ③ 🔁 La correspondance

| Hier — le module local | Aujourd'hui — le catalogue |
|---|---|
| `source = "../../modules/landing-zone"` | `source = "git::https://…/globalbank-modules-data-engineering//landing-zone?ref=v1.0.0"` |
| le dossier d'à côté | un **dépôt** |
| aucune version | un **tag** |
| `init` lit le disque | `init` **clone** dans `.terraform/modules/` |
| modifiable par moi seul, chez moi | modifiable par **une pull request approuvée** |

> 🧠 **Le double slash `//` n'est pas une faute de frappe.** Il sépare **l'adresse du dépôt** du **sous-dossier** à l'intérieur. C'est ce qui permet à cinq modules de cohabiter dans un seul dépôt.

## ④ ⌨️ Je consomme le catalogue

**`envs/dev/main.tf`** — remplacez le `source` local :

```hcl
module "landing_zone" {
  source = "git::file:///D:/git-repos/globalbank-modules-data-engineering//landing-zone?ref=v1.0.0"

  prefix       = var.prefix
  environment  = var.environment
  zone         = "RAW"
  schema_name  = "LANDING"
  audit_column = "LOAD_TS"
  tables       = var.tables
}
```

**Ctrl+Shift+B → `2 · Initialiser`**

```text
Initializing modules...
Downloading git::https://dev.azure.com/.../globalbank-modules?ref=v1.0.0 for domain...
- domain in .terraform/modules/domain/data-domain
```

> 🔒 **Aucun identifiant dans le `source`.** L'authentification passe par le **gestionnaire d'identifiants Git** déjà connecté dans VS Code — et, dans le pipeline, par les identifiants du job de `checkout`. **On ne met jamais de PAT dans une URL de `source` : elle serait committée avec le code.**

**4 · Prévisualiser** →

```text
No changes. Your infrastructure matches the configuration.
```

> 🏆 **`No changes.`** Vous venez de basculer d'un module local vers un module distant versionné **sans qu'un seul objet ne bouge**. C'est la seconde preuve, après celle d'hier, que **le contrat tient**.

**Faites la même bascule dans `envs/uat/`.**

### 🧪 Regardez ce que `init` a téléchargé

```
   .terraform/
   ├── modules/
   │   ├── modules.json          ← la carte : quel module, quelle version, où
   │   └── domain/
   │       └── data-domain/      ← le code cloné, en LECTURE SEULE
   └── providers/
```

> ⚠️ **Ne modifiez jamais un fichier dans `.terraform/modules/`.** Le prochain `init -upgrade` l'écrasera sans prévenir. **Une correction de module se fait dans le dépôt, par pull request.**

### La montée de version

Quand `v1.1.0` sortira :

```hcl
  source = "…//data-domain?ref=v1.1.0"
```

```
Ctrl+Shift+B → 2 · Initialiser
```

> 🧠 **`init` seul ne suffit pas toujours** : si vous gardez le même `ref` mais que le tag a été déplacé — ce qui ne devrait jamais arriver — il faut `terraform init -upgrade`. **C'est une raison de plus pour ne jamais déplacer un tag.**

> 🎯 **Le consommateur décide QUAND il monte de version.** Manel peut publier `v1.1.0` un mardi ; Leila reste sur `v1.0.0` jusqu'à ce que son planning le permette. **C'est exactement ce qu'un module local rendait impossible.**

## ⑤ 🧠 Le fondement de l'étape

```
   globalbank-modules  (dépôt · tags · CODEOWNERS)
        │
        │  source = git::…//<module>?ref=vX.Y.Z
        ▼
   ┌───────────┬───────────┬───────────┬───────────┐
   │ fares/dev │ amal/dev  │ manel/dev │ ghassen/  │  …  14 racines
   └───────────┴───────────┴───────────┴───────────┘
        chacune choisit SA version
```

| Fondement | En une phrase |
|---|---|
| **`source = git::…`** | Le module devient un **artefact partagé**, plus un dossier recopié. |
| **`//sous-dossier`** | Cinq modules dans un dépôt — le double slash désigne lequel. |
| **`?ref=v1.0.0`** | **Épingler une version est obligatoire.** Sans `ref`, le build n'est pas reproductible. |
| **Un tag ne bouge jamais** | Une branche avance ; un tag est une promesse. |
| **`CODEOWNERS` + politique de branche** | Le mainteneur d'hier devient un contrôle technique. |
| **`.terraform/modules/` est en lecture seule** | On corrige un module par pull request, jamais sur place. |
| 🔒 **Aucun identifiant dans le `source`** | L'authentification vient de l'environnement, pas de l'URL. |

> 📅 **Dans dix minutes**, le pipeline clonera ce même catalogue. **C'est parce que le module est dans un dépôt qu'une machine peut le construire.**

---
---

## 📝 Étape 2 — Le plan immuable

> **Commune aux onze.** 10 h 00 – 10 h 30.

## Le problème

Depuis lundi, vous faites **4 · Prévisualiser** puis **5 · Appliquer**. **Ce sont deux opérations indépendantes.** Entre les deux, quelqu'un a pu modifier Snowflake, ou modifier votre code.

> 🧠 **Vous n'appliquez donc pas le plan que vous avez lu.** Vous appliquez un plan **recalculé** au moment de l'`apply`. Sur un poste isolé, c'est acceptable. Dans une chaîne où **une personne lit et une autre approuve**, c'est inacceptable.

## ④ ⌨️ Un plan que l'on peut lire, transporter et approuver

Dans `envs/dev/`, exécutez la nouvelle tâche **`7 · Plan signé`** :

```
terraform plan -out=tfplan -input=false
```

```text
Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

> 🧠 **« exactly these actions ».** Le fichier `tfplan` contient **la liste figée** des actions. Il est binaire, il est lié à un state à un instant donné.

**Lisez-le sans l'appliquer :**

```
terraform show tfplan
terraform show -json tfplan > plan.json
```

> 🔒 **`plan.json` contient les valeurs réelles de vos ressources — c'est un secret**, exactement comme le state. Ajoutez `tfplan` et `plan.json` à votre `.gitignore` **maintenant**.

**Appliquez le plan lu :**

```
terraform apply tfplan
```

Aucune question, aucune confirmation : **le plan a déjà été approuvé.**

### 🧪 Prouvez qu'un plan périme

1. `terraform plan -out=tfplan -input=false`
2. **Modifiez un `comment`** dans votre code
3. `terraform apply tfplan`

```text
Error: Saved plan is stale

The given plan file can no longer be applied because the state was changed
by another operation after the plan was created.
```

> 🏆 **Terraform a refusé.** Un plan approuvé ne peut pas être appliqué sur une réalité qui a changé. **C'est la garantie que la CI va exploiter.**

## ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **`plan -out=tfplan`** | Fige les actions dans un fichier — c'est **l'objet que l'on approuve**. |
| **`apply tfplan`** | N'affiche aucune question : la décision a été prise en amont. |
| **`Saved plan is stale`** | La protection : un plan périmé ne s'applique pas. |
| 🔒 **`tfplan` et `plan.json` sont des secrets** | Ils contiennent les attributs réels. `.gitignore` obligatoire. |

> 🎯 **C'est la réponse n°1 à Sofia**, et c'est la brique centrale du pipeline : **l'étape qui planifie n'est pas celle qui applique.**

---
---

## 📝 Étape 3 — Le pipeline Azure DevOps

> **10 h 45 – 11 h 45.** 🔵 **Platform construit le pipeline** pour toute la salle. 🟢🟠🟣 **Les autres le lisent, le déclenchent et lisent son résultat** — c'est ainsi que cela se passe en entreprise.

## ① 🖱️ D'abord, à la main — dans Azure DevOps

**dev.azure.com → projet `GlobalBank-DataPlatform`**

```
   ┌─ Le vocabulaire à repérer ──────────────────────────┐
   │  Repos          le dépôt Git — le code             │
   │  Pipelines      la définition YAML                 │
   │  Environments   dev / uat — PORTEURS DES GATES ─── ①
   │  Library        variable groups et secrets    ──── ②
   │  Service conn.  l'identité Azure du pipeline  ──── ③
   └─────────────────────────────────────────────────────┘
```

**Ouvrez `Pipelines → Environments → uat → Approvals and checks`.**

```
   ┌─ Approvals ─────────────────────────────────────────┐
   │   Approvers          Sofia Almeida                  │
   │   Instructions       « Vérifier le plan publié »    │
   │   Timeout            1 jour                         │
   │   ☑ Approvers cannot approve their own runs         │
   └─────────────────────────────────────────────────────┘
```

> 🧠 **L'approbation n'est PAS dans le YAML.** Elle est attachée à l'**environnement** Azure DevOps. Le pipeline demande à déployer vers `uat` ; la plateforme le met en attente. **Un développeur ne peut pas contourner une approbation en modifiant le YAML** — c'est tout l'intérêt.

## ② 🔍 La correspondance — mes gestes de la semaine deviennent des étapes

| Ce que je faisais à la main | Dans le pipeline |
|---|---|
| **1 · Formater** | `terraform fmt -check` — **bloquant** |
| **2 · Initialiser** | `terraform init` |
| **3 · Vérifier** | `terraform validate` |
| **7 · Plan signé** | `terraform plan -out=tfplan -input=false` puis **publication en artefact** |
| *(je relis mon plan)* | **Approbation humaine** sur l'environnement |
| **5 · Appliquer** | `terraform apply tfplan` — **le plan téléchargé, pas un nouveau** |

## ④ ⌨️ `azure-pipelines.yml`

Le pipeline CI/CD complet est détaillé dans `atelier-globalbank-jour-05.md` §② (même contenu que `azure-pipelines.yml` à la racine du dépôt).

En résumé :
- `TerraformInstaller@1` 1.14.5
- `Validate` : `terraform fmt -check` + `terraform validate`
- `PlanDev` : `terraform plan -out=tfplan` + publication d'artefacts
- `ApplyDev` : `terraform apply tfplan` automatique
- `PlanUat` puis `ApplyUat` : approbation humaine requise sur `uat`

Les modules sont consommés depuis le registry Git (`git::...?ref=v1.0.0`) ; le `trigger` ne concerne que les changements d'`envs/`.

### 🧪 Faites échouer la CI volontairement

**Cassez le formatage** d'un fichier — une accolade décalée de trois espaces — commitez, poussez.

```text
Validate ✗
  terraform fmt -check
  modules/rbac/main.tf
##[error]Bash exited with code '3'.
```

> 🏆 **La CI a bloqué un code non conforme.** Personne n'a eu besoin de le relire pour s'en apercevoir. **C'est la première preuve attendue par l'Inspection.**

Corrigez, repoussez : le pipeline repart et s'arrête devant `uat`, en attente d'approbation.

## ⑤ 🧠 Le fondement de l'étape

```
   git push
      │
      ▼
   ┌──────────┐   ┌────────────────────┐   ┌──────────┐   ┌───────────────┐
   │ Validate │──►│ Plan               │──►│ ApplyDev │──►│ ApplyUat      │
   │ fmt      │   │ plan -out=tfplan   │   │ apply    │   │ ⏸ APPROBATION │
   │ validate │   │ publie l'artefact  │   │ tfplan   │   │ puis apply    │
   └──────────┘   └────────────────────┘   └──────────┘   └───────────────┘
        ✗ bloque        l'objet approuvé        auto            humain
```

| Fondement | En une phrase |
|---|---|
| **La CI applique le plan publié** | Pas un plan recalculé — c'est le sens de l'étape 2. |
| **L'approbation vit sur l'environnement** | Elle n'est pas dans le YAML, donc pas contournable par un commit. |
| **`fmt -check` bloquant** | Le style n'est plus un débat de revue de code. |
| 🔒 **Aucun secret dans le YAML** | `variables: - group:` pointe vers Key Vault. |
| **`TF_IN_AUTOMATION`** | Terraform adapte ses messages : il sait qu'aucun humain ne lit. |

---
---

## 📝 Étape 4 — L'identité de service

> **Commune aux onze.** 11 h 45 – 12 h 30.

## Le problème

Depuis lundi, votre `secrets.auto.tfvars` contient **votre** jeton personnel.

| Question | Réponse aujourd'hui |
|---|---|
| Qui a créé `GB_RAW_DB` ? | *Amal — avec son compte nominatif* |
| Que se passe-t-il si Amal quitte l'équipe ? | **Son compte est désactivé. Le pipeline s'arrête.** |
| Le PAT expire quand ? | Dans 90 jours — **sans prévenir** |
| Peut-on le faire tourner sans interruption ? | Non |

> 🎯 **C'est la réponse n°2 à Sofia.** Une plateforme ne doit dépendre d'aucune personne physique.

## ① 🖱️ D'abord, à la main — dans Azure Key Vault

**portail Azure → votre Key Vault *(`$env:KEY_VAULT_NAME`)* → Secrets → `SnowflakePrivateKey`**

```
   ┌─ Secret ────────────────────────────────────────────┐
   │   Nom              SnowflakePrivateKey              │
   │   Version          courante ✓  ·  précédente        │
   │   Activé           Oui                              │
   │   Date d'expiration 2026-12-07                ──── ①
   │   Valeur           ●●●●●●●●  [ Afficher ]     ──── ②
   │                                                     │
   │   ▸ Access control (IAM)                      ──── ③
   │       sc-globalbank-tfstate → Key Vault Secrets User│
   └─────────────────────────────────────────────────────┘
```

| Élément | Ce qu'il vous apprend |
|---|---|
| ① **Expiration** | Un secret sans date d'expiration est un secret oublié |
| ② **Versions** | Key Vault garde les versions : la **rotation** est native |
| ③ **IAM** | Seul le service connection du pipeline peut lire — **pas vous** |

> 🎤 **Le formateur a généré la paire de clés RSA 2048** avant la session et a déposé la clé privée ici. **Vous ne la verrez jamais** — et c'est exactement le but.

## ② 🔍 Côté Snowflake — la clé publique sur l'utilisateur de service

```sql
DESC USER SVC_GLOBALBANK_TF;
```

```
   property              value
   ─────────────────────────────────────────────
   TYPE                  SERVICE
   RSA_PUBLIC_KEY        MIIBIjANBgkqhkiG9w0BAQ...
   RSA_PUBLIC_KEY_2      null
   DEFAULT_ROLE          GB_DEPLOYER
   PASSWORD              null              ⬅️ AUCUN mot de passe
```

> 🔒 **`TYPE = SERVICE` et `PASSWORD = null`.** Cet utilisateur ne peut pas se connecter à Snowsight, ne peut pas recevoir de MFA, ne peut être utilisé **que** par un porteur de la clé privée.

## ③ 🔁 La correspondance

| Jusqu'à aujourd'hui | À partir de maintenant |
|---|---|
| `authenticator = "PROGRAMMATIC_ACCESS_TOKEN"` | `authenticator = "SNOWFLAKE_JWT"` |
| `token = var.snowflake_token` | `private_key = var.snowflake_private_key` |
| `user = "AMAL.NOUIOUI"` — un compte **nominatif** | `user = "SVC_GLOBALBANK_TF"` — un compte **de service** |
| Secret `SnowflakePAT` dans Key Vault | Secret `SnowflakePrivateKey` dans Key Vault |
| `TF_VAR_snowflake_token`, posé par `Learner-Login.ps1` | `TF_VAR_snowflake_private_key`, posé par le **pipeline** |

> 🧠 **Le mécanisme ne change pas — seul le secret change.** Depuis lundi, `Learner-Login.ps1` va chercher `SnowflakePAT` dans Key Vault et le pose dans `TF_VAR_snowflake_token`. **Vous avez donc déjà appliqué le bon schéma toute la semaine** : le secret vit dans le coffre, transite par une variable d'environnement, et ne touche jamais un fichier du projet. Ce qui change aujourd'hui, c'est **la nature du secret** — une clé privée qui n'appartient à personne, au lieu d'un jeton nominatif.

## ④ ⌨️ Le provider de production

**`envs/dev/providers.tf`** — ajoutez la variante de service :

```hcl
variable "snowflake_private_key" {
  type      = string
  sensitive = true
  default   = null
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.snowflake_service_user
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = var.snowflake_private_key
}
```

**Dans Azure DevOps → Library → variable group `globalbank-snowflake`**, cochez *Link secrets from an Azure Key Vault*, sélectionnez votre coffre, puis les secrets `SnowflakePrivateKey`, `ArmClientId`, `ArmClientSecret`, `ArmTenantId`, `ArmSubscriptionId`. Le pipeline les injecte :

```yaml
          env:
            TF_VAR_snowflake_private_key: $(SnowflakePrivateKey)
            ARM_CLIENT_ID: $(ArmClientId)
            ARM_CLIENT_SECRET: $(ArmClientSecret)
            ARM_TENANT_ID: $(ArmTenantId)
            ARM_SUBSCRIPTION_ID: $(ArmSubscriptionId)
```

> 🔒 **La variable s'appelle `TF_VAR_snowflake_private_key`.** Terraform lit automatiquement toute variable d'environnement préfixée `TF_VAR_`. **Le secret ne touche jamais un fichier.**

### 🧪 Deux vérifications de sécurité

**1. Le secret n'apparaît pas dans les logs.** Ouvrez l'exécution du pipeline, cherchez la clé : Azure DevOps affiche `***`.

**2. `sensitive = true` fonctionne.** Ajoutez temporairement :

```hcl
output "test" {
  value = var.snowflake_private_key
}
```

```text
Error: Output refers to sensitive values

To reduce the risk of accidentally exporting sensitive data, Terraform
requires that any root module output containing sensitive data be
explicitly marked as sensitive.
```

> 🛡️ **Terraform a refusé de publier le secret.** Supprimez cet output.

## La rotation — sans interruption

```sql
-- 1. la nouvelle clé arrive en second emplacement
ALTER USER SVC_GLOBALBANK_TF SET RSA_PUBLIC_KEY_2 = 'MIIBIjANBg...nouvelle';

-- 2. le pipeline bascule sur la nouvelle clé privée (nouvelle version Key Vault)

-- 3. l'ancienne est retirée
ALTER USER SVC_GLOBALBANK_TF UNSET RSA_PUBLIC_KEY;
```

> 🧠 **Deux emplacements de clé publique = rotation sans coupure.** Pendant la bascule, les deux clés sont acceptées. **C'est le seul moyen de faire tourner un secret sur une plateforme qui tourne 24 h / 24.**

## ⑤ 🧠 Le fondement de l'étape

| Fondement | En une phrase |
|---|---|
| **Une identité de service n'est liée à personne** | Un départ dans l'équipe n'arrête pas la plateforme. |
| **JWT key-pair > mot de passe / PAT** | Pas de secret partagé transmissible, pas d'expiration surprise. |
| **Le secret vit dans Key Vault** | Versionné, daté, auditable, lisible **seulement** par le pipeline. |
| **`TF_VAR_` injecte sans fichier** | Le secret ne touche ni le disque ni le dépôt. |
| ⚠️ **Un cache local n'est pas un coffre** | `Learner-Login.ps1` écrit `secrets/` **en clair** pour la salle. Acceptable en formation, **jamais en production** — et à supprimer ce soir. |
| **`RSA_PUBLIC_KEY_2`** | La rotation se fait sans coupure. |
| 🔒 **Fin du PAT** | Supprimez votre `secrets.auto.tfvars` en fin de journée. |

---
---

## 🐛 Chaos Lab — la dérive, puis le *breaking change*

## Partie A — la dérive que la CI attrape

> **13 h 30 – 14 h 00.** Tout le monde participe.

## ① Quelqu'un a cliqué

**Dans Snowsight**, modifiez un objet **à la main**, comme le ferait un collègue pressé un vendredi soir :

```sql
ALTER WAREHOUSE GB_INGEST_WH SET AUTO_SUSPEND = 3600;
-- ou, pour une équipe métier :
ALTER DATABASE GB_RAW_DB SET COMMENT = 'modifié à la main un vendredi soir';
```

> 💰 **`AUTO_SUSPEND = 3600` : le warehouse reste allumé une heure après la dernière requête.** Sur un X-SMALL, cela fait environ **24 crédits par jour** si personne ne s'en aperçoit.

## ② La CI le voit — c'est le rôle du job de nuit

Ajoutez au pipeline un **déclencheur planifié** qui ne fait que planifier :

```yaml
schedules:
  - cron: '0 5 * * *'
    displayName: 'Audit de dérive — 05 h 00 UTC'
    branches:
      include: [ main ]
    always: true

  # … dans le stage Plan :
          - script: |
              terraform plan -detailed-exitcode -out=tfplan
            displayName: 'Détection de dérive'
```

| Code de sortie | Signification | Ce que fait la CI |
|:---:|---|---|
| **0** | Aucune différence | ✅ vert |
| **1** | Erreur | ❌ rouge |
| **2** | **Des changements sont nécessaires** | ⚠️ **la dérive est signalée** |

## ③ Corrigez — par le code, jamais par Snowsight

**4 · Prévisualiser** dans `envs/dev/` :

```text
  ~ resource "snowflake_warehouse" "ingest" {
      ~ auto_suspend = 3600 -> 60
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**5 · Appliquer** → la dérive est effacée.

> 🎯 **Le réflexe à ancrer.** Face à une dérive, on **ne clique pas** pour remettre la valeur : on **applique le code**. Le code reste la seule source de vérité, et la trace de la correction est dans l'historique Git.

---

## Partie B — le *breaking change* de module

> 🎤 **Le formateur joue le rôle d'un mainteneur pressé.** Un seul module suffit pour la démonstration — prenons `data-domain`.

### ① Le mainteneur « améliore » son module

Dans le dépôt `globalbank-modules`, la variable `domain` est renommée en `domain_name` — un nom plus clair, en apparence :

```hcl
variable "domain_name" {   # ← s'appelait "domain"
  type        = string
  description = "Nom du domaine métier"
}
```

Le tag **`v2.0.0`** est publié.

### ② Les consommateurs qui montent de version se cassent

**Manel passe à `v2.0.0`** dans `envs/dev/main.tf`, puis **2 · Initialiser** → **4 · Prévisualiser** :

```text
Error: Unsupported argument
  on main.tf line 6, in module "domain":
   6:   domain = "CUSTOMER"

An argument named "domain" is not expected here.

Error: Missing required argument
  The argument "domain_name" is required, but no definition was found.
```

> 🔴 **Rien n'est cassé dans Snowflake — c'est le contrat qui est cassé.** Le module fonctionne parfaitement ; c'est l'appel qui ne lui parle plus la même langue.

### ③ Les consommateurs qui n'ont pas bougé ne voient rien

**Leila et Olfa sont restées sur `?ref=v1.0.0`.** Leur **4 · Prévisualiser** affiche `No changes.`

> 🏆 **C'est tout l'intérêt d'épingler une version.** Un mainteneur peut publier une rupture sans arrêter la production de trois équipes. **Chacun choisit son moment.**

### ④ Les deux réparations

| Rôle | Ce qu'il fait |
|---|---|
| **Le consommateur** *(Manel)* | Corrige son appel : `domain_name = "CUSTOMER"` — ou **revient à `?ref=v1.0.0`** en attendant |
| **Le mainteneur** | Aurait dû publier `v2.0.0` **et** annoncer la rupture dans le `README.md` |

### ⑤ La règle du versionnement — SemVer

```
   v  MAJEUR . MINEUR . CORRECTIF
      │        │         │
      │        │         └── un correctif — l'appelant ne change rien
      │        └── une variable OPTIONNELLE ajoutée — l'appelant ne change rien
      └── une variable renommée, supprimée ou rendue obligatoire
          ⚠️  L'APPELANT DOIT AGIR
```

| Le changement | La version | L'appelant doit… |
|---|:---:|---|
| Corriger une faute dans un `comment` | `v1.0.1` | rien |
| Ajouter une variable **avec `default`** | `v1.1.0` | rien |
| Ajouter un **output** | `v1.1.0` | rien |
| Ajouter une variable **obligatoire** | `v2.0.0` | **la fournir** |
| Renommer ou supprimer une variable | `v2.0.0` | **corriger son appel** |
| Renommer une ressource **dans** le module | `v2.0.0` | ⚠️ et le module doit livrer un bloc `moved` |

> 🧠 **La dernière ligne est la plus subtile.** Si le mainteneur renomme `snowflake_table.tables` en `snowflake_table.business_tables`, **tous ses consommateurs verront `to destroy`**. Le module doit alors embarquer lui-même le `moved` — c'est la responsabilité du mainteneur, pas de l'appelant.

### ⑥ Remettez tout en ordre

Manel revient à `?ref=v1.0.0` → **2 · Initialiser** → **4 · Prévisualiser** → `No changes.`

---

## 🧠 Ce que le Chaos Lab a prouvé

| Constat | Conséquence |
|---|---|
| Une modification manuelle **n'est pas détectée par Snowflake** | Seul `terraform plan` la révèle |
| `-detailed-exitcode` transforme le plan en **test** | La dérive devient une alerte, pas une découverte |
| Une dérive coûte de l'argent | 💰 `AUTO_SUSPEND` mal réglé = des crédits brûlés la nuit |
| On corrige par `apply`, jamais par ClickOps | Sinon la dérive suivante arrive le vendredi d'après |
| Un `ref` épinglé **protège du travail des autres** | Leila et Olfa n'ont rien vu de la rupture |
| Une rupture de contrat n'est **pas** une panne | Le module va bien ; c'est l'appel qui doit changer |
| Le mainteneur porte la charge du `moved` | Renommer une ressource **dans** un module casse tous ses appelants |

---

---
---

## 📝 Étape 5 — Ma ressource avancée

| Je m'appelle | Ce que je crée | Le fondement |
|---|---|---|
| **Amal** | **storage integration** + **external stage** vers ADLS Gen2 | l'identité de confiance entre deux clouds |
| **Lara** | **file format** + **stream** + **task** | la chaîne de traitement déclarée |

---

### 🟢 Amal — l'ingestion depuis Azure Data Lake

#### ① 🖱️ D'abord, à la main — les deux côtés

**Côté Azure — portail → `stglobalbankdata` → Containers → `landing`**

```
   ┌─ Ce que je dois noter ──────────────────────────────┐
   │   Compte de stockage   stglobalbankdata             │
   │   Conteneur            landing                      │
   │   URL                  abfss://landing@             │
   │                        stglobalbankdata.dfs.core.   │
   │                        windows.net/                 │
   │   Tenant ID            <GUID Entra ID>        ──── ①
   └─────────────────────────────────────────────────────┘
```

**Côté Snowflake — Snowsight → Worksheets**

```sql
CREATE STORAGE INTEGRATION GB_AZURE_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  AZURE_TENANT_ID = '<GUID Entra ID>'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('azure://stglobalbankdata.blob.core.windows.net/landing/');
```

#### ② 🔍 L'étape que personne n'oublie deux fois

```sql
DESC STORAGE INTEGRATION GB_AZURE_INT;
```

| property | value |
|---|---|
| AZURE_CONSENT_URL | `https://login.microsoftonline.com/…` |
| AZURE_MULTI_TENANT_APP_NAME | `snowflakepocXXX_1690…` |

> 🔒 **Snowflake vient de créer une application dans VOTRE annuaire Entra ID.** Il faut :
>
> 1. **ouvrir l'`AZURE_CONSENT_URL`** et donner le consentement ;
> 2. dans le portail Azure, sur le conteneur `landing`, **attribuer le rôle *Storage Blob Data Reader*** à l'application `AZURE_MULTI_TENANT_APP_NAME`.
>
> **Tant que ce rôle n'est pas donné, tout `LIST @stage` renvoie une erreur 403.** Ce n'est pas un bug : c'est Azure qui refuse, et il a raison.

> 🧠 **Aucune clé n'a été échangée.** Snowflake s'authentifie auprès d'Azure avec une **identité applicative**, pas avec un secret partagé. C'est le même principe que votre identité de service JWT de ce matin, dans l'autre sens.

**Puis le stage :**

```sql
CREATE STAGE GB_RAW_DB.LANDING.GB_AZURE_STAGE
  STORAGE_INTEGRATION = GB_AZURE_INT
  URL = 'azure://stglobalbankdata.blob.core.windows.net/landing/';

LIST @GB_RAW_DB.LANDING.GB_AZURE_STAGE;
```

#### ③ 🔁 La correspondance

| SQL | Terraform |
|---|---|
| `CREATE STORAGE INTEGRATION` | `snowflake_storage_integration` |
| `AZURE_TENANT_ID` | `azure_tenant_id` |
| `STORAGE_ALLOWED_LOCATIONS` | `storage_allowed_locations = [ … ]` |
| `CREATE STAGE … STORAGE_INTEGRATION =` | `snowflake_stage` + `storage_integration` |

#### ④ ⌨️ En Terraform

```hcl
resource "snowflake_storage_integration" "azure" {
  name                      = "${var.prefix}_AZURE_INT${local.suffix}"
  type                      = "EXTERNAL_STAGE"
  storage_provider          = "AZURE"
  azure_tenant_id           = var.azure_tenant_id
  enabled                   = true
  storage_allowed_locations = [var.storage_location]
  comment                   = "Ingestion ADLS Gen2 | ${local.owner_tag}"
}

resource "snowflake_stage" "landing" {
  name                = "${var.prefix}_AZURE_STAGE${local.suffix}"
  database            = snowflake_database.this.name
  schema              = snowflake_schema.this.name
  url                 = var.storage_location
  storage_integration = snowflake_storage_integration.azure.name
  comment             = "Zone d'atterrissage | ${local.owner_tag}"
}
```

> 🔒 **`azure_tenant_id` n'est pas un secret** — c'est un identifiant public d'annuaire. **Aucune clé de compte de stockage n'apparaît nulle part**, et c'est précisément l'intérêt de la storage integration.

> ⚠️ **Le consentement Entra ID et l'attribution du rôle restent des gestes manuels**, à refaire après toute recréation de l'intégration. **Notez-les dans le `README.md` de votre module** : c'est le genre de détail qui coûte deux heures six mois plus tard.

---

### 🟢 Lara — file format, stream et task

#### ① 🖱️ D'abord, à la main

**Snowsight → Data → `GB_CORE_DB` → `DIM` → Create → File Format**

```
   ┌─ Create File Format ────────────────────────────────┐
   │   Name              GB_CSV_FF                 ──── ①
   │   Format type       CSV                       ──── ②
   │   Field delimiter   ,                               │
   │   Skip header       1                         ──── ③
   │   Null if           NULL, \N, (vide)                │
   │   Compression       AUTO                            │
   └─────────────────────────────────────────────────────┘
```

**Puis, en SQL, le stream et la task :**

```sql
CREATE STREAM GB_DIM_STREAM ON TABLE GB_CORE_DB.DIM.DIM_CUSTOMER;

CREATE TASK GB_T_REFRESH_DIM
  WAREHOUSE = GB_INGEST_WH
  SCHEDULE  = '60 MINUTE'
  WHEN SYSTEM$STREAM_HAS_DATA('GB_DIM_STREAM')
AS
  SELECT CURRENT_TIMESTAMP();
```

> 🧠 **`WHEN SYSTEM$STREAM_HAS_DATA(...)` est la clause FinOps.** Sans elle, la task réveille le warehouse toutes les heures **même quand il n'y a rien à faire**. Avec elle, elle ne consomme que s'il y a du changement.

#### ② 🔍 Vérifiez

```sql
SHOW STREAMS IN SCHEMA GB_CORE_DB.DIM;
SHOW TASKS   IN SCHEMA GB_CORE_DB.DIM;
```

Colonne `state` : **`suspended`**. 💰 **C'est l'état attendu — une task créée est arrêtée par défaut.**

#### ③ 🔁 La correspondance

| SQL | Terraform |
|---|---|
| `CREATE FILE FORMAT … TYPE = CSV` | `snowflake_file_format` + `format_type = "CSV"` |
| `SKIP_HEADER = 1` | `skip_header = 1` |
| `CREATE STREAM … ON TABLE` | `snowflake_stream_on_table` |
| `SCHEDULE = '60 MINUTE'` | bloc `schedule` avec `minutes = 60` |
| `WAREHOUSE = GB_INGEST_WH` | `warehouse = var.ingest_warehouse` ⬅️ **le contrat avec Platform** |
| *(la task est suspendue)* | `started = false` |

#### ④ ⌨️ En Terraform

```hcl
resource "snowflake_file_format" "csv" {
  name        = "${var.prefix}_CSV_FF${local.suffix}"
  database    = snowflake_database.this.name
  schema      = snowflake_schema.this.name
  format_type = "CSV"
  skip_header = 1
  null_if     = ["NULL", "\\N", ""]
  comment     = "Format d'échange standard | ${local.owner_tag}"
}

resource "snowflake_stream_on_table" "dim" {
  name     = "${var.prefix}_DIM_STREAM${local.suffix}"
  database = snowflake_database.this.name
  schema   = snowflake_schema.this.name
  table    = snowflake_table.tables["customer"].fully_qualified_name
  comment  = "Capture des changements | ${local.owner_tag}"
}

resource "snowflake_task" "refresh_dim" {
  name          = "${var.prefix}_T_REFRESH_DIM${local.suffix}"
  database      = snowflake_database.this.name
  schema        = snowflake_schema.this.name
  warehouse     = var.ingest_warehouse        # ← fourni par Platform
  sql_statement = "SELECT CURRENT_TIMESTAMP()"
  started       = false                       # 💰 aucune consommation

  schedule {
    minutes = 60
  }
}
```

> 💰 **`started = false` reste non négociable.** Une task démarrée réveille un warehouse toutes les heures pendant tout le week-end.

> 💡 **Les noms de ressources de streams ont changé selon les versions** (`snowflake_stream` puis `snowflake_stream_on_table`). Vérifiez le Registry pour votre version.

#### ⑤ 🧠 Le fondement de l'étape — pour toute l'équipe

| Fondement | En une phrase |
|---|---|
| **Storage integration** | Une **identité de confiance** entre deux clouds — jamais une clé partagée. |
| **Le consentement Entra ID** | Un geste manuel obligatoire, à documenter dans le module. |
| **Stream** | Le changement devient une **donnée interrogeable**. |
| **`WHEN SYSTEM$STREAM_HAS_DATA`** | 💰 La task ne consomme que s'il y a du travail. |
| **`started = false`** | Une task se crée arrêtée. On la démarre en connaissance de cause. |
| **`warehouse = var.…`** | Le compute vient d'une autre équipe : c'est une variable, jamais un nom en dur. |

---
---

## 🏆 Défi autonome — 15 h 00

> **40 minutes. Chacun sur son poste. Aucune aide du formateur, sauf blocage technique.**

## L'énoncé

```
   ┌──────────────────────────────────────────────────────────────┐
   │  De : Sofia Almeida                                          │
   │  Le : vendredi, 15 h 00                                      │
   │                                                              │
   │  « L'Inspection arrive dans une heure.                       │
   │    Je veux, de chacun d'entre vous :                         │
   │                                                              │
   │    1. un plan à jour qui ne montre AUCUNE dérive ;           │
   │    2. la preuve que vos objets viennent bien de votre code ; │
   │    3. la preuve que DEV et UAT sont isolés ;                 │
   │    4. la preuve qu'aucun secret n'est dans le dépôt ;        │
   │    5. deux phrases sur ce que votre périmètre coûte. »       │
   └──────────────────────────────────────────────────────────────┘
```

## La checklist — à cocher soi-même

| # | Ce que je dois prouver | Comment |
|:---:|---|---|
| **1** | Mon code est formaté | **1 · Formater** → aucun fichier listé |
| **2** | Mon code est valide | **3 · Vérifier** → `Success!` |
| **3** | **Zéro dérive en DEV** | `envs/dev/` → **4 · Prévisualiser** → `No changes.` |
| **4** | **Zéro dérive en UAT** | `envs/uat/` → **4 · Prévisualiser** → `No changes.` |
| **5** | Mes objets existent vraiment | `SHOW … LIKE 'GB_%';` dans Snowsight |
| **6** | Mon module vient du catalogue | `source = git::…?ref=v1.0.0` — **avec un `ref`** |
| **7** | Mon state est distant | Portail Azure → mon blob → date de modification du jour |
| **8** | 🔒 **Aucun secret dans le dépôt** | `git status` propre + `.gitignore` couvrant **`secrets/` et `.env`** |
| **9** | 💰 Mes ressources sont sobres | Warehouses X-SMALL suspendus · tasks `started = false` |
| **10** | Mon contrat est publié | `terraform output` renvoie quelque chose d'utile à un collègue |

### 🔒 Le contrôle n°8 en détail — le seul qui est éliminatoire

Votre `.gitignore` doit contenir **au minimum** :

```gitignore
# secrets
secrets/            # ← écrit par Learner-Login.ps1 : SP + PAT EN CLAIR
.env                # ← valeurs personnelles
*.tfvars
!example.tfvars
profiles.yml

# state — contient TOUS les attributs en clair
terraform.tfstate
terraform.tfstate.*
.terraform.tfstate.lock.info

# plans — contiennent les valeurs réelles
*.tfplan
tfplan
plan.json

# artefacts locaux
.terraform/
crash.log
```

**Puis, dans le terminal intégré :**

```
git status
```

> 🔴 **Si `git status` liste `secrets/`, `.env`, un `.tfvars`, un `.tfstate`, un `tfplan` ou un `profiles.yml`, votre capstone est bloqué** jusqu'à correction — c'est la règle du parcours depuis lundi. **Un secret exposé n'est pas une pénalité de points : c'est un arrêt.**
>
> ⚠️ **Et si un secret a déjà été committé cette semaine**, l'ajouter au `.gitignore` **ne suffit pas** : il reste dans l'historique. Il faut le **révoquer** — c'est ce que nous ferons au cleanup pour les PAT.

## La grille d'évaluation — 100 points

| Domaine | Points | Ce qui est regardé |
|---|---:|---|
| **Structure et qualité Terraform** | 20 | `fmt`, `validate`, nommage, fichiers séparés, `description` |
| **State, idempotence et dérive** | 15 | Backend distant, `No changes.` sur les deux environnements |
| **Modularité et environnements** | 15 | `source` versionné avec `ref`, DEV/UAT isolés, zéro nom en dur |
| **RBAC et sécurité** | 20 | Moindre privilège, test négatif réussi, aucun secret dans le dépôt |
| **Pipeline Azure DevOps** | 10 | La CI bloque un code non conforme, l'approbation est active |
| **FinOps et Data Products** | 10 | Warehouses sobres, monitor rattaché, un indicateur interprété |
| **Documentation et démonstration** | 10 | `README.md` du module, contrat `output`, soutenance claire |
| **Total** | **100** | **Seuil de validation : 75** |

> 🔴 **Un secret exposé ou un contrôle de sécurité non résolu bloque la validation jusqu'à correction**, quel que soit le total.

---
---

# 🎤 LA SOUTENANCE — 15 h 40

> **Trois minutes par personne. Onze personnes. Le formateur chronomètre.**

## Les quatre phrases

Chacun, à l'écran, dans cet ordre :

| # | Ce que je dis | Ce que je montre |
|:---:|---|---|
| **1** | *« Je possède **X**, et voici le fichier qui le décrit. »* | Le `.tf`, puis l'objet dans Snowsight |
| **2** | *« Je consomme **Y**, fourni par **Z**. »* | La `variable` ou le `module` correspondant |
| **3** | *« Mon plan est sans dérive, sur les deux environnements. »* | Les deux `No changes.` |
| **4** | *« Mon périmètre coûte environ **N** crédits par semaine. »* | Le modèle FinOps de l'équipe BI |

## Le moment collectif — les onze en même temps

> 🎤 **« Tout le monde dans `envs/dev/`. À trois : quatre. Prévisualiser. »**

```
   No changes.  No changes.  No changes.  No changes.
   No changes.  No changes.  No changes.  No changes.
   No changes.  No changes.  No changes.

   ➡️  ONZE FOIS "No changes."
```

> 🏆 **C'est la réponse à l'Inspection Générale.** Onze personnes, une plateforme, deux environnements, un catalogue de cinq modules versionnés — et **aucun écart entre ce qui est écrit et ce qui existe**.
>
> **Ce n'est pas une démonstration technique. C'est une preuve d'audit.**

---
---

## 🧹 Nettoyage — 15 h 50

> ⚠️ **L'ordre compte.** Un objet consommé par un collègue ne se détruit pas en premier.

## L'ordre imposé

| # | Qui | Quoi | Pourquoi cet ordre |
|:---:|---|---|---|
| **1** | 🟣 BI · 🟠 Business | `envs/uat/` → `terraform destroy` | Les marts et domaines UAT ne servent à personne d'autre |
| **2** | 🟢 Data Eng | `envs/uat/` → `terraform destroy` | Après ses consommateurs |
| **3** | 🔵 Platform | `envs/uat/` → `terraform destroy` | **En dernier** — c'est lui qui fournit rôles et compute |
| **4** | *(tous)* | Répéter dans le même ordre pour `envs/dev/` | Idem |

```
   terraform destroy
```

```text
Plan: 0 to add, 0 to change, 5 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

> 🧠 **Lisez le plan de destruction comme vous lisez un plan de création.** C'est la dernière occasion de la semaine de vérifier que vous ne détruisez que ce qui vous appartient.

## Le cleanup côté Azure

| # | Action | Où |
|:---:|---|---|
| 1 | Supprimer les blobs de state | Portail → conteneur `tfstate` |
| 2 | Supprimer le conteneur de démonstration `landing` | Portail → `stglobalbankdata` |
| 3 | Désactiver le secret `snowflake-tf-private-key` | Key Vault → Secrets → *Disable* |
| 4 | Supprimer la service connection du pipeline | Azure DevOps → Project settings |

## 🔒 Le cleanup des identités — à ne pas oublier

```sql
-- 1. révoquer les PAT personnels utilisés du lundi au jeudi
SHOW USER PROGRAMMATIC ACCESS TOKENS;
-- puis, pour chacun :
ALTER USER <MOI> REMOVE PROGRAMMATIC ACCESS TOKEN <NOM_DU_TOKEN>;

-- 2. neutraliser l'utilisateur de service
ALTER USER SVC_GLOBALBANK_TF UNSET RSA_PUBLIC_KEY;
ALTER USER SVC_GLOBALBANK_TF SET DISABLED = TRUE;
```

**Puis, sur chaque poste : supprimez le dossier `secrets/`** — c'est là que `Learner-Login.ps1` a écrit, **en clair**, le secret du service principal Azure et votre PAT Snowflake.

```powershell
Remove-Item -Recurse -Force .\secrets
```

> 🔒 **Un secret non révoqué reste un secret actif.** Supprimer un fichier ne révoque rien : le jeton continue d'exister côté Snowflake jusqu'à ce qu'on le retire explicitement. **C'est la dernière leçon de sécurité de la semaine, et ce n'est pas la moins importante.**

## La vérification finale

```sql
SHOW DATABASES LIKE 'GB_%';
SHOW WAREHOUSES LIKE 'GB_%';
SHOW ROLES LIKE 'GB_%';
```

**Trois résultats vides.** Ce qui reste doit être **explicitement justifié** au tableau : par qui, pourquoi, jusqu'à quand.

---
---

## 🃏 Anti-sèche

```hcl
# ── Le catalogue de modules ──────────────────────────────
module "x" {
  source = "git::https://<hote>/<org>/_git/<depot>//<module>?ref=v1.0.0"
}
#                                              ▲        ▲
#                          le sous-dossier ────┘        └── OBLIGATOIRE
# init après tout changement de ref  ·  init -upgrade si le tag a bougé
```

```
# ── Le plan immuable ─────────────────────────────────────
terraform plan -out=tfplan -input=false          # fige les actions
terraform show tfplan               # lire
terraform show -json tfplan         # pour la CI
terraform apply tfplan              # applique EXACTEMENT ce plan
# "Saved plan is stale" = le state a bougé depuis  →  replanifier

# ── La détection de dérive ───────────────────────────────
terraform plan -detailed-exitcode   # 0 = OK · 1 = erreur · 2 = DÉRIVE

# ── Le verrou (rappel du J4) ─────────────────────────────
# "Error acquiring the state lock" → lire Who → aller lui parler
```

```hcl
# ── L'identité de service ────────────────────────────────
provider "snowflake" {
  user          = var.snowflake_service_user
  authenticator = "SNOWFLAKE_JWT"
  private_key   = var.snowflake_private_key   # ← via TF_VAR_, jamais un fichier
}
# rotation : SET RSA_PUBLIC_KEY_2  →  bascule  →  UNSET RSA_PUBLIC_KEY
```

```sql
-- ── Les droits qui tiennent dans le temps ───────────────
GRANT SELECT ON FUTURE TABLES IN SCHEMA <db>.<sc> TO ROLE <role>;
SHOW FUTURE GRANTS IN SCHEMA <db>.<sc>;   -- SHOW GRANTS ne les montre PAS
GRANT ROLE <acces> TO ROLE <fonctionnel>; -- l'héritage

-- ── FinOps ──────────────────────────────────────────────
SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY   -- les crédits
SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
-- latence 45 min à 3 h  ·  GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE
```

---

## 🔧 Si ça coince

| Symptôme | Cause probable | Correction |
|---|---|---|
| `Saved plan is stale` | Le state a changé depuis le `plan` | Replanifier — **ne jamais forcer** |
| `Module not installed` | `ref` modifié sans `init` | **2 · Initialiser** |
| `Could not download module` | Authentification Git absente | Se connecter au dépôt dans VS Code |
| `Unsupported argument` après une montée de version | 💥 **Breaking change** | Corriger l'appel, ou revenir au `ref` précédent |
| `JWT token is invalid` | Clé publique absente ou mal collée | `DESC USER` · vérifier `RSA_PUBLIC_KEY` |
| `Invalid PAT` alors que rien n'a changé | Le cache `secrets/` masque un secret renouvelé dans Key Vault | **Supprimer `secrets/`** puis relancer `Learner-Login.ps1` |
| `403` sur `LIST @stage` | Consentement Entra ID ou rôle Azure manquant | Rejouer `AZURE_CONSENT_URL` + *Storage Blob Data Reader* |
| `Object does not exist` sur `ACCOUNT_USAGE` | Privilèges importés manquants | `GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE` |
| Une vue FinOps est vide | ⏱️ Latence `ACCOUNT_USAGE` | Attendre — ce n'est pas une panne |
| Le pipeline échoue sur `fmt` | 🛡️ **Ce n'est pas une panne** — la CI fait son travail | **1 · Formater**, committer |
| `Insufficient privileges` avec `GB_ANALYST` | 🛡️ **Ce n'est pas une panne** — le moindre privilège fonctionne | C'est le résultat attendu du test négatif |

---

## 🎓 Après la formation — les cinq gestes du lundi

| # | Le geste | Pourquoi c'est le bon ordre |
|:---:|---|---|
| **1** | Mettre le **state sur un backend distant** | Rien d'autre n'est possible sans lui |
| **2** | Épingler **tous** les `source` et `version` | Un build non reproductible n'est pas un build |
| **3** | Faire passer le `plan` **par une revue** | Le plan immuable + l'approbation |
| **4** | Sortir les secrets vers un **coffre** | Puis **révoquer** ce qui traînait |
| **5** | Brancher **un** indicateur FinOps | Un seul, mais lu chaque lundi par une personne nommée |

> 🎯 **Ce que vous emportez n'est pas une syntaxe** — elle changera avec la prochaine version du provider. **C'est une méthode :** regarder l'objet à la main, comprendre ce qu'il est, l'écrire en code, lire le plan, prouver l'idempotence. **Cette méthode fonctionne avec n'importe quel provider, sur n'importe quel cloud.**

---

*Jour 5 — GlobalBank Data Platform · ODDO BHF · fin du parcours*