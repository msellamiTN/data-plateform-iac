# M02 — Le cycle de vie Terraform (micro-théorie)

## Une idée

Une ressource Terraform traverse **cinq états** : inexistante → planifiée → créée →
modifiée → détruite. Terraform trace chaque transition dans un fichier, le **state**,
pour savoir à tout moment où en est chaque ressource.

## Une analogie

Un chef de chantier avec un carnet. Chaque ligne du carnet = un ouvrage en cours. Le
chef ne reconstruit pas ce qui est déjà fait ; il ne modifie que ce qui a changé.
Terraform est le chef, le state est le carnet.

## Les 5 commandes et leur risque

| Commande | Modifie Snowflake ? | Risque |
|---|---|---|
| `init` | Non | Aucun |
| `fmt` | Non | Aucun (fichiers seulement) |
| `validate` | Non | Aucun |
| `plan` | Non | Aucun (simulation) |
| `apply` | **Oui** | Crée/modifie/détruit |
| `destroy` | **Oui** | Détruit |

> Les 4 premières sont **idempotentes et sans risque**. Relancez-les librement.

## Les 4 symboles du plan

| Symbole | Sens | Danger |
|---|---|---|
| `+` | Création | Faible (nouveau) |
| `~` | Modification en place | Faible (attribut change) |
| `-` | Destruction | **Élevé** (perte) |
| `-/+` | Destroy then create | **Élevé** (recréation) |

> Un `-/+` est souvent déclenché par un attribut « forces replacement » (ex: `name`).
> Lisez toujours la ligne `# forces replacement` dans le plan.

## Le state

Le fichier `terraform.tfstate` (JSON) enregistre l'identité de chaque ressource
créée. Sans lui, Terraform ne saurait pas ce qui existe déjà et proposerait tout de
recréer. On ne l'édite **jamais à la main** (on le manipule avec `terraform state`,
vu au M04).

## Idempotence

`terraform plan` après un `apply` réussi affiche `No changes.`. C'est la signature
d'une infrastructure maîtrisée : le code et la réalité coïncident.
