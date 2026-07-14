# Ordre De Developpement

## Principe

Le developpement suit l'ordre des dependances reelles du jeu. Les systemes bas
niveau sont poses avant les contenus, et chaque systeme arrive avec une scene de
validation quand son comportement doit etre ressenti.

## Scenes De Validation

`src/main/main.tscn` reste l'entree officielle du jeu.

Les scenes sous `src/dev/playgrounds` sont temporaires et servent a isoler un
comportement :

- mouvement joueur ;
- generation ou rendu d'arene ;
- projectiles et collisions ;
- economie, pieces et achats temporaires ;
- hazards de terrain.

Ces scenes peuvent utiliser des objets graybox et des overlays debug. Elles ne
doivent pas contenir de logique que le runtime final depend directement.

## Ordre Technique

1. Runtime : creer le controleur de run minimal et les etats officiels.
2. Player : implementer input, mouvement, camera, et config de mouvement.
3. Arena : construire la surface jouable et ses points de placement valides.
4. Projectiles : introduire les configs, spawners et collisions mortelles.
5. Run Loop : relier mort, restart et timer de survie.
6. Difficulty : piloter l'intensite sans connaitre les details des dangers.
7. Economy : ajouter monnaie de run, collecte, achats non centraux et couts d'upgrade.
8. Upgrades : brancher les effets sur le joueur sans casser son controleur.
9. Hazards : faire evoluer les cellules d'arene et leurs etats.
10. Art Pipeline : remplacer les placeholders seulement quand les besoins sont
    stables.
11. Events : ajouter les dangers complexes comme variations des systemes deja
    poses.
12. Progression : persister uniquement quand la boucle de run est claire.

## Conventions Initiales

Actions d'input officielles :

- `move_forward`, `move_backward`, `move_left`, `move_right`
- `jump`, `interact`, `restart_run`, `debug_toggle`

Couches de collision 3D officielles :

- `player`
- `terrain`
- `danger`
- `pickup`
- `shop` reserve a une mecanique d'apparition future, non centrale

Configs `Resource` initiales :

- `PlayerMovementConfig`
- `ArenaConfig`
- `ProjectileConfig`
- `DifficultyConfig`
- `UpgradeConfig`
