# Guide de Reprise

Ce document decrit les procedures a suivre en cas d'interruption ou de problemes
pendant la formation.

## Principe Fondamental

> **Le state n'est jamais supprime pour "repartir proprement".**
> La reprise se fait toujours a partir de l'etat existant.

---

## Scenarios de Reprise

### 1. Terminal ferme en plein apply

**Symptome :** Le terminal s'est ferme pendant un `terraform apply`.

**Procedure :**
```bash
# 1. Verifier l'etat actuel
terraform state list

# 2. Verifier s'il y a un lock
terraform force-unlock -list

# 3. Si lock present, le liberer (uniquement si personne d'autre n'utilise le state)
terraform force-unlock <LOCK_ID>

# 4. Relancer le plan pour verifier l'etat
terraform plan
```

**Critere :** Le plan doit afficher `No changes` ou les actions attendues.

---

### 2. Erreur de validation

**Symptome :** `terraform validate` echoue.

**Procedure :**
```bash
# 1. Formater le code
terraform fmt -recursive

# 2. Lire le message d'erreur
terraform validate 2>&1

# 3. Corriger le fichier indique
# 4. Revalider
terraform validate
```

**Cas courants :**
- Variable non declaree → ajouter dans `variables.tf`
- Syntaxe HCL incorrecte → verifier les accolades et virgules
- Reference inexistante → verifier le nom de la ressource

---

### 3. PAT expire ou refuse

**Symptome :** `Error: authentication error` ou `401 Unauthorized`.

**Procedure :**
```bash
# 1. Verifier la connexion Snowflake
snow sql -q 'SELECT 1' -c training

# 2. Si echec, regenerer le PAT dans Snowsight
#    Account > Security > Tokens > Create new token

# 3. Mettre a jour le PAT dans .env
# 4. Reinitialiser la connexion
terraform init -upgrade
```

---

### 4. Ressource deja existante

**Symptome :** `Error: resource already exists`.

**Procedure :**
```bash
# 1. Identifier la ressource dans Snowsight
#    (nom exact via SHOW WAREHOUSES LIKE '...')

# 2. Importer dans le state
terraform import snowflake_warehouse.mon_warehouse NOM_DE_LA_RESSOURCE

# 3. Verifier que le plan est propre
terraform plan
```

**Alternative :** Si la ressource n'est pas geree, la supprimer manuellement
dans Snowsight puis relancer `terraform apply`.

---

### 5. Dérive détectée

**Symptome :** `terraform plan` affiche des changements non attendus.

**Procedure :**
```bash
# 1. Identifier les changements
terraform plan -detailed-exitcode

# 2. Decider : corriger le code OU restaurer l'objet
#    - Si l'objet a ete modifie dans Snowsight → restaurer le code
#    - Si le code a ete modifie → corriger et reappliquer

# 3. Appliquer la correction
terraform apply
```

---

### 6. Lock du state

**Symptome :** `Error: State locked`.

**Procedure :**
```bash
# 1. Verifier qui a le lock
terraform force-unlock -list

# 2. Si c'est vous-meme (session interrompue)
terraform force-unlock <LOCK_ID>

# 3. Si c'est quelqu'un d'autre
#    → Attendre qu'il finisse
#    → OU contacter le formateur
```

> ⚠️ **Ne jamais forcer le lock sans confirmer que personne d'autre n'utilise le state.**

---

### 7. Backend Azure inaccessible

**Symptome :** `Error: failed to load state` ou `storage: service error`.

**Procedure :**
```bash
# 1. Verifier la connectivite Azure
az account show

# 2. Verifier les permissions du conteneur Blob
#    (le role Storage Blob Data Contributor est necessaire)

# 3. Si le conteneur n'existe pas, le creer
#    (voir le formateur)

# 4. Reinitialiser le backend
terraform init -migrate-state
```

---

### 8. Provider introuvable

**Symptome :** `Error: Provider configuration not present`.

**Procedure :**
```bash
# 1. Reinitialiser
terraform init -upgrade

# 2. Verifier les versions dans versions.tf
# 3. Verifier la connectivite reseau
```

---

## Environnement de Secours

Si l'environnement principal est inutilisable :

1. **Verifier** que le state distant est accessible
2. **Cloner** le depot sur un autre poste
3. **Reconfigurer** le `.env` avec les nouveaux identifiants
4. **Tester** la connexion Snowflake et Azure
5. **Continuer** avec le meme state distant

> L'environnement de secours doit etre teste avant le debut de la formation.

---

## Escalade

| Situation | Action |
|-----------|--------|
| Erreur non couverte ci-dessus | Contacter le formateur |
| Probleme de reseau | Utiliser l'environnement de secours |
| Compte Snowflake bloque | Contacter le formateur |
| Probleme Azure | Verifier les permissions du SP |

---

## Contacts

| Role | Responsabilite |
|------|----------------|
| **Formateur** | Pedagogie, evaluation, deblocage technique |
| **Referent technique** | Infrastructure, reseau, Azure, Snowflake |
| **Organisateur** | Logistique, salles, accès |
