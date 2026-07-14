# Direction Artistique

## Intention

Shardring vise une DA **arcade premium goofy** : lisible, expressive, propre,
avec une pointe d'humour, mais sans rendu enfantin ou bricolé.

Le jeu doit ressembler a un roguelite d'arene professionnel : silhouettes
fortes, dangers identifiables instantanement, materiaux stylises coherents,
eclairage clair et VFX gameplay soignes. L'humour vient des formes et des
animations, pas de details cheap.

## Principes

- Lisibilite gameplay avant decoration.
- Silhouettes fortes, reconnaissables depuis une camera third-person.
- Materiaux stylises propres : roughness, emission controlee, contrastes
  lisibles.
- Goofy leger : personnalite simple, pas mascottes enfantines partout.
- Les dangers doivent paraitre dangereux avant d'etre droles.
- Les VFX de warning sont des elements de production, jamais des traits debug.
- Les assets finaux doivent venir d'un pipeline trace : source, licence,
  cleanup, wrapper, test camera.

## Palette Fonctionnelle

| Usage | Couleur | Hex |
| --- | --- | --- |
| Sol principal | Vert mineral moyen | `#5F9B86` |
| Variation sol | Bleu ardoise clair | `#668EAD` |
| Variation sol | Vert mousse stylise | `#7D9C68` |
| Neutre UI/ombres | Graphite doux | `#333A46` |
| Joueur | Bleu pervenche sature | `#536DDE` |
| Direction joueur | Cyan vert lisible | `#39D4C2` |
| Interactable temporaire | Cyan propre | `#26C8D8` |
| Monnaie de run | Or arcade | `#F4B63D` |
| Monnaie cross-game | Blanc violet | `#D8C9FF` |
| Danger general | Rouge danger | `#FF2638` |
| Explosion / chaser | Orange chaud | `#FF6A28` |
| Laser | Magenta laser | `#F72FD3` |
| Glace | Cyan glace | `#9EE8FF` |
| Lave | Rouge orange emissif | `#FF461C` |

## Quality Bar

Un asset est acceptable seulement si :

- sa silhouette est reconnaissable en moins de 2 secondes dans la camera de jeu ;
- son role gameplay est lisible sans debug overlay ;
- son echelle correspond a la collision/hurtbox ;
- son orientation et ses sockets sont explicites ;
- son origine, son pivot et ses points VFX sont documentes ;
- sa licence est tracee dans `assets/art/asset_manifest.json` ;
- il passe par une scene wrapper Godot stable.

## Pipeline Officiel

Le pipeline officiel est **hybride professionnel** :

1. Sourcer une base CC0/procuree ou generer une variante IA licenciee.
2. Enregistrer la source dans `assets/art/source_external/` ou
   `assets/art/source_ai/`.
3. Nettoyer dans Blender : echelle, orientation, materiaux, sockets, pivot.
4. Sauvegarder le travail dans `assets/art/working_blender/`.
5. Exporter le GLB propre vers `assets/art/exports_godot/`.
6. Creer une scene wrapper dans `src/visual/assets/`.
7. Renseigner `assets/art/asset_manifest.json`.
8. Valider dans `src/dev/playgrounds/art_review_playground.tscn`.

Les scripts Blender internes restent autorises pour graybox, collision helpers,
adapters et placeholders. Ils ne sont plus consideres comme methode de
production des assets finaux.

## Interdits

- Pas d'asset final uniquement constitue de primitives scriptees non nettoyees.
- Pas de GLB brut reference directement par une config gameplay principale.
- Pas de ligne rouge ou forme debug comme warning final.
- Pas de micro-details invisibles en vue third-person.
- Pas de couleurs danger sur un objet non dangereux sans raison gameplay.
- Pas d'asset IA ou externe sans licence documentee.

## Reference Courte

Arcade premium goofy : un jeu d'esquive roguelite 3D propre, nerveux,
professionnel, avec des ennemis expressifs mais lisibles, des VFX de danger
soignes, et une production d'assets tracee.
