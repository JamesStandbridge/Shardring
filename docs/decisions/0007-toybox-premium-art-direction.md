# 0007 - Direction artistique Toybox Premium

Statut : remplacee par `0008-professional-art-pipeline.md`.

Cette decision documente l'ancienne direction. Elle ne doit plus guider les
nouveaux assets finaux.

## Decision

Remplacer la direction techno-rituelle sombre par une DA **toybox premium
pastel**, goofy et propre.

Les dangers deviennent des objets vivants absurdes : projectiles gummy,
lanceurs type jouet-canon/grille-pain, chasers bombes-jouets. Le gameplay garde
ses couleurs fonctionnelles : rouge, orange et magenta restent reserves aux
dangers.

## Raisons

- Le jeu vise une experience d'evasion nerveuse mais humoristique.
- Les formes toybox sont faciles a produire par IA et Blender scriptable.
- Une palette claire aide les tests manuels et evite le retour a une scene trop
  sombre.
- Des silhouettes rondes et simples restent lisibles depuis une camera
  third-person.
- Les assets peuvent etre regeneres sans competence manuelle Blender avancee.

## Consequences

- `docs/art/art_direction.md` devient la source de verite Toybox Premium.
- Le pipeline principal est `just art-kit`, qui execute Blender en background.
- Les exports `.glb` sont branches via configs `.tres` ou scenes, avec fallback
  procedural.
- Les assets high-volume utilisent encore `MultiMesh` et extraient un mesh du
  GLB.
- Les details comiques ne doivent jamais reduire la lisibilite du danger.
