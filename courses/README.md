# Formation Terraform & Snowflake

## Parcours Officiel — 5 Jours x 6 Heures = 30 Heures

> **Contexte :** GlobalBank migre son datawarehouse vers Snowflake. Le predecesseur a tout construit a la main dans Snowsight. L'Inspection Generale demande qui a cree quoi, quand, et pourquoi. Personne ne peut repondre.
>
> **Notre mission :** reconstruire la plateforme en tant que code.

**Stack :** Snowflake Enterprise · Terraform · Azure · Azure DevOps · dbt

**References :** [`PROGRAMME_FORMATION.md`](../PROGRAMME_FORMATION.md) · [architecture](shared/docs/architecture-reference.md) · [naming](shared/docs/naming-conventions.md) · [troubleshooting](shared/docs/guide-troubleshooting.md) · [reprise](shared/docs/guide-reprise.md)

---

## Le Fil Conducteur : GlobalBank

Chaque jour commence par un email de **Sofia Almeida** (Head of Data Platform) qui pose le probleme business du jour.

| Jour | Email de Sofia | Probleme |
|------|----------------|----------|
| J0 | Pas d'email — on prepare les outils | — |
| J1 | Pas d'email — on decouvre le workflow | Le predecesseur a tout fait a la main |
| J2 | *"Ou est ecrite votre convention de nommage ? Qui empeche un warehouse 4X-LARGE ?"* | Pas de garde-fous |
| J3 | *"for_each a detruit un objet. Sur une table avec des donnees, c'est un incident."* | Pas de facteurisation |
| J4 | *"Le state vit sur 11 ordinateurs. Si un casse, la plateforme est orpheline."* | Pas de backend distant |
| J5 | *"Lundi, on va en production. Pas d'apply sans review et preuve."* | Pas de governance |

---

## Comment Utiliser Ce Parcours

### Workflow par module

1. **Ouvrez le bon dossier** : `labs/mXX-name/` (repertoire dedie au module)
2. **Lisez `course.md`** — les concepts avant le code
3. **Executez `lab.md`** — sans consulter la solution
4. **Verifiez vos preuves** — comparez a `expected-output.md`
5. **Utilisez `troubleshooting.md`** — avant de demander de l'aide
6. **Terminez le challenge** — evaluation integree

### Les 3 Regles d'Or

> **Regle 1 :** Jamais une ligne de Terraform avant d'avoir clique le meme objet dans Snowsight.
>
> **Regle 2 :** Jamais de `terraform destroy` sans plan prealable ni confirmation.
>
> **Regle 3 :** Jamais de secret dans Git, les captures ou les rapports.

## Legend

| Badge | Portee |
|---|---|
| `[CORE]` | Obligatoire : Terraform, Snowflake, Azure, Azure DevOps |
| `[ANNEXE]` | Comparaison AWS ou GCP, non executee |
| `[WINDOWS]`, `[UNIX]` | Commande propre au shell |
| `[CHECK]` | Checkpoint ou preuve |
| `[SECURITY]` | Identite, privilege ou secret |
| `[COST]` | Ressource facturable |
| `[CLEANUP]` | Nettoyage controle |
| `[CHAOS]` | Exercice de rupture controlee |
| `[DEFI]` | Challenge temps limite |

## Convention de nommage

```text
<PREFIXE_APPRENANT>_<ZONE>_<ENVIRONNEMENT>
```

Exemples : `ABC_RAW_DEV`, `ABC_ETL_UAT`. Les environnements sont **DEV**, **UAT** et **PROD** dans un compte Snowflake unique.

> Chaque participant recoit un prefixe unique (APP01 a APP11). C'est votre identite dans la plateforme.

## Architecture des labs — isolation par module

Chaque module possede son **propre repertoire de travail** sous `labs/`. Cette architecture remplace l'ancien repertoire partage `environments/dev/` et garantit que chaque lab est **autonome** (aucune dependance entre labs).

```text
labs/
  m01-iac-workflow/         # M1: Premieres ressources Terraform
  m02-state-management/     # M2: Migration du state distant
  m03-import-brownfield/    # M3: Import de ressources existantes
  m04-variables-outputs/    # M4: Variables, validations, outputs
  m05-modules/              # M5: Extraction de module
  m06-dynamic-logic/        # M6: for_each, dynamic blocks
  m07-cicd-pipeline/        # M7: Pipeline Azure DevOps
  m08-environments/         # M8: Deploiement multi-environnement
  m09-snowflake-advanced/   # M9: Stages, file formats, COPY
  m10-security-auth/        # M10: Authentification JWT key-pair
  m11-rbac/                 # M11: Roles et grants RBAC
  m12-capstone/             # M12: Assemblage capstone
  m13-finops-observability/ # M13: FinOps avec dbt
  m14-data-products/        # M14: Data products
```

### Proprietes de chaque lab

- **Repertoire dedie** avec fichiers template (`provider.tf`, `versions.tf`, `variables.tf`, `terraform.tfvars.example`).
- **Nommage des ressources par module** : `APP01_M01_RAW_DEV`, `APP01_M05_RAW_DEV`, etc. — chaque lab cree des ressources uniques, sans collision avec les autres labs.
- **Demarrage propre** : executez `Reset-Lab.ps1` avant de commencer pour repartir d'un environnement sain (supprime le state, les ressources et les fichiers generes du lab precedent).
- **Cleanup final** : chaque lab se termine par `terraform destroy` pour nettoyer les ressources Snowflake et Azure.
- **Autonome** : aucun lab ne depend d'un autre — vous pouvez realiser les modules dans l'ordre ou reprendre un module isole.

> `[CLEANUP]` `Reset-Lab.ps1` (dans `scripts/`) est l'outil de nettoyage officiel. Il reinitialise un lab donne avant de commencer ou pour repartir a zero.

---

## Jour 0 — Preparer votre environnement (1 h 30)

> [Point d'entree Day 0 ->](day-00/README.md)

Le Jour 0 est **automatise** : clonez le projet type, executez les scripts, configurez les connexions Snowflake et Azure. Aucune ressource Cloud n'est creee.

| Etape | Duree | Support |
|---|---:|---|
| Installation et verification des outils | 40 min | [Lab Jour 0](day-00/module-00-setup/lab.md) |
| Connexion Snowflake + Azure + validation | 50 min | [Lab Jour 0](day-00/module-00-setup/lab.md) |
| **Total** | **1 h 30** | |

**Livrable :** `Toolchain status: READY` + `snow sql -q 'SELECT 1' -c training` + `Test-LabConnectivity -> READY`

**Preuves individuelles :**
- [ ] Terraform version affiche 1.14.x
- [ ] `snow sql -q 'SELECT 1' -c training` retourne un resultat
- [ ] Prefixe apprenant identifie (APP01 a APP11)

---

## Jour 1 — Fondations IaC et Variables (3 h 50)

> [Point d'entree Day 1 ->](day-01/README.md)

> **Email Sofia :** *Le predecesseur a tout construit a la main. L'Inspection Generale demande qui a cree quoi, quand, et pourquoi. Personne ne peut repondre. Notre mission : reconstruire la plateforme en tant que code.*

| Module | Duree | Lab | Course | Troubleshooting |
|---|---:|---|---|---|
| M1 — IaC Workflow | 3h | [lab](day-01/module-01-iac-workflow/lab.md) | [cours](day-01/module-01-iac-workflow/course.md) | [guide](day-01/module-01-iac-workflow/troubleshooting.md) |
| M4 — Variables & Outputs | 50 min | [lab](day-01/module-04-variables-outputs/lab.md) | [cours](day-01/module-04-variables-outputs/course.md) | [guide](day-01/module-04-variables-outputs/troubleshooting.md) |

**Livrable :** database, schema et warehouse Snowflake crees par un projet ecrit par l'apprenant, et contrats types.

**Preuves individuelles :**
- [ ] `terraform plan` affiche `No changes.` apres l'apply
- [ ] Preuve SQL : `SHOW WAREHOUSES LIKE '<PREFIX>%';` retourne mon objet
- [ ] Variable modifiee → `terraform plan` detecte la difference

**Point de convergence (15 min) :**
- Projection SQL montrant tous les objets crees
- Trois observations de la journee
- Justification du Jour 2

---

## Jour 2 — State et Import Brownfield (2 h 10)

> [Point d'entree Day 2 ->](day-02/README.md)

> **Email Sofia :** *"Ou est ecrite votre convention de nommage ? Qui empeche un ingenieur de creer un warehouse 4X-LARGE par erreur ? Aujourd'hui, vos parametres doivent etre declares, tyres, bornes — et vos conventions ecrites a UN seul endroit."*

| Module | Duree | Lab | Course | Troubleshooting |
|---|---:|---|---|---|
| M2 — State Management | 1h10 | [lab](day-02/module-02-state-management/lab.md) | [cours](day-02/module-02-state-management/course.md) | [guide](day-02/module-02-state-management/troubleshooting.md) |
| M3 — Import Brownfield | 1h | [lab](day-02/module-03-import-brownfield/lab.md) | [cours](day-02/module-03-import-brownfield/course.md) | [guide](day-02/module-03-import-brownfield/troubleshooting.md) |

**Livrable :** state distant securise sur Azure Blob Storage et ressource brownfield importee sans recreation.

**Preuves individuelles :**
- [ ] `terraform plan` affiche `No changes.` apres l'ajout d'un local
- [ ] Ajout d'une entree sans toucher au code → `Plan: 1 to add`
- [ ] Preuve Snowsight : les 3 objets visibles

**[CHAOS LAB] — Casser une collection :**
Supprimez une cle du milieu de votre map. Observez que `for_each` ne detruit que l'objet cible (contrairement a `count` qui reindexe tout).

**Point de convergence (15 min) :**
- Projection SQL montrant tous les objets
- Trois observations de la journee
- Justification du Jour 3

---

## Jour 3 — Modules et Logique Dynamique (2 h)

> [Point d'entree Day 3 ->](day-03/README.md)

> **Email Sofia :** *"for_each a detruit un objet. Sur une table avec des donnees, c'est un incident. Comment l'eviter ? Comment adopter vos objets legacy sans les detruire ? Et un constat : onze personnes ecrivent la meme structure. Pourquoi l'ecrire onze fois ?"*

| Module | Duree | Lab | Course | Troubleshooting |
|---|---:|---|---|---|
| M5 — Modules reutilisables | 1h | [lab](day-03/module-05-modules/lab.md) | [cours](day-03/module-05-modules/course.md) | [guide](day-03/module-05-modules/troubleshooting.md) |
| M6 — Logique dynamique | 1h | [lab](day-03/module-06-dynamic-logic/lab.md) | [cours](day-03/module-06-dynamic-logic/course.md) | [guide](day-03/module-06-dynamic-logic/troubleshooting.md) |

**Livrable :** module Landing Zone reutilisable et deploiement pilote par metadonnees.

**Preuves individuelles :**
- [ ] `terraform plan` affiche `has moved to` — 0 destruction
- [ ] Ajout d'un 5e objet via le module → `Plan: 1 to add`
- [ ] Explication : pourquoi `for_each` est preferred a `count`

**[CHAOS LAB] — Casser un module :**
Modifiez une valeur par defaut dans le module. Observez la propagation a toutes les ressources.

**[DEFI] — Ajout sans toucher au code :**
Ajoutez un 5e objet en modifiant UNIQUEMENT `terraform.tfvars`. Le plan doit montrer `1 to add`.

**Point de convergence (15 min) :**
- Projection SQL montrant tous les objets
- Trois observations de la journee
- Justification du Jour 4

---

## Jour 4 — CI/CD et Environnements (2 h 05)

> [Point d'entree Day 4 ->](day-04/README.md)

> **Email Sofia :** *"Le state vit sur 11 ordinateurs. Si un casse, la plateforme est orpheline. Inacceptable. Lundi, on va en production. Pas d'apply sans review et preuve."*

| Module | Duree | Lab | Course | Troubleshooting |
|---|---:|---|---|---|
| M7 — CI/CD Pipeline | 1h15 | [lab](day-04/module-07-cicd-pipeline/lab.md) | [cours](day-04/module-07-cicd-pipeline/course.md) | [guide](day-04/module-07-cicd-pipeline/troubleshooting.md) |
| M8 — Environnements | 50 min | [lab](day-04/module-08-environments/lab.md) | [cours](day-04/module-08-environments/course.md) | [guide](day-04/module-08-environments/troubleshooting.md) |

**Livrable :** pipeline CI/CD avec quality gates sur Azure DevOps et environnements isoles (DEV/UAT/PROD).

**Preuves individuelles :**
- [ ] Pipeline execute depuis l'agent (pas en local)
- [ ] States et noms distincts entre DEV et PROD
- [ ] Plan enregistré published comme potentiellement sensible

**[CHAOS LAB] — State Lock (par paires) :**
Deux personnes partagent une cle de state. Decouvrez le probleme de corruption, puis le mecanisme de lease le resout.

**[DEFI] — Convergence de modules :**
Trois versions d'un module, une retenue (par vote). Enseignement : la gouvernance de modules est un processus social.

**Point de convergence (15 min) :**
- Projection SQL montrant tous les objets
- Trois observations de la journee
- Justification du Jour 5

---

## Jour 5 — Snowflake Avance, Securite, Capstone, FinOps & Data Products (5 h 20)

> [Point d'entree Day 5 ->](day-05/README.md)

> **Email Sofia :** *"Lundi, on va en production. Pas d'apply sans review et preuve. Les cles ne voyagent plus sur Slack. Nous devons justifier chaque credit consomme."*

| Module | Duree | Lab | Course | Troubleshooting |
|---|---:|---|---|---|
| M9 — Ingestion et ressources avancees | 1h30 | [lab](day-05/module-09-snowflake-advanced/lab.md) | [cours](day-05/module-09-snowflake-advanced/course.md) | [guide](day-05/module-09-snowflake-advanced/troubleshooting.md) |
| M10 — Identite technique et Key Vault | 50 min | [lab](day-05/module-10-security-auth/lab.md) | [cours](day-05/module-10-security-auth/course.md) | [guide](day-05/module-10-security-auth/troubleshooting.md) |
| M11 — RBAC as Code | 1h | [lab](day-05/module-11-rbac/lab.md) | [cours](day-05/module-11-rbac/course.md) | [guide](day-05/module-11-rbac/troubleshooting.md) |
| M12 — Capstone | 1h | [lab](day-05/module-12-capstone/lab.md) | [cours](day-05/module-12-capstone/course.md) | [guide](day-05/module-12-capstone/troubleshooting.md) |
| M13 — FinOps & Observabilite | 30 min | [lab](day-05/module-13-finops-observability/lab.md) | [cours](day-05/module-13-finops-observability/course.md) | [guide](day-05/module-13-finops-observability/troubleshooting.md) |
| M14 — Data Products | 30 min | [lab](day-05/module-14-data-products/lab.md) | [cours](day-05/module-14-data-products/course.md) | [guide](day-05/module-14-data-products/troubleshooting.md) |

**Livrable :** plateforme composee et evaluee, pipeline de qualite, indicateurs FinOps et Data Products gouvernes. Capstone avec zero-drift et cleanup verifie.

**Preuves individuelles :**
- [ ] `terraform plan -detailed-exitcode` = 0 (zero drift)
- [ ] Action autorisee et action refusee testees
- [ ] Cleanup verifie cote Snowique ET cote Azure
- [ ] Projet explique et limites documentees

**[DEFI] — Capstone :**
Deploiement complet de la plateforme avec validation zero-drift. Presentation des preuves.

---

## Structure standard d'un module

Chaque module du catalogue (`courses/day-XX/module-XX-name/`) contient la **pedagogie** (cours, lab, troubleshooting, solution). Le **code de travail** de l'apprenant vit dans le repertoire dedie `labs/mXX-name/` du projet type clone.

```text
courses/day-XX/module-XX-name/      # pedagogie (lecture)
├── course.md           ← concepts (lire avant le lab)
├── lab.md              ← atelier pratique pas a pas
├── expected-output.md  ← resultats attendus pour comparaison
├── troubleshooting.md  ← diagnostics non destructifs
├── slides.md           ← support de presentation
├── starter/            ← squelette (sans code de ressource)
├── solution/           ← solution de reference (ne pas copier)
└── assets/             ← diagrammes et captures

labs/mXX-name/                      # code de travail (execution)
├── provider.tf         ← provider Terraform
├── versions.tf         ← contraintes de versions
├── variables.tf        ← variables du lab
├── terraform.tfvars.example  ← valeurs d'exemple
├── main.tf             ← ecrit par l'apprenant pendant le lab
└── outputs.tf          ← outputs du lab
```

Le `starter/` ne contient pas le code que l'apprenant doit apprendre a ecrire. Il peut contenir des donnees, validateurs et assets non pedagogiques. La solution est separee et n'est jamais copiee automatiquement dans le workspace. Le repertoire `labs/mXX-name/` fournit les fichiers template (provider, versions, variables) et l'apprenant y ecrit son `main.tf` pendant le lab.

## Navigation rapide

| Jour | Modules | Point d'entree |
|---|---|---|
| Jour 0 | M00 | [day-00/README.md](day-00/README.md) |
| Jour 1 | M1, M4 | [day-01/README.md](day-01/README.md) |
| Jour 2 | M2, M3 | [day-02/README.md](day-02/README.md) |
| Jour 3 | M5, M6 | [day-03/README.md](day-03/README.md) |
| Jour 4 | M7, M8 | [day-04/README.md](day-04/README.md) |
| Jour 5 | M9 → M14 | [day-05/README.md](day-05/README.md) |

## Contrat de validation

| Niveau | Controle |
|---|---|
| 1 | Structure et absence de placeholders/secrets |
| 2 | `terraform fmt -check` et `terraform validate` |
| 3 | Assertions sur le plan Terraform |
| 4 | Preuve fonctionnelle Snowflake, Snow CLI ou dbt |
| 5 | Second plan sans changement inattendu |
| 6 | Challenge evalue par criteres |

## Regles de securite

- aucun secret dans Git, les captures ou les rapports;
- aucun mot de passe Snowflake dans une racine enseignee;
- aucun `.terraform/`, state ou plan distribue dans un starter;
- ressources prefixees par apprenant et suffixees par environnement;
- warehouse economique avec auto-suspend;
- avertissement et portee avant toute destruction ou policy reseau;
- cleanup verifie cote Snowique **et** cote Azure;
- role d'administration limite aux operations qui l'exigent reellement.

## Versions

Les versions des outils et providers sont definies dans la [politique de versions](../docs/version-policy.md). Aucun support ne redefinit une version localement.

---

## Supports Historiques (Legacy)

> **Attention :** Les dossiers ci-dessous contiennent d'anciens supports de formation. Ils sont conserves a des fins de reference mais ne doivent plus etre utilises comme instructions d'execution.

| Dossier | Contenu | Statut |
|---------|---------|--------|
| `initiation/` | Ancien parcours GlobalBank (equipes) | Absorbe dans le parcours actuel |
| `terraform-initiation-3jours/` | Ancien parcours individuel 3 jours | Absorbe dans les Jours 1-3 |
| `terraform-avance-2jours/` | Ancien parcours avance 2 jours | Absorbe dans les Jours 4-5 |
| `export/` | Exports plats (artifacts de build) | Archive |

> Ces dossiers ne sont pas des points d'entree officiels. Utilisez `day-00/` a `day-05/` comme seul parcours.
