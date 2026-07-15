# Systeme Objectives

## Role

Les objectifs donnent au joueur une action volontaire pour terminer un level.
Shardring ne doit pas se resumer a attendre un chrono ou a subir assez de
dangers : le joueur choisit quand prendre un risque pour accelerer la sortie.

## Shards V1

- Un seul Shard actif a la fois.
- Pickup au contact, sans interaction maintenue.
- Le nombre requis augmente avec le level via `ShardObjectiveConfig`.
- Chaque collecte augmente le bonus d'intensite et declenche un court peak.
- Quand tous les Shards sont collectes, l'exit gate apparait.
- Apres `EXIT_AVAILABLE`, les Shards ne respawnent plus ; le joueur peut partir
  ou rester pour faire monter le bonus de risque.

Les Shards ne spawnent pas de dangers eux-memes. Ils signalent la progression ;
`StageController` orchestre la porte et `DangerDirector` orchestre la pression.
