# Systeme Dangers

## Role

Les dangers sont toutes les menaces actives qui forcent le joueur a esquiver :
projectiles, ennemis physiques, attaques en cloche, attaques venant du ciel,
hazards de terrain et evenements speciaux.

`DangerDirector` controle la pression globale de run. Il accumule des credits,
alterne des phases de buildup, peak et recovery, choisit des definitions de
danger valides, depense un cout, puis delegue a un executor specialise reference
dans `danger_executor_paths`.

Le Director ne doit pas connaitre `ProjectileSystem`, `ChaserEnemySystem` ou les
futurs systems de hazards en dur. Il utilise le contrat commun :

- `supports_danger_family(family) -> bool` ;
- `request_spawn_danger(definition) -> bool` ;
- `get_active_danger_count(definition) -> int` ;
- `get_total_active_danger_count() -> int`.

Les executors peuvent aussi exposer `get_active_readability_pressure() -> int`.
Cette valeur ne mesure pas la difficulte brute, mais la charge visuelle
temporaire : telegraphes projectile, chasers en priming/explosion, cellules en
warning/collapse. Le Director refuse temporairement un spawn si la pression
visuelle courante depasse le seuil de la phase active.

## Placement Fair

`DangerPlacementRules` decrit les contraintes communes de spawn : distance au
joueur, zone centrale safe, distance a l'exit gate et etats de cellules a
eviter. Ces regles sont referencees par `DangerDefinition`, ce qui permet de
tuner chaque danger sans ajouter de cas special dans les systems.

`DangerPlacementService` vit dans la scene principale. Il connait l'arene, le
joueur et la porte, mais ne spawn rien lui-meme. Les executors lui demandent
uniquement une position valide ou une validation de position. Les anciens champs
locaux des configs restent des fallbacks utiles pour les tests et playgrounds.

## Contrat futur

- Piloter les menaces par cout, cooldown, intensite minimale, poids de selection
  et limites actives.
- Emettre un evenement de spawn reussi pour permettre au `StageController` de
  mesurer la pression survecue, sans en faire l'objectif de completion.
- Reduire la pression apres apparition de l'exit gate, sans stopper totalement
  les dangers.
- Accepter des bonus d'intensite et des peaks forces venant des Shards, tout en
  conservant les caps de lisibilite.
- Garder `Difficulty` independant des details internes des projectiles, ennemis,
  hazards et events.
- Utiliser des skip reasons explicites quand un spawn est refuse :
  `placement_failed`, `readability_pressure_capped`, `active_cap`, `cooldown`,
  `credits` ou `unsupported`.
- Utiliser une architecture hybride :
  - pools data-oriented et rendu batche pour les dangers tres nombreux ;
  - nodes capes ou poolables pour les ennemis physiques complexes.
- Chaque danger doit definir sa lisibilite : telegraphe, silhouette, timing,
  couleur ou avertissement de zone.
- Chaque danger qui inflige des degats doit referencer ou produire un
  `DamageProfile`, puis appliquer ce profil au `HealthComponent` seulement apres
  collision confirmee.
- Aucun danger instantane ne doit devenir inevitable sans avertissement.

## Limites actuelles

L'implementation actuelle supporte trois familles :

- `PROJECTILE_LAUNCHER`, executee par `ProjectileSystem` avec pools et rendu
  `MultiMesh` ;
- `ACTOR_ENEMY`, executee par `ChaserEnemySystem` avec un pool de
  `CharacterBody3D` capes ;
- `TERRAIN_HAZARD`, executee par `ArenaHazardSystem` avec des groupes de
  cellules d'arene et aucun node par cellule.

Les familles reservees sont :

- `BALLISTIC_ATTACK` pour les tirs en cloche et explosifs lances ;
- `SKY_ATTACK` pour les attaques venant du ciel ;
- `SPECIAL_EVENT` pour les sequences rares.
