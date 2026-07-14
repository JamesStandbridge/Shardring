# Shardring - Vision Jeu

## Pitch

Le jeu est une survie roguelite 3D en arene, en vue a la troisieme personne. Le joueur survit sur une plateforme circulaire procedurale qui se degrade, change d'etat et se reconstruit pendant que des vagues de dangers de plus en plus complexes cherchent a le forcer a bouger.

Le coeur du jeu n'est pas de combattre directement, mais de lire l'arene, anticiper les signaux de danger, exploiter le mouvement et choisir les bonnes ameliorations au bon moment.

## Piliers

- Mouvement precis : courir, sauter, esquiver et se repositionner doivent etre fiables.
- Lisibilite du danger : chaque projectile ou evenement dangereux doit avoir une silhouette, un timing et un signal reconnaissables.
- Terrain vivant : l'arene est une ressource, une menace et un minuteur implicite.
- Pression progressive : la difficulte monte par intensite, frequence, combinaison et nouveaux types de dangers.
- Decisions de run : les pieces et upgrades doivent creer des choix simples mais consequents.
- Projet evolutif : les systemes doivent accepter de nouveaux dangers, upgrades, evenements et modes sans reorganisation majeure.

## Direction Visuelle

La direction artistique est techno-rituelle stylisee : pierre noire, metal graphite, lignes lumineuses et dangers geometriques colores. Elle doit rester simple pour etre produite par IA et lisible depuis une camera third-person.

Chaque couleur importante a une fonction gameplay. Les dangers sont rouges, orange ou magenta. Les interactables temporaires peuvent utiliser le cyan. La monnaie de run est or. La monnaie cross-game est blanc violet.

## Boucle De Jeu

1. Le joueur commence une run au centre de l'arene.
2. Les premiers dangers testent le mouvement de base.
3. Des pieces de run apparaissent rarement sur la carte.
4. Le joueur prend un risque pour collecter, puis choisit plus tard comment depenser selon une mecanique d'achat a definir.
5. La difficulte augmente, le terrain change ou se detruit, puis se reconstruit par cycles.
6. La run se termine a la mort du joueur.
7. Les resultats de run pourront plus tard attribuer une monnaie cross-game rare.

## Progression

Deux monnaies sont prevues.

- Monnaie de run : frequente, gagnee pendant une partie, depensee via une mecanique d'achat future, remise a zero a chaque run.
- Monnaie cross-game : rare, persistante entre les parties, reservee aux systemes de progression long terme.

La premiere version jouable doit se concentrer sur la monnaie de run. La monnaie cross-game doit etre anticipee dans l'architecture mais pas implementee avant que la boucle principale soit stable.

## Premiere Fondation Jouable

La premiere fondation jouable n'est pas un prototype jetable. Elle doit
installer les bases durables du jeu tout en restant lancable et observable.

Elle doit contenir :

- une arene circulaire simple ;
- un joueur third-person capable de courir et sauter ;
- au moins un projectile traversant l'arene ;
- une condition de mort claire ;
- un redemarrage de run ;
- une base de difficulte temporelle ;
- une piece de run et une base pour brancher les ameliorations plus tard.

Chaque etape doit garder le projet jouable, mais aucun systeme ne doit etre
code comme un raccourci temporaire difficile a remplacer.

## Vocabulaire Officiel

- Run : une tentative complete, du lancement a la mort/recompense.
- Danger : tout element qui peut tuer ou contraindre le joueur.
- Hazard : etat temporaire de terrain, comme lave, glace ou effondrement.
- Projectile : danger mobile ou instantane provenant de l'exterieur ou d'un ennemi.
- Upgrade : amelioration achetee pendant une run.
- Meta progression : progression persistante entre les runs, a differer.
- Intensity : niveau abstrait de pression utilise par le systeme de difficulte.
