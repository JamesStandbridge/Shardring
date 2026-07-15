# Systeme Stages

## Role

`StageController` transforme une run unique en suite infinie de levels. Les
levels piochent cycliquement dans un catalogue fini de `MapDefinition`, puis
augmentent la difficulte et l'objectif par index de level.

## Contrat

- La run reste persistante entre maps : la sante, les futures upgrades et la
  monnaie de run ne sont pas reset par un changement de stage.
- Une map definit son arene, son theme visuel, ses configs de danger et ses
  dangers disponibles.
- L'objectif V1 est volontaire : recuperer des Shards dans l'arene.
- Le budget de menaces survecu peut rester instrumente pour debug/score, mais
  il n'ouvre plus la porte.
- Quand l'objectif est atteint, l'exit gate apparait au centre ; les dangers
  continuent en pression reduite tant que le joueur ne traverse pas la porte.
- Apres apparition de la porte, les Shards cessent d'apparaitre. Le temps
  d'overstay augmente un bonus de risque/recompense affiche, pret a etre relie
  a l'economie plus tard.
- La transition de stage clear les dangers actifs, regenere l'arene, applique le
  theme suivant, repositionne le joueur et reset l'objectif.
- Les chasers restent des menaces d'evasion. Le joueur ne doit pas devoir
  provoquer leurs explosions pour progresser.

## Shards

`ShardObjectiveController` gere un seul Shard actif a la fois. Le pickup est au
contact en V1. Chaque Shard collecte augmente la progression du level, applique
un bonus d'intensite au `DangerDirector`, puis force un court peak de pression.

Les Shards doivent apparaitre sur une cellule valide, loin du joueur et hors de
la zone centrale safe. Ils sont l'action volontaire qui permet a un joueur fort
de finir plus vite sans forcer un joueur prudent a jouer parfaitement.

## Exit Gate

La porte est un interactable spatial, pas un menu. Elle s'ouvre quand le joueur
s'approche, se referme quand il s'eloigne, et declenche la transition uniquement
si le joueur traverse son volume ouvert.

Le visuel officiel vient du pipeline Blender scriptable. Le runtime conserve un
fallback procedural pour rester testable si le GLB n'est pas disponible.
