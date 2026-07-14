# Systeme Stages

## Role

`StageController` transforme une run unique en suite infinie de levels. Les
levels piochent cycliquement dans un catalogue fini de `MapDefinition`, puis
augmentent le budget de menace et la difficulte par index de level.

## Contrat

- La run reste persistante entre maps : la sante, les futures upgrades et la
  monnaie de run ne sont pas reset par un changement de stage.
- Une map definit son arene, son theme visuel, ses configs de danger et ses
  dangers disponibles.
- L'objectif V1 mesure un budget de menaces survecu. Chaque danger qui spawn
  via `DangerDirector` ajoute son `spawn_cost` a la progression du stage.
- Quand l'objectif est atteint, l'exit gate apparait au centre ; les dangers
  continuent en pression reduite tant que le joueur ne traverse pas la porte.
- La transition de stage clear les dangers actifs, regenere l'arene, applique le
  theme suivant, repositionne le joueur et reset l'objectif.
- Les chasers restent des menaces d'evasion. Le joueur ne doit pas devoir
  provoquer leurs explosions pour progresser.

## Exit Gate

La porte est un interactable spatial, pas un menu. Elle s'ouvre quand le joueur
s'approche, se referme quand il s'eloigne, et declenche la transition uniquement
si le joueur traverse son volume ouvert.

Le visuel officiel vient du pipeline Blender scriptable. Le runtime conserve un
fallback procedural pour rester testable si le GLB n'est pas disponible.
