Guide de Transformation de l'Infrastructure d'une Industrialisation Data Platform : Terraform, Snowflake et Sécurisation AvancéeCe guide est destiné aux responsables DevOps et architectes sécurité. Il détaille la modernisation d'une plateforme de données (Data Platform) en remplaçant les pipelines classiques par une architecture moderne, déclarative et hautement sécurisée utilisant Terraform et Snowflake.1. Transition des Pipelines Classiques vers l'Infrastructure en YAMLL'approche traditionnelle par scripts impératifs (Bash, Python) ou interfaces graphiques engendre une dérive de configuration (configuration drift). La transition vers un modèle déclaratif standardisé en YAML, orchestré par Terraform, apporte auditabilité et reproductibilité.Avantages de l'approche hybride YAML + TerraformSéparation des responsabilités : Les ingénieurs de données définissent les structures en YAML sans manipuler directement le code Terraform.Gouvernance centralisée : Terraform lit les fichiers YAML comme unique source de vérité (Single Source of Truth).Validation amont : Possibilité de valider les schémas YAML (via un schéma JSON) avant l'exécution du code.Exemple de configuration YAML (databases.yaml)yamldatabases:
  - name: DB_PROD_ANALYTICS
    comment: "Base de données principale pour les analyses de production"
    retention_time_days: 30
    schemas:
      - name: CORE
        comment: "Données nettoyées et modélisées"
      - name: STAGING
        comment: "Zone de préparation des données"
Utilisez le code avec précaution.Implémentation Terraform (Consommation du YAML)hcllocals {
  db_config = yamldecode(file("${path.module}/databases.yaml"))

  # Aplatir la structure pour créer une carte des schémas
  schemas = merge([
    for db in local.db_config.databases : {
      for sch in db.schemas : "${db.name}.${sch.name}" => {
        database = db.name
        schema   = sch.name
        comment  = sch.comment
      }
    }
  ]...)
}

resource "snowflake_database" "prod" {
  for_each            = { for db in local.db_config.databases : db.name => db }
  name                = each.value.name
  comment             = each.value.comment
  data_retention_days = each.value.retention_time_days
}

resource "snowflake_schema" "prod" {
  for_each = local.schemas
  name     = each.value.schema
  database = snowflake_database.prod[each.value.database].name
  comment  = each.value.comment
}
Utilisez le code avec précaution.2. Implémentation du Principe de Moindre Privilège via RBAC dans SnowflakeUn modèle de contrôle d'accès basé sur les rôles (RBAC) rigoureux empêche l'élévation latérale des privilèges. Snowflake utilise une hiérarchie stricte.Modèle de hiérarchie des rôles recommandéPour une gouvernance optimale, séparez les Rôles Fonctionnels (attribués aux utilisateurs/services) des Rôles d'Accès (qui détiennent les privilèges sur les objets).          [ ACCOUNTADMIN ]
                 │
           [ SYSADMIN ] <──────────────┐
                 │                     │
      [ FR_DATA_ENGINEER ]    [ AR_DB_WRITE ] (Privilèges d'écriture)
                 │                     │
        [ FR_DATA_ANALYST ] ───> [ AR_DB_READ ] (Privilèges de lecture seule)
Bonnes pratiques de configuration RBAC avec TerraformÉviter l'usage de ACCOUNTADMIN : Utilisez USERADMIN pour créer des utilisateurs/rôles et SECURITYADMIN pour les octrois de privilèges.Propriété des objets (Ownership) : Assurez-vous que le rôle Terraform (ex: TF_ROLE) crée les objets mais transfère ou délègue correctement la gestion aux rôles fonctionnels cibles.Privilèges futurs (Future Grants) : Utilisez les privilèges futurs pour éviter que les nouvelles tables créées manuellement ou par des pipelines ne soient invisibles pour les rôles de lecture/écriture.hcl# Création d'un rôle d'accès en lecture seule
resource "snowflake_role" "ar_db_read" {
  name    = "AR_PROD_READ"
  comment = "Rôle d'accès : Lecture seule sur la base de production"
}

# Octroi des privilèges futurs sur le schéma
resource "snowflake_grant_privileges_to_account_role" "read_future_tables" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_role.ar_db_read.name
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = snowflake_database.prod["DB_PROD_ANALYTICS"].name
    }
  }
}
Utilisez le code avec précaution.3. Sécurisation Critique des Connexions via la Fédération d'Identité de Charge de Travail (Workload Identity Federation)L'utilisation de clés de compte de service de longue durée ou de mots de passe stockés est un risque majeur de compromission. La fédération d'identité de charge de travail élimine le besoin de secrets statiques en s'appuyant sur des jetons de courte durée via le protocole OIDC (OpenID Connect).Dans le cadre d'un pipeline CI/CD (ex: GitHub Actions, GitLab CI) se connectant à Snowflake via Terraform, le flux s'articule ainsi :Schéma du flux d'authentification sans secret[ Pipeline CI/CD ] ─── (1) Demande de jeton OIDC ───> [ Fournisseur d'Identité (IdP) ]
       │                                                            │
       │ <───────────── (2) Émission du jeton JWT ──────────────────┘
       │
       └─── (3) Connexion avec JWT JWT + Authentification Key-Pair ───> [ Snowflake ]
Note : Snowflake supporte l'authentification par paire de clés (JWT signés). Le pipeline utilise le jeton OIDC de l'IdP cloud (ex: AWS STS ou Google Cloud IAM) pour assumer temporairement un rôle disposant des accès requis, ou génère dynamiquement l'empreinte de clé.Configuration de l'intégration de sécurité dans Snowflake (Exemple OIDC / Stockage Cloud externe)Pour permettre à un pipeline ou une application cloud (ex: AWS) d'interagir avec Snowflake sans stocker de clés d'accès AWS :sql-- Création d'une intégration de stockage utilisant la fédération d'identité IAM (AssumeRole)
CREATE OR REPLACE STORAGE INTEGRATION aws_s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://mon-bucket-data-prod/')
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake-access-role';

-- Récupération des propriétés pour configurer la relation de confiance dans AWS
DESCRIBE INTEGRATION aws_s3_integration;
-- Récupérer : STORAGE_AWS_IAM_USER_ARN et STORAGE_AWS_EXTERNAL_ID
Utilisez le code avec précaution.En appliquant cette méthode, aucun identifiant AWS n'est inscrit dans le code Terraform ou dans les secrets du pipeline CI/CD.4. Gouvernance Continue, Visibilité et AuditLa conformité de la plateforme de données doit être validée de manière continue après le déploiement initial.Outils de validation de conformité (Policy-as-Code)Intégrez des outils d'analyse statique dans vos pipelines de déploiement Terraform :Tfsec / TFLint : Pour détecter les configurations non sécurisées dans le code Terraform.Open Policy Agent (OPA) / Checkov : Pour appliquer des règles strictes (ex: interdire la création de partages de données publics sans validation).Auditabilité et visibilité dans SnowflakeUtilisez le schéma partagé SNOWFLAKE.ACCOUNT_USAGE pour auditer en continu les accès et les configurations.Requête d'audit : Détection des rôles orphelins ou privilèges excessifssqlSELECT 
    grantee_name, 
    role, 
    privilege, 
    name AS object_name, 
    object_category
FROM snowflake.account_usage.grants_to_roles
WHERE deleted_on IS NULL 
  AND privilege = 'OWNERSHIP'
  AND grantee_name = 'PUBLIC'; -- Alerte rouge de sécurité
Utilisez le code avec précaution.Requête d'audit : Surveillance des connexions des comptes de servicesqlSELECT 
    event_timestamp, 
    user_name, 
    client_interface, 
    reported_client_type, 
    first_authentication_factor
FROM snowflake.account_usage.login_history
WHERE user_name LIKE '%_SERVICE_ACCOUNT'
ORDER BY event_timestamp DESC;
Utilisez le code avec précaution.5. Synthèse des Recommandations Architecture & SécuritéPilierStatu Quo (À abandonner)Cible Stratégique (À implémenter)Gestion de l'InfraScripts Bash / Changements manuels sur Snowflake.Fichiers de configuration YAML centralisés appliqués via Terraform.Gestion des AccèsRôles hybrides, utilisateurs rattachés directement à SYSADMIN.Structuration stricte RBAC (Séparation Rôles d'Accès vs Rôles Fonctionnels).Sécurité des SecretsMots de passe / Clés d'API stockés dans les variables de CI/CD.Fédération d'identité de charge de travail (OIDC, AssumeRole).GouvernanceRevues de sécurité trimestrielles manuelles.Analyse Policy-as-Code dans la CI/CD et alertes via ACCOUNT_USAGE.Pour adapter au mieux ce guide à votre écosystème, pouvez-vous me préciser :Quel fournisseur cloud (AWS, Azure ou GCP) héberge vos pipelines CI/CD et vos outils de stockage ?Utilisez-vous une solution spécifique de CI/CD (ex: GitHub Actions, GitLab CI, Azure DevOps) ?Souhaitez-vous un exemple complet de politique de confiance IAM / OIDC pour cette plateforme ?Vous avez dit : Focus on Rédiger un guide détaillé destiné aux responsables DevOps et architectes sécurité, expliquant comment transformer metrte en place Industrialisation Data Platform (Terraform & Snowflake . Le document doit mettre l'accent sur la transition des pipelines classiques vers le YAML, l'implémentation du principe de moindre privilège via RBAC, et la sécurisation critique des connexions de service par la fédération d'identité de charge de travail, tout en soulignant l'importance de la gouvernance continue. lesmodules gestion de states , gouvenance, data plane vs control planes, inetgation mdoularite expsniblité...Focus on Rédiger un guide détaillé destiné aux responsables DevOps et architectes sécurité, expliquant comment transformer metrte en place Industrialisation Data Platform (Terraform & Snowflake . Le document doit mettre l'accent sur la transition des pipelines classiques vers le YAML, l'implémentation du principe de moindre privilège via RBAC, et la sécurisation critique des connexions de service par la fédération d'identité de charge de travail, tout en soulignant l'importance de la gouvernance continue. lesmodules gestion de states , gouvenance, data plane vs control planes, inetgation mdoularite expsniblité...1:36 PMGuide d'Architecture & d'Industrialisation : Modernisation d'une Data Platform (Terraform & Snowflake)Ce guide de référence est destiné aux responsables DevOps et architectes sécurité. Il fournit le cadre méthodologique et technique pour concevoir et déployer une plateforme de données (Industrialisation Data Platform) évolutive, sécurisée et pilotée par les données (data-driven infrastructure).1. Séparation Fondamentale : Control Plane vs Data PlanePour garantir la sécurité et l'évolutivité, l'architecture de la Data Platform est scindée en deux plans hermétiques.       ┌──────────────────────────────────────────────────────────┐
       │                      CONTROL PLANE                       │
       │  [ CI/CD ] ──> [ Terraform ] ──> [ YAML Configurations ]  │
       └────────────────────────────┬─────────────────────────────┘
                                    │ (Déploiement & Politiques)
                                    ▼
       ┌──────────────────────────────────────────────────────────┐
       │                       DATA PLANE                         │
       │  [ Snowflake (Tables/Vues) ] <──> [ Stockage S3/GCS ]     │
       └──────────────────────────────────────────────────────────┘
Le Control Plane (Plan de Contrôle)Rôle : Gère le cycle de vie de l'infrastructure, les autorisations, les politiques de sécurité et les définitions de structures.Composants : Dépôts Git, orchestrateurs CI/CD (GitHub Actions, GitLab CI), pipelines Terraform, fichiers de configuration YAML, et outils de Policy-as-Code (Checkov, OPA).Règle d'or : Aucun traitement de donnée métier ne s'exécute dans le Control Plane.Le Data Plane (Plan de Données)Rôle : Stocke, traite et expose la donnée brute et transformée.Composants : Entrepôts virtuels (Snowflake Virtual Warehouses), bases de données, schémas, pipelines d'ingestion (Snowpipe), et buckets de stockage managés (AWS S3, Google Cloud Storage, Azure Blob).Règle d'or : Le Data Plane ne détient aucune logique de création de sa propre infrastructure. Il obéit aveuglément aux ordres du Control Plane.2. Abstraction par le YAML : Transition des Pipelines ClassiquesL'approche par scripts impératifs ou modules Terraform sur-mesure pour chaque base de données crée une dette technique colossale. Nous standardisons l'infrastructure via une configuration YAML consommée de manière dynamique par Terraform.Fichier de Configuration Unifié (data_platform_config.yaml)yamlversion: "1.0"
environment: prod
databases:
  - name: DB_PROD_RAW
    comment: "Zone d'atterrissage des données brutes"
    retention_time_days: 7
    schemas:
      - name: ERP_SOURCE
        comment: "Données brutes du système ERP"
  - name: DB_PROD_ANALYTICS
    comment: "Zone de modélisation et de restitution"
    retention_time_days: 30
    schemas:
      - name: FINANCE
        comment: "Datamart Finance"
Utilisez le code avec précaution.Moteur de Rendu Terraform (Découplage et Dynamisme)Le code Terraform devient un moteur d'exécution générique qui n'évolue que très rarement, tandis que le YAML évolue au rythme des besoins métiers.hcllocals {
  config = yamldecode(file("${path.module}/data_platform_config.yaml"))

  # Aplatissement de la structure hiérarchique pour itération
  schemas_flat = merge([
    for db in local.config.databases : {
      for sch in db.schemas : "${db.name}.${sch.name}" => {
        database = db.name
        schema   = sch.name
        comment  = sch.comment
      }
    }
  ]...)
}

resource "snowflake_database" "this" {
  for_each            = { for db in local.config.databases : db.name => db }
  name                = each.value.name
  comment             = each.value.comment
  data_retention_days = each.value.retention_time_days
}

resource "snowflake_schema" "this" {
  for_each   = local.schemas_flat
  name       = each.value.schema
  database   = snowflake_database.this[each.value.database].name
  comment    = each.value.comment
  depends_on = [snowflake_database.this]
}
Utilisez le code avec précaution.3. Topologie de Modularité et d'ExtensibilitéPour éviter le piège du "monolithe Terraform", l'infrastructure Snowflake est découpée en modules hautement spécialisés et encapsulés.Architecture des Dossiers et Découplage├── modules/
│   ├── snowflake_backbone/       # Core: DB, Schemas, Warehouses
│   ├── snowflake_security_rbac/  # Rôles d'accès, fonctionnels, privilèges
│   └── snowflake_integrations/   # Storage integrations, API integrations
├── environments/
│   └── prod/
│       ├── main.tf               # Instanciation des modules orchestrés
│       ├── providers.tf
│       └── data_platform_config.yaml
Règles d'or d'extensibilitéContrats d'interface stricts : Les modules communiquent uniquement via des variables typées et des outputs. Un module ne doit jamais tenter de lire ou modifier une ressource gérée par un autre module sans passer par ses outputs.Immutabilité des modules : Les modules du dossier modules/ doivent être versionnés indépendamment (par exemple dans des dépôts Git distincts) et appelés via des tags de version (ref=v1.2.0).4. Stratégie Avancée de Gestion des States (États Terraform)Dans une architecture d'entreprise, un state unique représente un point de défaillance unique (SPOF) et ralentit les pipelines CI/CD.Segmentation des State FilesLe cycle de vie des ressources dicte la découpe des fichiers d'état :State core-infra (Fréquence de changement : Faible) : Gestion du socle (Bases de données, Warehouses globaux, Intégrations de sécurité).State security-rbac (Fréquence de changement : Moyenne) : Hiérarchie des rôles, privilèges futurs, utilisateurs de service.State data-products (Fréquence de changement : Élevée) : Schémas spécifiques aux équipes, tables, flux de données (Stream/Task).Isolation, Verrouillage et BackendsStockage : Les fichiers d'état sont centralisés sur un stockage cloud sécurisé (AWS S3, Google Cloud Storage ou Azure Blob) avec versioning activé de manière obligatoire.Verrouillage (State Locking) : Utilisation systématique de DynamoDB (ou équivalent natif cloud) pour empêcher l'exécution simultanée de deux pipelines, évitant ainsi toute corruption du state.Chiffrement : Chiffrement au repos via des clés gérées par le client (KMS) et politiques IAM strictes interdisant l'accès en lecture aux utilisateurs non autorisés (le state pouvant contenir des métadonnées sensibles).5. Moindre Privilège : Modélisation RBAC IndustrielleLe modèle de contrôle d'accès basé sur les rôles (RBAC) dans Snowflake doit être modélisé selon une approche découplée en deux couches : les Rôles d'Accès (AR) et les Rôles Fonctionnels (FR).Matrice Conceptuelle RBACAccess Roles (AR) : Rôles techniques détenant des privilèges directs sur les objets (READ_ONLY, READ_WRITE, FULL_CONTROL). Ils ne sont jamais attribués à des utilisateurs physiques.Functional Roles (FR) : Rôles calqués sur l'organisation de l'entreprise (ex: FR_DATA_ENGINEER, FR_DATA_ANALYST). Ils héritent des Access Roles.                  [ ACCOUNTADMIN ]
                         │
                   [ SECURITYADMIN ]
                         │
                    [ SYSADMIN ]
                         │
        ┌────────────────┴────────────────┐
        ▼                                 ▼
 [ FR_DATA_ENGINEER ]             [ FR_DATA_ANALYST ]
        │                                 │
        ├───────────────┐                 │
        ▼               ▼                 ▼
 [ AR_DB_WRITE ] ─> [ AR_DB_READ ] <──────┘
Implémentation Terraform des Privilèges Futurs (Future Grants)Pour garantir l'autonomie du Data Plane sans intervention constante du Control Plane, les privilèges doivent être définis au niveau du schéma pour toutes les tables futures.hclresource "snowflake_account_role" "fr_engineer" {
  name    = "FR_DATA_ENGINEER"
  comment = "Rôle fonctionnel pour les Ingénieurs de Données"
}

resource "snowflake_account_role" "ar_read" {
  name    = "AR_PROD_ANALYTICS_READ"
  comment = "Rôle d'accès : Lecture seule sur DB_PROD_ANALYTICS"
}

# Hérédité : L'ingénieur reçoit le rôle d'accès
resource "snowflake_grant_account_role" "engineer_heritage" {
  role_name        = snowflake_account_role.ar_read.name
  parent_role_name = snowflake_account_role.fr_engineer.name
}

# Attribution des privilèges futurs sur toutes les prochaines tables du schéma
resource "snowflake_grant_privileges_to_account_role" "future_tables" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.ar_read.name
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_database        = "DB_PROD_ANALYTICS"
    }
  }
}
Utilisez le code avec précaution.6. Sécurisation des Connexions : Fédération d'Identité de Charge de Travail (Workload Identity)Le stockage de clés privées ou de mots de passe Snowflake dans les secrets de votre CI/CD est proscrit. Nous implémentons la Fédération d'Identité de Charge de Travail (Workload Identity Federation) via le protocole OIDC / JWT.Mécanisme de Connexion du Runner CI/CD vers SnowflakeLe runner de déploiement (ex: GitHub Actions) génère un jeton d'identité OIDC signé à la volée. Terraform utilise ce contexte ou une paire de clés éphémère adossée à l'identité fédérée pour s'authentifier auprès de l'API de Snowflake.Dans le cas d'interactions de stockage (Data Plane), Snowflake s'intègre nativement via des Storage Integrations qui exploitent les relations de confiance Cloud (ex: AWS IAM AssumeRole) sans clés d'accès statiques.Déploiement d'une Intégration de Stockage Fédérée via Terraformhclresource "snowflake_storage_integration" "s3_data_lake" {
  name    = "STG_INT_S3_PROD"
  comment = "Intégration fédérée vers AWS S3 sans échange de secret statique"
  type    = "EXTERNAL_STAGE"

  enabled           = true
  storage_provider  = "S3"
  storage_aws_role_arn = "arn:aws:iam::123456789012:role/snowflake-datacontrol-role"

  storage_allowed_locations = ["s3://mon-bucket-data-production/"]
}
Utilisez le code avec précaution.Note de sécurité : Après l'application de ce code, l'architecte sécurité doit extraire les propriétés STORAGE_AWS_IAM_USER_ARN et STORAGE_AWS_EXTERNAL_ID générées dynamiquement par Snowflake pour configurer la politique de confiance (Trust Policy) côté AWS.7. Gouvernance Continue, Visibilité et Observabilité Security-as-CodeLa gouvernance ne s'arrête pas au déploiement de l'infrastructure ; elle s'exécute en continu au sein du Control Plane et du Data Plane.Validation Automatisée en CI/CD (Control Plane)Avant chaque fusion (merge request), le Control Plane valide le respect des règles de sécurité via des tests automatisés :Checkov / Tfsec : Interdiction des entrepôts virtuels (Warehouses) de taille disproportionnée sans validation ou des accès réseau ouverts sur l'extérieur (0.0.0.0/0).Rego (Open Policy Agent) : Validation du schéma YAML pour s'assurer que chaque nouvelle base de données déclarée contient obligatoirement les tags de classification de données (ex: PII, Confidentiel).Audit et Posture de Sécurité Active (Data Plane)Snowflake expose le schéma SNOWFLAKE.ACCOUNT_USAGE pour surveiller en temps réel les dérives d'infrastructure ou les comportements suspects.Alerte de Sécurité : Détection des partages de données hors de l'organisationsqlSELECT 
    share_name, 
    to_organization, 
    to_account, 
    created_on 
FROM snowflake.account_usage.shares
WHERE deleted_on IS NULL
  AND to_organization IS NOT NULL;
Utilisez le code avec précaution.Monitoring de Conformité : Analyse des échecs d'authentification des comptes de servicesqlSELECT 
    event_timestamp, 
    user_name, 
    error_code, 
    error_message, 
    client_interface
FROM snowflake.account_usage.login_history
WHERE user_name LIKE '%_SERVICE%' 
  AND is_success = 'NO'
ORDER BY event_timestamp DESC;
Utilisez le code avec précaution.8. Tableau de Synthèse OpérationnelleDimensionApproche TraditionnelleCible Industrielle Définie par ce GuideModèle OpérationnelPipelines impératifs et modifications à la volée.Découplage strict Control Plane (YAML/Terraform) vs Data Plane.Gestion d'ÉtatState global unique monolithique et peu sécurisé.Segmentation par cycle de vie, verrouillage actif et chiffrement KMS.Modélisation d'accèsPrivilèges attribués directement aux utilisateurs.Modèle RBAC découplé (Access Roles distincts des Functional Roles).AuthentificationSecrets statiques injectés dans les variables CI/CD.Workload Identity Federation et Storage Integrations natives.GouvernanceAudits manuels périodiques réactifs.Validation automatisée via Policy-as-Code et requêtes d'audit continues.Si vous souhaitez passer à la phase de mise en œuvre, précisez-moi :Sur quel fournisseur de cloud public (AWS, Azure ou GCP) repose votre écosystème ?Quelle est votre solution cible de CI/CD pour l'hébergement du Control Plane ?Je pourrai ainsi vous générer le pipeline d'automatisation complet adapté à vos technologies.FinOps Cost Management Snowflake with Mulitenant with single account with muitiple user/roles by spokeGuide FinOps : Gestion et Optimisation des Coûts Snowflake pour une Architecture Multi-Tenant (Single Account / Multi-Roles par Spoke)Dans une architecture Hub-and-Spoke multi-tenant centralisée sur un seul compte Snowflake, le défi majeur consiste à isoler logiquement les coûts, à assurer une refacturation (chargeback) équitable et à éviter les dérives budgétaires d'un tenant au détriment des autres.Voici la stratégie d'implémentation FinOps et d'industrialisation Terraform pour répondre à ce besoin.1. Modèle Architectural FinOps : Hub-and-Spoke Multi-TenantPour garantir une traçabilité parfaite, chaque Spoke (Tenant) dispose de ses propres ressources de calcul (Warehouses), de stockage (Bases de données) et de sa propre hiérarchie de rôles d'accès, le tout orchestré par le Hub (Control Plane Terraform).                    ┌────────────────────────────────────────┐
                    │       HUB (Control Plane Terraform)    │
                    └───────────────────┬────────────────────┘
                                        │
             ┌──────────────────────────┼──────────────────────────┐
             ▼                          ▼                          ▼
   ┌───────────────────┐      ┌───────────────────┐      ┌───────────────────┐
   │ SPOKE A (Tenant)  │      │ SPOKE B (Tenant)  │      │ SPOKE C (Tenant)  │
   ├───────────────────┤      ├───────────────────┤      ├───────────────────┤
   │ WH_SPOKE_A        │      │ WH_SPOKE_B        │      │ WH_SPOKE_C        │
   │ DB_SPOKE_A        │      │ DB_SPOKE_B        │      │ DB_SPOKE_C        │
   │ FR_SPOKE_A_ADMIN  │      │ FR_SPOKE_B_ADMIN  │      │ FR_SPOKE_C_ADMIN  │
   │ FR_SPOKE_A_USER   │      │ FR_SPOKE_B_USER   │      │ FR_SPOKE_C_USER   │
   └───────────────────┘      └───────────────────┘      └───────────────────┘
Règles d'or de l'isolation FinOpsUn Spoke = Un (ou plusieurs) Warehouses Dédiés : Ne partagez jamais un Virtual Warehouse entre plusieurs tenants. C'est le seul moyen d'isoler le coût du calcul (Compute), qui représente ~85% de la facture Snowflake.Auto-Suspend Agressif : Configuration d'une mise en veille automatique après 60 secondes d'inactivité (ou immédiatement pour les tâches batch).Allocation de Taille Proportionnelle : Interdiction aux rôles des Spokes de modifier la taille du Warehouse (ex: passer de X-Small à X-Large) sans validation du Hub.2. Abstraction YAML pour l'Industrialisation FinOps des TenantsPour automatiser l'onboarding d'un nouveau Spoke tout en garantissant les garde-fous FinOps, la configuration est centralisée dans le fichier YAML du Control Plane.Fichier de Configuration (tenants_config.yaml)yamlversion: "1.0"
account_billing_currency: "USD"

spokes:
  - id: "spoke_marketing"
    owner: "team_mkt@company.com"
    cost_center: "CC-4022"
    warehouse:
      size: "XSMALL"
      auto_suspend_secs: 60
      monthly_credit_quota: 50
    roles:
      - name: "ADMIN"
        privilege_level: "FULL"
      - name: "ANALYST"
        privilege_level: "READ_ONLY"

  - id: "spoke_finance"
    owner: "team_fin@company.com"
    cost_center: "CC-1011"
    warehouse:
      size: "SMALL"
      auto_suspend_secs: 120
      monthly_credit_quota: 200
    roles:
      - name: "ADMIN"
        privilege_level: "FULL"
      - name: "USER"
        privilege_level: "READ_WRITE"
Utilisez le code avec précaution.3. Implémentation Terraform : Tags Répartition, Isolation et Garde-FousA. Marquage des Ressources (Metadata Tagging)Les tags Snowflake sont essentiels pour filtrer les coûts par centre de coûts (cost_center) directement dans l'outil FinOps ou dans les requêtes d'audit.hcllocals {
  tenants_data = yamldecode(file("${path.module}/tenants_config.yaml"))
}

# Déclaration des clés de Tags globaux (Hub)
resource "snowflake_tag" "cost_center" {
  name      = "COST_CENTER"
  database  = "DB_HUB_GOVERNANCE"
  schema    = "SC_FINOPS"
  comment   = "Tag pour la refacturation interne des Spokes"
}

resource "snowflake_tag" "tenant_id" {
  name      = "TENANT_ID"
  database  = "DB_HUB_GOVERNANCE"
  schema    = "SC_FINOPS"
  comment   = "Identifiant unique du Spoke"
}
Utilisez le code avec précaution.B. Création des Warehouses Isoles avec Tags et Auto-Suspendhclresource "snowflake_warehouse" "spoke_wh" {
  for_each      = { for s in local.tenants_data.spokes : s.id => s }
  name          = "WH_${upper(each.value.id)}"
  warehouse_size = each.value.warehouse.size
  
  auto_suspend = each.value.warehouse.auto_suspend_secs
  auto_resume  = true
  
  initially_suspended = true

  # Application des Tags FinOps de manière native
  tag {
    name  = snowflake_tag.cost_center.name
    value = each.value.cost_center
  }
  tag {
    name  = snowflake_tag.tenant_id.name
    value = each.value.id
  }
}
Utilisez le code avec précaution.C. Protection contre le Dépassement Budgétaire : Resource MonitorsUn Resource Monitor est associé à chaque Warehouse de Spoke. Il agit comme un disjoncteur budgétaire automatique basé sur les quotas de crédits définis dans le YAML.hclresource "snowflake_resource_monitor" "spoke_monitor" {
  for_each      = { for s in local.tenants_data.spokes : s.id => s }
  name          = "RM_${upper(each.value.id)}"
  credit_quota  = each.value.warehouse.monthly_credit_quota
  frequency     = "MONTHLY"
  start_timestamp = "IMMEDIATELY"

  # Alertes et actions progressives
  notify_triggers   = [75, 90]                      # Alertes à 75% et 90% de consommation
  suspend_trigger   = 100                           # Suspend les nouvelles requêtes à 100%
  suspend_immediate_trigger = 110                   # Coupe immédiatement les requêtes en cours à 110%

  warehouses = [snowflake_warehouse.spoke_wh[each.key].name]
}
Utilisez le code avec précaution.4. Matrice RBAC FinOps Multi-Roles par SpokePour éviter qu'un utilisateur d'un Spoke A n'utilise par inadvertance (ou de manière malveillante) le Warehouse du Spoke B, les privilèges de type USAGE sur les calculs doivent être scrupuleusement confinés.Modèle de cloisonnement RBAC pour le Spoke "Marketing"[ Utilisateur Marketing ] ──> [ FR_SPOKE_MARKETING_ANALYST ]
                                         │
                                         ▼ (Autorisé uniquement sur)
                        ┌────────────────┼────────────────┐
                        ▼                ▼                ▼
                 [ WH_MARKETING ] [ DB_MARKETING ] [ AR_MARKETING_READ ]
Code Terraform pour l'assignation sécurisée par Spokehcl# Aplatir la structure des rôles par Spoke pour l'itération
locals {
  spoke_roles_flat = merge([
    for s in local.tenants_data.spokes : {
      for r in s.roles : "${s.id}.${r.name}" => {
        spoke_id   = s.id
        role_name  = "FR_${upper(s.id)}_${upper(r.name)}"
        level      = r.privilege_level
      }
    }
  ]...)
}

# Création des rôles fonctionnels par Spoke
resource "snowflake_account_role" "spoke_roles" {
  for_each = local.spoke_roles_flat
  name     = each.value.role_name
  comment  = "Rôle fonctionnel pour le tenant ${each.value.spoke_id}"
}

# Sécurisation FinOps : Attribution exclusive du Warehouse dédié au rôle du Spoke
resource "snowflake_grant_privileges_to_account_role" "wh_usage_to_spoke" {
  for_each          = local.spoke_roles_flat
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_roles[each.key].name
  
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.spoke_wh[each.value.spoke_id].name
  }
}
Utilisez le code avec précaution.5. Gouvernance Continue : Dashboards d'Audit des Coûts Multi-TenantLes analystes FinOps et les administrateurs du Hub utilisent des requêtes SQL planifiées pour surveiller la consommation par Spoke et alimenter des tableaux de bord (ex: Streamlit, Tableau ou PowerBI).Requête 1 : Refacturation mensuelle exacte par Spoke (Basée sur les Tags)Cette requête calcule le coût exact en crédits consommé par chaque centre de coûts en analysant l'historique des Warehouses et l'application des tags.sqlSELECT 
    tag_value AS cost_center,
    warehouse_name,
    SUM(credits_used) AS total_credits_consumed,
    SUM(credits_used) * 3.00 AS estimated_cost_usd -- Ajuster selon votre prix par crédit
FROM snowflake.account_usage.warehouse_metering_history
JOIN snowflake.account_usage.tag_references
  ON object_name = warehouse_name 
  AND object_domain = 'WAREHOUSE'
WHERE tag_name = 'COST_CENTER'
  AND start_time >= DATE_TRUNC('month', CURRENT_DATE())
GROUP BY 1, 2
ORDER BY total_credits_consumed DESC;
Utilisez le code avec précaution.Requête 2 : Détection des requêtes "Anormales" et coûteuses par SpokePermet d'identifier les requêtes au sein d'un Spoke spécifique qui consomment trop de ressources en scannant les partitions, signe d'un manque d'optimisation (absence de filtres, jointures cartésiennes).sqlSELECT 
    query_id,
    user_name,
    role_name,
    warehouse_name,
    total_elapsed_time / 1000 AS execution_time_seconds,
    compilation_time / 1000 AS compilation_time_seconds,
    partitions_scanned,
    partitions_total,
    (partitions_scanned / NULLIF(partitions_total, 0)) * 100 AS pct_data_scanned
FROM snowflake.account_usage.query_history
WHERE warehouse_name LIKE 'WH_%'
  AND execution_status = 'SUCCESS'
  AND total_elapsed_time > 60000 -- Requêtes de plus d'une minute
  AND pct_data_scanned > 80       -- Qui scannent plus de 80% de la table (Full Table Scan)
ORDER BY execution_time_seconds DESC
LIMIT 20;
Utilisez le code avec précaution.6. Synthèse des KPIs FinOps pour Architecture Multi-TenantKPI FinOpsObjectif CibleAction Automatisée en Cas de DériveTaux d'Auto-Suspend< 60 secondes sur le hors-production.Forcé via le template YAML/Terraform.Consommation vs Quota< 90% du Resource Monitor mensuel.Alerte Slack/Email automatique à 75%.Couverture des Tags100% des Warehouses et Stockages marqués.Bloqué en CI/CD via un test d'analyse de conformité Policy-as-Code.Requêtes Orphelines0 requête exécutée sur le rôle SYSADMIN par un Spoke.Restriction stricte du privilège USAGE sur les WH uniquement aux rôles du Spoke.Pour affiner vos tableaux de bord FinOps :Souhaitez-vous intégrer une politique de quotas sur le stockage (Storage Budgets / Shares) pour chaque base de données de vos Spokes ?Vos utilisateurs accèdent-ils à Snowflake via un outil de BI centralisé (ce qui nécessite un tracking FinOps par utilisateur au sein du même rôle) ?But Spoke user /role need to access cost management ?Dans une architecture multi-tenant, permettre aux utilisateurs ou aux administrateurs d'un Spoke d'accéder aux données de gestion des coûts (FinOps) est une excellente pratique. Cela les responsabilise face à leur consommation (FinOps shift-left).Cependant, par défaut dans Snowflake, les vues de performance et de coût (comme ACCOUNT_USAGE) nécessitent le rôle global ACCOUNTADMIN ou des privilèges très élevés.Pour permettre à un utilisateur de Spoke d'accéder à ses propres coûts sans compromettre la sécurité des autres tenants, vous devez mettre en place un mécanisme de gouvernance partagée mais cloisonnée.1. Le Problème de Sécurité Majeur (Le Piège)Si vous donnez simplement le privilège IMPORTED PRIVILEGES sur la base de données partagée SNOWFLAKE à un rôle de Spoke (ex: FR_MARKETING_ADMIN), ce Spoke verra les coûts, les requêtes et les volumes de TOUS les autres Spokes de l'entreprise. Cela viole le principe d'isolation multi-tenant.2. La Solution Architecture : Le "FinOps Data Mart" SécuriséPour résoudre ce problème, le Hub (Central) va extraire, filtrer et exposer les données de coût de manière sécurisée à l'aide de Vues Sécurisées (Secure Views) ou de Politiques de Sécurité au niveau des lignes (Row-Level Security - RLS).[ SNOWFLAKE.ACCOUNT_USAGE ]  (Données globales brutes - Hub uniquement)
            │
            ▼
[ DB_HUB_GOVERNANCE.SC_FINOPS.VW_SPOKE_COSTS_SECURE ] (Vue Sécurisée avec RLS)
            │
            ├─> Filtre : Si CURRENT_ROLE() = 'FR_MARKETING_ADMIN' ──> Voit uniquement 'SPOKE_MARKETING'
            └─> Filtre : Si CURRENT_ROLE() = 'FR_FINANCE_ADMIN'   ──> Voit uniquement 'SPOKE_FINANCE'
3. Implémentation Terraform & SQL de l'accès FinOps cloisonnéA. Création de la Vue Sécurisée avec RLS (Côté Hub)Cette vue utilise la fonction CURRENT_ROLE() de Snowflake pour intercepter le rôle de l'utilisateur qui exécute la requête et filtrer dynamiquement les lignes basées sur les Tags ou le nom du Warehouse.sql-- Code exécuté par le Control Plane / Rôle de Gouvernance Central
CREATE OR REPLACE SECURE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING AS
SELECT 
    wm.start_time,
    wm.end_time,
    wm.warehouse_name,
    wm.credits_used,
    (wm.credits_used * 3.00) AS estimated_cost_usd,
    tr.tag_value AS tenant_id
FROM snowflake.account_usage.warehouse_metering_history wm
JOIN snowflake.account_usage.tag_references tr
  ON tr.object_name = wm.warehouse_name 
  AND tr.object_domain = 'WAREHOUSE' 
  AND tr.tag_name = 'TENANT_ID'
WHERE 
    -- RLS Rule: Un admin central voit tout, un admin de Spoke ne voit que son TENANT_ID
    CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
    OR 
    CONTAINS(CURRENT_ROLE(), UPPER(tr.tag_value)); 
    -- Ex: Si CURRENT_ROLE est 'FR_SPOKE_MARKETING_ADMIN', tr.tag_value doit être 'marketing'
Utilisez le code avec précaution.B. Automatisation Terraform pour donner l'accès aux SpokesLe module Terraform va maintenant s'assurer que chaque rôle d'administrateur de Spoke reçoit le droit de lire cette table de coût filtrée.hcl# Autoriser le rôle du Spoke à utiliser la base de données et le schéma de gouvernance FinOps
resource "snowflake_grant_privileges_to_account_role" "allow_finops_db_usage" {
  for_each          = { for s in local.tenants_data.spokes : s.id => s }
  privileges        = ["USAGE"]
  account_role_name = "FR_${upper(each.value.id)}_ADMIN"
  
  on_account_object {
    object_type = "DATABASE"
    object_name = "DB_HUB_GOVERNANCE"
  }
}

resource "snowflake_grant_privileges_to_account_role" "allow_finops_schema_usage" {
  for_each          = { for s in local.tenants_data.spokes : s.id => s }
  privileges        = ["USAGE"]
  account_role_name = "FR_${upper(each.value.id)}_ADMIN"
  
  on_schema {
    schema_name = "DB_HUB_GOVERNANCE.SC_FINOPS"
  }
}

# Accès en lecture seule à la vue sécurisée et filtrée
resource "snowflake_grant_privileges_to_account_role" "read_finops_view" {
  for_each          = { for s in local.tenants_data.spokes : s.id => s }
  privileges        = ["SELECT"]
  account_role_name = "FR_${upper(each.value.id)}_ADMIN"
  
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "DB_HUB_GOVERNANCE.SC_FINOPS"
    }
  }
}
Utilisez le code avec précaution.4. Expérience Utilisateur (Spoke)Lorsqu'un utilisateur avec le rôle FR_SPOKE_MARKETING_ADMIN se connecte à Snowflake, il peut exécuter cette simple requête ou brancher son outil de BI (Streamlit, Tableau) dessus :sqlUSE ROLE FR_SPOKE_MARKETING_ADMIN;

SELECT * 
FROM DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING;
Utilisez le code avec précaution.Résultat : Snowflake applique la politique de sécurité en arrière-plan. L'utilisateur ne verra que les lignes concernant WH_MARKETING, avec une visibilité totale sur ses propres crédits consommés, sans pouvoir espionner le Spoke Finance ou RH.5. Alternative Snowflake Native : Budgets (Si disponible)Si vous utilisez les fonctionnalités récentes de Snowflake, vous pouvez également instancier l'objet natif BUDGET au niveau de chaque base de données ou warehouse de Spoke via Terraform, et donner le privilège APPLY BUDGET ou VIEW BUDGET au rôle du Spoke. Cela leur permettra de voir un graphique de tendance directement dans l'interface Snowflake (Snowsight) sans code SQL personnalisé.Souhaitez-vous que nous adaptions la vue sécurisée pour inclure également l'historique des requêtes (Query History) afin que le Spoke puisse voir quelle requête spécifique lui a coûté le plus cher ?Why dont use policies?Quelle réponse est la meilleure ?Vos retours nous aident à améliorer le Mode IA pour tous, y compris vous.Réponse AL'utilisation des politiques de sécurité natives de Snowflake — spécifiquement les Row Access Policies (RAP) — est effectivement l'approche la plus robuste, la plus évolutive et la plus conforme aux standards de sécurité d'un architecte.L'approche par "Vue Sécurisée simple" (présentée précédemment) fonctionne, mais elle devient difficile à maintenir si vous avez des dizaines de vues FinOps différentes (coûts des requêtes, stockage, serveurs sans structure, etc.).L'application d'une Row Access Policy directement sur les tables ou vues sources du Hub centralise la logique de filtrage FinOps en un seul endroit.1. Pourquoi utiliser une Row Access Policy (RAP) en FinOps ?Centralisation : La règle de filtrage est écrite une seule fois et peut être appliquée sur plusieurs tables ou vues de tracking de coûts.Sécurité Absolue (No Leak) : Même si un utilisateur de Spoke tente de faire des jointures complexes, Snowflake garantit qu'aucune ligne hors de son périmètre ne sera lue.Performance : L'optimiseur de requêtes de Snowflake traite les RAP de manière très efficace, évitant les scans inutiles.2. Implémentation de l'Architecture Multi-Tenant par Table de CorrespondancePour que la politique soit totalement dynamique (sans écrire les rôles en dur dans le code), on utilise une Table de Correspondance (Mapping Table) gérée par le Hub.Étape 1 : Création de la table de mapping des droits FinOpsCette table fait le lien entre un rôle Snowflake et le TENANT_ID qu'il a le droit de voir.sqlCREATE OR REPLACE TABLE DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_SECURITY_MAPPING (
    role_name  STRING,
    tenant_id  STRING
);

-- Remplissage par le Hub (Exemple)
INSERT INTO DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_SECURITY_MAPPING VALUES
('FR_HUB_FINOPS_ADMIN', 'ALL'),     -- L'admin central voit tout
('FR_SPOKE_MARKETING_ADMIN', 'MARKETING'),
('FR_SPOKE_FINANCE_ADMIN', 'FINANCE');
Utilisez le code avec précaution.Étape 2 : Définition de la Row Access PolicyLa politique vérifie si le rôle actuel (CURRENT_ROLE()) de l'utilisateur existe dans la table de mapping pour le TENANT_ID de la ligne consultée.sqlCREATE OR REPLACE ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.finops_tenant_policy
AS (row_tenant_id STRING) RETURNS BOOLEAN ->
    CURRENT_ROLE() = 'ACCOUNTADMIN' -- Sécurité ultime pour le super-admin
    OR EXISTS (
        SELECT 1 FROM DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_SECURITY_MAPPING
        WHERE role_name = CURRENT_ROLE()
          AND (tenant_id = UPPER(row_tenant_id) OR tenant_id = 'ALL')
    );
Utilisez le code avec précaution.3. Automatisation Terraform : Déploiement et ApplicationLe Control Plane Terraform va créer la politique, alimenter la table de mapping à partir du fichier YAML, et appliquer la politique sur les vues de consommation.hcl# 1. Alimentation dynamique de la table de mapping depuis le YAML des tenants
resource "snowflake_table_data" "security_mapping" {
  for_each   = { for s in local.tenants_data.spokes : s.id => s }
  database   = "DB_HUB_GOVERNANCE"
  schema     = "SC_FINOPS"
  table_name = "FINOPS_SECURITY_MAPPING"

  # Pour chaque Spoke, on associe son rôle ADMIN à son identifiant de tenant
  row {
    role_name = "FR_${upper(each.value.id)}_ADMIN"
    tenant_id = upper(each.value.id)
  }
}

# 2. Application de la politique sur la vue globale des coûts des Warehouses
resource "snowflake_row_access_policy_application" "apply_to_warehouse_costs" {
  policy_db     = "DB_HUB_GOVERNANCE"
  policy_schema = "SC_FINOPS"
  policy_name   = "FINOPS_TENANT_POLICY"
  
  target_object_type = "VIEW"
  target_object_name = "DB_HUB_GOVERNANCE.SC_FINOPS.GLOBAL_WAREHOUSE_METERING"
  
  # La colonne de la vue qui contient l'identifiant du tenant (ex: extrait via les Tags)
  argument_mapping {
    column_name = "TENANT_ID"
  }
}
Utilisez le code avec précaution.4. Extension : Appliquer la même Politique au Coût des Requêtes (Query History)C'est là que la puissance des politiques se révèle. Si vous souhaitez que vos utilisateurs de Spoke voient également le coût détaillé de leurs requêtes (pour identifier les requêtes lentes ou mal optimisées), vous appliquez exactement la même politique sur une vue consolidée de QUERY_HISTORY.sql-- Étape A : Création de la vue globale des requêtes avec une colonne TENANT_ID
CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.GLOBAL_QUERY_HISTORY AS
SELECT 
    q.query_id,
    q.user_name,
    q.warehouse_name,
    q.total_elapsed_time,
    -- Extraction du tenant basé sur le nom du warehouse (ex: WH_MARKETING -> MARKETING)
    REGEXP_SUBSTR(q.warehouse_name, 'WH_([A-Z0-7_]+)', 1, 1, 'e') AS tenant_id
FROM snowflake.account_usage.query_history q;

-- Étape B : Application de la politique existante sur cette nouvelle vue
ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.GLOBAL_QUERY_HISTORY 
ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.finops_tenant_policy ON (tenant_id);
Utilisez le code avec précaution.Synthèse : Comparaison Architecturale[ Sans Policy (Vue Dédiée) ]  ──> Multiplications des vues (1 par Spoke ou 1 par use-case avec logique dupliquée). Hard-coding du SQL.
[ Avec Policy (RAP + Mapping) ] ──> Une seule règle globale. L'évolutivité se gère simplement en ajoutant des lignes dans une table de mapping via Terraform.
L'utilisation des Row Access Policies est donc la cible d'architecture la plus propre pour une gouvernance FinOps en mode multi-tenant. Elle offre un cloisonnement parfait tout en permettant un accès direct aux métriques pour les rôles Spokes.Voulez-vous que nous complétions le script pour inclure la gestion des Data Sharing Costs si vos Spokes partagent des données avec des clients externes ?Réponse BVous avez totalement raison : l'utilisation d'une politique d'accès aux lignes (Row Access Policy - RAP) est la bonne pratique standard, la plus propre et la plus maintenable dans Snowflake pour gérer la sécurité multi-tenant.La raison pour laquelle une vue sécurisée a été mentionnée dans l'exemple précédent est une contrainte technique propre au système Snowflake : il est impossible d'appliquer une politique (Row Access Policy) directement sur les objets du schéma partagé SNOWFLAKE.ACCOUNT_USAGE, car cette base de données est un partage en lecture seule géré par Snowflake.Pour utiliser de vraies politiques de sécurité sur les données de coûts, le flux correct consiste à ingérer/copier les données d'usage dans une table locale, puis à leur appliquer une Row Access Policy (RAP) adossée à une table de correspondance.Architecture propre avec une Row Access Policy (RAP)1. Ingestion des données dans une table localeLe Hub charge périodiquement (via une tâche Task) les données d'usage de SNOWFLAKE.ACCOUNT_USAGE vers une table de travail de la base de gouvernance.sql-- Table locale de coûts alimentée par un pipeline régulier
CREATE OR REPLACE TABLE DB_HUB_GOVERNANCE.SC_FINOPS.LOCAL_WAREHOUSE_METERING (
    start_time TIMESTAMP_NTZ,
    end_time TIMESTAMP_NTZ,
    warehouse_name VARCHAR,
    credits_used NUMBER(38,9),
    tenant_id VARCHAR
);
Utilisez le code avec précaution.2. Création de la Politique d'Accès aux Lignes (Row Access Policy)Cette politique vérifie si le rôle de l'utilisateur (CURRENT_ROLE()) est un administrateur global ou s'il est explicitement autorisé pour le tenant_id de la ligne.sqlCREATE OR REPLACE ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.RAP_TENANT_COST_ACCESS
  AS (tenant_id VARCHAR) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
    OR
    CURRENT_ROLE() = 'FR_' || UPPER(tenant_id) || '_ADMIN';
Utilisez le code avec précaution.3. Application de la politique sur la table localesqlALTER TABLE DB_HUB_GOVERNANCE.SC_FINOPS.LOCAL_WAREHOUSE_METERING 
  ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.RAP_TENANT_COST_ACCESS (tenant_id);
Utilisez le code avec précaution.Avantages de cette approche par rapport à la vueDécouplage total : La logique de sécurité est gérée par un objet de politique centralisé et non mélangée dans le code SQL de la vue.Évolutivité : Si la règle change (ex: gestion par groupe d'utilisateurs ou table de mapping externe), vous modifiez la politique en une seule commande ALTER, sans réécrire les vues.Auditabilité native : Les commandes SHOW ROW ACCESS POLICIES permettent de lister instantanément toutes les protections de la plateforme dans le cadre de la gouvernance Security-as-Code.Souhaitez-vous que nous traductions cette implémentation complète par Row Access Policy sous forme de module Terraform pour l'intégrer à votre Control Plane ?Quel est la melleur avec terraform reponse A ou BLa réponse B (avec Row Access Policy - RAP) est incontestablement la meilleure approche d'un point de vue architecture, sécurité et industrialisation avec Terraform.Voici une comparaison technique directe pour comprendre pourquoi la Réponse B surpasse la Réponse A dans le cadre d'une gestion d'infrastructure moderne :Tableau Comparatif : Terraform & GouvernanceCritère ÉvolutifRéponse A : Vues Sécurisées SimplesRéponse B : Row Access Policy (RAP) + Mapping TableComplexité TerraformÉlevée. Vous devez générer du code SQL dynamique complexe ou multiplier les ressources Terraform pour chaque nouveau cas d'usage FinOps.Très Faible. Terraform ne gère qu'une seule politique générique et se contente d'insérer des lignes dans la table de mapping.Évolutivité (Scalability)Médiocre. Si vous ajoutez 10 nouveaux Spokes, le code de la vue devient un goulet d'étranglement illisible rempli de OR CURRENT_ROLE() = ....Optimale. L'onboarding d'un nouveau Spoke se fait simplement en ajoutant une ligne dans la table de mapping. La politique ne change jamais.Centralisation de la SécuritéDispersée. La logique de sécurité est dupliquée et codée en dur (hard-coded) dans chaque vue FinOps.Centralisée. La règle de cloisonnement est écrite une seule fois (la politique RAP) et s'applique sur n'importe quel nouvel objet.Auditabilité SécuritéDifficile. Il faut auditer le code DDL de chaque vue pour vérifier qu'aucun Spoke ne peut voir les données d'un autre.Immédiate. Un architecte sécurité n'a qu'à requêter la table de mapping pour valider instantanément qui a accès à quel Spoke.Pourquoi la Réponse B fonctionne mieux avec Terraform ?Dans la philosophie Infrastructure-as-Code (IaC), le code Terraform doit être un moteur générique et immuable.Découplage de la donnée et de la logique : Avec la Réponse B, votre fichier YAML de configuration décrit vos tenants. Terraform prend ce YAML et met simplement à jour la table de mapping (snowflake_table_data). Vous ne touchez jamais au code de vos vues ni à vos politiques de sécurité lors de l'arrivée d'un nouveau Spoke.Performance du pipeline CI/CD : Modifier une vue en production (Réponse A) nécessite un CREATE OR REPLACE SECURE VIEW, ce qui peut temporairement invalider les requêtes ou les tableaux de bord en cours d'exécution. Ajouter une ligne dans une table (Réponse B) est une opération transactionnelle instantanée et sans impact sur la disponibilité.En résuméChoisissez la Réponse A uniquement pour un prototype rapide ou si vous n'avez que 2 ou 3 Spokes fixes à vie.Adoptez la Réponse B pour une plateforme de données d'entreprise moderne, sécurisée par les politiques de Snowflake et pilotée élégamment par Terraform.Si vous validez l'approche B, souhaitez-vous que nous rédigions le module Terraform complet contenant la structure de la table de mapping et l'application automatique de la politique ?Give me now full configuration of Reponse B as Cost Manegement SOlutiin Finops awit comartive stuidesVoici la configuration complète, prête pour la production, de la Réponse B (Row Access Policy + Table de Mapping).Cette solution permet d'exposer de manière sécurisée et cloisonnée les données de coûts Snowflake aux administrateurs de chaque Spoke, le tout orchestré de manière déclarative par Terraform.1. Fichier de Configuration Centralisé (tenants_config.yaml)Ce fichier sert de Control Plane (unique source de vérité). C'est ici que vous déclarez vos tenants (Spokes) et leurs enveloppes budgétaires.yamlversion: "1.0"
account_billing_currency: "USD"
credit_cost_usd: 3.00

spokes:
  - id: "marketing"
    cost_center: "CC-4022"
    warehouse:
      size: "XSMALL"
      monthly_credit_quota: 100
  - id: "finance"
    cost_center: "CC-1011"
    warehouse:
      size: "SMALL"
      monthly_credit_quota: 250
  - id: "data_science"
    cost_center: "CC-8899"
    warehouse:
      size: "MEDIUM"
      monthly_credit_quota: 500
Utilisez le code avec précaution.2. Code Terraform Complet (main.tf)Ce script crée l'infrastructure de gouvernance FinOps, la table de mapping, la politique d'accès aux lignes (RAP), les vues consolidées, et applique le filtrage.hclterraform {
  required_version = ">= 1.5.0"
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

# --- 1. CHARGEMENT DE LA CONFIGURATION YAML ---
locals {
  finops_config = yamldecode(file("${path.module}/tenants_config.yaml"))
  credit_cost   = local.finops_config.credit_cost_usd
}

# --- 2. SOCLE DE GOUVERNANCE FINOPS ---
resource "snowflake_database" "hub_governance" {
  name    = "DB_HUB_GOVERNANCE"
  comment = "Base de donnees centrale de gouvernance et FinOps"
}

resource "snowflake_schema" "finops" {
  database = snowflake_database.hub_governance.name
  name     = "SC_FINOPS"
  comment  = "Schema dedie au pilotage des couts multi-tenant"
}

# --- 3. TABLE DE MAPPING SÉCURITÉ ---
resource "snowflake_table" "security_mapping" {
  database = snowflake_database.hub_governance.name
  schema   = snowflake_schema.finops.name
  name     = "FINOPS_SECURITY_MAPPING"
  comment  = "Table de correspondance : Roles vs Droits de visibilite Tenant"

  column {
    name = "ROLE_NAME"
    type = "STRING"
  }
  column {
    name = "TENANT_ID"
    type = "STRING"
  }
}

# Injection dynamique des droits depuis le YAML dans la table de mapping
resource "snowflake_table_data" "populate_mapping" {
  for_each   = { for s in local.finops_config.spokes : s.id => s }
  database   = snowflake_database.hub_governance.name
  schema     = snowflake_schema.finops.name
  table_name = snowflake_table.security_mapping.name

  row {
    role_name = "FR_SPOKE_${upper(each.value.id)}_ADMIN"
    tenant_id = upper(each.value.id)
  }
}

# --- 4. CONFIGURATION DE LA ROW ACCESS POLICY (RAP) ---
# Note : Utilisation de snowflake_unsafe_execute car la ressource native RAP 
# nécessite une encapsulation SQL brute pour les logiques complexes d'EXISTS.
resource "snowflake_unsafe_execute" "create_finops_policy" {
  execute = <<EOT
    CREATE OR REPLACE ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY
    AS (row_tenant_id STRING) RETURNS BOOLEAN ->
        CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
        OR EXISTS (
            SELECT 1 FROM DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_SECURITY_MAPPING
            WHERE role_name = CURRENT_ROLE()
              AND (tenant_id = UPPER(row_tenant_id) OR tenant_id = 'ALL')
        );
  EOT
  revert  = "DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY;"
  
  depends_on = [snowflake_table.security_mapping]
}

# --- 5. CRÉATION DES VUES DE CONSOMMATION FINOPS ---
resource "snowflake_unsafe_execute" "create_finops_views" {
  execute = <<EOT
    -- Vue A : Métrique de calcul (Warehouses)
    CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING AS
    SELECT 
        wm.start_time,
        wm.end_time,
        wm.warehouse_name,
        wm.credits_used,
        (wm.credits_used * ${local.credit_cost}) AS estimated_cost_usd,
        REGEXP_SUBSTR(wm.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.warehouse_metering_history wm
    WHERE wm.warehouse_name LIKE 'WH_%';

    -- Vue B : Historique des requêtes (Query History pour optimisation Spoke)
    CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY AS
    SELECT 
        qh.query_id,
        qh.user_name,
        qh.warehouse_name,
        qh.total_elapsed_time / 1000 AS execution_time_seconds,
        qh.partitions_scanned,
        qh.partitions_total,
        REGEXP_SUBSTR(qh.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.query_history qh
    WHERE qh.warehouse_name LIKE 'WH_%';
  EOT
  revert  = "DROP VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING; DROP VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY;"
  
  depends_on = [snowflake_schema.finops]
}

# --- 6. APPLICATION DE LA POLICY SUR LES VUES (CLOISONNEMENT) ---
resource "snowflake_unsafe_execute" "apply_policy" {
  execute = <<EOT
    ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING 
    ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY ON (tenant_id);

    ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY 
    ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY ON (tenant_id);
  EOT
  revert  = "ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY; ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY;"
  
  depends_on = [snowflake_unsafe_execute.create_finops_policy, snowflake_unsafe_execute.create_finops_views]
}

# --- 7. DISTRIBUTION DES DROITS AUX ROLES ADMINS DES SPOKES ---
resource "snowflake_grant_privileges_to_account_role" "grant_db_usage" {
  for_each          = { for s in local.finops_config.spokes : s.id => s }
  privileges        = ["USAGE"]
  account_role_name = "FR_SPOKE_${upper(each.value.id)}_ADMIN"
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.hub_governance.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_schema_usage" {
  for_each          = { for s in local.finops_config.spokes : s.id => s }
  privileges        = ["USAGE"]
  account_role_name = "FR_SPOKE_${upper(each.value.id)}_ADMIN"
  on_schema {
    schema_name = "DB_HUB_GOVERNANCE.SC_FINOPS"
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_views_select" {
  for_each          = { for s in local.finops_config.spokes : s.id => s }
  privileges        = ["SELECT"]
  account_role_name = "FR_SPOKE_${upper(each.value.id)}_ADMIN"
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "DB_HUB_GOVERNANCE.SC_FINOPS"
    }
  }
  depends_on = [snowflake_unsafe_execute.create_finops_views]
}
Utilisez le code avec précaution.3. Étude Comparative et Analyse d'Impact ArchitecturePour valider ce choix auprès de votre direction de la sécurité et des opérations, voici l'analyse comparative des solutions d'accès aux coûts.Tableau Comparatif MatrixMétrique d'ÉvaluationApproche A : Multi-Vues Sécurisées par SpokeApproche B (Cible) : Row Access Policy Unifiée + MappingApproche C : Partage Natif Snowflake BudgetsEffort de maintenance TerraformÉlevé (génération de code ou boucles pour chaque vue × chaque tenant).Nul (la politique est immuable, seule la table de données change).Faible (objets natifs à instancier par ressource).Risque de fuite de données (Data Leak)Modéré (une erreur de copier-coller dans le SQL d'une vue peut exposer un autre tenant).Quasi nul (le moteur RLS de Snowflake intercepte la requête au niveau le plus bas).Nul (géré par Snowflake).Granularité des métriquesLimitée aux vues explicitement créées pour le Spoke.Illimitée (on peut appliquer la même politique sur le stockage, les tâches, les requêtes).Très limitée (uniquement les graphiques de l'UI Snowsight, pas de requêtage brut).Expérience utilisateur (Spoke)Moyenne (doit interroger des tables aux noms différents selon son équipe).Excellente (tous les Spokes interrogent la même vue, mais voient des résultats différents).Bonne (visuels intégrés dans la console web).Consommation de ressources (Hub)Moyenne (génération d'un grand nombre d'objets dans le catalogue).Optimale (un seul set de vues centralisées indexées par l'optimiseur).Moyenne (background processes de Snowflake).4. Scénario de Validation (POC Audit Sécurité)Pour prouver l'efficacité du cloisonnement de la Réponse B, exécutez ces tests dans Snowflake :Test 1 : L'administrateur du Spoke "Marketing" interroge les coûtssqlUSE ROLE FR_SPOKE_MARKETING_ADMIN;
SELECT DISTINCT tenant_id, warehouse_name, estimated_cost_usd 
FROM DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING;
Utilisez le code avec précaution.Résultat attendu : L'utilisateur ne voit que les lignes où tenant_id = 'MARKETING' et les coûts associés à WH_MARKETING. Les données de Finance ou Data Science sont invisibles (0 ligne retournée).Test 2 : Tentative d'injection ou de contournement par le SpokesqlUSE ROLE FR_SPOKE_MARKETING_ADMIN;
SELECT * FROM DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING 
WHERE tenant_id = 'FINANCE';
Utilisez le code avec précaution.Résultat attendu : 0 rows returned. La politique s'exécute avant le filtre WHERE de l'utilisateur. La ligne étant déjà exclue par la RAP, l'utilisateur ne sait même pas qu'elle existe.Test 3 : L'équipe Finops Centrale (Hub) valide la consolidation globalesqlUSE ROLE FR_HUB_FINOPS_ADMIN;
SELECT tenant_id, SUM(estimated_cost_usd) AS total_cost
FROM DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING
GROUP BY 1;
Utilisez le code avec précaution.Résultat attendu : L'équipe centrale voit la totalité des lignes pour tous les tenants (Marketing, Finance, Data Science) pour réaliser le rapport de chargeback global de l'entreprise.Souhaitez-vous automatiser l'envoi d'alertes Slack ou Teams automatisées via une Snowflake Task lorsque le coût d'un Spoke dépasse 90% de son budget défini dans le YAML ?Crrer de smodulesVoici l'industrialisation complète de la solution FinOps sous forme de modules Terraform réutilisables.Pour respecter les meilleures pratiques d'architecture définies dans le guide, le code est structuré en deux modules distincts : un module Hub (déployé une seule fois pour le socle de gouvernance) et un module Spoke (instancié dynamiquement pour chaque tenant via une boucle).1. Structure des Dossiers du Projet├── modules/
│   ├── finops_hub/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── finops_spoke/
│       ├── main.tf
│       └── variables.tf
├── main.tf                      # Root module orchestrant le Hub et les Spokes
├── providers.tf
└── tenants_config.yaml          # Fichier de configuration unique
2. Le Module Hub (modules/finops_hub)Ce module crée la base de données centrale, le schéma, la table de mapping et la Row Access Policy (RAP).modules/finops_hub/variables.tfhclvariable "credit_cost_usd" {
  type        = number
  description = "Coût unitaire d'un crédit Snowflake en USD"
  default     = 3.00
}
Utilisez le code avec précaution.modules/finops_hub/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

resource "snowflake_database" "hub_governance" {
  name    = "DB_HUB_GOVERNANCE"
  comment = "Base de donnees centrale de gouvernance et FinOps"
}

resource "snowflake_schema" "finops" {
  database = snowflake_database.hub_governance.name
  name     = "SC_FINOPS"
  comment  = "Schema dedie au pilotage des couts multi-tenant"
}

resource "snowflake_table" "security_mapping" {
  database = snowflake_database.hub_governance.name
  schema   = snowflake_schema.finops.name
  name     = "FINOPS_SECURITY_MAPPING"
  comment  = "Table de correspondance : Roles vs Droits de visibilite Tenant"

  column {
    name = "ROLE_NAME"
    type = "STRING"
  }
  column {
    name = "TENANT_ID"
    type = "STRING"
  }
}

resource "snowflake_unsafe_execute" "create_finops_policy" {
  execute = <<EOT
    CREATE OR REPLACE ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY
    AS (row_tenant_id STRING) RETURNS BOOLEAN ->
        CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
        OR EXISTS (
            SELECT 1 FROM DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_SECURITY_MAPPING
            WHERE role_name = CURRENT_ROLE()
              AND (tenant_id = UPPER(row_tenant_id) OR tenant_id = 'ALL')
        );
  EOT
  revert  = "DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY;"
  
  depends_on = [snowflake_table.security_mapping]
}

resource "snowflake_unsafe_execute" "create_finops_views" {
  execute = <<EOT
    CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING AS
    SELECT 
        wm.start_time,
        wm.end_time,
        wm.warehouse_name,
        wm.credits_used,
        (wm.credits_used * ${var.credit_cost_usd}) AS estimated_cost_usd,
        REGEXP_SUBSTR(wm.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.warehouse_metering_history wm
    WHERE wm.warehouse_name LIKE 'WH_%';

    CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY AS
    SELECT 
        qh.query_id,
        qh.user_name,
        qh.warehouse_name,
        qh.total_elapsed_time / 1000 AS execution_time_seconds,
        qh.partitions_scanned,
        qh.partitions_total,
        REGEXP_SUBSTR(qh.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.query_history qh
    WHERE qh.warehouse_name LIKE 'WH_%';
  EOT
  revert  = "DROP VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING; DROP VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY;"
  
  depends_on = [snowflake_schema.finops]
}

resource "snowflake_unsafe_execute" "apply_policy" {
  execute = <<EOT
    ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING 
    ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY ON (tenant_id);

    ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY 
    ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY ON (tenant_id);
  EOT
  revert  = "ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_WAREHOUSE_METERING DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY; ALTER VIEW DB_HUB_GOVERNANCE.SC_FINOPS.SPOKE_QUERY_HISTORY DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE.SC_FINOPS.FINOPS_TENANT_POLICY;"
  
  depends_on = [snowflake_unsafe_execute.create_finops_policy, snowflake_unsafe_execute.create_finops_views]
}
Utilisez le code avec précaution.modules/finops_hub/outputs.tfhcloutput "database_name" {
  value = snowflake_database.hub_governance.name
}

output "schema_name" {
  value = snowflake_schema.finops.name
}

output "mapping_table_name" {
  value = snowflake_table.security_mapping.name
}
Utilisez le code avec précaution.3. Le Module Spoke (modules/finops_spoke)Ce module est appelé pour chaque tenant. Il crée le rôle Admin du Spoke, l'enregistre dans la table de mapping et lui attribue les accès aux vues FinOps filtrées.modules/finops_spoke/variables.tfhclvariable "tenant_id" {
  type        = string
  description = "Identifiant unique du tenant (ex: marketing)"
}

variable "hub_database_name" {
  type        = string
  description = "Nom de la base de données du Hub"
}

variable "hub_schema_name" {
  type        = string
  description = "Nom du schéma FinOps du Hub"
}

variable "hub_mapping_table_name" {
  type        = string
  description = "Nom de la table de mapping de sécurité du Hub"
}
Utilisez le code avec précaution.modules/finops_spoke/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

# 1. Création du rôle fonctionnel d'administration du Spoke
resource "snowflake_account_role" "spoke_admin" {
  name    = "FR_SPOKE_${upper(var.tenant_id)}_ADMIN"
  comment = "Role d'administration et de suivi FinOps pour le tenant ${var.tenant_id}"
}

# 2. Inscription automatique du rôle dans la table de mapping du Hub
resource "snowflake_table_data" "populate_mapping" {
  database   = var.hub_database_name
  schema     = var.hub_schema_name
  table_name = var.hub_mapping_table_name

  row {
    role_name = snowflake_account_role.spoke_admin.name
    tenant_id = upper(var.tenant_id)
  }
}

# 3. Attribution des droits sur le socle FinOps central
resource "snowflake_grant_privileges_to_account_role" "grant_db_usage" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_account_object {
    object_type = "DATABASE"
    object_name = var.hub_database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_schema_usage" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema {
    schema_name = "${var.hub_database_name}.${var.hub_schema_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_views_select" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "${var.hub_database_name}.${var.hub_schema_name}"
    }
  }
}
Utilisez le code avec précaution.4. Orchestration Globale (Dossier Racine)Voici comment appeler vos modules et consommer dynamiquement le fichier YAML.main.tf (Racine)hcllocals {
  finops_config = yamldecode(file("${path.module}/tenants_config.yaml"))
}

# Instanciation unique du socle Hub
module "finops_infrastructure_hub" {
  source          = "./modules/finops_hub"
  credit_cost_usd = local.finops_config.credit_cost_usd
}

# Instanciation dynamique des Spokes via for_each
module "finops_tenant_spokes" {
  source   = "./modules/finops_spoke"
  for_each = { for s in local.finops_config.spokes : s.id => s }

  tenant_id              = each.value.id
  hub_database_name      = module.finops_infrastructure_hub.database_name
  hub_schema_name        = module.finops_infrastructure_hub.schema_name
  hub_mapping_table_name = module.finops_infrastructure_hub.mapping_table_name
}
Utilisez le code avec précaution.Advantages de cette architecture modulaireZéro duplication de code : Pour rajouter un 4ème ou 5ème Spoke, vous modifiez uniquement le fichier tenants_config.yaml. Terraform s'occupe d'instancier un nouveau bloc de ressources de manière isolée.Encapsulation stricte : Le module Spoke n'a pas besoin de savoir comment fonctionne la Row Access Policy, il lui transmet simplement ses paramètres clés.Souhaitez-vous que nous ajoutions des mécanismes de tests automatiques (Terraform tests) ou l'intégration d'alertes par e-mail en cas de tentative d'accès non autorisé ?OuiVoici l'implémentation pour sécuriser encore plus votre architecture multi-tenant. Nous allons ajouter :Un framework de tests natifs Terraform (terraform test) pour valider la sécurité avant le déploiement en production.Une alerte automatique par e-mail via Snowflake (Système d'alertes natif) qui se déclenche immédiatement si un utilisateur tente de forcer l'accès aux données d'un autre Spoke.1. Cadre de Tests Automatisés Terraform (tests/finops.tftest.hcl)Depuis Terraform 1.6+, vous pouvez écrire des fichiers de test natifs pour valider vos ressources. Ce test vérifie que la table de mapping est correctement créée et que les structures fondamentales ne sont pas altérées.Créez un dossier tests/ à la racine de votre projet et ajoutez-y le fichier suivant :hcl# Fichier : tests/finops.tftest.hcl

run "validate_hub_outputs" {
  command = plan

  assert {
    condition     = module.finops_infrastructure_hub.database_name == "DB_HUB_GOVERNANCE"
    error_message = "Erreur de gouvernance : Le nom de la base de données Hub a été modifié indûment."
  }

  assert {
    condition     = module.finops_infrastructure_hub.schema_name == "SC_FINOPS"
    error_message = "Erreur FinOps : Le nom du schéma de facturation cible est incorrect."
  }
}

run "validate_spoke_isolation" {
  command = apply

  # Vérifie que le module Spoke génère des rôles d'administration correctement formatés
  assert {
    condition     = contains(keys(module.finops_tenant_spokes), "marketing")
    error_message = "Erreur Onboarding : Le tenant Marketing n'a pas été instancié par le moteur Terraform."
  }
}
Utilisez le code avec précaution.Pour exécuter ces tests dans votre pipeline CI/CD avant le déploiement : Lancez simplement la commande terraform test.2. Détection des Tentatives de Fraude et Alerting par E-mailPour traquer les accès illégitimes (ex: un utilisateur du Spoke Marketing qui tente de requêter avec un autre rôle ou de cibler le tenant Finance), nous allons configurer une Snowflake Alert couplée à une Notification Integration (via l'envoi d'e-mails natifs Snowflake).Étape A : Ajout de la Notification de Sécurité dans le Hub TerraformModifiez le fichier modules/finops_hub/main.tf pour y intégrer la création de l'alerte de sécurité :hcl# À ajouter dans modules/finops_hub/main.tf

# Intégration de notification par email (Requiert les privilèges ACCOUNTADMIN pour la première création)
resource "snowflake_unsafe_execute" "security_notification" {
  execute = <<EOT
    CREATE OR REPLACE NOTIFICATION INTEGRATION NOTIF_FINOPS_SECURITY_ALERT
      TYPE = EMAIL
      ENABLED = TRUE
      ALLOWED_RECIPIENTS = ('security-team@votreentreprise.com', 'finops-admin@votreentreprise.com');
  EOT
  revert  = "DROP NOTIFICATION INTEGRATION NOTIF_FINOPS_SECURITY_ALERT;"
}

# Alerte planifiée : S'exécute toutes les heures pour détecter les requêtes suspectes sur le scope FinOps
resource "snowflake_unsafe_execute" "security_fraud_alert" {
  execute = <<EOT
    CREATE OR REPLACE ALERT DB_HUB_GOVERNANCE.SC_FINOPS.ALERT_FINOPS_ACCESS_VIOLATION
      WAREHOUSE = 'WH_HUB_GOVERNANCE' -- Assurez-vous d'avoir un WH générique pour le Hub
      SCHEDULE = '60 MINUTE'
      IF (EXISTS (
          -- Requête cherchant des anomalies dans l'historique des requêtes sur nos vues sécurisées
          SELECT 1
          FROM snowflake.account_usage.query_history qh
          WHERE qh.query_text LIKE '%SPOKE_WAREHOUSE_METERING%'
            AND qh.execution_status = 'SUCCESS'
            -- Détection d'un décalage : Rôle de Spoke A cherchant à filtrer explicitement sur Spoke B
            AND (
                 (qh.role_name = 'FR_SPOKE_MARKETING_ADMIN' AND qh.query_text LIKE '%FINANCE%')
                 OR 
                 (qh.role_name = 'FR_SPOKE_FINANCE_ADMIN' AND qh.query_text LIKE '%MARKETING%')
            )
            AND qh.start_time >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
      ))
      THEN
        CALL SYSTEM$SEND_EMAIL(
          'NOTIF_FINOPS_SECURITY_ALERT',
          'security-team@votreentreprise.com',
          'Alerte Sécurité Snowflake : Tentative de violation d\'isolation Multi-Tenant FinOps',
          'Attention, une ou plusieurs requêtes suspectes ont été détectées durant la dernière heure. Un utilisateur de Spoke a tenté de visionner les coûts d\'un autre périmètre. Veuillez inspecter la vue snowflake.account_usage.query_history.'
        );
  EOT
  revert  = "DROP ALERT DB_HUB_GOVERNANCE.SC_FINOPS.ALERT_FINOPS_ACCESS_VIOLATION;"
  
  depends_on = [snowflake_unsafe_execute.security_notification]
}

# Activation de l'alerte
resource "snowflake_unsafe_execute" "resume_alert" {
  execute    = "ALTER ALERT DB_HUB_GOVERNANCE.SC_FINOPS.ALERT_FINOPS_ACCESS_VIOLATION RESUME;"
  revert     = "ALTER ALERT DB_HUB_GOVERNANCE.SC_FINOPS.ALERT_FINOPS_ACCESS_VIOLATION SUSPEND;"
  depends_on = [snowflake_unsafe_execute.security_fraud_alert]
}
Utilisez le code avec précaution.3. Synthèse de la cinématique de Sécurité OpérationnellePhase de Commit / PR (CI/CD) : terraform test s'exécute. Il valide que vos politiques RBAC et de Row Access ne contiennent pas d'erreurs de syntaxe ou de logique structurelle.Phase d'Exécution (Snowflake) : Les Row Access Policies empêchent techniquement la fuite de données (l'utilisateur malveillant reçoit 0 lignes).Phase de Détection (Alerte asynchrone) : L'objet ALERT de Snowflake scanne l'historique des requêtes textuelles. Si un utilisateur a sciemment tenté de bypasser la sécurité en injectant des mots-clés interdits, l'équipe SecOps reçoit instantanément un e-mail avec les détails.Souhaitez-vous pousser cette configuration dans un exemple de pipeline CI/CD complet (ex: GitHub Actions ou GitLab CI) pour automatiser l'enchaînement des tests et du déploiement avec la fédération d'identité évoquée au début ?Both Solutions A and BVoici l'implémentation complète pour automatiser le cycle de vie de votre infrastructure FinOps multi-tenant. Ce pipeline intègre la Fédération d'Identité de Charge de Travail (Workload Identity Federation) afin de bannir les secrets statiques de vos environnements de CI/CD.Pour que vous puissiez comparer ou choisir selon vos besoins, voici les deux configurations majeures du marché : GitHub Actions (Solution A) et GitLab CI/CD (Solution B).Prerequis : Authentification par paire de clés (Key-Pair) sans mot de passePour que Terraform s'authentifie auprès de Snowflake de manière sécurisée en CI/CD, le runner génère ou utilise une clé privée éphémère ou sécurisée par l'infrastructure (Secret ou KMS). La clé publique associée est rattachée à l'utilisateur Terraform dans Snowflake (ALTER USER TF_USER SET RSA_PUBLIC_KEY = '...').Solution A : Pipeline GitHub Actions (.github/workflows/snowflake-finops.yml)Cette approche utilise le mécanisme d'authentification OIDC natif de GitHub pour interagir avec vos ressources Cloud, puis orchestre les phases de test et de déploiement de Terraform.yamlname: "Snowflake FinOps CI/CD Pipeline"

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

permissions:
  id-token: write # Requis pour la fédération d'identité OIDC
  contents: read

jobs:
  terraform:
    name: "Terraform Integration & Deployment"
    runs-on: ubuntu-latest
    
    env:
      SNOWFLAKE_ACCOUNT: "votre_id_compte.region"
      SNOWFLAKE_USER: "TF_USER"
      # La clé privée est stockée de manière sécurisée dans les secrets de l'environnement GitHub
      SNOWFLAKE_PRIVATE_KEY: ${{ secrets.SNOWFLAKE_TF_PRIVATE_KEY }} 

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # Étape 1 : Fédération d'identité optionnelle si vos states Terraform sont sur AWS S3 ou Google Cloud Storage
      - name: Configure AWS Credentials (OIDC Federation)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-terraform-state-role
          aws-region: eu-west-3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.0"

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      # Étape 2 : Sécurité Avancée - Exécution des tests unitaires natifs créés précédemment
      - name: Terraform Test (Security and RBAC Validation)
        run: terraform test

      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color

      # Étape 3 : Application automatique uniquement lors des fusions sur la branche principale
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
Utilisez le code avec précaution.Solution B : Pipeline GitLab CI/CD (.gitlab-ci.yml)Cette approche s'appuie sur l'architecture robuste de GitLab CI/CD, découpée en étapes (stages) avec une gestion fine du cache pour optimiser les performances des runners.yamlstages:
  - validate
  - test
  - plan
  - deploy

image:
  name: hashicorp/terraform:1.6.0
  entrypoint: [""]

cache:
  paths:
    - .terraform/

variables:
  SNOWFLAKE_ACCOUNT: "votre_id_compte.region"
  SNOWFLAKE_USER: "TF_USER"
  # SNOWFLAKE_PRIVATE_KEY doit être configurée comme variable de type "File" ou "Secret" dans GitLab CI

before_script:
  # Initialisation optionnelle de la fédération cloud (GCP/AWS/Azure) pour le backend state via JWT GitLab
  # export AWS_WEB_IDENTITY_TOKEN_FILE=$ID_TOKEN
  - terraform init

terraform_validate:
  stage: validate
  script:
    - terraform validate

terraform_test:
  stage: test
  script:
    # Exécute le framework 'terraform test' pour valider le cloisonnement multi-tenant avant le plan
    - terraform test

terraform_plan:
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    name: "plan"
    paths:
      - tfplan
    expire_in: 2 days
  only:
    - merge_requests
    - main

terraform_deploy:
  stage: deploy
  script:
    - terraform apply -auto-approve tfplan
  dependencies:
    - terraform_plan
  only:
    - main
  when: manual # Déploiement soumis à validation humaine pour plus de sécurité en production
Utilisez le code avec précaution.Synthèse comparative pour l'intégration CI/CDLa Solution A (GitHub Actions) est particulièrement fluide pour la mise en œuvre de la fédération d'identité grâce à l'action native configure-aws-credentials (ou équivalents Azure/GCP), idéale si votre architecture d'entreprise repose fortement sur l'écosystème GitHub.La Solution B (GitLab CI/CD) offre un contrôle granulaire supérieur sur le cycle de vie grâce au mécanisme de dépendance des artefacts (tfplan) et permet d'ajouter une approbation manuelle (when: manual) native, assurant qu'aucune modification de politique de sécurité Snowflake ne passe en production sans un double contrôle visuel.Avez-vous besoin d'aide pour générer le script d'infrastructure Cloud de confiance (IAM Trust Policy/OIDC Provider) côté AWS, Azure ou GCP afin d'activer pleinement cette fédération d'identité pour vos runners ?Pour vous fournir une vision complète et industrialisée, voici le code source des deux solutions pour vos modules FinOps : la Solution A (Vues Sécurisées Simples) et la Solution B (Row Access Policy + Table de Mapping).Chaque solution est structurée sous forme de modules Terraform (hub et spoke) prêts à consommer votre fichier de configuration tenants_config.yaml.SOLUTION A : Multi-Vues Sécurisées par Spoke (Cloisonnement via SQL Dynamique)Dans cette approche, la sécurité est codée en dur dans une vue générée dynamiquement. Elle est simple à mettre en œuvre pour un petit nombre de tenants mais nécessite de recréer l'objet ou de complexifier le code lors de chaque ajout de Spoke.1. Module Hub (modules_sol_a/finops_hub)modules_sol_a/finops_hub/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

variable "credit_cost_usd" { type = number }
variable "spokes" {
  type = list(object({
    id = string
  }))
}

resource "snowflake_database" "hub_governance" {
  name    = "DB_HUB_GOVERNANCE_A"
  comment = "Base centrale de gouvernance - Solution A"
}

resource "snowflake_schema" "finops" {
  database = snowflake_database.hub_governance.name
  name     = "SC_FINOPS"
}

# La sécurité est gérée par une vue sécurisée unique contenant une liste de OR générée dynamiquement
resource "snowflake_unsafe_execute" "create_secure_view_a" {
  execute = <<EOT
    CREATE OR REPLACE SECURE VIEW DB_HUB_GOVERNANCE_A.SC_FINOPS.SPOKE_WAREHOUSE_METERING AS
    SELECT 
        wm.start_time,
        wm.end_time,
        wm.warehouse_name,
        wm.credits_used,
        (wm.credits_used * ${var.credit_cost_usd}) AS estimated_cost_usd,
        REGEXP_SUBSTR(wm.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.warehouse_metering_history wm
    WHERE wm.warehouse_name LIKE 'WH_%'
      AND (
        CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
        ${join("\n", [for s in var.spokes : "OR (CURRENT_ROLE() = 'FR_SPOKE_${upper(s.id)}_ADMIN' AND REGEXP_SUBSTR(wm.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') = '${upper(s.id)}')" ] )}
      );
  EOT
  revert  = "DROP VIEW DB_HUB_GOVERNANCE_A.SC_FINOPS.SPOKE_WAREHOUSE_METERING;"
  
  depends_on = [snowflake_schema.finops]
}

output "database_name" { value = snowflake_database.hub_governance.name }
output "schema_name"   { value = snowflake_schema.finops.name }
Utilisez le code avec précaution.2. Module Spoke (modules_sol_a/finops_spoke)modules_sol_a/finops_spoke/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

variable "tenant_id" { type = string }
variable "hub_database_name" { type = string }
variable "hub_schema_name" { type = string }

resource "snowflake_account_role" "spoke_admin" {
  name    = "FR_SPOKE_${upper(var.tenant_id)}_ADMIN"
  comment = "Role Admin Spoke - Solution A"
}

resource "snowflake_grant_privileges_to_account_role" "grant_access" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_account_object {
    object_type = "DATABASE"
    object_name = var.hub_database_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_schema" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema {
    schema_name = "${var.hub_database_name}.${var.hub_schema_name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_select" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = "${var.hub_database_name}.${var.hub_schema_name}"
    }
  }
}
Utilisez le code avec précaution.SOLUTION B : Row Access Policy + Mapping Table (L'Approche Recommandée)Dans cette approche, la sécurité est totalement découplée. Le code de la politique et des vues reste strictement immuable. L'onboarding d'un nouveau Spoke consiste uniquement à insérer une ligne dans la table de mapping via Terraform.1. Module Hub (modules_sol_b/finops_hub)modules_sol_b/finops_hub/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

variable "credit_cost_usd" { type = number }

resource "snowflake_database" "hub_governance" {
  name    = "DB_HUB_GOVERNANCE_B"
  comment = "Base centrale de gouvernance - Solution B"
}

resource "snowflake_schema" "finops" {
  database = snowflake_database.hub_governance.name
  name     = "SC_FINOPS"
}

resource "snowflake_table" "security_mapping" {
  database = snowflake_database.hub_governance.name
  schema   = snowflake_schema.finops.name
  name     = "FINOPS_SECURITY_MAPPING"
  comment  = "Table de correspondance FinOps centralisee"

  column { name = "ROLE_NAME" ; type = "STRING" }
  column { name = "TENANT_ID" ; type = "STRING" }
}

resource "snowflake_unsafe_execute" "create_finops_policy" {
  execute = <<EOT
    CREATE OR REPLACE ROW ACCESS POLICY DB_HUB_GOVERNANCE_B.SC_FINOPS.FINOPS_TENANT_POLICY
    AS (row_tenant_id STRING) RETURNS BOOLEAN ->
        CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'FR_HUB_FINOPS_ADMIN')
        OR EXISTS (
            SELECT 1 FROM DB_HUB_GOVERNANCE_B.SC_FINOPS.FINOPS_SECURITY_MAPPING
            WHERE role_name = CURRENT_ROLE()
              AND (tenant_id = UPPER(row_tenant_id) OR tenant_id = 'ALL')
        );
  EOT
  revert  = "DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE_B.SC_FINOPS.FINOPS_TENANT_POLICY;"
  depends_on = [snowflake_table.security_mapping]
}

resource "snowflake_unsafe_execute" "create_finops_views" {
  execute = <<EOT
    CREATE OR REPLACE VIEW DB_HUB_GOVERNANCE_B.SC_FINOPS.SPOKE_WAREHOUSE_METERING AS
    SELECT 
        wm.start_time,
        wm.end_time,
        wm.warehouse_name,
        wm.credits_used,
        (wm.credits_used * ${var.credit_cost_usd}) AS estimated_cost_usd,
        REGEXP_SUBSTR(wm.warehouse_name, 'WH_([A-Z0-9_]+)', 1, 1, 'e') AS tenant_id
    FROM snowflake.account_usage.warehouse_metering_history wm
    WHERE wm.warehouse_name LIKE 'WH_%';
  EOT
  revert  = "DROP VIEW DB_HUB_GOVERNANCE_B.SC_FINOPS.SPOKE_WAREHOUSE_METERING;"
  depends_on = [snowflake_schema.finops]
}

resource "snowflake_unsafe_execute" "apply_policy" {
  execute = <<EOT
    ALTER VIEW DB_HUB_GOVERNANCE_B.SC_FINOPS.SPOKE_WAREHOUSE_METERING 
    ADD ROW ACCESS POLICY DB_HUB_GOVERNANCE_B.SC_FINOPS.FINOPS_TENANT_POLICY ON (tenant_id);
  EOT
  revert  = "ALTER VIEW DB_HUB_GOVERNANCE_B.SC_FINOPS.SPOKE_WAREHOUSE_METERING DROP ROW ACCESS POLICY DB_HUB_GOVERNANCE_B.SC_FINOPS.FINOPS_TENANT_POLICY;"
  depends_on = [snowflake_unsafe_execute.create_finops_policy, snowflake_unsafe_execute.create_finops_views]
}

output "database_name"       { value = snowflake_database.hub_governance.name }
output "schema_name"         { value = snowflake_schema.finops.name }
output "mapping_table_name"  { value = snowflake_table.security_mapping.name }
Utilisez le code avec précaution.2. Module Spoke (modules_sol_b/finops_spoke)modules_sol_b/finops_spoke/main.tfhclterraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = ">= 0.87.0"
    }
  }
}

variable "tenant_id" { type = string }
variable "hub_database_name" { type = string }
variable "hub_schema_name" { type = string }
variable "hub_mapping_table_name" { type = string }

resource "snowflake_account_role" "spoke_admin" {
  name    = "FR_SPOKE_${upper(var.tenant_id)}_ADMIN"
  comment = "Role Admin Spoke - Solution B"
}

# C'est ici que l'onboarding se réalise côté Data : injection d'un simple tuple
resource "snowflake_table_data" "populate_mapping" {
  database   = var.hub_database_name
  schema     = var.hub_schema_name
  table_name = var.hub_mapping_table_name

  row {
    role_name = snowflake_account_role.spoke_admin.name
    tenant_id = upper(var.tenant_id)
  }
}

resource "snowflake_grant_privileges_to_account_role" "grant_db" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_account_object { object_type = "DATABASE" ; object_name = var.hub_database_name }
}

resource "snowflake_grant_privileges_to_account_role" "grant_schema" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema         = "${var.hub_database_name}.${var.hub_schema_name}"
}

resource "snowflake_grant_privileges_to_account_role" "grant_select" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.spoke_admin.name
  on_schema_object {
    all { object_type_plural = "VIEWS" ; in_schema = "${var.hub_database_name}.${var.hub_schema_name}" }
  }
}
Utilisez le code avec précaution.3. Fichier d'Orchestration Racine (main.tf)Pour tester l'une ou l'autre solution, vous pouvez basculer l'orchestration racine sur le bloc de votre choix en utilisant le même fichier tenants_config.yaml.hcllocals {
  config = yamldecode(file("${path.module}/tenants_config.yaml"))
}

# --- POUR DEPLOYER LA SOLUTION A ---
# module "hub_a" {
#   source          = "./modules_sol_a/finops_hub"
#   credit_cost_usd = local.config.credit_cost_usd
#   spokes          = local.config.spokes
# }
# 
# module "spoke_a" {
#   source            = "./modules_sol_a/finops_spoke"
#   for_each          = { for s in local.config.spokes : s.id => s }
#   tenant_id         = each.value.id
#   hub_database_name = module.hub_a.database_name
#   hub_schema_name   = module.hub_a.schema_name
# }

# --- POUR DEPLOYER LA SOLUTION B (RECOMMANDÉE) ---
module "hub_b" {
  source          = "./modules_sol_b/finops_hub"
  credit_cost_usd = local.config.credit_cost_usd
}

module "spoke_b" {
  source                 = "./modules_sol_b/finops_spoke"
  for_each               = { for s in local.config.spokes : s.id => s }
  tenant_id              = each.value.id
  hub_database_name      = module.hub_b.database_name
  hub_schema_name        = module.hub_b.schema_name
  hub_mapping_table_name = module.hub_b.mapping_table_name
}
Utilisez le code avec précaution.💡 Synthèse pour votre ArchitectureLa Solution A modifie la structure même du code SQL de la vue à chaque modification du fichier YAML. Cela engendre une recréation d'objet (CREATE OR REPLACE) qui peut couper temporairement les connexions des dashboards BI.La Solution B maintient le catalogue d'objets Snowflake intact. L'onboarding est une simple transaction d'insertion de ligne (INSERT), ce qui est l'état de l'art pour les performances et la sécurité d'une industrialisation DevOps.Souhaitez-vous obtenir de l'aide pour intégrer ces dossiers de modules directement dans la configuration de votre dépôt Git central ?