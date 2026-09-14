# Troubleshooting — M1

> [<- Jour 1](../README.md) · [<- Jour 0](../../day-00/README.md) · **Module 1** · [Module suivant ->](../module-02-state-management/lab.md)

| Symptôme | Diagnostic non destructif | Correction minimale | Prévention |
|---|---|---|---|
| Module M1 introuvable | Lister `student-track/module-01-*` | Utiliser la version refondue du dépôt | Préflight du catalogue |
| Workspace existe déjà | Vérifier le chemin affiché | Choisir un autre `WorkspaceRoot` | Ne jamais supprimer automatiquement |
| Branche créée au mauvais endroit | `git rev-parse --show-toplevel` | Recréer sous `$HOME/Data2AI-Labs` | Workspace hors dépôt du cours |
| Provider non trouvé | Lire `versions.tf`, tester accès registry | Corriger source/version puis `terraform init` | Checkpoint 1 |
| Profil Snowflake absent | `snow connection test -c terraform_svc` | Refaire le checkpoint M0 | Ne pas ajouter un password au provider |
| `Invalid account` | Tester le même profil avec Snow CLI | Corriger la configuration locale | Une seule source de connexion |
| Permission insuffisante | `SELECT CURRENT_ROLE()` puis erreur exacte | Demander le rôle sandbox prévu | Ne pas basculer génériquement sur ACCOUNTADMIN |
| Préfixe refusé | Lire le message de validation | Utiliser 2-12 caracteres majuscules/chiffres/underscore | Validation de variable |
| Resource already exists | Vérifier le préfixe et `terraform state list` | Les ressources existent déjà (test formateur). Changer de `LEARNER_PREFIX` (ex. APP01 -> APP01B) ou supprimer les ressources existantes pour refaire l'exercice de création | Préfixe unique par apprenant |
| `terraform fmt -check` échoue | `terraform fmt -diff` | Exécuter `terraform fmt` | Format avant chaque plan |
| Plan contient delete | `terraform show m01.tfplan` | Arrêter; vérifier workspace, state et préfixe | Revue obligatoire |
| Plan contient plus de 3 créations | Lire les adresses | Comparer `main.tf` au lab | Checkpoint structurel |
| Warehouse démarre à consommer | `SHOW WAREHOUSES` | Suspendre le warehouse si aucune requête n'est nécessaire | Initially suspended + auto-suspend |
| Second plan non vide | Lire l'attribut modifié | Corriger code ou drift intentionnellement | Ne pas appliquer sans comprendre |

## Resource already exists - Détail

L'objectif de M1 est de **créer** les ressources. Si elles existent déjà, deux options :

### Option A - Changer de préfixe (recommandé)

Modifiez `LEARNER_PREFIX` dans votre `.env` et `terraform.tfvars` :

```text
LEARNER_PREFIX=APP01B   # au lieu de APP01
```

> `[IMPORTANT]` Vous devez **aussi** mettre a jour `terraform.tfvars` dans `environments/dev/` :
> ```hcl
> learner_prefix = "APP01B"   # meme valeur que LEARNER_PREFIX dans .env
> ```
> Terraform lit les variables depuis `terraform.tfvars`, pas depuis `.env`.
> Si le plan affiche encore l'ancien prefixe, c'est que `terraform.tfvars` n'a pas ete mis a jour.

Relancez `terraform plan -out "m01.tfplan"` puis `terraform apply "m01.tfplan"`.

Vous créez ainsi vos propres ressources avec un préfixe unique.

### Option B - Supprimer les ressources existantes

Si le formateur vous autorise à nettoyer :

```bash
snow sql -c training -q "DROP DATABASE IF EXISTS APP01_RAW_DEV"
snow sql -c training -q "DROP WAREHOUSE IF EXISTS WH_APP01_ETL_DEV"
```

Puis relancez `terraform plan` et `terraform apply`.

> L'import de ressources existantes est couvert au **M3** (import-brownfield).
> Ne pas utiliser `terraform import` en M1.

## `terraform plan` demande `var.snowflake_token`

**Symptome :**

```text
var.snowflake_token
  Snowflake PAT (read from secrets/snowflake_pat.txt)

  Enter a value:
```

**Cause :**

Le PAT n'est pas accessible. Le `provider.tf` lit `secrets/snowflake_pat.txt`
automatiquement, mais le fichier n'existe pas ou est vide.

**Correction :**

```powershell
# 1. Verifier que le PAT file existe
cd "$HOME\Data2AI-Labs\data-platform"
Test-Path secrets\snowflake_pat.txt

# 2. Si absent, recreer la connexion Snowflake
.\scripts\New-SnowflakeConnection.ps1

# 3. Relancer Learner-Login (set TF_VAR_snowflake_token)
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01

# 4. Pre-flight check
cd environments\dev
..\..\scripts\Test-TerraformReady.ps1

# 5. Si READY, relancer terraform plan
terraform plan -out "m01.tfplan"
```

> Si le pre-flight affiche `READY` mais terraform plan demande encore le token,
> settez la variable manuellement :
> ```powershell
> $env:TF_VAR_snowflake_token = (Get-Content ..\..\secrets\snowflake_pat.txt -Raw).Trim()
> ```

---

## `Test-TerraformReady.ps1` affiche `[FAIL] LEARNER_PREFIX not set` ou `[FAIL] ARM_SUBSCRIPTION_ID not set`

**Symptome :**

```text
[FAIL] LEARNER_PREFIX not set. Run: .\scripts\Learner-Login.ps1 -LearnerPrefix APP01
[FAIL] ARM_SUBSCRIPTION_ID not set. Run: .\scripts\Learner-Login.ps1 -LearnerPrefix APP01
```

**Cause :**

Les variables d'environnement ne persistent pas entre les sessions PowerShell.
Si vous ouvrez un nouveau terminal ou redemarrez la VM, les variables `LEARNER_PREFIX`,
`ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, etc. ne sont plus definies.

**Correction :**

Relancez `Learner-Login.ps1` dans **le meme terminal** que celui ou vous lancez
`Test-TerraformReady.ps1` et `terraform plan` :

```powershell
cd "$HOME\Data2AI-Labs\data-platform"
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01
cd labs\m01-iac-workflow
..\..\scripts\Test-TerraformReady.ps1
```

> `[IMPORTANT]` Vous devez relancer `Learner-Login.ps1` au debut de **chaque session**
> (nouveau terminal, redemarrage VM). Les variables d'environnement ne persistent pas.

---

## `Test-TerraformReady.ps1` affiche `[WARN] TF_VAR_snowflake_token not set`

**Symptome :**

```text
[WARN] TF_VAR_snowflake_token not set (OK - provider.tf reads PAT file directly)
```

**Cause :**

Ce n'est **pas une erreur**. Le `provider.tf` lit le PAT directement depuis
`secrets/snowflake_pat.txt`. La variable `TF_VAR_snowflake_token` est optionnelle.

**Action :**

Aucune action requise. Le WARN n'empeche pas `terraform plan` de fonctionner.
Si `terraform plan` demande quand meme le token, verifiez que le fichier
`secrets/snowflake_pat.txt` existe et n'est pas vide (voir section ci-dessus).

---

## `Test-TerraformReady.ps1` affiche `[FAIL] Terraform found but 'terraform version' failed`

**Symptome :**

```text
[FAIL] Terraform found but 'terraform version' failed (exit 1)
       Output: <message d'erreur>
```

**Cause :**

Terraform est installe mais n'est pas accessible correctement dans le PATH de la
session courante, ou l'executable est corrompu.

**Correction :**

1. Testez terraform avec le chemin complet :

```powershell
& "$HOME\.data2ai\bin\terraform.exe" version
```

2. Si cela fonctionne, le probleme vient du PATH. Relancez `Learner-Login.ps1`
   qui met a jour le PATH pour la session :

```powershell
cd "$HOME\Data2AI-Labs\data-platform"
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01
```

3. Si terraform n'est pas installe, relancez `Install-Tools.ps1` :

```powershell
.\scripts\Install-Tools.ps1
```

---

## `Private Key authentication requires authenticator set to SNOWFLAKE_JWT`

**Symptome :**

```text
Private Key authentication requires authenticator set to SNOWFLAKE_JWT
```

**Cause :**

La variable d'environnement `SNOWFLAKE_PRIVATE_KEY_FILE` est definie dans la session.
Le Snowflake CLI et le provider Terraform lisent les variables `SNOWFLAKE_*` comme
des overrides de connexion. Quand `SNOWFLAKE_PRIVATE_KEY_FILE` est present, le mode
d'authentification est force en JWT (cle privee) au lieu de PAT.

Cette variable est necessaire a partir du Jour 4 uniquement.

**Correction :**

```powershell
# Supprimer la variable pour cette session
Remove-Item Env:\SNOWFLAKE_PRIVATE_KEY_FILE
Remove-Item Env:\SNOWFLAKE_PRIVATE_KEY_PATH -ErrorAction SilentlyContinue
Remove-Item Env:\SNOWFLAKE_PRIVATE_KEY -ErrorAction SilentlyContinue

# Verifier
snow sql -q 'SELECT 1' -c training
```

Pour la correction permanente, voir `troubleshooting.md` entree 33 (Jour 0).

---

## `Reset-Lab.ps1` : erreur de parse `Le terminateur ' est manquant`

**Symptome :**

```text
Au caractère ...Reset-Lab.ps1:209 : 29
+ Write-Host '  terraform plan' -ForegroundColor DarkGray
+                             ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Le terminateur ' est manquant dans la chaîne.
```

**Cause :**

Une ancienne version du script contenait des caracteres em dash (`—`) dans des
chaines de caracteres. PowerShell 5.1 sur Windows en francais interprete mal ces
caracteres UTF-8, causant une erreur de parse.

**Correction :**

```powershell
cd "$HOME\Data2AI-Labs\data-platform"
git pull origin main
```

La version corrigee remplace les em dashes par des tirets simples.

---

## `snow sql` echoue avec `Private Key authentication requires authenticator set to SNOWFLAKE_JWT`

Voir la section dediee ci-dessus. La cause est la variable `SNOWFLAKE_PRIVATE_KEY_FILE`
definie dans la session. Les scripts `New-SnowflakeConnection.ps1` et
`Test-LabConnectivity.ps1` suppriment automatiquement cette variable, mais si vous
lancez `snow sql` manuellement, vous devez la supprimer vous-meme.

---

## Execution policy PowerShell

**Symptome :**

```text
Impossible de charger le fichier ...ps1, car l'execution de scripts est desactivee.
```

**Cause :** La politique d'execution PowerShell est reglee sur `Restricted`.

**Correction :**

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

> `RemoteSigned` autorise les scripts locaux. C'est le parametre standard pour un poste de formation.

**Alternative ponctuelle :**

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\<script-name>.ps1
```

## Informations à communiquer pour obtenir de l'aide

- OS et shell;
- chemin retourné par `pwd`/`Get-Location`;
- version Terraform et provider;
- adresse de ressource concernée;
- message d'erreur expurgé.

Ne communiquez jamais `terraform.tfvars`, un PAT, une clé privée, un state ou la configuration Snowflake complète.

---

## ❌ `Object already exists` in Snowflake

**Symptom** : `terraform plan` ou `terraform apply` échoue avec :

```
Error: Object does not exist or not authorized
```

ou

```
Error: Object already exists
```

**Cause** : Une exécution précédente du lab a créé des ressources qui n'ont pas été nettoyées.

**Fix** :

🪟 **Windows (PowerShell)** :

```powershell
cd "$HOME\Data2AI-Labs\data-platform"
.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M01
```

🐧 **Linux/macOS (Bash)** :

```bash
cd "$HOME/Data2AI-Labs/data-platform"
./scripts/reset-lab.sh --learner-prefix APP01 --lab M01
```

Remplacez `M01` par le numéro du lab (M01, M05, etc.) et `APP01` par votre préfixe.

> 💡 **Note** : `Reset-Lab.ps1` ne détruit que les ressources du lab spécifié. Les autres labs ne sont pas affectés.

---

## ❌ `Duplicate output/variable/resource definition`

**Symptom** : `terraform validate` ou `terraform plan` échoue avec :

```
Error: Duplicate output definition
```

ou

```
Error: Duplicate variable definition
```

**Cause** : Vous avez ajouté un bloc qui existe déjà, ou vous travaillez dans le mauvais répertoire.

**Fix** :

1. Vérifiez que vous êtes dans le bon répertoire :

   ```powershell
   pwd  # doit afficher labs/m01-name/
   ```

2. Si vous êtes dans `environments/dev/`, vous êtes dans l'ancienne structure. Déplacez-vous vers `labs/m01-name/`.

3. Si le fichier contient des doublons, **remplacez tout le contenu** au lieu d'ajouter à la fin.
