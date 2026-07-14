# Systeme Player

## Role

Le joueur est le point de controle principal. Sa priorite est la fiabilite du mouvement et la lisibilite de ses etats.

## Contrat futur

- Deplacement third-person avec course et saut simple nerveux.
- Support d'upgrades de run comme double saut et glissade rapide.
- Detection claire de mort : terrain detruit, lave, projectile, explosion.
- Separation entre input, mouvement, et application d'upgrades.

## Limites actuelles

Le premier controleur est implemente dans le projet, sans addon gameplay.

Etat actuel :

- `PlayerController` utilise `CharacterBody3D` et `PlayerMovementConfig` ;
- mouvement clavier/souris third-person, course et saut simple ;
- feeling arcade configure par data : acceleration, freinage, virage,
  controle aerien, coyote time, jump buffer, saut variable, apex hang,
  boost horizontal au decollage et reglages natifs `CharacterBody3D` ;
- camera reusable via `ThirdPersonCameraRig` ;
- API minimale pour le runtime : activation du mouvement, reset au spawn,
  lecture de vitesse horizontale, verticale et etat au sol.

Les upgrades doivent rester ajoutes par effets explicites, sans transformer le
controleur en systeme d'economie ou de progression.
