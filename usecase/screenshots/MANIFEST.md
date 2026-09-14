# Captures écran nécessaires

Chaque fichier `team-*.md` contient des placeholders `[CAPTURE]` qui doivent être remplacés par de vraies captures d'écran.

## Convention de nommage

```
screenshots/
├── j1-01-warehouse-created.png       ← Snowsight — liste des warehouses après création
├── j1-02-warehouse-visible.png       ← Snowsight — WH_APP01_INGEST_DEV visible
├── j1-03-database-created.png        ← Snowsight — database créée
├── j1-04-arborescence.png            ← Snowsight — arborescence database → schema → table
├── j1-05-3-objects-created.png       ← Snowsight — les 3 objets créés
├── j1-06-drift-plan.png              ← Terminal — terraform plan détecte la dérive
├── j2-01-no-changes.png              ← Terminal — No changes après locals
├── j2-02-validation-error.png        ← Terminal — erreur de validation
├── j2-03-3-objects-snowsight.png     ← Snowsight — les 3 objets créés (J2)
├── j2-04-terraform-output.png        ← Terminal — terraform output
├── j3-01-moved-plan.png              ← Terminal — plan "has moved to" — 0 destroy
├── j3-02-state-list.png              ← Terminal — terraform state list montrant legacy
├── j3-03-modules-arborescence.png    ← VS Code — arborescence modules/
└── j3-04-output-data-source.png      ← Terminal — terraform output montrant la ressource lue
```

## Mapping [CAPTURE] → fichier image

| Jour | Placeholder | Image |
|------|-------------|-------|
| **J1** | `Snowsight — le warehouse créé dans la liste` | `j1-01-warehouse-created.png` |
| **J1** | `Snowsight — le warehouse WH_APP01_INGEST_DEV visible` | `j1-02-warehouse-visible.png` |
| **J1** | `Snowsight — la database créée` | `j1-03-database-created.png` |
| **J1** | `Snowsight — l'arborescence database → schema → table` | `j1-04-arborescence.png` |
| **J1** | `Snowsight — les 3 objets créés` | `j1-05-3-objects-created.png` |
| **J1** | `Le plan qui détecte la dérive` | `j1-06-drift-plan.png` |
| **J2** | `Le plan No changes. après l'introduction du local` | `j2-01-no-changes.png` |
| **J2** | `L'erreur de validation dans le terminal` | `j2-02-validation-error.png` |
| **J2** | `Snowsight — les 3 objets créés` | `j2-03-3-objects-snowsight.png` |
| **J2** | `terraform output dans le terminal` | `j2-04-terraform-output.png` |
| **J3** | `Le plan has moved to — 0 destroy` | `j3-01-moved-plan.png` |
| **J3** | `terraform state list montrant legacy` | `j3-02-state-list.png` |
| **J3** | `L'arborescence modules/ dans VS Code` | `j3-03-modules-arborescence.png` |
| **J3** | `terraform output montrant la ressource lue` | `j3-04-output-data-source.png` |

## Comment prendre les captures

1. **Exécutez les étapes** du fichier `team-*.md` correspondant
2. **Capturez l'écran** au moment indiqué
3. **Enregistrez** dans `screenshots/` avec le nom du fichier ci-dessus
4. Les images seront automatiquement affichées dans les fichiers Markdown
