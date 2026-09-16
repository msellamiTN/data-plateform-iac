# Jour 0 — Diagnostiquer votre environnement

**Durée estimée :** 30–90 minutes (hors temps de cours)
**Résultat attendu :** `Toolchain status: READY` + `SELECT 1` Snowflake réussi

> [<- Catalogue](../README.md) · **Jour 0** · [Jour 1 ->](../day-01/README.md)

---

## Objectif

Le Jour 0 est un **préflight automatisé**. Il ne crée aucune ressource Cloud. Il vérifie que vous pouvez suivre le Jour 1 sans incident d'outillage.

Aucune connaissance Azure, PowerShell, Python ou programmation n'est requise. Les ressources Azure nécessaires au state distant et au pipeline sont **préparées par le formateur**.

---

## Les 3 règles d'or

> **Règle 1 :** Jamais une ligne de Terraform avant d'avoir cliqué le même objet dans Snowsight.
>
> **Règle 2 :** Jamais de `terraform destroy` sans plan préalable ni confirmation.
>
> **Règle 3 :** Jamais de secret dans Git, les captures ou les rapports.

---

## Deux chemins

| Chemin | Quand | Durée |
|---|---|---|
| **A — VM préconfigurée** (recommandé) | Le formateur a provisionné une VM | ~15 min |
| **B — Installation locale** | Vous utilisez votre propre poste | ~1 h 30 |

> Si vous recevez une IP RDP et des identifiants `apprenantXX`, vous êtes sur le **Chemin A**. Sinon, suivez le **Chemin B**.

---

## Progression

| Étape | Temps | Action | Preuve pour continuer |
|---:|---:|---|---|
| 1 | 5 min | Cloner le projet type | Dépôt présent, scripts visibles |
| 2 | 20 min | Installer et vérifier les outils | `Toolchain status: READY` |
| 3 | 10 min | Configurer `.env` | `git check-ignore .env` retourne `.env` |
| 4 | 20 min | Configurer la connexion Snowflake (PAT) | `snow sql -q 'SELECT 1' -c training` réussit |
| 5 | 10 min | Inspecter la structure du projet | Dossiers `courses/`, `labs/`, `scripts/` présents |
| 6 | 10 min | Validation finale | `Toolchain status: READY` + Snowflake OK |

> Le lab détaillé est dans [module-00-setup/lab.md](module-00-setup/lab.md).

---

## Ce que vous devez disposer à la fin

- le **projet type** cloné sous `$HOME/Data2AI-Labs/data-platform` ;
- **Terraform**, **Git**, **Snowflake CLI** et **VS Code** disponibles dans le terminal ;
- une connexion Snowflake `training` testée via PAT saisi de façon sécurisée ;
- votre **préfixe apprenant** (`APP01` à `APP11`) confirmé ;
- un rapport de validation sans erreur ni secret.

> Azure CLI, OpenSSL et Python sont **optionnels** ou préinstallés par le formateur selon le chemin. Aucune administration Azure n'est demandée à l'apprenant.

---

## Règles de sécurité

1. Le PAT est saisi via une invite masquée — jamais affiché, jamais collé dans une commande.
2. Aucun PAT, mot de passe ou clé privée n'est placé dans un fichier du dépôt.
3. N'ajoutez pas `ACCOUNTADMIN` pour résoudre une erreur de privilège.
4. Ne créez pas de network policy, utilisateur global ou ressource Cloud pendant ce module.
5. Arrêtez-vous si `git check-ignore .env` ne retourne pas `.env`.

---

## Formateur — Préparation

> Si vous êtes formateur, consultez le [guide de préparation](instructor-setup.md). Il décrit la création du backend Azure, des connexions de service, des utilisateurs Snowflake et des préfixes apprenants. Ces éléments sont **hors périmètre apprenant**.

---

## Critère de fin

Le Jour 0 est terminé lorsque :

```text
Toolchain status: READY
snow sql -q 'SELECT 1' -c training  →  retourne un résultat
```

## Preuves individuelles

- [ ] `terraform version` affiche 1.14.x
- [ ] `snow sql -q 'SELECT 1' -c training` retourne un résultat
- [ ] `git status` fonctionne dans le projet cloné
- [ ] Votre préfixe apprenant est identifié (`APP01` à `APP11`)
- [ ] Le fichier `.env` est présent et gitignored
- [ ] VS Code ouvre le projet sans erreur

---

## Suite

Passez à [Jour 1 — Workflow Terraform](../day-01/README.md).
