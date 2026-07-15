# Analyse Assets Kenney

## Resume

Six packs Kenney ont ete extraits et analyses localement. Ils sont tous sous
licence CC0 d'apres leur `License.txt` local. Le catalogue exhaustif est
`assets/art/source_external/kenney/asset_catalog.json`.

Resultat du scan :

- 501 assets 3D.
- 18 candidats joueur.
- 24 candidats chaser.
- 14 candidats lanceur.
- 26 candidats projectile ou objet lance.
- 15 candidats porte/gate.
- 106 candidats arene.
- 53 candidats hazard.

## Lecture Direction Artistique

Les packs Kenney fonctionnent mieux si on arrete de chercher une DA
"premium goofy" dans un melange sci-fi/fantasy. La voie la plus coherente est :

**cartoon platformer arena + factory chaos + creatures goofy**.

Cela garde un langage visuel simple :

- le joueur vient des `blocky_characters`, donc silhouette humaine neutre ;
- les chasers viennent des `cube_pets`, donc menace goofy assumee ;
- les lanceurs/projectiles viennent de `pirate_kit` ou `factory_kit`, donc
  lisibilite immediate ;
- l'arene vient surtout de `platformer_kit`, enrichie par `factory_kit`.

Le `graveyard_kit` est interessant, mais plutot pour une map 2 ou 3 avec DA
spooky coherente, pas dans le premier set runtime.

## Pack Par Pack

### Blocky Characters

Usage recommande : joueur, NPC futurs, variations cosmetics.

Forces :

- style Kenney tres lisible ;
- personnages non agressifs ;
- bonnes silhouettes pour third-person ;
- 18 variantes deja coherentes entre elles.

Risques :

- animations non garanties dans le GLB ;
- il faudra normaliser orientation, pivot, echelle et `VisualRoot` ;
- certains skins peuvent evoquer un ennemi selon les couleurs.

Candidats V1 : `character-a`, `character-c`, `character-e`, `character-f`.

### Cube Pets

Usage recommande : chasers explosifs et petits ennemis goofy.

Forces :

- silhouette simple ;
- emotion immediate ;
- tres bon contraste avec un joueur humanoide ;
- fonctionne bien avec animation runtime de marche/course/excitation.

Risques :

- trop mignon si aucun VFX danger n'est ajoute ;
- collision/hurtbox a garder gameplay-first, pas calquee betement sur le mesh.

Candidats V1 : `animal-bee`, `animal-crab`, `animal-caterpillar`,
`animal-dog`, `animal-fox`.

### Factory Kit

Usage recommande : arene secondaire, portes, hazards, props lisibles, machines.

Forces :

- tres coherent comme theme de map ;
- beaucoup de conveyors, warnings, cogs et portes ;
- excellent pour introduire hazards futurs sans changer d'univers.

Risques :

- peut devenir trop gris/industriel si on n'ajoute pas une palette Shardring ;
- les machines ne doivent pas remplacer un vrai design de lanceur sans sockets.

Candidats V1 : `floor-large`, `structure-doorway-wide`, `door`,
`door-wide-half`, `machine`, `robot-arm-a`, `cog-a`, `arrow-basic`,
`warning-orange`, `conveyor-*`.

### Pirate Kit

Usage recommande : lanceur canon, boulet, map future pirate/bois.

Forces :

- `cannon-mobile` et `cannon-ball` sont immediatement lisibles ;
- le langage canon -> projectile est clair pour le joueur ;
- props utiles pour une map thematique future.

Risques :

- theme pirate peut parasiter une map factory si on l'utilise partout ;
- `cannon` doit etre recolore/normalise pour rester dans Shardring.

Candidats V1 : `cannon-mobile`, `cannon`, `cannon-ball`, `castle-gate`,
`platform`.

### Platformer Kit

Usage recommande : base de l'arene et premiers themes de sol.

Forces :

- tres coherent avec une camera third-person ;
- beaucoup de variations grass/snow/curves/overhangs ;
- parfait pour des maps procedurales lisibles.

Risques :

- les blocs sont modulaires, donc il faut eviter un rendu trop grid/lego ;
- notre generation procedurale par cellules doit rester organique.

Candidats V1 : `block-grass`, `block-grass-large`, `block-grass-curve`,
`block-snow`, `block-moving`, `trap-spikes`.

### Graveyard Kit

Usage recommande : map future, ennemis spooky, porte/fence alternative.

Forces :

- tres coherent en standalone ;
- bons props d'ambiance et ennemis simples ;
- peut devenir une variation de level lisible.

Risques :

- ne colle pas naturellement avec le set factory/platformer ;
- a utiliser seulement quand le systeme de themes de map est pret.

Candidats futurs : `character-zombie`, `character-skeleton`,
`character-ghost`, `fence-gate`, `crypt-door`, `road`.

## Selection V1 Proposee

Le premier remplacement runtime devrait tester ce set :

- Player : `blocky_characters:character-a`.
- Chaser : `cube_pets:animal-bee`.
- Launcher : `pirate_kit:cannon-mobile`.
- Projectile : `pirate_kit:cannon-ball`.
- Exit gate : `factory_kit:structure-doorway-wide` + deux panneaux
  `factory_kit:door`.
- Arena material/props : `platformer_kit:block-grass` + `factory_kit:floor-large`.

Ce set est volontairement simple. Il vise la coherence et la lisibilite avant
la richesse.

## Prochaine Etape Recommandee

Creer une scene `kenney_asset_review_playground.tscn` qui charge les candidats
depuis le catalogue, puis genere les premiers wrappers uniquement pour les
assets valides visuellement.

Ne pas brancher directement les GLB bruts dans les configs gameplay.
