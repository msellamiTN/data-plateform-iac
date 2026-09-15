# Guide du Formateur

Ce document contient les notes et procédures pour le formateur de la formation Terraform & Snowflake.

## Vue d'ensemble

| Aspect | Détail |
|---|---|
| **Durée** | 5 jours × 6 heures = 30 heures |
| **Participants** | 11 apprenants (préfixes `APP01` à `APP11`) |
| **Stack apprenant** | Terraform + provider Snowflake |
| **Stack préconfigurée** | Azure (backend, agent, service connection, external stage) + Azure DevOps (projet) |
| **Prérequis apprenant** | Aucun — ni Azure, ni PowerShell, ni programmation |

---

## Séparation des responsabilités

### Ce que le formateur prépare (hors périmètre apprenant)

| Élément | Quand | Preuve |
|---|---|---|
| Compte Snowflake + utilisateurs + PAT | T-15 jours | 11 utilisateurs + PAT individuels |
| Backend Azure Blob Storage | T-7 jours | RG, storage account, conteneur `tfstate` |
| Service principal + RBAC Blob | T-7 jours | `Storage Blob Data Contributor` sur l'object ID |
| Projet Azure DevOps + agent + service connection | T-7 jours | Pipeline exécutable |
| Storage account pour external stage (M09) | T-5 jours | Container accessible depuis Snowflake |
| Entra ID / identité technique (M10) | T-5 jours | Utilisateur technique pour JWT |
| VMs de formation (Chemin A) | T-3 jours | 11 VMs avec outils préinstallés |
| Environnement de secours | T-3 jours | VM + backend + pipeline testés |

### Ce que l'apprenant fait (périmètre cours)

| Jour | Actions apprenant |
|---|---|
| J0 | Cloner, installer, configurer `.env`, tester `SELECT 1` |
| J1 | Écrire HCL, `init`/`fmt`/`validate`/`plan`/`apply`, variables, outputs |
| J2 | Créer un module, `for_each`, `moved`, `dynamic` |
| J3 | Migrer le state vers backend préconfiguré, `import`, drift |
| J4 | Isoler DEV/UAT/PROD, pipeline Terraform `validate`→`plan`→`apply` |
| J5 | Stages, `COPY INTO`, RSA/JWT, RBAC, capstone, cleanup |

---

## Préparation avant la formation

### T-15 jours

| Action | Preuve |
|---|---|
| Identifier postes, réseaux, droits et compte Snowflake | Liste des contraintes et responsables |
| Confirmer les VMs ou postes de formation | 11 postes fonctionnels |
| Créer les utilisateurs Snowflake + PAT | 11 PAT individuels |

### T-7 jours

| Action | Preuve |
|---|---|
| Installer Terraform et VS Code sur les VMs | Versions vérifiées sur chaque poste |
| Préparer le backend Azure Blob Storage | RG + storage account + conteneur |
| Configurer le service principal + RBAC | `Storage Blob Data Contributor` |
| Configurer Azure DevOps (projet, agent, service connection) | Pipeline testé |
| Préparer le storage account pour external stage (M09) | Container accessible |

### T-3 jours

| Action | Preuve |
|---|---|
| Tester le PAT et un objet de formation dédié | Création, lecture et nettoyage contrôlés |
| Vérifier les droits RBAC Snowflake | Permissions suffisantes pour M11 |
| Tester la pipeline CI/CD | Pipeline fonctionnelle |
| Préparer l'identité technique pour JWT (M10) | Utilisateur + clé configurés |

### T-1 jour

| Action | Preuve |
|---|---|
| Confirmer accès, validité du PAT et postes de secours | Décision de démarrage |
| Dernier test de connectivité | Tous les postes OK |
| Préparer le plan de secours | Environnement de secours testé |

---

## Credentials et secrets

### Structure des identifiants

| Identifiant | Usage | Distribution |
|---|---|---|
| Préfixe apprenant | Nommage des ressources | Fourni en début de session |
| PAT Snowflake | CLI et Terraform | Individuel, saisi dans `.env` |
| Username + password | Interface web Snowsight | Individuel |
| Paramètres Azure backend | State distant | Dans `.env.example` (non secret) |
| Service principal | Pipeline (préconfiguré) | Injecté dans Azure DevOps, non visible par l'apprenant |

### Règles de sécurité

1. **Jamais** de secret dans Git, les captures ou les rapports
2. **Jamais** de PAT collé dans une commande
3. **Jamais** de password dans un fichier du dépôt
4. **Toujours** utiliser le PAT via saisie masquée
5. **Toujours** nettoyer les credentials en fin de session
6. **Jamais** `ACCOUNTADMIN` comme solution de dépannage

---

## Gestion des équipes

### Nommage des ressources

```text
<PREFIXE_APPRENANT>_M<MODULE>_<ZONE>_<ENVIRONNEMENT>
```

Exemples :
- `APP01_M01_RAW_DEV` (Database du Module 1)
- `WH_APP01_M01_ETL_DEV` (Warehouse du Module 1)
- `APP01_M05_RAW_DEV` (Database du Module 5)

### Règles d'isolation

| Aspect | Isolation |
|---|---|
| Resources Snowflake | Par préfixe apprenant + module |
| State Terraform | Par préfixe apprenant + module |
| Pipelines | Par préfixe apprenant |
| Environment | DEV → UAT → PROD |

---

## Animation de la formation

### Les 3 règles d'or

> **Règle 1 :** Jamais une ligne de Terraform avant d'avoir cliqué le même objet dans Snowsight.
>
> **Règle 2 :** Jamais de `terraform destroy` sans plan préalable ni confirmation.
>
> **Règle 3 :** Jamais de secret dans Git, les captures ou les rapports.

### Points de convergence (15 min par jour)

À la fin de chaque jour :

1. **Projection SQL** montrant tous les objets créés
2. **Trois observations** extraites de la journée
3. **Justification** du lendemain

### Chaos labs

| Jour | Chaos lab | Objectif |
|---|---|---|
| J2 | Casser un module | Comprendre les contrats de module |
| J3 | State lock (par paires) | Découvrir le locking |
| J4 | Validation cassée | Vérifier que le pipeline bloque |

### Défis

| Jour | Défi | Temps |
|---|---|---|
| J2 | Ajout sans toucher au code | 10 min |
| J5 | Capstone zero-drift | 1 h |

---

## Évaluation

### Contrat de validation (par module)

| Niveau | Contrôle |
|---|---|
| 1 | Structure et absence de placeholders/secrets |
| 2 | `terraform fmt -check` et `terraform validate` |
| 3 | Assertions sur le plan Terraform |
| 4 | Preuve fonctionnelle Snowflake ou Snow CLI |
| 5 | Second plan sans changement inattendu |
| 6 | Challenge évalué par critères |

### Grille d'autonomie

Voir [grille-autonomie.md](grille-autonomie.md).

### Critères de remédiation

| Situation | Parcours |
|---|---|
| Environnement seul en cause | Réparation préalable puis évaluation |
| Workflow encore fragile | Lab guidé puis variante |
| Exécution acquise, explication fragile | Prédiction de plans et reformulation |
| Socle autonome | Exercice de transfert plus exigeant |

---

## Plan de secours

Voir [guide-reprise.md](guide-reprise.md).

---

## Post-formation

### Contrôle différé (J+7)

1. Proposer une variante courte avec documentation autorisée
2. Mesurer la reproduction sans assistance systématique
3. Documenter les résultats

### Feedback

Recueillir le feedback des 11 participants :

1. Aspects positifs
2. Points à améliorer
3. Suggestions d'amélioration
4. Difficultés rencontrées

---

## Contacts utiles

| Rôle | Nom | Contact |
|---|---|---|
| Commanditaire | | |
| Concepteur | | |
| Référent technique | | |
| Relecteur | | |
