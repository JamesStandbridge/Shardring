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
- habillage visuel low-poly Kenney via `ArenaThemeConfig` : textures PNG
  world-space par theme, detail map subtile, tranche de plateau et bordure
  exterieure ;
- les cellules restent des unites de gameplay, mais leurs limites internes ne
  sont pas affichees en etat normal pour garder un sol naturel ;
- le terrain normal ne doit pas ressembler a une mosaique de couleurs par
  cellule : les variations sont portees par des textures de matiere continues
  en coordonnees monde, pas par une couleur aleatoire par cellule ;
- les couleurs fortes sont reservees aux hazards lisibles : warning, lave,
  glace, collapse, destroyed et rebuilding ;
- les hazards utilisent des textures d'effet dediees et animees par shader :
  warning strie, lave fluide, glace craquelee, effondrement fissure ;
- aucune zone centrale speciale et aucun shop central ;
- cellules representees par `ArenaCell` ;
- etats de cellules modifiables par API : `NORMAL`, `WARNING`, `LAVA`, `ICE`,
  `COLLAPSING`, `DESTROYED`, `REBUILDING` ;
- collisions statiques sur la couche `terrain` ;
- API de placement pour spawn et positions valides.
- cellule `DESTROYED` masquee avec collision desactivee ; les autres etats
  restent marchables.

Les hazards, destructions et reconstructions utilisent ces cellules au lieu de
recreer leur propre representation de terrain.
