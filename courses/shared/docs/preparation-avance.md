# Preparation de l'Avance

Ce document decrit les pre-requis et la preparation necessaires avant de commencer
les 2 jours d'avance (Jours 3-4).

## Pre-Requis : Initiation Terminee

Avant de commencer l'avance, le participant doit maitriser les competences
du socle d'initiation :

| Competence | Critere |
|------------|---------|
| Workflow Terraform | `init`, `validate`, `plan`, `apply` |
| State | Comprendre les 4 roles, lire le state |
| Collections | `for_each`, `locals`, `validation` |
| Modules | Creer et appeler un module simple |
| CI/CD | Pipeline basic Azure DevOps |
| Environnements | Isolation DEV/UAT/PROD |

> Si une faiblesse est detectee, une consolidation ciblee est menee avant
> le demarrage de l'avance.

## Pre-Requis Materiels

### Poste de Formation

Meme configuration que l'initiation, plus :

| Composant | Minimum | Recommande |
|-----------|---------|------------|
| RAM | 8 GB | 16 GB |
| Disque | 50 GB libres | 100 GB |

### Logiciels Supplémentaires

| Logiciel | Version | Usage |
|----------|---------|-------|
| Azure CLI | 2.83.0 | Authentification Azure |
| OpenSSL | Dernier | Generation de cles RSA |

## Pre-Requis Cloud

### Azure

| Element | Detail |
|---------|--------|
| Abonnement | Actif et accessible |
| Service Principal | Fourni dans secrets/shared-sp.txt |
| Conteneur Blob | Cree et accessible |
| Key Vault | Configure avec les secrets |
| Azure DevOps | Projet et connexion de service |

### Snowflake

| Element | Detail |
|---------|--------|
| Compte | Actif |
| Role | SECURITYADMIN (pour RBAC) |
| Warehouse | DEMO |
| Utilisateur technique | Cree pour la pipeline |

## Preparation

### Etape 1 : Verifier l'Initiation

```bash
# Verifier que les ressources d'initiation sont presentes
terraform state list

# Verifier que le plan est clean
terraform plan -detailed-exitcode
```

**Resultat attendu :** Exit code 0 (pas de changement)

### Etape 2 : Configurer Azure

```bash
# Authentifier Azure
az login --service-principal -u <APP_ID> -p <SECRET> --tenant <TENANT_ID>

# Verifier l'abonnement
az account show

# Creer le conteneur Blob (si pas encore fait)
az storage container create --name tfstate --account-name <STORAGE_ACCOUNT>
```

### Etape 3 : Configurer le Backend Distant

```bash
# Depuis environments/dev/
terraform init -migrate-state
```

### Etape 4 : Tester la Pipeline

```bash
# Pousser vers Azure DevOps
git push origin main

# Verifier que le pipeline se lance
# (dans Azure DevOps > Pipelines)
```

### Etape 5 : Generer les Cles RSA

```bash
# Generer une cle privee
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -out snowflake_key.p8

# Generer la cle publique
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub

# Creer l'utilisateur Snowflake avec la cle publique
snowsql -q "CREATE USER training_svc SET RSA_PUBLIC_KEY='...'"
```

## Verification Pre-Session

| Check | Action | Preuve |
|-------|--------|--------|
| Initiation | `terraform plan -detailed-exitcode` | Exit 0 |
| Azure CLI | `az account show` | Affiche la souscription |
| Key Vault | `az keyvault secret show ...` | Secret accessible |
| Blob Storage | `az storage container show ...` | Conteneur accessible |
| Azure DevOps | Pipeline green | Dernier build reussi |
| Snowflake | `snow sql -q 'SELECT 1' -c training` | Connexion OK |
| Cles RSA | `ls -la *.p8 *.pub` | Cles generees |

## Environnement de Secours

| Element | Statut |
|---------|--------|
| VM de secours | Prete |
| Backend distant | Accessible |
| Credentials | Configures |
| Pipeline | Fonctionnelle |
| Teste | Oui |

## Timing

| Moment | Action | Duree |
|--------|--------|-------|
| T-7 jours | Verifier les prerequis initiation | 2h |
| T-5 jours | Configurer Azure et le backend | 3h |
| T-3 jours | Tester la pipeline et les cles | 2h |
| T-1 jour | Derniere verification | 1h |

## Contenu Avance

| Jour | Modules | Duree | Livrable |
|------|---------|-------|----------|
| J4 | M7 (CI/CD) + M8 (Environnements) | 6h | Pipeline + isolation |
| J5 | M9 (Ingestion) + M10 (Auth) + M11 (RBAC) + M12 (Capstone) + M13+M14 (FinOps) | 6h | Plateforme complete |

## Escalade

| Situation | Action |
|-----------|--------|
| Azure non accessible | Utiliser l'environnement de secours |
| Pipeline echoue | Verifier les logs Azure DevOps |
| Cle RSA invalide | Regenerer avec OpenSSL |
| Snowflake refuse l'auth | Verifier l'utilisateur et les permissions |
