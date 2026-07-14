# Systeme Upgrades

## Role

Les upgrades modifient les capacites du joueur pendant une run. Elles doivent rester explicites et faciles a equilibrer.

## Contrat futur

- Definir les upgrades par donnees : id, nom, prix, prerequis, effet.
- Appliquer les effets via des composants ou services dedies au domaine cible.
- Supporter au minimum double saut et glissade rapide.
- Separer les upgrades de run des futurs debloquages persistants.

## Limites actuelles

Les upgrades ne doivent pas devenir un ensemble de flags disperses dans le joueur. Le systeme doit garder une source de verite claire.

