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
- Quaternius : packs low-poly gratuits sous licence CC0. Source :
  https://quaternius.com/
- Poly Haven : HDRI, textures et modeles CC0. Source :
  https://polyhaven.com/license

La selection concrete des premiers packs candidats est documentee dans
`docs/art/asset_sourcing_shortlist.md`.

## Packs Quaternius Extraits

Les trois premiers packs Quaternius ont ete extraits depuis `~/Downloads` vers
`assets/art/source_external/quaternius/` :

- `toon_shooter_game_kit` depuis `Toon Shooter Game Kit - Dec 2022`.
- `cyberpunk_game_kit` depuis `Cyberpunk Game Kit - Quaternius`.
- `cute_animated_monsters` depuis `Cute Animated Monsters - Aug 2020`.

Le catalogue local genere est
`assets/art/source_external/quaternius/asset_catalog.json`.

Selection V1 en revue :

- joueur : `Enemy_2Legs` depuis Cyberpunk, retenu comme candidat robot propre ;
- chaser : `Cyclops`;
- lanceur : `Turret_Cannon`;
- projectile : `Grenade`;
- porte : `Door`.

Ces assets sont en statut `candidate_review` dans le manifest. Ils ne remplacent
pas encore les placeholders runtime tant qu'ils ne sont pas valides dans
`just external-art-review`.

Note analyse : les personnages humanoides `Character_Soldier` et
`Character` ont ete rejetes pour l'instant, car leurs exports glTF/Blender
affichent des elements de rig/equipement incompatibles avec une silhouette
joueur propre.

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
