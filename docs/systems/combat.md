# Systeme Combat

## Role

Le combat centralise les degats et la sante. Les dangers ne tuent plus
directement le joueur : ils produisent un hit confirme puis appliquent un
`DamageProfile` au `HealthComponent`.

## Contrat

- `DamageProfile` porte le montant, le type de degat, la raison de mort et le
  label de hit.
- `HealthComponent` possede les HP courants, l'invulnerabilite post-hit et les
  derniers degats acceptes.
- `PlayerHurtboxConfig` decrit la capsule de degats du joueur. Elle doit rester
  proche de la silhouette visible tout en etant legerement plus indulgente.
- `RunController` ne calcule pas la sante. Il recoit une mort uniquement quand
  `HealthComponent.depleted` est emis.
- Les resistances futures doivent etre indexees par `DamageType`, pas par
  chaines de caracteres dans le chemin chaud.

## Optimisation

- Aucun node n'est cree par hit.
- Les projectiles, explosions et hazards confirment d'abord leur collision dans
  leur systeme specialise.
- Les dangers doivent interroger la hurtbox joueur centralisee au lieu de
  dupliquer leurs propres constantes de collision joueur.
- Seuls les hits confirmes appellent `HealthComponent.apply_damage()`.
- Les signaux de degats ne sont emis que pour les degats acceptes.

## Limites actuelles

- Pas encore de bouclier, armure, regeneration ou DoT.
- Pas encore de resistance configurable par type.
- Pas encore de feedback visuel avance hors HUD sante et logs debug.
