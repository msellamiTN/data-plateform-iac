# Couverture du référentiel officiel Terraform — Matrice instructeur

Matrice de correspondance entre les **6 domaines officiels** du référentiel Terraform et les modules du cours. Usage : vérifier qu'un concept demandé en session est couvert, et où.

> Légende : ✅ exercé en lab · 📘 enseigné en théorie · 💡 mentionné/cadré · — hors scope initiation

## Domaine 1 — Manage resource lifecycle

| Concept | Module | Couverture |
|---|---|---|
| init / plan / apply / destroy | M01 + tous les labs | ✅ |
| Importer des ressources (`import {}`, `terraform import`) | M03 | ✅ |
| Corriger un drift (`plan`, `apply`) | M02, M03, M12 | ✅ |
| Audit de drift sans correction (`plan -refresh-only`) | M03 étape 5.4 | ✅ |
| Refactorer sans casser le state (`moved`) | M03, M05 | ✅ |
| `terraform state list/show/mv/rm` | M02 étape 5.5 | ✅ |
| Resource targeting (`-target`) | M03 étape 5.6 | ✅ |
| Workspaces CLI (`workspace new/select/delete`) | M02 étape 5.7 | ✅ |

## Domaine 2 — Develop and troubleshoot dynamic configuration

| Concept | Module | Couverture |
|---|---|---|
| HCL dynamique (`for_each`, `dynamic`, `for`) | M06 | ✅ |
| Data sources (`data "..."`) | M06 étape 5.5, M12 check | ✅ |
| Fonctions (`lookup`, `merge`, `coalesce`, `flatten`, `try`, `can`, `format`, `jsonencode`) | M04 (`can`), M06 étape 5.6 | ✅ |
| Meta-arguments (`count`, `for_each`, `depends_on`, `lifecycle`) | M04 étape 5.5–5.6, M06 | ✅ |
| Type constraints + `validation {}` | M04 | ✅ |
| Custom conditions (`precondition`, `postcondition`) | M04 étape 5.6 | ✅ |
| `check` blocks | M06 étape 5.7, M12 étape 5.5 | ✅ |
| Tests Terraform (`.tftest.hcl`) | M12 étape 5.5 | ✅ |
| Données sensibles (`sensitive`, state en clair, éphémère/write-only) | M04 étape 5.7, M13 | ✅ |
| Intégration coffre de secrets (Vault) | J0/J5 : Azure Key Vault ; M13 cadrage Vault↔KV | 💡 |

## Domaine 3 — Collaborative Terraform workflows

| Concept | Module | Couverture |
|---|---|---|
| Versions providers + `.terraform.lock.hcl` | M02 étape 5.8, tous les `versions.tf` | ✅ |
| Backend distant (Azure Blob, RBAC, locking) | M02 | ✅ |
| Terraform en automatisation (`-input=false`, `-detailed-exitcode`, artefacts tfplan) | M07 | ✅ |
| Partage de données entre stacks (`terraform_remote_state`) | M02 étape 5.6, M08 étape 5.6 | ✅ |
| Workspaces vs répertoires/tfvars | M02 étape 5.7, M08 étape 5.5 | ✅ |
| Gestion du binaire + upgrades (`init -upgrade`) | M02 étape 5.8 | ✅ |

## Domaine 4 — Create, maintain, and use Terraform modules

| Concept | Module | Couverture |
|---|---|---|
| Créer un module (contrat d'interface) | M05, M06, M12 | ✅ |
| Appeler un module (local) | M05, M06, M10, M12 | ✅ |
| Versionner (`git::...?ref=`, registry) | M05 étape 5.5 | ✅ |
| Refactorer config existante → modules | M05 (`moved`) | ✅ |
| Providers dans les modules (`providers = {}`) | M05 étape 5.5, M10 étape 5.6 | ✅ |

## Domaine 5 — Configure and use Terraform providers

| Concept | Module | Couverture |
|---|---|---|
| Architecture plugin (core ↔ provider ↔ registry) | M10 course §6.0 | 📘 |
| Configurer le provider + auth (PAT → RSA/JWT) | M01 → M10 | ✅ |
| `required_providers` / `required_version` | Tous les `versions.tf` | ✅ |
| Provider aliases | M10 étape 5.6 | ✅ |
| Diagnostiquer (`TF_LOG`, `TF_LOG_PATH`, `terraform console`, `terraform providers`) | M10 étape 5.7 | ✅ |

## Domaine 6 — Collaborate using HCP Terraform

| Concept | Module | Couverture |
|---|---|---|
| Backend `cloud {}` / `remote`, enhanced backends | M02 course §3.1.bis | 💡 |
| Run workflow / run modes / run tasks | M02 §3.1.bis + M07 (équivalent ADO) | 💡 |
| Workspaces HCP / variables / credentials | M02 §3.1.bis + M08 course §2 | 💡 |
| Gouvernance / access management | M08 course §2 | 💡 |
| Migration vers HCP Terraform | — | — |

> **Choix pédagogique** : le domaine 6 est couvert en cadrage/mapping — les concepts (runs gérés, workspaces managés, gouvernance) sont démontrés avec Azure DevOps + backend Azure, sans provisionner une org HCP Terraform. Cohérent avec le périmètre initiation.

## Concepts volontairement hors scope

- Hands-on HCP Terraform (org, tokens) — remplacé par le mapping Azure DevOps
- HashiCorp Vault déployé — remplacé par Azure Key Vault (déjà en place)
- Sentinel/OPA policy-as-code — les gates ADO jouent ce rôle
