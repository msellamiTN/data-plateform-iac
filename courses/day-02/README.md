# Jour 2 — Modules réutilisables et logique dynamique

**Objectif :** Factoriser le code en modules réutilisables et piloter par métadonnées.
**Durée :** 6 heures (2 h concepts · 4 h pratique)

> [<- Catalogue](../README.md) · [Jour 1](../day-01/README.md) · **Jour 2** · [Jour 3 ->](../day-03/README.md)

---

## Contexte GlobalBank

> *"Onze personnes écrivent la même structure. Pourquoi l'écrire onze fois ? Et `for_each` a détruit un objet — sur une table avec des données, c'est un incident. Comment l'éviter ?"*

**Aujourd'hui :** vous passez de la copie à la factorisation. Vous apprenez `module` (réutiliser la même structure), `moved` (renommer sans détruire), `for_each` (collections stables) et `dynamic` (blocs répétés).

---

## Les 4 niveaux de maturité

| Niveau | Approche | Exemple |
|---|---|---|
| **1** | Copy-paste | 11 fichiers `main.tf` identiques |
| **2** | Module | 1 définition réutilisable |
| **3** | Data-driven | Ajout d'un objet = 3 lignes dans une map |
| **4** | Platform | Modules + backends + CI/CD |

> Aujourd'hui, on passe du Niveau 1 au Niveau 3.

---

## Progression

```mermaid
flowchart LR
    M5[M5 Modules] --> M6[M6 Logique dynamique]
    M6 --> J3[Jour 3]
```

## Modules

| Module | Durée | Dossier de travail | Lab | Cours | Troubleshooting | Output attendu |
|---|---:|---|---|---|---|---|
| [M5 — Modules réutilisables](module-05-modules/lab.md) | 2 h 30 | `labs/m05-modules/` | [lab](module-05-modules/lab.md) | [cours](module-05-modules/course.md) | [guide](module-05-modules/troubleshooting.md) | [output](module-05-modules/expected-output.md) |
| [M6 — Logique dynamique](module-06-dynamic-logic/lab.md) | 1 h 30 | `labs/m06-dynamic-logic/` | [lab](module-06-dynamic-logic/lab.md) | [cours](module-06-dynamic-logic/course.md) | [guide](module-06-dynamic-logic/troubleshooting.md) | [output](module-06-dynamic-logic/expected-output.md) |

## Workflow du jour

1. **Lisez** le `course.md` du module (concepts, 15–20 min)
2. **Réalisez** le `lab.md` pas à pas (création de fichiers, exécution, checkpoints)
3. **Comparez** avec `expected-output.md`
4. **Consultez** `troubleshooting.md` en cas d'erreur
5. **Passez** au module suivant

> Chaque module possède son propre dossier de travail sous `labs/mXX-name/`. Chaque lab est **autonome** : il démarre par `Reset-Lab.ps1` pour un environnement propre et se termine par un cleanup contrôlé. Les ressources sont nommées par module (ex. `APP01_M05_RAW_DEV`).

---

## Livrable du jour

Module Landing Zone Snowflake réutilisable et versionné. Déploiement piloté par métadonnées avec `for_each` et blocs `dynamic`.

---

## Preuves individuelles

- [ ] `terraform plan` affiche `has moved to` — 0 destruction après extraction en module
- [ ] Ajout d'un objet via `terraform.tfvars` → `Plan: 1 to add` sans destruction
- [ ] Vous pouvez expliquer pourquoi `for_each` est préféré à `count`
- [ ] Vous comprenez la différence entre `moved` et `import`
- [ ] Vous pouvez expliquer le contrat d'un module (variables + outputs)

---

## [CHAOS LAB] — Casser un module

> ⚠️ Exercice de rupture contrôlée.

**Objectif :** Comprendre que les modules sont des contrats.

1. Ouvrez `modules/landing-zone/variables.tf`
2. Modifiez la valeur par défaut de `warehouse_size` (ex. `X-SMALL` → `LARGE`)
3. Exécutez `terraform plan`
4. Observez : TOUTES les ressources du module sont concernées

**Question :** Pourquoi la modification d'une seule variable affecte-t-elle tout le module ?

---

## [DÉFI] — Ajout sans toucher au code

**Temps :** 10 minutes

1. Ajoutez un nouvel objet dans `terraform.tfvars` (pas dans `main.tf` !)
2. Exécutez `terraform plan`
3. Le plan doit afficher `Plan: 1 to add` — sans aucune destruction

**Validation :** Le formateur vérifie que vous n'avez pas modifié `main.tf`.

---

## Anti-sèche Jour 2

### `moved` vs `import`

| Commande | Quand | Risque |
|---|---|---|
| `moved` | Renommer ou restructurer dans le même code | Aucun — pas de destruction |
| `import` | Adopter une ressource existante hors Terraform | Faible — pas de recreation si correct |

### Structure d'un module

```text
modules/landing-zone/
├── main.tf           # Les ressources
├── variables.tf      # Les entrées (contrat)
├── outputs.tf        # Les sorties (contrat)
└── versions.tf       # Les versions (obligatoire)
```

### Règles d'un module

- Pas de `provider` dans le module enfant
- Pas de `backend` dans le module enfant
- Variables et outputs documentés
- Pas de secrets en dur

### `count` vs `for_each`

| Critère | `count` | `for_each` |
|---|---|---|
| Type d'entrée | `number` | `map` ou `set(string)` |
| Adressage | `res[0]`, `res[1]` | `res["clé"]` |
| Retrait d'un élément du milieu | 🔴 Réindexe tout | ✅ Ne touche que la clé visée |
| Bon usage | Interrupteur on/off | Collections nommées |

> **Règle professionnelle :** `for_each` par défaut. `count` uniquement pour un interrupteur booléen.

---

## Point de convergence (15 min)

- Projection SQL montrant tous les objets
- Trois observations de la journée
- Justification du Jour 3

## Navigation

[<- Catalogue](../README.md) · [Jour 1](../day-01/README.md) · **Jour 2** · [Jour 3 ->](../day-03/README.md)
