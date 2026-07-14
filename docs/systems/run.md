# Systeme Run

## Role

La run est l'unite centrale du jeu. Elle coordonne le debut, le jeu actif, la mort, la recompense et le redemarrage.

## Contrat futur

- Initialiser l'etat de partie : joueur, arene, economie de run, difficulte.
- Passer en jeu actif apres preparation.
- Recevoir les conditions de mort et figer les systemes concernes.
- Calculer les resultats de run et preparer le restart.
- Ne pas stocker directement la meta progression ; deleguer a `progression`.

## Limites actuelles

Le premier contrat runtime est implemente par `RunController`.

Etat actuel :

- etats officiels : `READY`, `PLAYING`, `DEAD` ;
- timer de survie actif uniquement en `PLAYING` ;
- restart propre via `restart_run()` ;
- raison de mort conservee via `register_death(reason)`.

Les prochains systemes doivent reagir a ce controleur plutot que creer leur
propre cycle de run.
