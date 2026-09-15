# Grille d'Autonomie

Cette grille évalue les compétences acquises par chaque participant à chaque jour de la formation. Elle est utilisée par le formateur pour identifier les besoins de remédiation.

## Niveaux d'évaluation

| Niveau | Symbole | Description |
|---|---|---|
| **Autonome** | ✅ | Le participant sait exécuter et expliquer |
| **Accompagné** | ⚠️ | Le participant sait exécuter avec aide ponctuelle |
| **Non acquis** | ❌ | Le participant ne sait pas exécuter ni expliquer |
| **Non évalué** | — | Pas encore testé |

---

## Jour 0 — Préparation

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Cloner le dépôt | | | |
| Installer les outils | | | |
| Configurer `.env` | | | |
| Tester la connexion Snowflake (`SELECT 1`) | | | |
| Confirmer son préfixe apprenant | | | |
| Lancer la validation finale | | | |

---

## Jour 1 — Workflow IaC et contrats typés

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Créer un objet dans Snowsight | | | |
| Écrire un `main.tf` simple | | | |
| Exécuter `init`, `fmt`, `validate`, `plan`, `apply` | | | |
| Remplacer un nom en dur par une variable | | | |
| Définir un `local` et un `output` | | | |
| Ajouter une validation de variable | | | |
| Expliquer le rôle du `plan` | | | |
| Obtenir un second plan sans changement | | | |

---

## Jour 2 — Modules et logique dynamique

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Créer un module simple | | | |
| Appeler un module depuis `main.tf` | | | |
| Expliquer `moved` vs `import` | | | |
| Ajouter un objet via le module | | | |
| Créer une collection avec `for_each` | | | |
| Ajouter un objet sans toucher au code | | | |
| Expliquer le contrat de module (variables + outputs) | | | |
| Expliquer pourquoi `for_each` est préféré à `count` | | | |

---

## Jour 3 — State, import et brownfield

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Expliquer les 4 rôles du state | | | |
| Migrer le state local vers backend distant | | | |
| Expliquer le mécanisme de locking | | | |
| Exécuter `terraform state list` / `state show` | | | |
| Importer une ressource existante | | | |
| Détecter et corriger une dérive | | | |
| Interpréter `plan -detailed-exitcode` | | | |

---

## Jour 4 — Environnements et pipeline

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Expliquer les 3 axes d'isolation | | | |
| Isoler DEV/UAT/PROD par répertoires | | | |
| Distinguer workspace vs répertoire | | | |
| Lire un pipeline CI/CD Terraform | | | |
| Expliquer le flux Validate → Plan → Apply | | | |
| Comprendre le plan immuable (artefact) | | | |
| Vérifier qu'une config invalide est bloquée | | | |

---

## Jour 5 — Snowflake avancé, sécurité et capstone

| Compétence | Autonome | Accompagné | Non acquis |
|---|---|---|---|
| Créer un stage et un file format | | | |
| Exécuter un `COPY INTO` | | | |
| Configurer l'authentification RSA/JWT | | | |
| Définir des droits RBAC as code | | | |
| Tester une action autorisée et refusée | | | |
| Exécuter `terraform plan -detailed-exitcode` | | | |
| Expliquer le zero-drift | | | |
| Nettoyer les ressources de formation (préfixe only) | | | |
| Expliquer l'architecture et ses limites | | | |

---

## Synthèse individuelle

| Participant | J0 | J1 | J2 | J3 | J4 | J5 | Statut |
|---|---|---|---|---|---|---|---|
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

## Critères de remédiation

| Situation | Parcours proposé |
|---|---|
| Environnement seul en cause | Réparation préalable puis évaluation directe |
| Workflow encore fragile | Lab guidé puis variante |
| Exécution acquise, explication fragile | Prédiction de plans et reformulation |
| Socle autonome | Exercice de transfert plus exigeant |

---

## Contrôle différé (J+7)

Proposer une variante courte avec documentation autorisée.
Mesurer la reproduction sans assistance systématique, pas la mémoire des commandes.
