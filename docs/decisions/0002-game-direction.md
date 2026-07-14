# 0002 - Direction jeu

## Decision

Structurer le jeu comme une survie roguelite 3D en arene.

Le projet doit privilegier une boucle de run claire, une difficulte progressive, des dangers lisibles, un terrain dynamique et des upgrades de run. La progression persistante est anticipee, mais differee.

## Raisons

- Les regles existantes decrivent deja une escalation de dangers, une arene destructible et des ameliorations achetables.
- La structure roguelite donne un cadre naturel a la rejouabilite et a l'ajout progressif de contenu.
- Differer la meta progression evite de complexifier trop tot les sauvegardes, l'economie long terme et l'equilibrage.

## Consequences

- La premiere monnaie est une monnaie de run, gagnee et depensee pendant une tentative.
- Une seconde monnaie cross-game, rare et persistante, sera prevue dans les docs et l'architecture mais pas implementee dans la premiere fondation jouable.
- Les systemes doivent etre data-driven autant que possible afin d'ajouter projectiles, hazards, upgrades et evenements sans reecrire la boucle principale.
- Le premier objectif reste une fondation jouable lisible, testable et durable avant toute production de contenu large.
