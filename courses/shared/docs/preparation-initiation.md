# Preparation de l'Initiation

Ce document decrit les pre-requis et la preparation necessaires avant de commencer
les 3 jours d'initiation (Jours 0-2).

## Pre-Requis Materiels

### Poste de Formation

| Composant | Minimum | Recommande |
|-----------|---------|------------|
| OS | Windows 10, Linux, macOS | Windows 11 |
| RAM | 8 GB | 16 GB |
| Disque | 50 GB libres | 100 GB |
| Reseau | Internet | Internet haut debit |

### Logiciels Requis

| Logiciel | Version | Installation |
|----------|---------|--------------|
| Terraform | 1.14.5 | Via script d'installation |
| VS Code | Derniere | Marketplace |
| Git | Dernier | Via script d'installation |
| Snowflake CLI | Dernier | Via script d'installation |
| Python | 3.12 | Via script d'installation |
| Azure CLI | 2.83.0 | Via script d'installation |
| dbt | <3.0.0 | Via script d'installation |
| tflint | 0.50.0 | Via script d'installation |

## Pre-Requis Cloud

### Snowflake

| Element | Detail |
|---------|--------|
| Compte | Fourni par le formateur |
| Organisation | Fournie dans .env.example |
| Role | SYSADMIN (ou role de training) |
| Warehouse | DEMO (pour les exercices) |
| PAT | Individuel, genere dans Snowsight |

### Azure

| Element | Detail |
|---------|--------|
| Abonnement | Partage via SP |
| Service Principal | Fourni dans secrets/shared-sp.txt |
| Conteneur Blob | Pour le state Terraform |
| Key Vault | Pour les secrets |

## Preparation

### Etape 1 : Cloner le Depot

```bash
git clone https://github.com/msellamiTN/data-platform-starter.git "$HOME/Data2AI-Labs/data-platform"
cd "$HOME/Data2AI-Labs/data-platform"
```

### Etape 2 : Installer les Outils

**Windows :**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1
```

**Linux/macOS :**
```bash
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

### Etape 3 : Configurer .env

```bash
cp .env.example .env
```

Editer `.env` et ajouter :
- `LEARNER_PREFIX` : votre prefixe (APP01 a APP11)
- `SNOWFLAKE_PAT` : votre PAT genere dans Snowsight

### Etape 4 : Tester la Connexion

```bash
# Snowflake
snow sql -q 'SELECT 1' -c training

# Azure
az account show
```

### Etape 5 : Validation Finale

**Windows :**
```powershell
.\scripts\Test-LabConnectivity.ps1
```

**Linux/macOS :**
```bash
./scripts/test-lab-connectivity.sh
```

**Resultat attendu :**
```text
Toolchain status: READY
Test-LabConnectivity -> Status: READY (0 FAIL)
```

## Verification Pre-Session

| Check | Action | Preuve |
|-------|--------|--------|
| Terraform | `terraform version` | Affiche 1.14.x |
| Snowflake | `snow sql -q 'SELECT 1' -c training` | Retourne un resultat |
| Azure | `az account show` | Affiche la souscription |
| Git | `git status` | Fonctionne dans le projet |
| .env | `git check-ignore .env` | Retourne `.env` |

## Environnement de Secours

Un environnement de secours doit etre pret :

| Element | Statut |
|---------|--------|
| VM de secours | Prete |
| Copie du depot | Clonee |
| Credentials | Configures |
| Teste | Oui |

## Timing

| Moment | Action | Duree |
|--------|--------|-------|
| T-15 jours | Identifier postes et droits | 2h |
| T-7 jours | Installer et verifier les outils | 4h |
| T-3 jours | Tester PAT et connectivite | 2h |
| T-1 jour | Derniere verification | 1h |
