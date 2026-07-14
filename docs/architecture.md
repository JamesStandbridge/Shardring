# Architecture

Ce projet part d'un socle volontairement simple : Godot gere les scenes, les noeuds, la physique et l'UI, tandis que la logique metier reste structuree par domaines.

## Domaines

- `src/main` contient la scene de lancement et l'orchestration minimale.
- `src/dev/playgrounds` contient les scenes temporaires de validation,
  separees du runtime principal.
- `src/gameplay/run` contiendra le cycle de run : preparation, jeu actif, mort, recompense, restart.
- `src/gameplay/stages` contient la progression de levels d'une run, la selection de maps et la porte de sortie.
- `src/gameplay/player` contiendra le controleur third-person, les etats de mouvement et les upgrades joueur.
- `src/gameplay/combat` contient la sante, les degats typés et les futurs points d'extension pour bouclier, armure et resistances.
- `src/gameplay/feedback` contient les reactions visuelles et sensorielles aux evenements acceptes, comme le shake camera et les flashs HUD.
- `src/gameplay/arena` contiendra la generation, la destruction et la reconstruction du terrain.
- `src/gameplay/dangers` contient le Director qui budgete et declenche les menaces de run.
- `src/gameplay/projectiles` contient le systeme de lanceurs/projectiles. Les volumes eleves doivent utiliser des pools data-oriented et du rendu batche, pas une node par projectile.
- `src/gameplay/enemies` contient les ennemis physiques controles par des pools de nodes capes et des machines a etats simples.
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
- `Stage` pilote les levels infinis d'une run persistante. Il choisit une map dans un catalogue fini, applique l'arene/theme/dangers, suit l'objectif et fait apparaitre l'exit gate.
- `Combat` centralise les degats via `DamageProfile` et `HealthComponent`. Les dangers appliquent des degats, la run ne meurt que lorsque la sante est epuisee.
- `Feedback` reagit aux signaux de gameplay deja valides, par exemple `HealthComponent.damaged`. Les dangers ne pilotent pas directement la camera ou l'UI.
- `Danger` pilote la pression de run via credits, couts, cooldowns et limites actives, puis delegue aux executors specialises (`ProjectileSystem`, `ChaserEnemySystem`, futurs hazards/events).
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
  `ArenaConfig`, `HealthConfig`, `PlayerHurtboxConfig`, `DamageProfile`,
  `CameraShakeConfig`, `DamageFeedbackConfig`, `DangerDefinition`, `DangerDirectorConfig`,
  `StageSequenceConfig`, `MapDefinition`, `ArenaThemeConfig`,
  `ProjectileConfig`, `ProjectileLauncherConfig`,
  `TelegraphVisualConfig`, `ExplosiveChaserConfig`, `DifficultyConfig` et
  `UpgradeConfig`.
- Les signaux transverses passent par `game_events.gd`; les signaux locaux restent dans leur scene ou domaine.
- Aucun addon gameplay n'est introduit au demarrage afin de garder la maitrise de l'architecture.

## Assets visuels

- `assets/art/source_external` contient les packs et sources procures.
- `assets/art/source_ai` contient les generations IA et preuves de licence.
- `assets/art/working_blender` contient les fichiers `.blend` nettoyes.
- `assets/art/source_blender` conserve les sources historiques des placeholders scriptes.
- `assets/art/exports_godot` contient les exports `.glb` utilisables dans Godot.
- `assets/art/generated_concepts` contient les concepts IA temporaires ou retenus.
- `assets/art/reference` contient les references validees pour guider les prochaines generations.
- `src/visual/assets` contient les scenes wrapper stables referencees par les configs gameplay.
- `src/visual/vfx` contient les configs et ressources visuelles de VFX runtime.
- Les assets doivent suivre `docs/art/art_direction.md` et les prompts de `docs/art/asset_prompts.md`.
- Les configs gameplay principales doivent referencer les wrappers, pas les GLB bruts.

## Tests

Les tests GDScript sont executes avec GUT. Les tests unitaires vont dans `tests/unit`, les scenarios traversant plusieurs scenes dans `tests/integration`.

Les systemes de gameplay devront couvrir au minimum leurs regles de calcul par tests unitaires. Les interactions entre run, difficulte, economie et arene devront etre couvertes par tests d'integration quand les scenes existeront.
