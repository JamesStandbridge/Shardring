Concept général
---------------
- Jeu 3D en vue à la troisième personne.
- Contrôle d’un personnage capable de courir et de sauter une fois.
- Difficulté progressive au fil du temps : plus de projectiles, terrains changeants, nouveaux types de projectiles.

Projectiles
-----------
Types :
- Projectiles variés (formes et vitesses différentes) traversant l’écran vers le joueur.
- Projectiles explosifs pré-contact, signalés via une animation.
- Missiles téléguidés lents, explosion après un temps donné.
- Lasers quasi instantanés, animation d’avertissement avant tir.
- Gros projectiles (“canon balls”) traversant le terrain de long en large.

Événements spéciaux :
- Apparition occasionnelle d’un ennemi porteur d’un baril explosif : il le lance près du joueur (zone d’explosion large, détruit le terrain).

Terrain
-------
Structure :
- Terrain circulaire, découpé en plusieurs parties de forme et de taille aléatoires (hors hexagones).
- Chaque partie est générée procéduralement avec des formes différentes.
- La plateforme principale est un disque d’épaisseur 1.

Modifications temporaires (aléatoires, durée variable) :
  - Effondrement de certaines parties.
  - Certaines zones deviennent de la lave (mort si on marche dessus).
  - Certaines zones deviennent de la glace (surface glissante).

Dynamique :
- Le terrain peut être détruit (par certaines mécaniques) et se reconstruit automatiquement toutes les 30 secondes.
- Marcher sur un terrain détruit tue le joueur.

Monnaie & améliorations
-----------------------
- Des pièces (monnaie du jeu) apparaissent rarement et aléatoirement sur la carte.
- La mécanique d'apparition du shop ou des achats sera définie plus tard.
- Le shop n'est pas permanent et n'est pas placé au centre du terrain.
- Améliorations prévues :
  - Double saut : 20 pièces
  - Glissade rapide : 50 pièces
