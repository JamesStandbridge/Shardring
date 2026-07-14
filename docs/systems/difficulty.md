# Systeme Difficulty

## Role

La difficulte transforme le temps de survie en pression de jeu. Elle controle l'intensite, les familles de dangers disponibles et leur frequence.

## Contrat futur

- Produire une valeur d'intensite a partir du temps de run.
- Debloquer progressivement projectiles, lasers, missiles, hazards et evenements speciaux.
- Eviter les combinaisons illisibles en limitant les pics de danger simultanes.
- Fournir des parametres aux spawners sans connaitre leurs implementations internes.

## Limites actuelles

La premiere version doit rester simple : une courbe temporelle explicite et testable avant toute logique adaptative.

