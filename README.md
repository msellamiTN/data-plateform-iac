# Data Platform as Code — Terraform × Snowflake

Formation officielle **Terraform pour le provider Snowflake** : 3 jours d'initiation + 2 jours avancé (CI/CD, RBAC, FinOps), conçue pour 11 participants hétérogènes (Data Analysts, Data Engineers, Business Developers, BI Engineers) — **sans prérequis** Azure, Azure DevOps, PowerShell ou programmation.

## Parcours

| Jour | Contenu | Modules |
|---|---|---|
| **J0** (optionnel) | Onboarding, installation, connectivité | M00 |
| **J1** | Fondations IaC : cycle `init → plan → apply`, variables, locals, outputs | M01, M04 |
| **J2** | State : backend distant (Azure Blob préconfiguré), locking, drift, import brownfield | M02, M03 |
| **J3** | Modularité : modules réutilisables, `for_each`, logique dynamique | M05, M06 |
| **J4** | Industrialisation : multi-environnements, pipeline CI/CD Azure DevOps | M07, M08 |
| **J5** | Avancé : stages/COPY, auth RSA/JWT, RBAC as Code, FinOps, capstone zero-drift | M09, M10, M11, M13, M12 (+M14 optionnel) |

Catalogue détaillé : [`courses/README.md`](courses/README.md)

## Démarrage rapide (apprenant)

```powershell
# Jours 1–3 : Snowflake uniquement, aucun Azure requis
.\scripts\Learner-Login.ps1 -LearnerPrefix APP01 -SnowflakeOnly
.\scripts\Test-TerraformReady.ps1
cd labs\m01-iac-workflow
```

```bash
# Équivalent Bash
source ./scripts/learner-login.sh APP01 --snowflake-only
./scripts/test-terraform-ready.sh
cd labs/m01-iac-workflow
```

- `labs/mXX-*/` — workspaces hands-on prêts à l'emploi (M01→M14)
- `courses/day-XX/` — supports, ateliers guidés, solutions et troubleshooting
- `student-track/` — parcours auto-évalué : `.\scripts\SelfPacedLab.ps1 -Module 4 -All`

## Structure

```
courses/        Supports officiels par jour (course.md, lab.md, starter/, solution/)
labs/           Workspaces apprenant m01..m14 (Terraform prêt à l'emploi)
student-track/  Mode self-paced avec validateurs automatiques et rapports
scripts/        Outillage PS + Bash : login, preflight, reset, flotte formateur
usecase/        Contexte métier GlobalBank (4 équipes, personas)
secrets/        Jamais commité — PAT/SP locaux, voir secrets/README.md
```

## Personas GlobalBank

Chaque lab se décline sur les objets de votre équipe — voir [`courses/shared/docs/personas-globalbank.md`](courses/shared/docs/personas-globalbank.md) :

- 🔵 **Platform** — warehouses, resource monitors, rôles globaux
- 🟢 **Data Engineering** — landing zones, stages, file formats, `COPY INTO`
- 🟠 **Business Data** — domaines métiers, rétention, tags, data sharing
- 🟣 **BI & Analytics** — datamarts, schémas en étoile, vues de reporting

## Formateur

```powershell
.\scripts\Test-FleetReadiness.ps1          # état des 11 flottes APP01..APP11
.\scripts\Clean-FleetResources.ps1         # suspendre les warehouses (défaut)
.\scripts\Clean-FleetResources.ps1 -Drop -Force   # destruction bornée aux préfixes
```

Guide complet : [`courses/shared/docs/guide-formateur.md`](courses/shared/docs/guide-formateur.md)

## Sécurité

- Aucun secret dans Git — `secrets/`, `.env`, `*.tfvars`, `*.exe`, `.terraform/` sont ignorés (`.gitignore`)
- Backend Azure : `use_azuread_auth = true` (RBAC, pas de clés de compte)
- Auth progressive : PAT (J1–J3) → RSA/JWT (M10) → workload identity (CI/CD)
- Règles détaillées : [`secrets/README.md`](secrets/README.md)
