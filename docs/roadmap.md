# Roadmap Durable

## Intention

Shardring doit avancer par fondations jouables. Chaque jalon ajoute un systeme
utile au jeu final, reste testable, et permet de ressentir le resultat dans
Godot avant de poursuivre.

Le but n'est pas de livrer vite un prototype, mais de reduire le risque de
mauvaise direction par des validations frequentes.

## Jalons

1. Runtime Foundation : etat de run minimal, boot stable, debug visible.
2. Player Foundation : deplacement third-person, course, saut, camera.
3. Arena Foundation : disque graybox, cellules polygonales irregulieres, materiaux officiels.
4. Projectile Foundation : configs `Resource`, spawner, projectile lisible.
5. Run Loop : start, playing, death, restart, timer de survie.
6. Danger Director Foundation : credits, couts, cadence globale et limites actives.
7. Stage Progression Foundation : levels infinis, maps reutilisables et exit gate.
8. Difficulty Foundation : intensite temporelle, unlocks progressifs, pilotage du Director.
9. Economy Foundation : pieces de run, mecanique d'achat non centrale, achat simple.
10. Upgrade Foundation : double saut puis glissade, effets decouples du player.
11. Terrain Hazards : lave, glace, effondrement, destruction, reconstruction.
12. AI Asset Pipeline : remplacement progressif des placeholders graybox.
13. Special Events : baril explosif, missiles, lasers, canon balls.
14. Meta Progression : monnaie persistante, save, progression cross-game.

## Regle De Validation

Chaque jalon doit fournir :

- une scene lancable ou un comportement visible dans la scene principale ;
- une configuration data-driven pour les valeurs de balancing ;
- des tests pour la logique deterministe ;
- une validation manuelle courte de ressenti.

Une etape n'est pas consideree terminee si elle oblige a reecrire son systeme
au jalon suivant.
