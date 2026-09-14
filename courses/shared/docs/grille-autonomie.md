# Grille d'Autonomie

Cette grille evalue les competences acquises par chaque participant a chaque jour
de la formation. Elle est utilisee par le formateur pour identifier les besoins
de remediation.

## Niveaux d'Aval

| Niveau | Symbole | Description |
|--------|---------|-------------|
| **Autonome** | ✅ | Le participant sait executer et expliquer |
| **Accompagne** | ⚠️ | Le participant sait executer avec aide ponctuelle |
| **Non acquis** | ❌ | Le participant ne sait pas executer ni expliquer |
| **Non evalue** | — | Pas encore teste |

---

## Jour 0 — Preparation

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Cloner le depot | | | |
| Installer les outils | | | |
| Configurer .env | | | |
| Tester la connexion Snowflake | | | |
| Authentifier Azure | | | |
| Lancer la validation finale | | | |

---

## Jour 1 — Fondations IaC

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Creer un objet dans Snowsight | | | |
| Ecrire un `main.tf` simple | | | |
| Executer `init`, `validate`, `plan`, `apply` | | | |
| Remplacer un nom dur par une variable | | | |
| Detecter une derive | | | |
| Expliquer la difference `variable` vs `local` | | | |
| Expliquer le role du `plan` | | | |

---

## Jour 2 — Collections et State

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Centraliser une convention dans `locals` | | | |
| Ajouter une validation de variable | | | |
| Creer une collection avec `for_each` | | | |
| Ajouter un objet sans toucher au code | | | |
| Expliquer les 4 roles du state | | | |
| Detecter et corriger une derive | | | |
| Executer `terraform state list` | | | |

---

## Jour 3 — Modules

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Creer un module simple | | | |
| Appeler un module depuis `main.tf` | | | |
| Expliquer `moved` vs `import` | | | |
| Ajouter un objet via un module | | | |
| Utiliser une `data source` | | | |
| Expliquer pourquoi `for_each` est preferred a `count` | | | |
| Expliquer le concept de contrat de module | | | |

---

## Jour 4 — CI/CD et Environnements

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Configurer un backend Azure Blob | | | |
| Migrer le state local vers distant | | | |
| Expliquer les 3 axes d'isolation | | | |
| Lire un pipeline CI/CD | | | |
| Expliquer le flux Validate → Plan → Apply | | | |
| Distinguer workspace vs repertoire | | | |
| Expliquer le mecanisme de locking | | | |

---

## Jour 5 — Production

| Competence | Autonome | Accompagne | Non acquis |
|------------|----------|------------|------------|
| Configurer l'authentification par cle | | | |
| Definir des droits RBAC | | | |
| Tester une action autorisee et refusee | | | |
| Executer `terraform plan -detailed-exitcode` | | | |
| Expliquer le zero-drift | | | |
| Nettoyer les ressources de formation | | | |
| Expliquer l'architecture et ses limites | | | |
| Justifier les choix de production | | | |

---

## Synthese Individuelle

| Participant | J0 | J1 | J2 | J3 | J4 | J5 | Statut |
|-------------|----|----|----|----|----|----| ----|
| APP01 | | | | | | | |
| APP02 | | | | | | | |
| APP03 | | | | | | | |
| APP04 | | | | | | | |
| APP05 | | | | | | | |
| APP06 | | | | | | | |
| APP07 | | | | | | | |
| APP08 | | | | | | | |
| APP09 | | | | | | | |
| APP10 | | | | | | | |
| APP11 | | | | | | | |

---

## Criteres de Remediation

| Situation | Parcours propose |
|-----------|------------------|
| Environnement seul en cause | Reparation prealable puis evaluation directe |
| Workflow encore fragile | Lab guide puis variante |
| Execution acquise, explication fragile | Prediction de plans et reformulation |
| Socle autonome | Exercice de transfert plus exigeant |

---

## Controle Differe (J+7)

Proposer une variante courte avec documentation autorisee.
Mesurer la reproduction sans assistance systematique, pas la memoire des commandes.
