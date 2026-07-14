# Systeme Arena

## Role

L'arene est la surface principale de jeu. Elle doit devenir un danger dynamique : parties detruites, zones temporaires, reconstruction et contraintes de placement.

## Contrat futur

- Generer une plateforme grossierement circulaire decoupee en pieces non hexagonales.
- Garder un contour irregulier mais controle, sans casser la lecture generale du disque.
- Garder un relief leger et marchable, utile visuellement mais non punitif.
- Fournir des positions valides pour joueur, pieces, dangers, evenements et futurs achats temporaires.
- Exposer l'etat des cellules : normal, detruit, lave, glace, effondrement.
- Reconstruire les zones detruites selon le cycle de run.

## Limites actuelles

La premiere fondation runtime est implementee par `ArenaController`.

Etat actuel :

- generation deterministe depuis `ArenaConfig` ;
- grande arene grossierement circulaire, avec contour irregulier deterministe ;
- surface legerement ondulee, generee depuis `ArenaConfig` ;
- disque complet decoupe en cellules polygonales aleatoires ;
- aucune zone centrale speciale et aucun shop central ;
- cellules representees par `ArenaCell` ;
- collisions statiques sur la couche `terrain` ;
- API de placement pour spawn et positions valides.

Les hazards, destructions et reconstructions utiliseront ces cellules plus tard
au lieu de recreer leur propre representation de terrain.
