# Systeme Save

## Role

Le systeme de sauvegarde persiste les donnees cross-game : monnaie rare, debloquages futurs et versions de donnees.

## Contrat futur

- Charger une sauvegarde absente comme un profil neuf.
- Versionner le format pour permettre les migrations.
- Ne jamais persister la monnaie de run.
- Isoler les erreurs de sauvegarde de la boucle de jeu active.

## Limites actuelles

Aucune sauvegarde n'est implementee dans cette passe. Le domaine existe pour empecher la progression persistante de se melanger avec l'economie de run.

