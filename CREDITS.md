# Crédits et licences

Le code du projet (`scripts/`, `scenes/`, `tests/`) est original. Les ressources tierces ci-dessous sont
toutes sous licence libre ; les textes de licence sont dans `assets/licenses/`.

## Modèles 3D

| Usage | Pack / auteur | Licence | Fichiers |
|---|---|---|---|
| Héros, PNJ, patients, Gourou, pièces, drapeau | *Starter Kit 3D Platformer* — Kenney | Modèles CC0 (code du kit : MIT) | `assets/models/characters/`, `assets/models/misc/` |
| Monstres volants de la Fosse | *Starter Kit FPS* — Kenney | Modèles CC0 (code du kit : MIT) | `assets/models/monsters/` |
| Maisons, arbres, fontaine du Village | *Starter Kit City Builder* — Kenney | Modèles CC0 (code du kit : MIT) | `assets/models/village/` |
| Murs, lits, bureau, toilettes, lampes... de l'Asile | *Furniture Kit 2.0* — Kenney (kenney.nl) | CC0 | `assets/models/props/` (sans préfixe) |
| Fauteuil, étagère, armoire, lampadaire, cadre | *Furniture Bits 1.0* — Kay Lousberg (kaylousberg.com) | CC0 | `assets/models/props/kaykit_*` |

Provenance : les trois « Starter Kit » viennent des dépôts GitHub `KenneyNL/Starter-Kit-3D-Platformer`,
`KenneyNL/Starter-Kit-FPS` et `KenneyNL/Starter-Kit-City-Builder`. Les deux packs de mobilier ont été
récupérés via le dépôt GitHub `yuyou-dev/OpenHome3D`, qui les redistribue avec leurs fichiers de licence CC0
d'origine (sources originales : kenney.nl et kaylousberg.com). Aucun modèle n'a été modifié, hormis la
mise à l'échelle et la teinte appliquées à l'exécution.

CC0 ne demande pas d'attribution, mais elle est donnée ici avec plaisir.

## Police

*Lilita One* — Juan Montoreano, licence SIL Open Font License 1.1 (`assets/licenses/OFL_LilitaOne.txt`).

## Moteur

Godot Engine 4.3 — licence MIT.

## Remplacer un modèle

Tous les modèles passent par `scripts/world/assets.gd` : changez le chemin dans le dictionnaire `PATHS`
(par exemple pour utiliser un pack médiéval Quaternius ou le *Castle Kit* de Kenney, tous deux CC0) ;
l'échelle et le recentrage sont calculés automatiquement.
