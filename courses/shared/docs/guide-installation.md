# Guide d'installation — poste Windows

Temps estimé : 45 à 60 minutes.

Ce guide est pour un ordinateur **Windows**. Aucune connaissance préalable n'est requise.

## 1. Installer Terraform

1. Ouvrir un navigateur.
2. Aller sur `https://developer.hashicorp.com/terraform/install`.
3. Section **Windows** → télécharger le ZIP **amd64** (la plupart des PC).
4. Extraire le ZIP (clic droit → Extraire tout).
5. Copier `terraform.exe` dans un dossier simple, par exemple `C:\Terraform\`.
6. Ajouter ce dossier au PATH :
   - Touche Windows, taper `variables d'environnement`.
   - Ouvrir **Modifier les variables d'environnement système**.
   - Bouton **Variables d'environnement**.
   - Dans **Variables utilisateur**, sélectionner `Path` → **Modifier**.
   - **Nouveau** → coller `C:\Terraform`.
   - OK sur toutes les fenêtres.
7. Fermer **tous** les terminaux ouverts, puis en ouvrir un nouveau.
8. Taper :

```text
terraform version
```

Résultat attendu : une ligne du type `Terraform v1.14.5`.

Si Windows affiche « commande introuvable », le PATH n'est pas pris en compte. Relancer le PC une fois, puis réessayer.

## 2. Installer Visual Studio Code

1. Aller sur `https://code.visualstudio.com`.
2. Télécharger **Windows User Installer**.
3. Lancer l'installeur. Laisser les options par défaut.
4. Cocher **Add to PATH** si la case apparaît.
5. Ouvrir VS Code.
6. Icône Extensions (barre gauche) ou `Ctrl+Shift+X`.
7. Chercher `HashiCorp Terraform` → **Install**.

## 3. Créer un PAT Snowflake

1. Ouvrir `https://app.snowflake.com`.
2. Se connecter avec l'identifiant fourni par l'instructeur.
3. En bas à gauche, cliquer sur votre nom d'utilisateur.
4. Choisir **Settings** (Paramètres) ou **My Profile**.
5. Section **Programmatic Access Tokens** / **Authentication**.
   - Cliquez sur **Connect a tool** > **Programmatic Access Tokens** (ou **Authentication > Tokens** selon la version de Snowsight).
6. **Generate new token**.
7. Donner un nom : `terraform-formation`.
8. Durée : la plus longue autorisée pour la formation (souvent 15 ou 90 jours).
9. Rôle : `SYSADMIN` si proposé.
10. **Copier le token immédiatement**. Snowflake ne le réaffiche plus.

## 4. Fichier local du PAT

1. Dans le dossier de votre projet Terraform, créer un fichier nommé exactement `snowflake-config.txt`.
2. Coller **uniquement** le token, sans guillemets, sans espace avant/après.
3. Enregistrer (`Ctrl+S`).
4. Vérifier que ce fichier est listé dans `.gitignore`.

Ne jamais envoyer ce fichier par e-mail, Teams ou Git.

## 5. Fichier de connexion `terraform.tfvars`

Créer `terraform.tfvars` (non versionné) :

```hcl
snowflake_organization = "VOTRE_ORG"
snowflake_account      = "VOTRE_COMPTE"
snowflake_user         = "VOTRE_USER"
```

L'instructeur vous donne ces trois valeurs.

## Vérification finale

| Contrôle | Commande ou action | Résultat attendu |
|---|---|---|
| Terraform | `terraform version` | Version affichée |
| VS Code | ouvrir un fichier `.tf` | coloration HCL |
| Snowflake | Snowsight s'ouvre | vous êtes connecté |
| PAT | fichier `snowflake-config.txt` | une seule ligne |
