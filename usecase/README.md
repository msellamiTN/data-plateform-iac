> ⚠️ **AVERTISSEMENT — SUPPORT HISTORIQUE**
>
> Ce dossier contient l'ancien parcours de formation GlobalBank. Il est conserve
> a des fins de reference mais **ne doit plus etre utilise comme instruction
> d'execution**.
>
> **Le parcours officiel unique se trouve dans :** [courses/day-00/ a day-05/](../README.md)
>
> Ce dossier a ete absorbe dans le nouveau parcours. Les elements utiles
> (narrative, Chaos Labs, anti-seches) ont ete integres aux README enrichis.

---

# 🏦 Parcours GlobalBank — Industrialisation d'une Data Platform

> **Formation Terraform + provider Snowflake**
> **Durée :** 5 jours · **Public :** 11 apprenants répartis en 4 équipes
> **Prérequis :** aucun en Terraform ; un accès Snowflake et Azure par apprenant

---

## Le scénario

GlobalBank migre son datawarehouse vers Snowflake. L'ancien responsable a tout construit **à la main** dans Snowsight. L'Inspection Générale exige de savoir qui a créé quoi, quand et pourquoi. L'équipe Data Platform doit **reconstruire la plateforme en tant que code**.

```
                    GLOBALBANK DATA PLATFORM
                              │
   ┌──────────────┬───────────┼──────────────┬──────────────┐
   ▼              ▼           ▼              ▼              ▼
🔵 PLATFORM   🟢 DATA ENG  🟠 BUSINESS DATA  🟣 BI
le compute    les zones     un domaine       un mart
et les rôles  techniques    = une database   = une database
```

---

## Les 4 équipes

| Équipe | Membres | Types de ressources qu'elle crée |
|---|---|---|
| 🔵 **Platform / DevOps** | Fares · Mohamed · Sirine | `WAREHOUSE` · `ROLE` · `GRANT` · `RESOURCE MONITOR` |
| 🟢 **Data Engineering** | Amal · Lara | `DATABASE` · `SCHEMA` · `TABLE` · `FILE FORMAT` · `STAGE` · `STREAM` · `TASK` |
| 🟠 **Business Data** | Manel · Leila · Olfa | `DATABASE` · `SCHEMA` · `TABLE` · `VIEW` · `FUNCTION` · `SHARE` · `GRANT` |
| 🟣 **BI / Analytics** | Ghassen · Adem · Hadhemi | `DATABASE` · `SCHEMA` · `TABLE` · `VIEW` · `MATERIALIZED VIEW` · `SHARE` |

> **Règle n°1 de la semaine :** chacun ne crée que les objets de son équipe. C'est ce qui permet à 11 personnes de travailler en parallèle dès le premier jour.

---

## Parcours de 5 jours

| Jour | Thème | Fondements | Atelier |
|---:|---|---|---|
| **1** | Du clic au code | `resource`, `provider`, `plan`/`apply`, `variable`, dérive | [day-01/atelier-globalbank-jour-01.md](day-01/atelier-globalbank-jour-01.md) |
| **2** | Industrialiser une collection | `locals`, `validation`, `for_each`, `output` | [day-02/atelier-globalbank-jour-02.md](day-02/atelier-globalbank-jour-02.md) |
| **3** | Devenir une plateforme | `moved`, `import`, `module`, `data` sources | [day-03/atelier-globalbank-jour-03.md](day-03/atelier-globalbank-jour-03.md) |
| **4** | State distant, modules, environnements | `backend "azurerm"`, modules, DEV/UAT | [day-04/atelier-globalbank-jour-04.md](day-04/atelier-globalbank-jour-04.md) |
| **5** | Pipeline, sécurité, gouvernance, capstone | CI/CD, JWT/Key Vault, RBAC, ingestion, FinOps/dbt, capstone | [day-05/atelier-globalbank-jour-05.md](day-05/atelier-globalbank-jour-05.md) |

---

## Pédagogie

1. **Snowsight-first :** jamais une ligne de Terraform avant d'avoir cliqué le même objet dans Snowsight.
2. **Table de correspondance :** champ Snowsight → SQL généré → argument Terraform.
3. **Un fondement par étape :** chaque étape ajoute exactement un concept.
4. **Personne n'attend personne :** warehouses et databases sont indépendants, permettant le travail parallèle.
5. **Preuve vérifiable :** `No changes.`, `has moved to`, `0 to destroy`, `plan -detailed-exitcode`.

---

## Architecture et conventions

- [Architecture cible](docs/architecture.md)
- [Conventions de nommage](docs/naming-conventions.md)
- [Runbook](docs/runbook.md)

---

## Correspondance avec le catalogue officiel

Ce parcours en 5 jours est un **scénario GlobalBank autour du catalogue officiel** `courses/day-0x/`. Chaque jour mobilise les modules correspondants :

| Jour | Modules officiels |
|---:|---|
| 1 | M01 — IaC Workflow, M04 — Variables & Outputs |
| 2 | M04 — Variables & Outputs, M06 — Logique dynamique |
| 3 | M03 — Import Brownfield, M05 — Modules réutilisables |
| 4 | M02 — State Management, M05 — Modules, M08 — Environnements |
| 5 | M07 — CI/CD, M09 — Snowflake advanced, M10 — Security, M11 — RBAC, M12 — Capstone, M13 — FinOps, M14 — Data Products |
