# Systeme Difficulty

## Role

La difficulte transforme le temps de survie en pression de jeu. Elle controle l'intensite, les familles de dangers disponibles et leur frequence.

## Contrat futur

- Produire une valeur d'intensite a partir du temps de run.
- Ajouter des bonus d'intensite venant d'actions volontaires du joueur, comme la
  collecte de Shards.
- Permettre des peaks courts forces par certains evenements de run sans
  dupliquer la cadence globale hors du `DangerDirector`.
- Debloquer progressivement projectiles, lasers, missiles, hazards et evenements speciaux.
- Eviter les combinaisons illisibles en limitant les pics de danger simultanes.
- Fournir des parametres a `DangerDirector` sans connaitre les implementations internes
  des projectiles, ennemis, hazards ou events.

## Limites actuelles

La premiere version reste simple : `DangerDirector` utilise une intensite
temporelle plus un bonus d'objectif venant des Shards pour accumuler des
credits. La collecte d'un Shard peut forcer un court peak. Un
`DifficultyController` dedie pourra ensuite remplacer cette logique sans changer
les systemes specialises.
