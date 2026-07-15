# Sources Assets

## Politique

Shardring utilise maintenant un pipeline hybride arcade premium :

- assets CC0/procures pour les bases de qualite ;
- IA pour concepts, variations et exploration ;
- Blender pour cleanup, echelle, orientation, retopologie simple et sockets ;
- scenes wrapper Godot pour stabiliser l'integration runtime.

Les assets generes par script Blender dans le repo sont des placeholders. Ils
restent utiles pour tester les collisions, les sockets et les fallbacks, mais ne
representent plus la qualite visuelle ciblee.

## Sources Prioritaires

- Kenney : assets publics CC0, utilisables commercialement, attribution non
  requise. Source : https://kenney.nl/support
- Poly Haven : HDRI, textures et modeles CC0. Source :
  https://polyhaven.com/license

La selection concrete des premiers packs candidats est documentee dans
`docs/art/asset_sourcing_shortlist.md`.

## Packs Kenney Extraits

Les premiers packs Kenney ont ete extraits depuis `~/Downloads` vers
`assets/art/source_external/kenney/` :

- `blocky_characters` depuis `kenney_blocky-characters_20.zip`.
- `cube_pets` depuis `kenney_cube-pets_1.0.zip`.
- `factory_kit` depuis `kenney_factory-kit_3.0.zip`.
- `graveyard_kit` depuis `kenney_graveyard-kit_5.0.zip`.
- `pirate_kit` depuis `kenney_pirate-kit.zip`.
- `platformer_kit` depuis `kenney_platformer-kit.zip`.

Le catalogue local genere est
`assets/art/source_external/kenney/asset_catalog.json`.

Chaque pack contient un `License.txt` local indiquant Creative Commons Zero
CC0, utilisable pour projets personnels, educatifs et commerciaux. Le credit
Kenney est encourage mais non requis.

Analyse de contenu :

- 501 assets catalogues.
- 18 candidats joueur.
- 24 candidats chaser.
- 14 candidats lanceur.
- 26 candidats projectile ou objet lance.
- 15 candidats porte ou gate.
- 106 candidats arene.
- 53 candidats hazard.

La selection V1 recommandee est documentee dans
`docs/art/kenney_asset_analysis.md`.

## Sources IA Payantes Ou Controlees

Meshy, Tripo, Rodin ou equivalent peuvent etre utilises pour des besoins
specifiques, mais uniquement si le manifest documente :

- l'outil et le plan utilise ;
- la licence exacte ;
- l'URL ou preuve de generation ;
- les fichiers source/export ;
- les restrictions eventuelles de commercialisation.

Les assets IA non verifies ne doivent pas remplacer les assets runtime.

## Manifest

`assets/art/asset_manifest.json` est la source de verite des assets runtime.
Chaque entree doit declarer le statut, la source, la licence, le fichier brut,
le `.blend` de travail, l'export Godot, la scene wrapper et la preview si elle
existe.
