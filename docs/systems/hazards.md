# Systeme Hazards

## Role

Les hazards sont les dangers lies au terrain : lave, glace, effondrement, zones detruites et effets temporaires.

## Contrat

- Appliquer des etats temporaires a des zones d'arene.
- Publier clairement les effets : mort, glisse, indisponibilite, reconstruction.
- Respecter les signaux visuels avant danger quand le joueur doit anticiper.
- Coopérer avec `Difficulty` pour limiter les situations injustes.
- Passer par `DangerDirector` avec la famille `TERRAIN_HAZARD`.
- Appliquer les degats via `DamageProfile -> HealthComponent`.
- Modifier le mouvement joueur via l'API de surface du player, pas en changeant
  directement les constantes de mouvement.

## Implementation actuelle

`ArenaHazardSystem` execute trois hazards V1 :

- lave : warning, zone lave temporaire, degats terrain par tick ;
- glace : warning, zone glace temporaire, mouvement plus glissant ;
- collapse : warning, effondrement, cellule detruite sans collision, reconstruction.

Les etats officiels de cellule sont `NORMAL`, `WARNING`, `LAVA`, `ICE`,
`COLLAPSING`, `DESTROYED` et `REBUILDING`.

Les hazards actifs sont stockes comme groupes logiques de cellules avec timers.
Le systeme ne cree pas de node par cellule dangereuse.

## Limites

Les hazards ne contournent pas encore les ennemis ou projectiles. Le pathfinding
et les comportements adverses autour des trous sont differes.
