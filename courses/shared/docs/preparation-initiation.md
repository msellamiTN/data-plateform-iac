# Préparation de l'Initiation

Ce document décrit les prérequis et la préparation nécessaires avant de commencer les 3 jours d'initiation (Jours 1 à 3).

> Azure est une dépendance d'environnement **préconfigurée par le formateur**. Les apprenants ne créent ni subscription, ni service principal, ni storage account, ni Key Vault. Les paramètres du backend distant sont fournis et consommés tels quels.

## Prérequis matériels

### Poste de formation

| Composant | Minimum | Recommandé |
|---|---|---|
| OS | Windows 10, Linux, macOS | Windows 11 |
| RAM | 8 GB | 16 GB |
| Disque | 50 GB libres | 100 GB |
| Réseau | Internet | Internet haut débit |

### Logiciels requis (apprenant)

| Logiciel | Version | Rôle dans le parcours |
|---|---|---|
| Terraform | 1.14.5 | Workflow IaC |
| VS Code | Dernière | Éditeur |
| Git | Dernier | Versionnement |
| Snowflake CLI | Dernier | Vérification `SELECT 1`, preuves SQL |

### Logiciels optionnels ou préinstallés

| Logiciel | Statut | Raison |
|---|---|---|
| Azure CLI | Préinstallé (Chemin A) ou optionnel | Utilisé uniquement pour consommer le backend, pas pour l'administrer |
| Python | Optionnel | Non requis pour le parcours principal |
| dbt | Hors périmètre | Non couvert dans les 3 jours d'initiation |
| tflint | Optionnel | Bonus de validation, non évalué |
| OpenSSL | Jour 5 uniquement | Génération de clés RSA (avancé) |

## Prérequis Cloud

### Snowflake (fourni par le formateur)

| Élément | Détail |
|---|---|
| Compte | Fourni par le formateur |
| Organisation | Fournie dans `.env.example` |
| Rôle | `SYSADMIN` ou rôle de training |
| Warehouse | Démonstration (pour les exercices) |
| PAT | Individuel, généré dans Snowsight |

### Azure (préconfiguré par le formateur — consommé, non administré)

| Élément | Détail |
|---|---|
| Subscription | Préconfigurée, paramètres dans `.env.example` |
| Backend Blob Storage | Pour le state Terraform (Jour 3) |
| Service connection Azure DevOps | Pour le pipeline (Jour 4) |

> L'apprenant reçoit les paramètres (`ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, etc.) dans `.env.example`. Il ne crée aucune de ces ressources.

## Préparation apprenant

### Étape 1 : Cloner le dépôt

```bash
git clone https://github.com/msellamiTN/data-platform-starter.git "$HOME/Data2AI-Labs/data-platform"
cd "$HOME/Data2AI-Labs/data-platform"
```

### Étape 2 : Installer les outils

**Windows :**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Install-Tools.ps1
```

**Linux/macOS :**
```bash
chmod +x scripts/install-tools.sh
./scripts/install-tools.sh
```

### Étape 3 : Configurer `.env`

```bash
cp secrets/.env.example .env
```

Éditer `.env` et ajouter uniquement :
- `LEARNER_PREFIX` : votre préfixe (`APP01` à `APP11`)
- `SNOWFLAKE_PAT` : votre PAT généré dans Snowsight

### Étape 4 : Tester la connexion Snowflake

```bash
snow sql -q 'SELECT 1' -c training
```

> La connexion Azure n'est pas testée par l'apprenant en initiation. Le backend est consommé au Jour 3 avec les paramètres fournis.

### Étape 5 : Validation finale

**Windows :**
```powershell
.\scripts\Test-LabConnectivity.ps1
```

**Linux/macOS :**
```bash
./scripts/test-lab-connectivity.sh
```

**Résultat attendu :**
```text
Toolchain status: READY
Test-LabConnectivity -> Status: READY (0 FAIL)
```

## Vérification pré-session

| Check | Action | Preuve |
|---|---|---|
| Terraform | `terraform version` | Affiche 1.14.x |
| Snowflake | `snow sql -q 'SELECT 1' -c training` | Retourne un résultat |
| Git | `git status` | Fonctionne dans le projet |
| `.env` | `git check-ignore .env` | Retourne `.env` |
| Préfixe | `echo $LEARNER_PREFIX` | `APP01` à `APP11` |

## Environnement de secours

Un environnement de secours doit être prêt :

| Élément | Statut |
|---|---|
| VM de secours | Prête |
| Copie du dépôt | Clonée |
| Credentials | Configurés |
| Testé | Oui |

## Timing

| Moment | Action | Durée |
|---|---|---|
| T-15 jours | Identifier postes et droits | 2 h |
| T-7 jours | Installer et vérifier les outils | 4 h |
| T-3 jours | Tester PAT et connectivité Snowflake | 2 h |
| T-1 jour | Dernière vérification | 1 h |
