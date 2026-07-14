# 0005 - Enemy Actor Runtime

## Status

Accepted.

## Context

Shardring doit supporter plusieurs types de menaces : projectiles nombreux,
ennemis qui poursuivent le joueur, explosifs lances, attaques venant du ciel,
hazards de terrain et evenements speciaux.

Le `DangerDirector` ne doit pas grossir avec un cas specifique pour chaque
famille. Les projectiles utilisent deja une approche data-oriented et batchee,
mais les ennemis physiques ont besoin de nodes pour profiter du mouvement,
de la collision terrain et de la lisibilite en scene.

## Decision

Les ennemis physiques repetes utilisent un runtime actor capé :

- `DangerDirector` choisit et budgete via `DangerDefinition`.
- `ChaserEnemySystem` execute la famille `ACTOR_ENEMY`.
- Les actors sont precrees dans un pool borne.
- Chaque actor est un `CharacterBody3D` avec une machine a etats simple.
- Les configs restent dans `Resource`, notamment `ExplosiveChaserConfig`.

Le Director route les familles via `danger_executor_paths` et le contrat commun :

- `supports_danger_family(family)`;
- `request_spawn_danger(definition)`;
- `get_active_danger_count(definition)`;
- `get_total_active_danger_count()`.

## Consequences

- Ajouter une nouvelle famille ne doit plus modifier le Director.
- Les limites actives sont mesurees par l'executor qui connait sa famille.
- Les ennemis complexes peuvent utiliser des nodes, mais seulement dans un pool
  capé et observable.
- Les projectiles restent optimises separement avec `MultiMesh`.

## Non-goals

- Pas de pathfinding dans ce lot.
- Pas d'animation, audio, particules ou assets finalises.
- Pas de systeme generique unique pour toutes les menaces.
