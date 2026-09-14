# Jour 3 — Modules et Logique Dynamique

**Objectif :** Composants reutilisables et déploiement piloté par métadonnées.

> [<- Catalogue](../README.md) · [Jour 2](../day-02/README.md) · **Jour 3** · [Jour 4 ->](../day-04/README.md)

---

## Contexte GlobalBank

> **Email Sofia Almeida :**
>
> *"for_each a detruit un objet. Sur une table avec des donnees, c'est un incident.
> Comment l'eviter ? Comment adopter vos objets legacy sans les detruire ?*
>
> *Et un constat : onze personnes ecrivent la meme structure.
> Pourquoi l'ecrire onze fois ?"*

**Aujourd'hui :** vous passez de la copie a la factorisation. Vous apprenez
`moved` (renommer sans detruire), `import` (adopter l'existant), `module`
(reutiliser la meme structure), et `data source` (lire ce que vous n'avez pas cree).

---

## Les 4 Niveaux de Maturite

| Niveau | Approche | Exemple |
|--------|----------|---------|
| **1** | Copy-paste | 11 fichiers `main.tf` identiques |
| **2** | Module | 1 definition reutilisable |
| **3** | Data-driven | Ajout d'un objet = 3 lignes dans une map |
| **4** | Platform | Modules + backends + CI/CD |

> Aujourd'hui, on passe du Niveau 1 au Niveau 3.

---

## Progression

```mermaid
flowchart LR
    M5[M5 Modules] --> M6[M6 Dynamic]
    M6 --> J4[Jour 4]
```

## Modules

| Module | Duree | Repertoire de travail | Lab | Course | Troubleshooting | Resultat attendu |
|---|---:|---|---|---|---|---|
| [M5 — Modules reutilisables](module-05-modules/lab.md) | 1h | `labs/m05-modules/` | [lab](module-05-modules/lab.md) | [cours](module-05-modules/course.md) | [guide](module-05-modules/troubleshooting.md) | [output](module-05-modules/expected-output.md) |
| [M6 — Logique dynamique](module-06-dynamic-logic/lab.md) | 1h | `labs/m06-dynamic-logic/` | [lab](module-06-dynamic-logic/lab.md) | [cours](module-06-dynamic-logic/course.md) | [guide](module-06-dynamic-logic/troubleshooting.md) | [output](module-06-dynamic-logic/expected-output.md) |

## Workflow du jour

1. **Lisez** le `course.md` du module (concepts, 15-20 min)
2. **Realisez** le `lab.md` pas a pas (creation de fichiers, execution, checkpoints)
3. **Comparez** avec `expected-output.md`
4. **Consultez** `troubleshooting.md` en cas d'erreur
5. **Passez** au module suivant

> Chaque module possede son propre repertoire de travail sous `labs/mXX-name/` (ex. `labs/m05-modules/` pour M5). Chaque lab est **autonome** : il demarre par `Reset-Lab.ps1` pour un environnement propre, possede ses propres fichiers template et se termine par `terraform destroy`. Les ressources sont nommees par module (ex. `APP01_M05_RAW_DEV`).

> `[WINDOWS]` Si l'execution de scripts `.ps1` est bloquee, autorisez les scripts locaux :
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

## Livrable du jour

Module Landing Zone reutilisable et versionné.
Déploiement piloté par métadonnées avec for_each et dynamic blocks.

---

## Preuves individuelles

- [ ] `terraform plan` affiche `has moved to` — 0 destruction
- [ ] Ajout d'un 5e objet via le module → `Plan: 1 to add`
- [ ] Vous pouvez expliquer pourquoi `for_each` est preferred a `count`
- [ ] Vous comprenez la difference entre `moved` et `import`

---

## [CHAOS LAB] — Casser un module

> ⚠️ Exercice de rupture controlee.

**Objectif :** Comprendre que les modules sont des contrats.

1. Ouvrez `modules/landing-zone/variables.tf`
2. Modifiez la valeur par defaut de `warehouse_size` (ex. `X-SMALL` → `LARGE`)
3. Executez `terraform plan`
4. Observez : TOUTES les ressources du module sont concernees

**Question :** Pourquoi la modification d'une seule variable affecte-t-elle tout le module ?

---

## [DEFI] — Ajout sans toucher au code

**Temps :** 10 minutes

1. Ajoutez un 5e objet dans `terraform.tfvars` (pas dans `main.tf` !)
2. Executez `terraform plan`
3. Le plan doit afficher `Plan: 1 to add` — sans aucune destruction

**Validation :** Le formateur verifie que vous n'avez pas modifie `main.tf`.

---

## Anti-seche Jour 3

### `moved` vs `import`

| Commande | Quand | Risque |
|----------|-------|--------|
| `moved` | Renommer ou restructurer dans le meme code | Aucun — pas de destruction |
| `import` | Adopter une ressource existante hors Terraform | Faible — pas de recreation si correctly |

### Structure d'un module

```text
modules/landing-zone/
├── main.tf           # Les ressources
├── variables.tf      # Les entrees (contrat)
├── outputs.tf        # Les sorties (contrat)
└── versions.tf       # Les versions (obligatoire)
```

### Règles d'un module

- Pas de `provider` dans le module
- Pas de `backend` dans le module
- Variables et outputs documentes
- Pas de secrets en dur

## Point de convergence (15 min)

- Projection SQL montrant tous les objets
- Trois observations de la journee
- Justification du Jour 4

## Navigation

[<- Catalogue](../README.md) · [Jour 2](../day-02/README.md) · **Jour 3** · [Jour 4 ->](../day-04/README.md)
