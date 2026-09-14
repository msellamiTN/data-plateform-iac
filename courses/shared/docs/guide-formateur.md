# Guide du Formateur

Ce document contient les notes et procedures pour le formateur de la formation
Terraform & Snowflake.

## Vue d'Ensemble

| Aspect | Detail |
|--------|--------|
| **Duree** | 5 jours x 6 heures = 30 heures |
| **Participants** | 11 apprenants (prefixes APP01 a APP11) |
| **Stack** | Snowflake, Terraform, Azure, Azure DevOps, dbt |
| **Pre-requis** | Aucun prerequis technique pour le Jour 0 |

---

## Preparation Avant la Formation

### T-15 jours

| Action | Preuve |
|--------|--------|
| Identifier postes, reseaux, droits et compte Snowflake | Liste des contraintes et responsables |
| Confirmer les VMs ou postes de formation | 11 postes fonctionnels |
| Verifier les versions des outils | Terraform 1.14.5, provider 2.14.0 |

### T-7 jours

| Action | Preuve |
|--------|--------|
| Installer Terraform et VS Code | Versions verifyes sur chaque poste |
| Obtenir le provider Snowflake | Provider accessible |
| Configurer Azure DevOps | Projet et pipeline prets |

### T-3 jours

| Action | Preuve |
|--------|--------|
| Tester le PAT et un objet de formation dedie | Creation, lecture et nettoyage controles |
| Verifier les droits RBAC | Permissions suffisantes |
| Tester la pipeline CI/CD | Pipeline fonctionnelle |

### T-1 jour

| Action | Preuve |
|--------|--------|
| Confirmer acces, validite du PAT et postes de secours | Decision de demarrage |
| Dernier test de connectivite | Tous les postes OK |
| Preparer le plan de secours | Environnement de secours teste |

---

## Credentials et Secrets

### Structure des Identifiants

| Identifiant | Usage | Distribution |
|-------------|-------|--------------|
| Prefixe apprenant | Nommage des ressources | Fourni en debut de session |
| PAT Snowflake | CLI et Terraform | Individuel, saisi dans .env |
| Username + password | Interface web Snowsight | Individuel |
| Service principal Azure | Authentification Azure | Partage pour tout le groupe |

### Regles de Securite

1. **Jamais** de secret dans Git, les captures ou les rapports
2. **Jamais** de PAT colle dans une commande
3. **Jamais** de password dans un fichier du depot
4. **Toujours** utiliser le PAT via saisie masquee
5. **Toujours** nettoyer les credentials en fin de session

---

## Gestion des Equipes

### Nommage des Resources

```text
<PREFIXE_APPRENANT>_<ZONE>_<ENVIRONNEMENT>
```

Exemples :
- `APP01_RAW_DEV` (Database)
- `WH_APP01_INGEST_DEV` (Warehouse)
- `APP01_M01_RAW_DEV` (Resource du module M01)

### Regles d'Isolation

| Aspect | Isolation |
|--------|-----------|
| Resources Snowflake | Par prefixe apprenant |
| State Terraform | Par prefixe apprenant |
| Pipelines | Par prefixe apprenant |
| Environment | DEV → UAT → PROD |

---

## Animation de la Formation

### Les 3 Regles d'Or

> **Regle 1 :** Jamais une ligne de Terraform avant d'avoir clique le meme objet dans Snowsight.
>
> **Regle 2 :** Jamais de `terraform destroy` sans plan prealable ni confirmation.
>
> **Regle 3 :** Jamais de secret dans Git, les captures ou les rapports.

### Points de Convergence (15 min par jour)

A la fin de chaque jour :

1. **Projection SQL** montrant tous les objets crees
2. **Trois observations** extraites de la journee
3. **Justification** du lendemain

### Chaos Labs

| Jour | Chaos Lab | Objectif |
|------|-----------|----------|
| J2 | Casser une collection | Comprendre `for_each` vs `count` |
| J3 | Casser un module | Comprendre les contrats de module |
| J4 | State Lock (par paires) | Decouvrir le locking |

### Defis

| Jour | Defi | Temps |
|------|------|-------|
| J2 | Ajout sans toucher au code | 10 min |
| J3 | Ajout via module | 10 min |
| J4 | Convergence de modules | 15 min |
| J5 | Capstone zero-drift | 1h |

---

## Evaluation

### Contrat de Validation (par module)

| Niveau | Controle |
|--------|----------|
| 1 | Structure et absence de placeholders/secrets |
| 2 | `terraform fmt -check` et `terraform validate` |
| 3 | Assertions sur le plan Terraform |
| 4 | Preuve fonctionnelle Snowflake, Snow CLI ou dbt |
| 5 | Second plan sans changement inattendu |
| 6 | Challenge evalue par criteres |

### Grille d'Autonomie

Voir [grille-autonomie.md](grille-autonomie.md).

### Criteres de Remediation

| Situation | Parcours |
|-----------|----------|
| Environnement seul en cause | Reparation prealable puis evaluation |
| Workflow encore fragile | Lab guide puis variante |
| Execution acquise, explication fragile | Prediction de plans et reformulation |
| Socle autonome | Exercice de transfert plus exigeant |

---

## Plan de Secours

Voir [guide-reprise.md](guide-reprise.md).

---

## Preparing l'Avance (Jours 4-5)

### Pre-Requis Avance

| Controle | Statut |
|----------|--------|
| Azure CLI disponible | |
| Abonnement et contexte connus | |
| Conteneur Blob et autorisations prets | |
| Projet Azure DevOps et connexion de service | |
| Capacite d'execution d'un agent | |
| Acces au backend et depuis l'agent | |

### Contenu Avance

| Jour | Modules | Duree |
|------|---------|-------|
| J4 | M7 (CI/CD) + M8 (Environnements) | 6h |
| J5 | M9 (Ingestion) + M10 (Auth) + M11 (RBAC) + M12 (Capstone) + M13+M14 (FinOps) | 6h |

---

## Post-Formation

### Controle Differe (J+7)

1. Proposer une variante courte avec documentation autorisee
2. Mesurer la reproduction sans assistance systematique
3. Documenter les resultats

### Feedback

Recueillir le feedback des 11 participants :

1. Aspects positifs
2. Points a ameliorer
3. Suggestions d'amelioration
4. difficultes rencontrees

---

## Contacts Utiles

| Role | Nom | Contact |
|------|-----|---------|
| Commanditaire | | |
| Concepteur | | |
| Referent technique | | |
| Relecteur | | |
