# 0001 - Moteur et langage

## Decision

Utiliser Godot `4.7-stable`, version standard non-.NET, avec GDScript type.

## Raisons

- Godot fournit un editeur stable, une boucle d'iteration rapide et un support macOS officiel.
- GDScript est le langage le plus integre a Godot et reduit la friction pour apprendre le moteur.
- Le typage explicite garde une discipline proche d'un projet logiciel classique.
- C# et GDExtension restent disponibles plus tard pour des besoins de performance ou d'integration precis.

## Consequences

- Le code applicatif doit rester fortement type et organise par domaines.
- Les outils de qualite GDScript font partie du bootstrap des le depart.
- Le projet privilegie la clarte de gameplay et la testabilite avant l'optimisation prematuree.

