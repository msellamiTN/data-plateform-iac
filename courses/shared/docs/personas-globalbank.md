# Personas GlobalBank — 4 équipes, 11 apprenants

> Document de référence du parcours. Chaque apprenant joue un rôle métier dans
> l'entreprise fictive **GlobalBank**, qui migre son datawarehouse vers Snowflake
> et doit reconstruire en code ce que le prédécesseur avait cliqué à la main.

## Pourquoi des personas ?

Les 11 participants n'ont pas le même métier. Les personas font deux choses :

1. **Ancrage métier** — chaque lab est raconté depuis le point de vue d'une
   équipe, pour que les Data Analysts et Business Developers voient le lien
   avec leur quotidien, pas seulement les ingénieurs.
2. **Isolation naturelle** — chaque équipe crée des *types* d'objets Snowflake
   différents, ce qui évite les collisions quand 11 personnes travaillent en
   parallèle dans le même compte de formation.

> **Règle n°1 de la semaine :** chacun ne crée que les objets de son équipe,
> nommés avec son préfixe (`APPxx`).

## Les 4 équipes

| Équipe | Membres | Types de ressources qu'elle crée |
|---|---|---|
| 🔵 **Platform / DevOps** | Fares · Mohamed · Sirine | `WAREHOUSE` · `ROLE` · `GRANT` · `RESOURCE MONITOR` |
| 🟢 **Data Engineering** | Amal · Lara | `DATABASE` · `SCHEMA` · `TABLE` · `FILE FORMAT` · `STAGE` |
| 🟠 **Business Data** | Manel · Leila · Olfa | `DATABASE` · `SCHEMA` · `TABLE` · `VIEW` · `SHARE` |
| 🟣 **BI / Analytics** | Ghassen · Adem · Hadhemi | `DATABASE` · `SCHEMA` · `VIEW` · `MATERIALIZED VIEW` |

## Lecture des labs par persona

Les concepts Terraform (plan, state, modules, `for_each`, backend) sont
**identiques pour tous**. Ce qui change, c'est l'objet Snowflake sur lequel
vous les appliquez :

| Module | Concept | 🔵 Platform | 🟢 Data Eng | 🟠 Business | 🟣 BI |
|---|---|---|---|---|---|
| M01 | Premier apply | Warehouse ETL | Database RAW | Database domaine | Database mart |
| M04 | Variables/outputs | Contract warehouse | Contract zone | Contract domaine | Contract mart |
| M05 | Modules | Module compute | Module ingestion | Module domaine | Module analytics |
| M06 | `for_each`/dynamic | Warehouses par env | Schémas par source | Domaines par BU | Marts par équipe |
| M09 | Stages/COPY | Monitoring ingestion | `COPY INTO` fichier | Qualité données | Dataset reporting |
| M11 | RBAC | Rôles/grants | Grants ingestion | Grants domaine | Grants lecture |
| M13 | FinOps | Resource monitors | Coût ingestion | Budget domaine | Coût dashboards |

> En cas de doute pendant un lab : appliquez le concept sur **votre** type
> d'objet. Le résultat attendu (`expected-output.md`) reste le même.

## Préfixes apprenants

Chaque participant possède un préfixe unique `APP01`–`APP11` (fourni par le
formateur, variable `LEARNER_PREFIX` dans `.env`). Toutes les ressources sont
nommées `{PREFIX}_{MODULE}_{OBJET}_{ENV}` — ex. `APP01_M01_RAW_DEV`.

Voir : [naming-conventions.md](naming-conventions.md)
