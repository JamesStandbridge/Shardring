# Systeme Projectiles

## Role

Les projectiles sont les dangers principaux qui traversent ou ciblent l'arene. Ils doivent etre varies, lisibles et configurables.

## Contrat futur

- Supporter des projectiles simples, explosifs, missiles lents, lasers avertis et canon balls.
- Separer configuration, lanceur visible, spawn et comportement de projectile.
- Fournir un signal visuel ou temporel pour les dangers non evitables instantanement.
- Garder le telegraphe fidele au tir : la direction annoncee doit etre la direction effective du projectile.
- Faire partir le telegraphe et le projectile du meme `muzzle` explicite du lanceur.
  Le centre logique du lanceur ne doit pas etre utilise comme origine de tir si
  l'asset visuel possede une bouche de canon differente.
- Configurer les warnings via `TelegraphVisualConfig` pour eviter les traits
  debug bruts : faisceau segmente/pulse, marker de bouche et marker de cible.
- Garder une collision logique coherente avec la hurtbox joueur centralisee :
  toucher une silhouette visible doit compter, mais les near misses hors
  silhouette doivent rester fair.
- Appliquer un `DamageProfile` au `HealthComponent` apres collision confirmee,
  sans creer de node ou d'objet runtime par hit.
- Utiliser des couleurs de danger stables : rouge pour le danger general, orange pour explosion/missile, magenta pour laser.
- Interdire les dangers instantanes sans avertissement lisible.
- Permettre a `Difficulty` de choisir types et cadence sans connaitre le detail des scenes.
- Recevoir la cadence principale depuis `DangerDirector`, pas depuis un timer local de production.
- Supporter a terme des centaines de lanceurs et milliers de projectiles sans creer une node par projectile.
- Implementer le contrat d'executor de danger pour rester interchangeable avec les autres familles de menaces.

## Limites actuelles

Le premier systeme runtime utilise un `ProjectileSystem` data-oriented :

- les lanceurs sont les sources de menace visibles ;
- les projectiles sont des donnees actives mises a jour en batch ;
- le rendu passe par `MultiMeshInstance3D` ;
- la collision joueur est logique, sans `Area3D` par projectile.
- la collision joueur applique le `DamageProfile` configure au lieu de tuer directement ;
- les trails, telegraphes, points de bouche et marqueurs de cible sont rendus en
  batch pour conserver un nombre de nodes borne.
- la scene principale desactive le spawn autonome du `ProjectileSystem` et laisse
  `DangerDirector` demander les lanceurs.
- `ProjectileSystem` execute la famille `PROJECTILE_LAUNCHER` via le contrat
  `supports_danger_family`, `request_spawn_danger`, `get_active_danger_count`
  et `get_total_active_danger_count`.

Chaque famille de projectile devra etre ajoutee par donnees et tests, pas par duplication de logique dans un spawner unique massif.
