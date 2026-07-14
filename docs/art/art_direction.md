# Direction Artistique

## Intention

Le jeu doit etre agreable visuellement sans demander une production artistique complexe. La DA est concue pour etre appliquee par IA : formes simples, palette courte, materiaux peu nombreux, regles de lisibilite strictes.

Style retenu : **techno-rituel stylise**.

L'arene est une structure sombre et ancienne, reactive a une energie instable. Le joueur survit dans un espace lisible, presque abstrait, ou chaque couleur a une fonction de gameplay.

## Regles Simples

- Silhouettes simples avant details.
- Contraste fort entre terrain sombre et dangers lumineux.
- Chaque type de danger a une couleur dominante stable.
- Peu de textures detaillees ; preferer materiaux plats, emission et bords nets.
- Pas de realisme, pas de salissure complexe, pas de micro-details.
- Tous les assets doivent rester lisibles avec une camera third-person eloignee.
- Les formes doivent pouvoir etre generees en Blender par primitives, bevels, extrusions et materiaux simples.

## Palette Fonctionnelle

| Usage | Couleur | Hex |
| --- | --- | --- |
| Sol principal | Pierre noire froide | `#16181D` |
| Metal sombre | Graphite bleute | `#252A33` |
| Lignes neutres | Gris clair froid | `#A8B0BD` |
| Interactable temporaire | Cyan calme | `#36D7D9` |
| Monnaie de run | Or chaud | `#F5B642` |
| Monnaie cross-game | Blanc violet rare | `#D9C7FF` |
| Danger general | Rouge alerte | `#FF3B30` |
| Explosion / missile | Orange chaud | `#FF8A1F` |
| Laser | Magenta violent | `#FF2BD6` |
| Glace | Bleu cyan pale | `#9EEBFF` |
| Lave | Rouge orange emissif | `#FF4A1C` |
| Terrain reconstruit | Vert energie faible | `#6CFF9E` |

## Formes

- Terrain : cellules polygonales irregulieres dans un disque, bords nets, epaisseur visible.
- Achats futurs : interactables temporaires calmes, cyan, distincts des dangers.
- Pieces : petites formes rondes ou cristallines, emission or, rotation lente.
- Projectiles simples : spheres, cones, capsules, prismes.
- Missiles : capsule allongee avec noyau orange et train lumineux.
- Lasers : faisceau tres fin, magenta, avec zone d'avertissement avant tir.
- Canon balls : grosses spheres sombres avec noyau rouge/orange.
- Baril explosif : cylindre trapu, bandes orange, silhouette lisible.

## Materiaux

- `mat_stone_dark` : albedo sombre, roughness haute.
- `mat_metal_dark` : graphite, roughness moyenne, leger metallic.
- `mat_interactable_energy` : cyan emissif doux.
- `mat_coin_run` : or emissif leger.
- `mat_coin_meta` : violet blanc emissif.
- `mat_danger_red` : rouge emissif.
- `mat_explosion_orange` : orange emissif fort.
- `mat_laser_magenta` : magenta emissif tres fort.
- `mat_ice` : bleu pale, transparent leger si possible.
- `mat_lava` : rouge orange emissif, animation shader plus tard.

## Interdits

- Pas de palette majoritairement beige, marron, violette ou bleu nuit uniforme.
- Pas de textures photo realistes au demarrage.
- Pas d'assets tres detailles qui deviennent illisibles de loin.
- Pas de couleur decorative qui entre en conflit avec les couleurs gameplay.
- Pas de formes trop organiques pour les dangers principaux.
- Pas d'interactable d'achat qui ressemble a un danger.

## Reference Verbale Courte

Une arene circulaire sombre, stylisee, techno-rituelle, composee de cellules polygonales de pierre noire et metal graphite. Les dangers sont des formes geometriques lumineuses tres codees par couleur. Les pieces sont or. Le rendu est propre, lisible, low-poly premium, sans realisme.
