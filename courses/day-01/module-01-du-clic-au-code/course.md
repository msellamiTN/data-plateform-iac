# M01 — Du clic au code (micro-théorie)

## Une idée

**ClickOps, SQL et HCL décrivent le même objet.** Le formulaire Snowsight, la commande
`SHOW WAREHOUSES`, et le bloc `resource "snowflake_warehouse"` sont trois langages pour
la même réalité. Apprendre Terraform, c'est apprendre cette correspondance.

## Une analogie

Un meuble IKEA : la notice (HCL), l'étiquette sur l'étagère (SQL), et le meuble monté
(Snowflake). Les trois décrivent le même objet. Modifier la notice → le prochain
montage change. Modifier l'étagère à la main → la notice ne sait pas.

## La boucle fondamentale

```
① CLIQUER    → voir les champs du formulaire
② LIRE (SQL) → voir les noms exacts (SHOW, DESC)
③ ÉCRIRE HCL → chaque champ = un argument
④ plan/apply → Terraform crée/modifie
⑤ No changes → preuve d'idempotence
```

## Tableau de correspondance (warehouse)

| Snowsight | SQL (DESC) | HCL |
|---|---|---|
| Name | `name` | `name` |
| Size | `WAREHOUSE_SIZE` | `warehouse_size` |
| Auto Suspend | `AUTO_SUSPEND` | `auto_suspend` |
| Resume Automatically | `AUTO_RESUME` | `auto_resume` |
| Initially Suspended | `INITIALLY_SUSPENDED` | `initially_suspended` |

## Pourquoi on clique d'abord

La **Règle 1** (« jamais une ligne de Terraform avant d'avoir cliqué ») n'est pas
un caprice : cliquer vous montre les champs possibles, leurs valeurs autorisées, et
les effets de bord. Sans cette étape, vous écrivez du HCL à l'aveugle et vous ne savez
pas si un argument existe ou ce qu'il fait.

## ClickOps vs IaC

| ClickOps | IaC (Terraform) |
|---|---|
| Rapide pour un objet | Rapide pour mille objets |
| Pas de trace | Versionné, audité |
| « Qui a créé quoi ? » → inconnu | Le commit répond |
| Reproduire = tout refaire | Reproduire = `terraform apply` |
| Dérive invisible | Dérive détectée par `plan` |

## Le plan est une promesse, l'apply est un acte

`terraform plan` **simule** ce qui va se passer sans rien toucher. Lisez-le toujours.
`terraform apply` **exécute**. La Règle 2 (« jamais de destroy sans plan ») vient de
là : un plan vous montre les `-` (destructions) avant qu'elles ne se produisent.
