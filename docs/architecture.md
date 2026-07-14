# Architecture

Ce projet part d'un socle volontairement simple : Godot gere les scenes, les noeuds, la physique et l'UI, tandis que la logique metier reste structuree par domaines.

## Domaines

- `src/main` contient la scene de lancement et l'orchestration minimale.
- `src/dev/playgrounds` contient les scenes temporaires de validation,
  separees du runtime principal.
- `src/gameplay/run` contiendra le cycle de run : preparation, jeu actif, mort, recompense, restart.
- `src/gameplay/player` contiendra le controleur third-person, les etats de mouvement et les upgrades joueur.
- `src/gameplay/arena` contiendra la generation, la destruction et la reconstruction du terrain.
- `src/gameplay/projectiles` contient le systeme de lanceurs/projectiles. Les volumes eleves doivent utiliser des pools data-oriented et du rendu batche, pas une node par projectile.
- `src/gameplay/hazards` contiendra les effets temporaires de terrain et evenements speciaux.
- `src/gameplay/difficulty` contiendra la courbe de difficulte, l'intensite et les unlocks progressifs.
- `src/gameplay/events` contiendra les evenements speciaux, comme l'ennemi au baril explosif.
- `src/gameplay/economy` contiendra les pieces, achats et upgrades.
- `src/gameplay/upgrades` contiendra les definitions et effets d'ameliorations.
- `src/gameplay/progression` contiendra plus tard la progression persistante cross-game.
- `src/gameplay/save` contiendra plus tard l'acces aux sauvegardes et leur migration.
- `src/data` contiendra les `Resource` de configuration versionnees pour gameplay et balancing.
- `src/shared` contient le code transversal limite, dont l'autoload d'evenements.

## Contrats systeme

- `Run` pilote le cycle `start -> playing -> death -> reward -> restart`. Les autres systemes doivent reagir a ce cycle plutot que le recreer localement.
- `Difficulty` expose une intensite temporelle et debloque progressivement les familles de dangers.
- `Economy` separe la monnaie de run, remise a zero a chaque partie, de la monnaie cross-game persistante.
- `Save` persiste uniquement les donnees cross-game et doit rester absent de la boucle de run immediate.
- `Data` fournit les configurations via des `Resource` Godot pour eviter les constantes dispersees dans les scripts.
- `GameEvents` reste le bus transversal. Aucun nouveau signal global ne doit etre ajoute sans usage concret.
- Les scenes de playground doivent valider un comportement precis sans devenir
  des dependances du jeu final.

## Regles de code

- GDScript type par defaut : retours, parametres et proprietes exportees doivent etre types.
- Classes en `PascalCase` via `class_name`, fichiers en `snake_case`.
- Les configurations de gameplay evolutives seront modelisees avec des `Resource`.
- Les premieres configs officielles sont `PlayerMovementConfig`,
  `ArenaConfig`, `ProjectileConfig`, `DifficultyConfig` et `UpgradeConfig`.
- Les signaux transverses passent par `game_events.gd`; les signaux locaux restent dans leur scene ou domaine.
- Aucun addon gameplay n'est introduit au demarrage afin de garder la maitrise de l'architecture.

## Assets visuels

- `assets/art/source_blender` contient les sources `.blend` produites ou nettoyees.
- `assets/art/exports_godot` contient les exports `.glb` utilisables dans Godot.
- `assets/art/generated_concepts` contient les concepts IA temporaires ou retenus.
- `assets/art/reference` contient les references validees pour guider les prochaines generations.
- Les assets doivent suivre `docs/art/art_direction.md` et les prompts de `docs/art/asset_prompts.md`.

## Tests

Les tests GDScript sont executes avec GUT. Les tests unitaires vont dans `tests/unit`, les scenarios traversant plusieurs scenes dans `tests/integration`.

Les systemes de gameplay devront couvrir au minimum leurs regles de calcul par tests unitaires. Les interactions entre run, difficulte, economie et arene devront etre couvertes par tests d'integration quand les scenes existeront.
