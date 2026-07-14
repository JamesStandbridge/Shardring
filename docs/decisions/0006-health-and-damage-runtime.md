# 0006 - Health And Damage Runtime

## Status

Accepted.

## Context

Shardring ne doit plus etre binaire. Le joueur doit pouvoir encaisser plusieurs
erreurs, et le jeu devra plus tard supporter boucliers, armure, resistances et
types de degats comme feu, laser, explosif ou projectile.

Les dangers peuvent etre tres nombreux. Le chemin de degats ne doit donc pas
creer d'objet ou de node par hit.

## Decision

Ajouter un pipeline centralise :

- `DamageProfile` decrit les degats.
- Les systems de danger detectent les collisions.
- `HealthComponent.apply_damage()` applique les degats acceptes.
- `HealthComponent.depleted` declenche `RunController.register_death()`.

Les resistances futures seront indexees par `DamageType`.

## Consequences

- Les projectiles et enemies n'appellent plus directement `register_death()` pour
  les degats normaux.
- L'UI peut observer la sante sans connaitre les dangers.
- Les futurs boucliers, armures et resistances ont un point d'entree unique.
