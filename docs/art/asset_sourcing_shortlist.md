# Shortlist Assets Kenney

## Position

La direction actuelle doit partir d'un univers Kenney coherent, lisible et
cartoon. Les packs sci-fi/cyberpunk et les assemblages Quaternius ne sont plus
retenus pour la V1 visuelle : ils melangent trop les silhouettes et donnent une
impression d'assets colles ensemble.

Objectif : construire Shardring autour d'une base visuelle commune, puis ajouter
des variations de maps par theme Kenney compatible.

## Packs Locaux Analyses

Les six packs suivants sont extraits dans
`assets/art/source_external/kenney/` et catalogues dans
`assets/art/source_external/kenney/asset_catalog.json` :

- `blocky_characters` : 18 personnages.
- `cube_pets` : 24 creatures goofy.
- `factory_kit` : machines, portes, conveyors, hazards, sols.
- `graveyard_kit` : props et ennemis pour une future map spooky.
- `pirate_kit` : canons, boulets, portes, plateformes, props.
- `platformer_kit` : blocs d'arene, portes, hazards lisibles.

Chaque pack contient un `License.txt` Kenney CC0 local.

## Direction V1 Recommandee

Theme principal : **arena cartoon factory / platformer**.

Raison :

- `platformer_kit` fournit une base arene claire, lumineuse et coherente.
- `factory_kit` fournit portes, machines, hazards et signes de danger.
- `cube_pets` fournit des chasers goofy qui contrastent bien avec le joueur.
- `pirate_kit` fournit un canon et un boulet tres lisibles pour le lanceur
  projectile.
- `blocky_characters` fournit un joueur qui ne ressemble pas a un ennemi.

Le `graveyard_kit` doit rester pour une map future, pas pour la premiere
integration. Il est coherent en lui-meme, mais tirer trop tot dedans ajouterait
une rupture de theme.

## Selection Candidate V1

Joueur :

- Primaire : `blocky_characters:character-a`
- Alternatives : `character-c`, `character-e`, `character-f`
- A eviter : tout asset type monstre, robot ou personnage trop hostile.

Chaser explosif :

- Primaire : `cube_pets:animal-bee`
- Alternatives : `animal-crab`, `animal-caterpillar`, `animal-dog`,
  `animal-fox`
- Principe : ajouter la bombe/excitation par VFX et animation runtime, pas en
  choisissant un asset deja agressif.

Lanceur projectile :

- Primaire : `pirate_kit:cannon-mobile`
- Alternatives : `pirate_kit:cannon`, `factory_kit:machine`,
  `factory_kit:robot-arm-a`
- Principe : le muzzle doit etre explicite dans le wrapper Godot.

Projectile simple :

- Primaire : `pirate_kit:cannon-ball`
- Alternatives : `factory_kit:cog-a`, `factory_kit:box-small`,
  `factory_kit:arrow-basic`
- Principe : high-volume, donc mesh simple et lisible.

Exit gate :

- Primaire runtime : composition `factory_kit:structure-doorway-wide` +
  deux panneaux `factory_kit:door`
- Alternatives : `factory_kit:door-wide-half`, `pirate_kit:castle-gate`,
  `graveyard_kit:fence-gate`
- Principe : garder deux battants/volumes clairement lisibles pour l'animation
  goofy d'ouverture.

Arene et themes :

- Base : `platformer_kit:block-grass`, `block-grass-large`,
  `block-grass-curve`, `block-snow`.
- Factory layer : `factory_kit:floor-large`, `catwalk-straight`,
  `conveyor-*`, `warning-orange`.
- Pirate layer futur : `pirate_kit:platform`, `platform-planks`,
  `castle-gate`, `cannon`.
- Graveyard layer futur : `graveyard_kit:road`, `fence-gate`, props de
  cimetierre, ennemis spooky.

## Ordre De Revue

1. Creer une scene `kenney_asset_review_playground.tscn`.
2. Afficher les candidats primaires avec la camera third-person actuelle.
3. Comparer silhouette, echelle, couleur et lisibilite danger.
4. Choisir un set coherent par theme avant de remplacer les wrappers runtime.
5. Normaliser chaque asset retenu dans `working_blender`, exporter en GLB propre,
   puis brancher via wrapper Godot.

## Non-Retenus

Le batch Quaternius local a ete nettoye. Il ne doit plus servir de base V1 :

- joueur trop proche d'un ennemi ;
- coherence faible entre joueur, ennemis, arene et porte ;
- direction sci-fi/cyberpunk non souhaitee ;
- assets candidats supprimes du manifest et des wrappers runtime.
