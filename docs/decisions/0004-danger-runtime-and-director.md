# 0004 - Danger Runtime Et Director

## Statut

Accepte.

## Contexte

Shardring n'est pas un jeu uniquement base sur des projectiles. La pression de
survie doit venir de menaces variees : projectiles horizontaux, attaques venant
du ciel, explosifs en cloche, ennemis physiques qui poursuivent le joueur,
hazards de terrain et evenements speciaux.

Forcer toutes ces menaces dans `ProjectileSystem` creerait un spawner massif,
difficile a optimiser et difficile a faire evoluer.

Risk of Rain 2 montre un modele pertinent : un Director controle la population
par credits, couts et limites, tandis que les monstres, projectiles et attaques
restent des implementations specialisees.

## Decision

Shardring utilise une couche `Danger` au-dessus des systemes specialises.

- `DangerDirector` accumule des credits pendant `PLAYING`.
- Chaque danger est decrit par `DangerDefinition`.
- Le Director choisit une menace selon cout, poids, cooldown, intensite minimale
  et limites actives.
- Le Director delegue ensuite a un systeme specialise.
- Les projectiles nombreux restent data-oriented et rendus en batch.
- Les ennemis physiques complexes pourront etre des nodes capes ou poolables avec
  state machines simples.

## Consequences

- `ProjectileSystem` ne doit plus etre la source centrale de cadence dans la scene
  principale.
- `Difficulty` devra piloter le Director, pas les internals des projectiles,
  ennemis, hazards ou events.
- Chaque nouveau danger doit declarer son cout, ses limites, sa lisibilite et sa
  condition de cleanup.
- Les futurs chasers explosifs et lanceurs d'explosifs seront ajoutes comme
  familles de danger specialisees, pas comme extensions directes du projectile
  lineaire actuel.
