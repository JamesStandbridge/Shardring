# Systeme Projectiles

## Role

Les projectiles sont les dangers principaux qui traversent ou ciblent l'arene. Ils doivent etre varies, lisibles et configurables.

## Contrat futur

- Supporter des projectiles simples, explosifs, missiles lents, lasers avertis et canon balls.
- Separer configuration, lanceur visible, spawn et comportement de projectile.
- Fournir un signal visuel ou temporel pour les dangers non evitables instantanement.
- Garder le telegraphe fidele au tir : la direction annoncee doit etre la direction effective du projectile.
- Garder une collision logique plus indulgente ou egale a la silhouette visible.
- Utiliser des couleurs de danger stables : rouge pour le danger general, orange pour explosion/missile, magenta pour laser.
- Interdire les dangers instantanes sans avertissement lisible.
- Permettre a `Difficulty` de choisir types et cadence sans connaitre le detail des scenes.
- Supporter a terme des centaines de lanceurs et milliers de projectiles sans creer une node par projectile.

## Limites actuelles

Le premier systeme runtime utilise un `ProjectileSystem` data-oriented :

- les lanceurs sont les sources de menace visibles ;
- les projectiles sont des donnees actives mises a jour en batch ;
- le rendu passe par `MultiMeshInstance3D` ;
- la collision joueur est logique, sans `Area3D` par projectile.
- les trails et telegraphes sont rendus en batch pour conserver un nombre de nodes borne.

Chaque famille de projectile devra etre ajoutee par donnees et tests, pas par duplication de logique dans un spawner unique massif.
