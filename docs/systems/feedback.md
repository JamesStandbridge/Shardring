# Feedback

Le feedback rend les evenements importants lisibles et ressentis sans changer la logique de gameplay.

## Contrat

- Les systemes de feedback reagissent a des evenements deja acceptes par le gameplay.
- Un danger n'appelle pas directement la camera, le HUD ou un effet visuel global.
- Pour les degats, le chemin officiel est :
  `DamageProfile -> HealthComponent.apply_damage() -> damaged -> DamageFeedbackController`.
- La mort reste declenchee par `HealthComponent.depleted`, pas par le feedback.

## Premiere Passe

- `DamageFeedbackController` ecoute `HealthComponent.damaged`.
- `ThirdPersonCameraRig` expose `request_shake(config, strength)` pour un shake court et decroissant.
- `HealthHud` expose `request_flash(color, duration)` pour rendre le hit visible sans masquer l'action.
- `DamageFeedbackConfig` choisit un `CameraShakeConfig` par `DamageType`.

## Regles De Lisibilite

- Le feedback doit etre court, clair et jamais plus important que l'information de danger.
- Le shake doit rester faible pour eviter fatigue visuelle et perte de controle.
- Les intensites sont derivees du montant de degat applique, avec bornes min/max.
- Les futurs effets audio, particules, hit stop ou vibration manette devront passer par le meme controleur ou par des sous-controleurs specialises, pas par les dangers.
