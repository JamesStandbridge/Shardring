# Systeme Enemies

## Role

Les ennemis physiques sont des dangers qui ont une presence dans l'arene :
ils peuvent se deplacer, telegraphier une attaque, occuper une silhouette lisible
et appliquer une consequence au joueur.

Ils ne remplacent pas les projectiles. Ils executent la famille `ACTOR_ENEMY`
via le contrat d'executor du `DangerDirector`.

## Contrat

- La cadence et le budget viennent de `DangerDirector`.
- Le systeme ennemi gere spawn, mouvement, etats, telegraphie, explosion et cleanup.
- Les ennemis repetes doivent etre capes et poolables.
- Les machines a etats doivent rester simples et observables.
- Les valeurs de tuning vivent dans des `Resource`, pas dans la logique.
- Un ennemi doit avoir une silhouette, une distance de reaction et une condition
  de cleanup claires.

## Implementation actuelle

`ChaserEnemySystem` gere le premier actor enemy : `ExplosiveChaser`.

- Pool de `CharacterBody3D` precrees.
- Etats : `INACTIVE`, `CHASING`, `PRIMING`, `EXPLODING`.
- Spawn sur position valide d'arene, avec rejet si trop proche du joueur.
- Poursuite au sol, sans pathfinding, avec un leger zigzag procedural pour eviter
  une trajectoire parfaitement lineaire.
- Marche vers le joueur a longue distance, puis montee progressive en
  course/excitation quand le joueur entre dans le rayon configure.
- Animation procedural locale au mesh enfant : pop de spawn, bob, roll,
  squash/stretch et vibration de priming, sans deformer la collision.
- Priming lisible avant explosion.
- Explosion automatique a expiration de lifetime si le chaser n'a pas atteint le
  joueur.
- Explosion logique par rayon horizontal, puis application du `DamageProfile`
  explosif au `HealthComponent`.
- Cleanup sur mort, restart et fin de linger d'explosion.

Le preset `basic_explosive_chaser.tres` configure le comportement. La definition
`explosive_chaser_danger.tres` donne au Director le cout, cooldown, poids,
limite active et tags de lisibilite.

## Limites actuelles

- Pas de navigation avancee ni avoidance entre ennemis.
- Pas d'animation squelettique, audio ou particules.
- Pas de collision directe joueur-ennemi hors explosion.
- Pas de variantes de comportement.

Ces limites sont volontaires : le but est de valider le runtime actor capé avant
d'ajouter des familles plus complexes comme les lanceurs d'explosifs, les
dashers ou les ennemis qui modifient le terrain.
