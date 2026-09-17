# M03 — Variables (micro-théorie)

## Une idée

Une **variable** sépare le *quoi* (le code, stable) du *combien* (les valeurs,
variables). Le même `main.tf` déploie un warehouse X-SMALL en DEV et SMALL en PROD :
seul `terraform.tfvars` change.

## Une analogie

Une recette de cuisine (le code) dit « ajouter du sel ». La quantité (la variable)
dépend du plat. Vous ne réécrivez pas la recette pour chaque plat ; vous ajustez la
quantité.

## Les 4 éléments d'une variable

```hcl
variable "warehouse_size" {
  description = "Taille du warehouse."   # 1. documente
  type        = string                    # 2. contraint le type
  default     = "X-SMALL"                 # 3. valeur si non fournie
  validation {                            # 4. garde-fou
    condition     = contains(["X-SMALL", "SMALL"], var.warehouse_size)
    error_message = "Doit être X-SMALL ou SMALL."
  }
}
```

## Priorité des sources de valeur

```
-var="x=1"  >  terraform.tfvars  >  *.auto.tfvars  >  default
```

`-var` gagne. Utile pour un test ponctuel sans modifier `tfvars`.

## Types courants

| Type | Exemple |
|---|---|
| `string` | `"X-SMALL"` |
| `number` | `60` |
| `bool` | `true` |
| `list(string)` | `["DEV", "UAT", "PROD"]` |
| `map(string)` | `{ DEV = "x-small", PROD = "small" }` |
| `object({...})` | `{ name = "RAW", size = "X-SMALL" }` |

## Pourquoi valider

Sans `validation`, un `LARGE` arrive jusqu'à Snowflake et coûte cher. Avec
`validation`, le `plan` échoue **avant** d'atteindre Snowflake. C'est votre garde-fou
FinOps, au plus tôt.

## Custom conditions : `validation` vs `precondition`

| | Porte sur | Moment |
|---|---|---|
| `validation {}` (dans `variable`) | La **valeur d'entrée** | Évaluation de la variable |
| `lifecycle { precondition {} }` (dans `resource`) | La **ressource** à créer | Au `plan`, avant tout appel Snowflake |
| `check { assert {} }` (bloc racine, TF ≥ 1.5) | L'**état réel** après apply | Après `apply` (vu au M06) |

Une `precondition` exprime une règle métier au niveau de la ressource :
« en PROD, `auto_suspend` ≤ 120 s ». Le bloc `lifecycle` regroupe aussi
`prevent_destroy`, `create_before_destroy`, `ignore_changes` — des comportements
avancés utiles en production.

## `sensitive` ≠ chiffré

`sensitive = true` masque la valeur à l'écran et dans le plan, **mais le state la
contient en clair**. Règle : le state (fichier ou backend) est un secret à protéger
— `.gitignore` en local, backend chiffré dès le M12.
