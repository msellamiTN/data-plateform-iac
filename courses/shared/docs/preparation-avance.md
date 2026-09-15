# Préparation de l'Avancé

Ce document décrit les prérequis et la préparation nécessaires avant de commencer les 2 jours avancés (Jours 4 et 5).

> L'avancé conserve le même périmètre : Terraform + Snowflake. Azure DevOps est utilisé uniquement pour exécuter un pipeline Terraform. Les ressources Azure (backend, agent, service connection, storage pour external stage) sont **préconfigurées par le formateur**.

## Prérequis : Initiation terminée

Avant de commencer l'avancé, le participant doit maîtriser les compétences du socle d'initiation :

| Compétence | Critère |
|---|---|
| Workflow Terraform | `init`, `validate`, `plan`, `apply`, `output`, `state list` |
| Variables & outputs | Contrats typés, `locals`, validations |
| Modules | Créer et appeler un module simple |
| State | Comprendre les 4 rôles, lire le state, migration vers backend distant |
| Import & drift | Importer un objet existant, détecter et corriger une dérive |
| `for_each` | Collections stables, ajout par données |

> Si une faiblesse est détectée, une consolidation ciblée est menée avant le démarrage de l'avancé.

## Prérequis matériels

### Poste de formation

Même configuration que l'initiation.

### Logiciels supplémentaires

| Logiciel | Version | Usage |
|---|---|---|
| OpenSSL | Dernier | Génération de clés RSA (Jour 5) |

> Azure CLI est préinstallé sur les VM de formation (Chemin A). En installation locale (Chemin B), il est optionnel : le backend est consommé via les paramètres fournis.

## Prérequis Cloud (préconfigurés par le formateur)

### Azure — préconfiguré, non administré par l'apprenant

| Élément | Détail |
|---|---|
| Backend Blob Storage | Accessible, paramètres dans `.env` |
| Projet Azure DevOps | Prêt, agent et service connection configurés |
| Storage account pour external stage | Préparé pour M09 (Jour 5) |
| Entra ID / identité technique | Préparé pour M10 (Jour 5) |

### Snowflake

| Élément | Détail |
|---|---|
| Compte | Actif |
| Rôle | `SYSADMIN` + rôle de training pour RBAC |
| Warehouse | Démonstration |
| Utilisateur technique | Préparé pour le pipeline (Jour 4) |

## Préparation apprenant

### Étape 1 : Vérifier l'initiation

```bash
# Vérifier que les ressources d'initiation sont présentes
terraform state list

# Vérifier que le plan est clean
terraform plan -detailed-exitcode
```

**Résultat attendu :** Exit code 0 (pas de changement)

### Étape 2 : Consommer le backend distant

```bash
# Depuis le dossier du lab — le backend est déjà configuré
terraform init
```

> Le backend Azure Blob est préconfiguré. Vous ne créez pas le storage account ni le conteneur. Vous référencez les paramètres fournis dans `.env`.

### Étape 3 : Tester le pipeline (Jour 4)

```bash
# Pousser vers Azure DevOps
git push origin main

# Vérifier que le pipeline se lance
# (dans Azure DevOps > Pipelines)
```

> Le projet, l'agent et la service connection sont préconfigurés. Vous n'administrez pas Azure DevOps.

### Étape 4 : Générer les clés RSA (Jour 5)

```bash
# Générer une clé privée
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -out snowflake_key.p8

# Générer la clé publique
openssl rsa -in snowflake_key.p8 -pubout -out snowflake_key.pub
```

> 🔒 Les clés privées ne sont **jamais** dans Git. Elles sont gitignored et injectées au runtime.

## Vérification pré-session

| Check | Action | Preuve |
|---|---|---|
| Initiation | `terraform plan -detailed-exitcode` | Exit 0 |
| Backend distant | `terraform init` | State migré sans erreur |
| Snowflake | `snow sql -q 'SELECT 1' -c training` | Connexion OK |
| Pipeline | Push de test | Pipeline déclenché |
| Clés RSA | `ls -la *.p8 *.pub` | Clés générées (Jour 5) |

## Environnement de secours

| Élément | Statut |
|---|---|
| VM de secours | Prête |
| Backend distant | Accessible |
| Credentials | Configurés |
| Pipeline | Fonctionnelle |
| Testé | Oui |

## Timing

| Moment | Action | Durée |
|---|---|---|
| T-7 jours | Vérifier les prérequis initiation | 2 h |
| T-5 jours | Vérifier le backend et le pipeline (formateur) | 3 h |
| T-3 jours | Tester le pipeline et les clés | 2 h |
| T-1 jour | Dernière vérification | 1 h |

## Contenu avancé

| Jour | Modules | Durée | Livrable |
|---|---|---|---|
| J4 | M8 (Environnements) + M7 (Pipeline CI/CD) | 6 h | Environnements isolés + pipeline Terraform |
| J5 | M9 (Snowflake avancé) + M10 (Auth) + M11 (RBAC) + M12 (Capstone) | 6 h | Plateforme sécurisée + zero-drift + cleanup |
| Annexe | M13 (FinOps) + M14 (Data products) | Optionnel | Hors parcours 3+2 |

## Escalade

| Situation | Action |
|---|---|
| Backend inaccessible | Contacter le formateur (problème infrastructure) |
| Pipeline échoue | Vérifier les logs Azure DevOps, le code Terraform |
| Clé RSA invalide | Régénérer avec OpenSSL |
| Snowflake refuse l'auth | Vérifier l'utilisateur et les permissions |
