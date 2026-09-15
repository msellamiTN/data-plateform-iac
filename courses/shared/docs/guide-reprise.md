# Guide de Reprise

Ce document décrit les procédures à suivre en cas d'interruption ou de problèmes pendant la formation.

## Principe fondamental

> **Le state n'est jamais supprimé pour "repartir proprement".**
> La reprise se fait toujours à partir de l'état existant.

---

## Scénarios de reprise

### 1. Terminal fermé en plein apply

**Symptôme :** Le terminal s'est fermé pendant un `terraform apply`.

**Procédure :**
```bash
# 1. Vérifier l'état actuel
terraform state list

# 2. Vérifier s'il y a un lock
terraform force-unlock -list

# 3. Si lock présent, le libérer (uniquement si personne d'autre n'utilise le state)
terraform force-unlock <LOCK_ID>

# 4. Relancer le plan pour vérifier l'état
terraform plan
```

**Critère :** Le plan doit afficher `No changes` ou les actions attendues.

---

### 2. Erreur de validation

**Symptôme :** `terraform validate` échoue.

**Procédure :**
```bash
# 1. Formater le code
terraform fmt -recursive

# 2. Lire le message d'erreur
terraform validate 2>&1

# 3. Corriger le fichier indiqué
# 4. Revalider
terraform validate
```

**Cas courants :**
- Variable non déclarée → ajouter dans `variables.tf`
- Syntaxe HCL incorrecte → vérifier les accolades et virgules
- Référence inexistante → vérifier le nom de la ressource

---

### 3. PAT expiré ou refusé

**Symptôme :** `Error: authentication error` ou `401 Unauthorized`.

**Procédure :**
```bash
# 1. Vérifier la connexion Snowflake
snow sql -q 'SELECT 1' -c training

# 2. Si échec, régénérer le PAT dans Snowsight
#    Account > Security > Tokens > Create new token

# 3. Mettre à jour le PAT dans .env
# 4. Réinitialiser la connexion
terraform init -upgrade
```

---

### 4. Ressource déjà existante

**Symptôme :** `Error: resource already exists`.

**Procédure :**
```bash
# 1. Identifier la ressource dans Snowsight
#    (nom exact via SHOW WAREHOUSES LIKE '...')

# 2. Importer dans le state
terraform import snowflake_warehouse.mon_warehouse NOM_DE_LA_RESSOURCE

# 3. Vérifier que le plan est propre
terraform plan
```

**Alternative :** Si la ressource n'est pas gérée, la supprimer manuellement dans Snowsight puis relancer `terraform apply`.

---

### 5. Dérive détectée

**Symptôme :** `terraform plan` affiche des changements non attendus.

**Procédure :**
```bash
# 1. Identifier les changements
terraform plan -detailed-exitcode

# 2. Décider : corriger le code OU restaurer l'objet
#    - Si l'objet a été modifié dans Snowsight → restaurer le code
#    - Si le code a été modifié → corriger et réappliquer

# 3. Appliquer la correction
terraform apply
```

---

### 6. Lock du state

**Symptôme :** `Error: State locked`.

**Procédure :**
```bash
# 1. Vérifier qui a le lock
terraform force-unlock -list

# 2. Si c'est vous-même (session interrompue)
terraform force-unlock <LOCK_ID>

# 3. Si c'est quelqu'un d'autre
#    → Attendre qu'il finisse
#    → OU contacter le formateur
```

> ⚠️ **Ne jamais forcer le lock sans confirmer que personne d'autre n'utilise le state.**

---

### 7. Backend Azure inaccessible

**Symptôme :** `Error: failed to load state` ou `storage: service error`.

**Procédure :**

> Le backend est **préconfiguré par le formateur**. Vous ne créez pas le storage account.

1. Vérifier que les paramètres dans `.env` correspondent à ceux fournis.
2. Si le conteneur n'est pas accessible, **contacter le formateur** (problème infrastructure).
3. Ne pas créer le storage account vous-même.
4. Une fois le problème résolu : `terraform init -migrate-state`.

---

### 8. Provider introuvable

**Symptôme :** `Error: Provider configuration not present`.

**Procédure :**
```bash
# 1. Réinitialiser
terraform init -upgrade

# 2. Vérifier les versions dans versions.tf
# 3. Vérifier la connectivité réseau
```

---

## Environnement de secours

Si l'environnement principal est inutilisable :

1. **Vérifier** que le state distant est accessible
2. **Cloner** le dépôt sur un autre poste
3. **Reconfigurer** le `.env` avec les nouveaux identifiants
4. **Tester** la connexion Snowflake
5. **Continuer** avec le même state distant

> L'environnement de secours doit être testé avant le début de la formation.

---

## Escalade

| Situation | Action |
|---|---|
| Erreur non couverte ci-dessus | Contacter le formateur |
| Problème de réseau | Utiliser l'environnement de secours |
| Compte Snowflake bloqué | Contacter le formateur |
| Backend Azure inaccessible | Contacter le formateur (problème infrastructure) |
| Pipeline Azure DevOps en échec | Vérifier les logs, contacter le formateur si infrastructure |

---

## Contacts

| Rôle | Responsabilité |
|---|---|
| **Formateur** | Pédagogie, évaluation, déblocage technique |
| **Référent technique** | Infrastructure, réseau, Azure, Snowflake |
| **Organisateur** | Logistique, salles, accès |
