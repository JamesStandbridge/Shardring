# 0003 - Direction artistique

## Statut

Remplacee par `0008 - Pipeline Assets Arcade Premium`. Cette decision est
conservee uniquement comme historique et ne doit plus guider les nouveaux
assets.

## Decision

Adopter une direction artistique **stylisee techno-rituelle**, low-poly propre, lumineuse et tres lisible.

Le jeu doit ressembler a une arene ancienne controlee par une technologie instable : pierre noire, metal sombre, lignes lumineuses, dangers colores et silhouettes simples.

## Raisons

- Le gameplay demande une lecture immediate des dangers, du terrain et des interactables temporaires.
- Le style stylise est plus simple a produire par IA et plus facile a maintenir sans designer.
- Des formes simples et des couleurs codees permettent d'ajouter du contenu sans perdre la coherence.
- Le rendu realiste est differe car il complique la production, l'optimisation et la lisibilite.

## Consequences

- Les assets doivent privilegier les silhouettes fortes, les materiaux simples et les couleurs fonctionnelles.
- Les dangers utilisent une couleur dominante selon leur role.
- Les textures doivent rester secondaires : forme, couleur et animation portent la lisibilite.
- Blender peut etre pilote par scripts ou par IA, mais les assets doivent rester exportables proprement vers Godot.
