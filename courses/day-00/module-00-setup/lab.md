# ðŸ§ª Lab M00 â€” PrÃ©parer votre environnement de formation

> [<- Jour 0](../README.md) Â· **M00 Setup** Â· [Jour 1 ->](../../day-01/module-01-iac-workflow/lab.md)

| Ã‰lÃ©ment | Valeur |
|---|---|
| **DurÃ©e** | 1 h 30 |
| **Piste** | `[CORE]` |
| **Workspace** | `$HOME/Data2AI-Labs/data-platform` (le clone du projet type) |
| **CoÃ»t EstimÃ©** | $0 (aucune ressource cloud crÃ©Ã©e) |
| **Certifications** | HashiCorp Terraform Associate Â· Snowflake SnowPro Â· Azure AZ-104 |
| **Cleanup** | Conservation obligatoire â€” base de tous les modules suivants |

---

## ðŸŽ¯ 1. Mission MÃ©tier & User Story

> **En tant que :** Cloud Data Engineer en formation
> **Je veux :** prÃ©parer et valider mon environnement de travail (toolchain, credentials, connexions)
> **Afin de :** garantir que tous les labs M01 Ã  M14 s'exÃ©cutent sans friction technique

---

## ðŸ—ï¸ 2. Architecture & ModÃ¨le Mental

```mermaid
flowchart LR
    DEV["ðŸ§‘â€ðŸ’» Apprenant"] -->|"1. git clone"| REPO["ðŸ“¦ data-platform-starter"]
    REPO -->|"2. Install-Tools"| TOOLS["âš™ï¸ Toolchain: Terraform, Snow CLI, Azure CLI, dbt"]
    REPO -->|"3. Learner-Login"| AZURE["â˜ï¸ Azure SP + Key Vault PAT"]
    REPO -->|"4. New-SnowflakeConnection"| SNOW["â„ï¸ Snowflake CLI -c training"]
    TOOLS --> VERIFY["âœ… Test-LabConnectivity: READY"]
    SNOW --> VERIFY
    AZURE --> VERIFY
```

---

## ðŸŽ¯ 3. Objectifs PÃ©dagogiques VÃ©rifiables

- âœ… le **projet type** est clonÃ© sous `$HOME/Data2AI-Labs/data-platform`;
- âœ… Git, Terraform, Snowflake CLI, Azure CLI et dbt sont disponibles dans le terminal;
- âœ… la connexion Snowflake `training` rÃ©pond Ã  `snow sql -q 'SELECT 1' -c training`;
- âœ… Azure est authentifiÃ© via le service principal partagÃ©;
- âœ… la connexion aux consoles web (Snowsight + Azure Portal) est confirmÃ©e;
- âœ… la validation finale affiche `Toolchain status: READY`.

---

## ðŸš€ 4. Pre-Flight Diagnostic (VÃ©rification Initiale)

> **Toutes les commandes s'exÃ©cutent depuis la racine du clone** (`$HOME/Data2AI-Labs/data-platform`).

### Si votre VM a des outils prÃ©installÃ©s (vÃ©rification rapide)

> `[IMPORTANT]` Si vous travaillez sur une **VM prÃ©configurÃ©e** (outils dÃ©jÃ  installÃ©s
> par le formateur), commencez par vÃ©rifier l'installation existante **avant** de
> lancer l'installation. Le prÃ©flight est **non destructif** : il n'installe rien.

```powershell
# VÃ©rification des outils uniquement (avant configuration .env / Azure / Snowflake)
.\scripts\Test-VMReadiness.ps1 -SkipConnectivity
```

**RÃ©sultat attendu si les outils sont corrects :**

```text
Status: READY
```

- âœ… Si tous les outils sont en `PASS` â†’ **sautez l'Ã©tape 5.1** (installation) et passez directement Ã  l'Ã©tape 5.2 (configuration `.env`).
- âŒ Si un ou plusieurs outils sont en `FAIL` â†’ suivez l'Ã©tape 5.1 normale ci-dessous (`Install-Tools.ps1`), puis relancez le prÃ©flight.

Une fois `.env` configurÃ© et `Learner-Login` exÃ©cutÃ©, lancez le prÃ©flight complet :

```powershell
.\scripts\Test-VMReadiness.ps1 -LearnerPrefix APP01
```

> Remplacez `APP01` par votre prÃ©fixe. Le rapport consolidÃ© est Ã©crit dans
> `reports/vm-readiness.md`. Aucun secret n'y apparaÃ®t.

### Cloner le projet type (5 min)

Le projet type est le dÃ©pÃ´t `data-platform-starter`. Il contient les scripts d'installation, la structure de gouvernance et les validateurs. **C'est votre racine de travail pour toute la formation.**

Le dÃ©pÃ´t du projet type est : `https://github.com/msellamiTN/data-platform-starter.git`

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
New-Item -ItemType Directory -Path "$HOME\Data2AI-Labs" -Force | Out-Null
git clone https://github.com/msellamiTN/data-platform-starter.git "$HOME\Data2AI-Labs\data-platform"
cd "$HOME\Data2AI-Labs\data-platform"
```

> **IMPORTANT** Sous Windows, ne pas utiliser `~` (tilde) dans le chemin de clone.
> PowerShell ne l'interprete pas comme le dossier personnel. Utilisez `$HOME` entre guillemets.
> Si le repertoire contient des espaces (ex. `Formation Terraform`), encadrez toujours le chemin.
</details>

<details>
<summary>Linux/macOS (Bash)</summary>

```bash
mkdir -p "$HOME/Data2AI-Labs"
git clone https://github.com/msellamiTN/data-platform-starter.git "$HOME/Data2AI-Labs/data-platform"
cd "$HOME/Data2AI-Labs/data-platform"
```
</details>

### VÃ©rifier que les scripts sont prÃ©sents

```bash
Get-ChildItem scripts/
```

âœ… **Checkpoint 0 :**

```text
Install-Tools.ps1
install-tools.sh
New-SnowflakeConnection.ps1
new-snowflake-connection.sh
Learner-Login.ps1
learner-login.sh
Test-LabConnectivity.ps1
test-lab-connectivity.sh
validate.ps1
validate.sh
```

> Ã€ partir d'ici, **toutes les commandes s'exÃ©cutent depuis la racine du clone**.

---

### Ordre d'exÃ©cution des scripts

> `[IMPORTANT]` L'ordre des scripts est important. Suivez cette sÃ©quence exacte.

| # | Script | Quand | Action |
|---|---|---|---|
| 0 | `Set-ExecutionPolicy` | Une seule fois | Autorise les scripts PowerShell (Windows) |
| 1 | `Install-Tools.ps1` | Une seule fois | Installe Terraform, Snow CLI, dbt, tflint |
| 2 | `Learner-Login.ps1` | **Chaque session** | Login Azure + rÃ©cupÃ¨re le PAT depuis Key Vault + Ã©crit `secrets/shared-sp.txt` + `secrets/snowflake_pat.txt` + set `TF_VAR_snowflake_token` |
| 3 | `New-SnowflakeConnection.ps1` | Une seule fois | Configure Snow CLI (lit le PAT depuis `secrets/snowflake_pat.txt` crÃ©Ã© par Learner-Login) |
| 4 | `Test-LabConnectivity.ps1` | VÃ©rification | Valide tous les accÃ¨s (Snowflake + Azure + Git + Terraform) |
| - | `Test-VMReadiness.ps1` | Diagnostic | VÃ©rifie outils + config + connectivitÃ© (non destructif, voir Pre-Flight ci-dessus) |

```powershell
# 0. Autoriser les scripts (une seule fois, Windows seulement)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 1. Installer les outils (une seule fois)
.\scripts\Install-Tools.ps1

# 2. Login Azure + rÃ©cupÃ©rer les secrets depuis Key Vault (chaque session)
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01

# 3. Configurer Snowflake (une seule fois, aprÃ¨s Learner-Login)
.\scripts\New-SnowflakeConnection.ps1

# 4. VÃ©rifier tout
.\scripts\Test-LabConnectivity.ps1 -SkipDevOps
```

> `[IMPORTANT]` `Learner-Login.ps1` rÃ©cupÃ¨re le PAT depuis **Azure Key Vault**
> (secret partagÃ© `SnowflakePAT`) et l'Ã©crit dans `secrets/snowflake_pat.txt`.
> Si Key Vault est inaccessible, le PAT peut Ãªtre saisi manuellement via `New-SnowflakeConnection.ps1`.
> Sans cela, `terraform plan` vous demandera `var.snowflake_token` manuellement.

> `[WINDOWS]` Si vous obtenez l'erreur `l'exÃ©cution de scripts est dÃ©sactivÃ©e`,
> autorisez les scripts locaux une seule fois :
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```
>
> `RemoteSigned` est le paramÃ¨tre standard pour un poste de formation.
> Il autorise les scripts locaux mais bloque les scripts tÃ©lÃ©chargÃ©s non signÃ©s.
>
> `[NOTE]` Si vous voyez le message *"ce paramÃ©trage est remplacÃ© par une stratÃ©gie
> dÃ©finie dans un contexte plus spÃ©cifique"* et que votre stratÃ©gie actuelle est
> `Bypass`, **c'est normal et sans consÃ©quence**. La VM de formation a dÃ©jÃ 
> `Bypass` actif (qui autorise tout). La commande `Set-ExecutionPolicy` n'a aucun
> effet dans ce cas, mais vous n'en avez pas besoin â€” vos scripts fonctionneront.
> VÃ©rifiez avec :
> ```powershell
> Get-ExecutionPolicy -List
> ```

---

## ðŸ“ 5. Ã‰tapes d'ImplÃ©mentation Pas-Ã -Pas (80% Hands-On)

### ðŸ“ Ã‰tape 5.1 â€” Installer et vÃ©rifier les outils (20 min)

Le Jour 0 est **automatise**. Vous executez les scripts qui se trouvent dans le clone, puis vous lisez le rapport.

- **Windows** : `scripts/Install-Tools.ps1`
- **Linux/macOS** : `scripts/install-tools.sh`

Les deux scripts ont le mÃªme contrat : mÃªmes versions, mÃªmes vÃ©rifications, mÃªme format de rapport.

#### Diagnostic initial

Executez le script en mode `Check` pour voir l'etat actuel sans rien installer :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1 -Check -ReportPath .\preflight
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh --check --report-path ./preflight
```
</details>

**Checkpoint** : un rapport s'affiche et deux fichiers sont crees (`preflight.md` et `preflight.json`). Les outils deja installes sont en `PASS`, les autres en `FAIL` ou `WARN`.

#### Installation

> `[NOTE]` Le script installe automatiquement Python 3.12 via `winget` si nÃ©cessaire.
> Si votre systÃ¨me a Python 3.13+ ou 3.14, le script installe Python 3.12 en parallÃ¨le
> et l'utilise pour crÃ©er le venv. Vous n'avez pas besoin d'installer Python 3.12 manuellement.
> Si un ancien venv existe avec la mauvaise version de Python, le script le dÃ©tecte,
> le supprime et le recrÃ©e avec Python 3.12.

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1 -ReportPath .\preflight
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/install-tools.sh --report-path ./preflight
```
</details>

**Checkpoint** : le script installe les outils manquants sous `$HOME/.data2ai`. Les outils Python (Snow CLI, dbt) sont installes dans un environnement virtuel isole **avec Python 3.12**. Le rapport final indique `Toolchain status: READY`.

> Si le rapport affiche `WARN` pour Python (ex. "Found Python 3.14, policy requires 3.12"),
> ce n'est pas bloquant : le script a installÃ© Python 3.12 en parallÃ¨le et l'utilise
> pour le venv. Le `WARN` indique seulement que `python` (sans version) pointe encore
> vers 3.14. Pour corriger, rouvrez le terminal ou rÃ©installez Python 3.12 avec
> l'option "Add python.exe to PATH".

#### Corriger les Ã©checs

Si un outil est en `FAIL`, le rapport affiche la procedure manuelle officielle. Suivez-la, puis relancez :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1 -Check
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/install-tools.sh --check
```
</details>

#### Rouvrir le terminal

Si une commande reste introuvable apres l'installation, fermez et rouvrez le terminal pour rafraichir le `PATH`.

<details>
<summary>ðŸ§ <b>Linux/macOS â€” si le PATH ne persiste pas</b></summary>

```bash
export PATH="$HOME/.data2ai/bin:$HOME/.data2ai/venv/bin:$PATH"
```

Ajoutez cette ligne a votre `~/.bashrc` ou `~/.zshrc` pour la persistence.
</details>

#### VÃ©rifier les versions

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
terraform version
snow --version
az version
python --version
dbt --version
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
terraform version
snow --version
az version
python3 --version
dbt --version
```
</details>

**Checkpoint** : chaque commande retourne une version. Les versions doivent correspondre a la [politique de versions](../../../docs/version-policy.md).

#### Comprendre ce que le script a fait

Repondez a ces questions pour valider votre comprehension :

1. **Ou sont installes Terraform et tflint ?**
   - Windows : `$HOME\.data2ai\bin`
   - Linux/macOS : `$HOME/.data2ai/bin`

2. **Ou sont installes Snow CLI et dbt ?**
   - Dans un environnement virtuel Python isole sous `$HOME/.data2ai/venv`.

3. **Comment le PATH a-t-il ete modifie ?**
   - Windows : le dossier `$HOME\.data2ai\bin` a ete ajoute au PATH utilisateur.
   - Linux/macOS : le script affiche l'instruction `export PATH=...` a ajouter a votre profil shell.

4. **Pourquoi un environnement virtuel isole avec Python 3.12 ?**
   - Pour eviter les conflits avec d'autres projets Python sur votre poste et garantir des versions reproductibles.
   - Python 3.12 est la version requise par la politique de versions. Les packages comme `cffi` et `pyyaml` n'ont pas de wheels pre-compilÃ©s pour Python 3.14 sur Windows â€” utiliser 3.12 evite les echecs de compilation.

---

### ðŸ“ Ã‰tape 5.2 â€” Configurer votre fichier `.env` (10 min)

> `[IMPORTANT]` **Cette Ã©tape DOIT Ãªtre terminÃ©e AVANT les Ã©tapes 5.3 et 5.4.**
> Les scripts `New-SnowflakeConnection.ps1` et `Learner-Login.ps1` lisent `.env`.
> Sans `.env`, ils affichent un avertissement et ne fonctionnent pas correctement.

Le formateur a prÃ©-rempli `.env.example` avec les paramÃ¨tres d'accÃ¨s Snowflake, Azure et Azure DevOps. Vous copiez ce fichier en `.env` et vous ajoutez uniquement vos valeurs personnelles.

**Suivez ces Ã©tapes dans l'ordre :**

**1.** Copiez `.env.example` en `.env` :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
Copy-Item .env.example .env
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
cp .env.example .env
```
</details>

**2.** Ouvrez `.env` dans VS Code :

```powershell
code .env
```

**3.** Mettez Ã  jour **uniquement** votre prÃ©fixe apprenant dans le fichier :

| Variable | Valeur |
|---|---|
| `LEARNER_PREFIX` | Votre prÃ©fixe apprenant (ex. `APP01`, fourni par le formateur) |
| `ENVIRONMENT` | `DEV` (par dÃ©faut, ne pas changer) |

> Les autres valeurs (organisation, compte, utilisateur, Azure, Key Vault) sont dans
> `config/shared.env` (commitÃ©e, chargÃ©e automatiquement par les scripts).
> **Ne modifiez pas** les valeurs partagÃ©es dans `.env` â€” seul `LEARNER_PREFIX` est personnel.

**4.** Sauvegardez le fichier (`Ctrl+S`) et fermez l'Ã©diteur.

**5.** VÃ©rifiez que `.env` existe et contient votre prÃ©fixe :

```powershell
# Windows
Test-Path .env
Get-Content .env | Select-String 'LEARNER_PREFIX'
```
```bash
# Linux/macOS
Test-Path .env
Select-String -Path .env -Pattern LEARNER_PREFIX
```

**RÃ©sultat attendu :** `True` / `OK` et `LEARNER_PREFIX=APP01` (ou votre prÃ©fixe).

**6.** VÃ©rifiez que `.env` est ignorÃ© par Git :

```bash
git check-ignore .env
```

**RÃ©sultat attendu :** `.env` â€” Git confirme qu'il ignore le fichier.

> `.env` est gitignored. Il ne sera jamais committÃ©.

**7.** VÃ©rifiez que `config/shared.env` existe (configuration partagÃ©e chargÃ©e par les scripts) :

```powershell
# Windows
Test-Path config/shared.env
```
```bash
# Linux/macOS
Test-Path config/shared.env
```

**RÃ©sultat attendu :** `True` / `OK`.

> `config/shared.env` est commitÃ© dans le dÃ©pÃ´t. Il contient les paramÃ¨tres partagÃ©s
> (organisation Snowflake, compte, Key Vault, IDs Azure). Les scripts le chargent
> automatiquement. S'il est absent, `Learner-Login.ps1` ne pourra pas rÃ©soudre
> `KEY_VAULT_NAME` et le mode KV-first ne fonctionnera pas.

---

### ðŸ“ Ã‰tape 5.3 â€” Authentifier Azure et rÃ©cupÃ©rer les secrets (10 min)

> `[IMPORTANT]` **PrÃ©requis :** l'Ã©tape 5.2 (`.env`) doit Ãªtre terminÃ©e.
> Le script `Learner-Login.ps1` lit `.env` pour rÃ©cupÃ©rer votre prÃ©fixe apprenant.

> `[IMPORTANT]` **Vous devez relancer cette Ã©tape au dÃ©but de chaque session**
> (nouveau terminal, redÃ©marrage VM). Les variables d'environnement ne persistent
> pas entre les sessions.

Cette Ã©tape vous connecte Ã  Azure, rÃ©cupÃ¨re **tous les secrets** depuis Key Vault
(identifiants SP + PAT Snowflake) et les persiste dans `secrets/` pour les sessions futures.
Il existe **deux modes** â€” choisissez selon votre situation :

#### Quel mode utiliser ?

| Situation | Mode | Commande |
|---|---|---|
| Vous avez un compte AAD apprenant (fourni par le formateur) | **KV-first** (recommandÃ©) | Ã‰tape A ci-dessous |
| Le compte AAD n'est pas configurÃ©, ou vous n'avez pas de navigateur | **Fallback** | Ã‰tape B ci-dessous |

---

#### Ã‰tape A â€” Mode KV-first (recommandÃ©, aucun fichier secret requis)

**1.** Lancez le script **sans** `-ForceFallback` :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/learner-login.sh --learner-prefix APP01
```
</details>

> Remplacez `APP01` par **votre** prÃ©fixe apprenant fourni par le formateur.

**2.** Une fenÃªtre de navigateur s'ouvre automatiquement.

> `[IMPORTANT]` **C'est normal !** Le navigateur s'ouvre pour vous authentifier
> avec votre compte AAD (work/school account). C'est le mode KV-first.
> Si aucun navigateur ne s'ouvre, copiez l'URL affichÃ©e dans le terminal
> et collez-la dans votre navigateur manuellement.

Connectez-vous avec votre compte apprenant (ex: `apprenant01@mokhtarsellamigmail.onmicrosoft.com`).

> `[IMPORTANT]` **Mot de passe AAD :** le formateur vous fournit individuellement votre
> mot de passe AAD (format: `AzureLearner2026@XX` oÃ¹ `XX` est votre numÃ©ro apprenant).
> Ce mot de passe est **diffÃ©rent** du mot de passe Snowflake (utilisÃ© pour l'interface web).
> Si vous n'avez pas reÃ§u vos identifiants AAD, demandez-les au formateur avant de continuer.

> `[MFA]` **Si Azure AD affiche Â« SÃ©curisons votre compte Â»** et vous demande d'installer
> Microsoft Authenticator, c'est que les Security Defaults sont activÃ©s sur le tenant.
> Deux options :
> - **Option A (recommandÃ©e) :** le formateur dÃ©sactive les Security Defaults dans Entra ID
>   (voir `troubleshooting.md` entrÃ©e 32), puis vous relancez le script.
> - **Option B :** vous configurez Microsoft Authenticator sur votre smartphone (une seule fois).
>   Voir `troubleshooting.md` entrÃ©e 32 pour les Ã©tapes dÃ©taillÃ©es.

**3.** Le script rÃ©cupÃ¨re automatiquement les secrets depuis Key Vault, puis **se reconnecte
avec le service principal** (SP) pour que la session Azure soit authentifiÃ©e en tant que SP.
Ceci est nÃ©cessaire car seul le SP a le rÃ´le `Storage Blob Data Contributor` (accÃ¨s data-plane
au storage account). L'utilisateur AAD n'a que le rÃ´le `Reader`.

**RÃ©sultat attendu :**

```text
[PASS] AAD login successful
[INFO] Fetching SP credentials from Key Vault...
[PASS] SP credentials retrieved from Key Vault
[PASS] SP credentials persisted to secrets/shared-sp.txt
[PASS] Snowflake PAT retrieved from Key Vault
[PASS] Snowflake PAT persisted to secrets/snowflake_pat.txt
[INFO] Logging in with shared service principal...
[PASS] Logged in to Azure
       Subscription: Azure subscription 1 (...)
       Learner prefix: APP01
[PASS] Environment variables set:
       ARM_CLIENT_ID
       ARM_CLIENT_SECRET (hidden)
       ARM_TENANT_ID
       ARM_SUBSCRIPTION_ID
       LEARNER_PREFIX = APP01
       TF_VAR_snowflake_token (hidden)
============================================================
 Ready for labs
============================================================
```

> `[IMPORTANT]` **Verifiez que la session est bien le SP** (et non l'utilisateur AAD) :
> ```powershell
> az account show --query "user.name" -o tsv
> ```
> Le resultat doit etre l'appId du SP (`ab35eee0-...`), pas `apprenantXX@...`.
> Si vous voyez l'utilisateur AAD, voir `troubleshooting.md` entree 34.

**Si le navigateur ne s'ouvre pas ou si la connexion AAD Ã©choue**, passez Ã  l'Ã‰tape B.

---

#### Ã‰tape A-bis â€” Configurer Microsoft Authenticator (si MFA demandÃ©e)

> Si Azure AD affiche **Â« SÃ©curisons votre compte Â»** lors de l'Ã‰tape A, suivez ces Ã©tapes.
> Sinon, sautez cette section et passez Ã  la vÃ©rification des secrets ci-dessous.

**PrÃ©requis :** un smartphone (iOS ou Android) avec accÃ¨s Ã  Internet.

**1.** TÃ©lÃ©chargez l'application **Microsoft Authenticator** :
- **iOS** : App Store â†’ recherchez Â« Microsoft Authenticator Â»
- **Android** : Google Play â†’ recherchez Â« Microsoft Authenticator Â»

**2.** Ouvrez l'application et sÃ©lectionnez **Ajouter un compte** â†’ **Compte professionnel ou scolaire**.

**3.** Sur l'Ã©cran Â« SÃ©curisons votre compte Â» dans votre navigateur, cliquez sur **Suivant**.

**4.** Un **QR code** s'affiche dans le navigateur. Scannez-le avec l'application Microsoft Authenticator.

**5.** L'application affiche un code Ã  6 chiffres. Saisissez ce code dans le navigateur pour valider l'enregistrement.

**6.** Une fois validÃ©, le login AAD se poursuit automatiquement â€” le script rÃ©cupÃ¨re les secrets depuis Key Vault.

> `[NOTE]` Cette configuration MFA n'est nÃ©cessaire qu'**une seule fois** par compte apprenant.
> Les logins suivants demanderont uniquement une approbation sur le tÃ©lÃ©phone (notification push).

> `[NOTE]` Si le formateur a dÃ©sactivÃ© les Security Defaults (recommandÃ©), vous ne verrez **jamais**
> cet Ã©cran MFA. Voir `troubleshooting.md` entrÃ©e 32 pour plus de dÃ©tails.

---

#### VÃ©rifier que tous les secrets sont stockÃ©s localement

> `[IMPORTANT]` En mode KV-first, `Learner-Login.ps1` rÃ©cupÃ¨re **tous** les secrets depuis Key Vault
> et les persiste dans `secrets/` pour les sessions futures. VÃ©rifiez que les fichiers sont bien prÃ©sents.

**1.** VÃ©rifiez que `secrets/shared-sp.txt` existe et contient les 4 variables SP :

```powershell
# Windows
Test-Path secrets\shared-sp.txt
Get-Content secrets\shared-sp.txt | Select-String 'ARM_'
```
```bash
# Linux/macOS
Test-Path secrets/shared-sp.txt
Select-String -Path secrets/shared-sp.txt -Pattern 'ARM_'
```

**RÃ©sultat attendu :** `True` / `OK` et 4 lignes :
```text
ARM_CLIENT_ID=...
ARM_CLIENT_SECRET=...
ARM_TENANT_ID=...
ARM_SUBSCRIPTION_ID=...
```

**2.** VÃ©rifiez que `secrets/snowflake_pat.txt` existe et contient le PAT :

```powershell
# Windows
Test-Path secrets\snowflake_pat.txt
```
```bash
# Linux/macOS
Test-Path secrets/snowflake_pat.txt
```

**RÃ©sultat attendu :** `True` / `OK`.

> `[SECURITY]` Ces fichiers sont **gitignored**. Ne les commitez jamais.
> Ils sont rÃ©gÃ©nÃ©rÃ©s automatiquement Ã  chaque login KV-first rÃ©ussi.

**3.** VÃ©rifiez que les variables d'environnement sont dÃ©finies dans la session courante :

```powershell
# Windows
$env:ARM_CLIENT_ID
$env:ARM_TENANT_ID
$env:ARM_SUBSCRIPTION_ID
$env:LEARNER_PREFIX
$env:TF_VAR_snowflake_token
```
```bash
# Linux/macOS
$env:ARM_CLIENT_ID
$env:ARM_TENANT_ID
$env:ARM_SUBSCRIPTION_ID
$env:LEARNER_PREFIX
$env:TF_VAR_snowflake_token
```

**RÃ©sultat attendu :** chaque variable affiche une valeur non vide (le token est une longue chaÃ®ne JWT).

> `[NOTE]` Les variables d'environnement ne persistent pas entre les sessions PowerShell.
> Les fichiers `secrets/` persistent, mais vous devez relancer `Learner-Login.ps1` au dÃ©but
> de chaque nouvelle session pour recharger les variables d'environnement.

---

#### Ã‰tape B â€” Mode fallback (si KV-first Ã©choue)

> `[IMPORTANT]` Le mode fallback nÃ©cessite les fichiers `secrets/shared-sp.txt` et
> `secrets/snowflake_pat.txt`. Ces fichiers sont soit :
> - **auto-gÃ©nÃ©rÃ©s** par un login KV-first rÃ©ussi prÃ©cÃ©dent (Ã‰tape A), soit
> - **distribuÃ©s par le formateur** en secours.
>
> **S'ils ne sont pas prÃ©sents, le fallback Ã©chouera.** Demandez-les au formateur.

**1.** VÃ©rifiez que les fichiers secrets existent :

```powershell
# Windows
Test-Path secrets\shared-sp.txt
Test-Path secrets\snowflake_pat.txt
```
```bash
# Linux/macOS
Test-Path secrets/shared-sp.txt
Test-Path secrets/snowflake_pat.txt
```

**Si le rÃ©sultat n'est pas `True` / `OK`**, demandez ces fichiers au formateur.
Ne continuez pas sans eux.

**2.** Lancez le script avec `-ForceFallback` :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01 -ForceFallback
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/learner-login.sh --learner-prefix APP01 --force-fallback
```
</details>

> Remplacez `APP01` par **votre** prÃ©fixe apprenant fourni par le formateur.

**RÃ©sultat attendu :**

```text
[INFO] Fallback mode: using local secrets files...
[PASS] Logged in to Azure
       Subscription: Azure subscription 1 (...)
       Learner prefix: APP01
[PASS] Environment variables set
============================================================
 Ready for labs
============================================================
```

---

#### VÃ©rifier la connexion Azure

**AprÃ¨s l'Ã‰tape A ou B**, vÃ©rifiez que vous Ãªtes connectÃ© :

```bash
az account show --query 'name' -o tsv
```

**RÃ©sultat attendu :** le nom de la souscription Azure (ex: `Azure subscription 1`).

#### VÃ©rifier le prÃ©fixe apprenant

```powershell
# Windows
$env:LEARNER_PREFIX
```
```bash
# Linux/macOS
$env:LEARNER_PREFIX
```

**RÃ©sultat attendu :** votre prÃ©fixe (ex: `APP01`).

> `[SECURITY]` Les fichiers `secrets/` sont gitignored. Ne les commitez jamais.
> PrÃ©fÃ©rez le mode KV-first (Ã‰tape A) qui ne stocke aucun secret sur votre VM.

---

### ðŸ“ Ã‰tape 5.4 â€” Configurer la connexion Snowflake (20 min)

> `[IMPORTANT]` **PrÃ©requis :** l'Ã©tape 5.3 (Learner-Login) doit Ãªtre terminÃ©e.
> Le script `New-SnowflakeConnection.ps1` lit `.env` et `secrets/snowflake_pat.txt`
> (crÃ©Ã© par Learner-Login en mode KV-first). Si le PAT n'est pas disponible, il vous le demande.

**Avant de continuer, vÃ©rifiez que `.env` existe :**

```powershell
# Windows
Test-Path .env
```
```bash
# Linux/macOS
Test-Path .env
```

**Si le rÃ©sultat n'est pas `True` / `OK`, revenez Ã  l'Ã©tape 5.2.**

> `[IMPORTANT]` Cette Ã©tape configure Snow CLI et crÃ©e un fichier PAT local (`secrets/snowflake_pat.txt`).
> En mode KV-first (Ã©tape 5.3 Ã‰tape A), le PAT est rÃ©cupÃ©rÃ© automatiquement depuis Key Vault â€”
> cette Ã©tape est donc principalement nÃ©cessaire pour le mode fallback, ou pour vÃ©rifier la connexion Snowflake.
> Le fichier `secrets/snowflake_pat.txt` crÃ©Ã© ici sert de **fallback** si Key Vault est inaccessible.

Le script de connexion lit `.env` automatiquement. Si `SNOWFLAKE_PAT` est vide dans `.env`, il vous le demande de faÃ§on masquÃ©e.

**Suivez ces Ã©tapes dans l'ordre :**

**1.** Lancez le script de connexion :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
.\scripts\New-SnowflakeConnection.ps1
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
chmod +x scripts/new-snowflake-connection.sh
./scripts/new-snowflake-connection.sh
```
</details>

**2.** Si le script demande un PAT, saisissez-le (il ne s'affiche pas Ã  l'Ã©cran) :

```text
Snowflake PAT (token): ********
```

Le PAT vous a Ã©tÃ© fourni par le formateur.

> `[NOTE]` Le PAT est partagÃ© entre tous les apprenants (utilisateur `DATA2AI`, rÃ´le `SYSADMIN`).
> L'isolation se fait via votre `LEARNER_PREFIX`, pas via le PAT.

**3.** VÃ©rifiez que la connexion fonctionne :

```bash
snow sql -q 'SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_ACCOUNT()' -c training
```

**RÃ©sultat attendu :** une ligne avec `DATA2AI`, `SYSADMIN` et votre compte.

> `[NOTE]` Le script a crÃ©Ã© `secrets/snowflake_pat.txt`. Ce fichier sera utilisÃ©
> automatiquement par `Learner-Login.ps1` en mode fallback (Ã©tape 5.3 Ã‰tape B).

**Si vous voyez `[WARN] No .env file found`**, revenez Ã  l'Ã©tape 5.2.

#### AccÃ©der Ã  l'interface web Snowflake (optionnel)

Le formateur vous a fourni un **identifiant Snowflake individuel** (username + password)
pour acceder a l'interface web.

1. Ouvrez **https://app.snowflake.com**
2. Connectez-vous avec :
   - **Username :** `apprenant01` (votre identifiant apprenant)
   - **Password :** fourni par le formateur (14+ caracteres)

> Le PAT (utilise par CLI et Terraform) ne fonctionne pas pour l'interface web.
> L'interface web necessite un username + password.
> Le formateur vous distribue votre password individuel de facon securisee.

---

### ðŸ“ Ã‰tape 5.5 â€” Inspecter la structure du projet type (10 min)

#### Lister les dossiers

```bash
Get-ChildItem -Force
Get-ChildItem environments/
Get-ChildItem modules/
Get-ChildItem docs/
Get-ChildItem scripts/
```

**Checkpoint** :

```text
environments/
  dev/
  uat/
  prod/
modules/
docs/
  architecture.md
  naming-conventions.md
  runbook.md
  adr/
scripts/
  Install-Tools.ps1
  install-tools.sh
  New-SnowflakeConnection.ps1
  new-snowflake-connection.sh
  validate.ps1
  validate.sh
azure-pipelines.yml
CODEOWNERS
.gitignore
.gitattributes
.editorconfig
.tflint.hcl
```

#### VÃ©rifier l'absence de code de ressource

```bash
find . -name '*.tf' -type f
```

**Checkpoint** : aucun resultat. Le squelette ne contient aucun fichier `.tf`. Vous les creerez a partir du Jour 1.

#### Comprendre le rÃ´le du squelette

| Element | Role |
|---|---|
| `labs/m01-iac-workflow/` ... `m14-data-products/` | Chaque lab a son propre dossier isole |
| `labs/_templates/` | Modeles de fichiers (provider.tf, versions.tf, variables.tf) |
| `environments/` | Reserve pour M8 (deploiement multi-environnement) |
| `modules/` | Modules reutilisables (cree dans M5, M12, M14) |
| `docs/` | Architecture, conventions de nommage, runbook, decisions |
| `azure-pipelines.yml` | Pipeline CI/CD Azure DevOps |
| `.gitignore` | Exclut state, plans, secrets, tfvars |
| `.tflint.hcl` | Configuration du linter |
| `CODEOWNERS` | Propriete du code et revue obligatoire |
| `scripts/` | Installation, connexion, validation et `Reset-Lab.ps1` |

#### Renommer l'origine (optionnel)

Pour eviter d'ecraser le template, renommez l'origine et ajoutez votre propre depot apprenant :

```bash
git remote rename origin template
git remote add origin <VOTRE_REPO_APPRENANT>
```

> Si vous n'avez pas encore de depot apprenant, ignorez cette etape pour l'instant. Vous le creerez au Jour 1.

---

### ðŸ“ Ã‰tape 5.6 â€” Validation finale (10 min)

> `[IMPORTANT]` **ExÃ©cutez chaque commande une par une.**
> Ne copiez pas plusieurs commandes sur la mÃªme ligne.
> Chaque commande ci-dessous est sÃ©parÃ©e â€” exÃ©cutez-les individuellement.

**1.** Relancez le diagnostic des outils :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1 -Check
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/install-tools.sh --check
```
</details>

**RÃ©sultat attendu :** `Toolchain status: READY`.

**2.** VÃ©rifiez la connexion Snowflake :

```bash
snow sql -q 'SELECT 1' -c training
```

**RÃ©sultat attendu :** un rÃ©sultat contenant `1`.

> Si vous obtenez `Private Key authentication requires authenticator set to SNOWFLAKE_JWT`,
> la variable `SNOWFLAKE_PRIVATE_KEY_FILE` est dÃ©finie dans votre session.
> Voir `troubleshooting.md` entrÃ©e 33.

**3.** VÃ©rifiez le projet Git :

```bash
git status
```

**RÃ©sultat attendu :** branche propre, aucun fichier modifiÃ© (sauf `preflight.md` et `preflight.json` qui sont ignorÃ©s).

**3b.** VÃ©rifiez que la session Azure est le service principal :

```powershell
az account show --query "user.name" -o tsv
```

**RÃ©sultat attendu :** l'appId du SP (`ab35eee0-5d09-4c4d-b41c-f536ce7dbdf0`), pas `apprenantXX@...`.

> Si vous voyez l'utilisateur AAD, relancez `Learner-Login.ps1` et vÃ©rifiez le message d'erreur.
> Voir `troubleshooting.md` entrÃ©e 34.

**4.** Lancez le test de connectivitÃ© complet :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
.\scripts\Test-LabConnectivity.ps1 -SkipDevOps
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/test-lab-connectivity.sh --skip-devops
```
</details>

**RÃ©sultat attendu :** `Status: READY` avec 0 FAIL.

> Si `Blob write access` est en FAIL, c'est un probleme RBAC cote formateur.
> Le role `Storage Blob Data Contributor` n'a pas ete attribue au SP ou
> la propagation n'est pas encore effective (jusqu'a 10 minutes).
> Consultez le [guide de troubleshooting](troubleshooting.md) entree 15.
>
> Si `Blob write access` est en FAIL **et** `az account show --query "user.name" -o tsv`
> retourne `apprenantXX@...` au lieu de l'appId du SP, le login SP a echoue.
> Consultez le [guide de troubleshooting](troubleshooting.md) entree 34.
>
> Si `Snowflake query` est en FAIL avec `Private Key authentication requires
> authenticator set to SNOWFLAKE_JWT`, la variable `SNOWFLAKE_PRIVATE_KEY_FILE`
> est definie dans la session. Consultez le [guide de troubleshooting](troubleshooting.md)
> entree 33.

---

### ðŸŒ Ã‰tape 5.7 â€” VÃ©rification Graphique via les Consoles Web

L'apprentissage professionnel associe les commandes du terminal Ã  la maÃ®trise des interfaces graphiques d'administration.

#### â„ï¸ Console Snowflake Snowsight (`https://app.snowflake.com`)

1. Ouvrez votre navigateur et accÃ©dez Ã  : `https://app.snowflake.com`
2. Saisissez votre identifiant de compte Snowflake : `<ORGANIZATION>-<ACCOUNT>` (valeur prÃ©sente dans votre `.env`).
3. Connectez-vous avec vos identifiants apprenant :
   - **Nom d'utilisateur :** `apprenant01` (votre identifiant apprenant, **diffÃ©rent** de votre prÃ©fixe `APP01`)
   - **Mot de passe :** fourni individuellement par le formateur (voir Ã©tape 5.4).
4. VÃ©rifiez en haut Ã  droite que votre rÃ´le actif est **`SYSADMIN`** (et non `ACCOUNTADMIN`).
5. Cliquez sur **Worksheets > + SQL Worksheet**, collez et exÃ©cutez (`Ctrl + Enter`) :
   ```sql
   SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_ACCOUNT(), CURRENT_REGION();
   ```
6. Vous devez voir votre identifiant apprenant et le rÃ´le `SYSADMIN`.

#### ðŸ”µ Portail Microsoft Azure (`https://portal.azure.com`)

1. AccÃ©dez au portail officiel : `https://portal.azure.com`
2. VÃ©rifiez votre accÃ¨s Ã  la souscription de formation indiquÃ©e par :
   ```powershell
   az account show --query "name" -o tsv
   ```
3. Naviguez vers le groupe de ressources de la formation et repÃ©rez :
   - Le compte de stockage Azure Blob Storage qui hÃ©bergera votre state Terraform distant (Ã©tudiÃ© au Jour 1).
   - Le coffre **Azure Key Vault** contenant le secret PAT Snowflake partagÃ© (`SnowflakePAT`).

---

## ðŸ› 6. Incident ContrÃ´lÃ© (*Chaos Engineering Lab*)

*Pour apprendre Ã  dÃ©panner sans stress, simulez une anomalie courante de configuration :*

### SymptÃ´me & Injection de l'Anomalie
1. Ouvrez votre `.env` et modifiez temporairement `LEARNER_PREFIX` avec un nom non conforme contenant un tiret et des minuscules :
   ```text
   LEARNER_PREFIX=app-01-test
   ```

### Diagnostic & Observation
Lancez la vÃ©rification d'environnement :

```powershell
.\scripts\SelfPacedLab.ps1 -Module 0 -All
```

```bash
./scripts/self-paced-lab.sh --module 0 --all
```

Le validateur signale un Ã©chec immÃ©diat sur la conformitÃ© de l'identifiant (la regex de validation impose `^[A-Z0-9]{2,10}$`).

### RemÃ©diation
Restaurez votre prÃ©fixe officiel (ex: `APP01`), rÃ©-exÃ©cutez le script et vÃ©rifiez le retour au statut `PASS`.

---

## ðŸ¤– 7. Validation AutomatisÃ©e (*Check My Progress*)

Validez votre avancement avec le moteur d'auto-Ã©valuation du cours :

<details>
<summary>ðŸªŸ <b>Windows (PowerShell)</b></summary>

```powershell
.\scripts\SelfPacedLab.ps1 -Module 0 -All -Report
```
</details>

<details>
<summary>ðŸ§ <b>Linux/macOS (Bash)</b></summary>

```bash
./scripts/self-paced-lab.sh --module 0 --all --report
```
</details>

<details>
<summary>âœ… <b>Exemple de Rapport de Validation</b></summary>

```text
[PASS] T1 Git installed and configured
[PASS] T2 Terraform installed and pinned correctly
[PASS] T3 Snow CLI connection 'training' operational
[PASS] T4 Azure CLI authenticated with service principal
[PASS] T5 Project structure validated (no .tf files)
Result: 5/5 Tasks Passed.
Report written to: student-track/_reports/module-00-APP01.md
```
</details>

âœ… **Checkpoint Final :** Les conditions suivantes doivent Ãªtre rÃ©unies :

1. `Toolchain status: READY`
2. `az account show --query 'name' -o tsv` affiche la souscription Azure
3. `az account show --query 'user.name' -o tsv` affiche l'appId du SP (`ab35eee0-...`), pas l'utilisateur AAD
4. `snow sql -q 'SELECT 1' -c training` retourne un rÃ©sultat
5. Connexion confirmÃ©e dans **Snowflake Snowsight Web UI** avec le rÃ´le `SYSADMIN`
6. `Test-LabConnectivity.ps1` affiche `Status: READY` (0 FAIL)
7. Le projet type est clonÃ© et ne contient aucun fichier `.tf`
8. `secrets/shared-sp.txt` et `secrets/snowflake_pat.txt` sont prÃ©sents (persistÃ©s depuis KV)
9. `$env:TF_VAR_snowflake_token` est dÃ©fini (non vide)

```text
Ready for Day 1
```

---

## ðŸ† 8. DÃ©fi Autonome (*Unguided Challenge*)

> **ScÃ©nario :** Votre Ã©quipe vous demande de prÃ©parer un second environnement de test avec un prÃ©fixe diffÃ©rent.
> **Contraintes :**
> - CrÃ©ez un fichier `.env.test` avec un prÃ©fixe `APP01TEST` (conforme Ã  la regex);
> - VÃ©rifiez que `git check-ignore .env.test` confirme l'ignorance du fichier;
> - Lancez `Learner-Login.ps1 -LearnerPrefix APP01TEST` et vÃ©rifiez que les variables d'environnement sont correctement dÃ©finies;
> - Ne modifiez jamais le fichier `.env` principal.

| CritÃ¨re d'Ã‰valuation | Points |
|---|---:|
| Fichier `.env.test` crÃ©Ã© avec prÃ©fixe conforme | 30 pts |
| `git check-ignore` confirme l'ignorance | 20 pts |
| `Learner-Login` rÃ©ussit avec le nouveau prÃ©fixe | 30 pts |
| Aucune modification du `.env` principal | 20 pts |
| **Total** | **100 pts** |

---

## ðŸ§¹ 9. Conservation & Point de Reprise (*FinOps Teardown*)

> **M00 est un module de conservation obligatoire.** Ne dÃ©truisez rien â€” l'environnement est la base de tous les labs M01 Ã  M14.

### Point de reprise pour les sessions suivantes

Ã€ partir du Jour 1, **tous les fichiers `.tf` que vous crÃ©erez** iront dans le dossier du lab correspondant :

- `labs/m01-iac-workflow/main.tf`, `locals.tf`, `outputs.tf`... pour M1;
- `labs/m05-modules/modules/landing-zone/` pour M5;
- `labs/m08-environments/dev/`, `uat/`, `prod/` pour M8;
- etc.

Chaque lab est **isolÃ©** : il a son propre dossier, son propre state et ses propres ressources (prÃ©fixÃ©es par le numÃ©ro de module, ex. `APP01_M01_RAW_DEV`). Utilisez `Reset-Lab.ps1` pour nettoyer avant/aprÃ¨s un lab :

```powershell
.\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M01
```

Les scripts `validate.ps1` et `validate.sh` dans `scripts/` vÃ©rifient votre travail localement avant de pousser.

> âš ï¸ **WARNING** : Vous devez relancer `Learner-Login` au dÃ©but de chaque session (nouveau terminal, redÃ©marrage VM). Les variables d'environnement ne persistent pas entre les sessions.

Passez Ã  [M1 â€” Premier dÃ©ploiement Terraform Snowflake](../../day-01/module-01-iac-workflow/lab.md).

---

## Navigation

[<- Jour 0](../README.md) Â· **Lab M00** Â· [Lab M1 ->](../../day-01/module-01-iac-workflow/lab.md)
