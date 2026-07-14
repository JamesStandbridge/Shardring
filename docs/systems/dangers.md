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

## Contrat futur

- Piloter les menaces par cout, cooldown, intensite minimale, poids de selection
  et limites actives.
- Emettre un evenement de spawn reussi pour permettre au `StageController` de
  compter le budget de menaces survecu, sans connaitre les familles de dangers.
- Reduire la pression apres apparition de l'exit gate, sans stopper totalement
  les dangers.
- Garder `Difficulty` independant des details internes des projectiles, ennemis,
  hazards et events.
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

La premiere implementation supporte deux familles :

- `PROJECTILE_LAUNCHER`, executee par `ProjectileSystem` avec pools et rendu
  `MultiMesh` ;
- `ACTOR_ENEMY`, executee par `ChaserEnemySystem` avec un pool de
  `CharacterBody3D` capes.

Les familles reservees sont :

- `BALLISTIC_ATTACK` pour les tirs en cloche et explosifs lances ;
- `SKY_ATTACK` pour les attaques venant du ciel ;
- `TERRAIN_HAZARD` pour lave, glace, effondrement et terrain detruit ;
- `SPECIAL_EVENT` pour les sequences rares.
