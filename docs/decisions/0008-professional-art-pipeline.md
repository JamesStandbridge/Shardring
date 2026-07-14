# 0008 - Pipeline Assets Arcade Premium

## Decision

Remplacer le pipeline "Blender primitives scriptées comme assets finaux" par un
pipeline hybride professionnel.

La direction devient **arcade premium goofy** : humour léger, silhouettes
fortes, matériaux stylisés propres, VFX gameplay lisibles, et assets validés à
la caméra de jeu.

## Raisons

- Les assets scriptés actuels sont reproductibles mais trop pauvres
  visuellement pour porter le jeu.
- Le gameplay a besoin de dangers immédiatement lisibles, pas de formes
  techniques ou de traits debug.
- Les sources CC0/procures donnent une base plus professionnelle que des
  primitives assemblées.
- Les wrapper scenes Godot permettent de remplacer les assets sans toucher au
  code gameplay.

## Consequences

- Les assets toybox générés restent des placeholders dépréciés.
- Les configs gameplay référencent des wrapper scenes, pas des GLB bruts.
- Chaque asset runtime doit être tracé dans `assets/art/asset_manifest.json`.
- Les VFX de warning sont traités comme assets de gameplay, pas comme debug
  geometry.
