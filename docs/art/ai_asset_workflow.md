# Workflow Assets IA

## Objectif

Produire des assets coherents sans demander au developpeur de designer
manuellement. Le pipeline n'est plus "generer des primitives et les utiliser en
final" : il doit sourcer, nettoyer, tracer et valider les assets.

## Pipeline Principal

Le pipeline officiel est hybride.

1. Chercher une base CC0/procuree ou generer une variante IA licenciee.
2. Stocker la source dans `assets/art/source_external/` ou
   `assets/art/source_ai/`.
3. Nettoyer dans Blender : echelle, orientation, pivot, sockets, materiaux.
4. Sauvegarder le fichier de travail dans `assets/art/working_blender/`.
5. Exporter le GLB dans `assets/art/exports_godot/`.
6. Creer une scene wrapper dans `src/visual/assets/`.
7. Renseigner `assets/art/asset_manifest.json`.
8. Tester dans `just art-review`, puis lancer `just check`.

`just art-kit` reste disponible pour regenerer les placeholders actuels, mais
ces assets sont deprecies pour le rendu final.

## Regles De Production

- Ne pas traiter des primitives scriptees comme assets finaux.
- Joindre en un seul mesh les assets utilises par `MultiMesh` lorsque le runtime
  en a besoin.
- Garder `1 Godot unit = 1 metre approximatif`.
- Appliquer les transforms avant export.
- Nommer objets et fichiers en `snake_case`.
- Preferer source externe/IA + `.blend` de travail + `.glb` runtime + wrapper.
- Ne pas importer de textures externes sans verifier leur licence.
- Garder les dangers en rouge, orange ou magenta, mais sous forme de VFX
  propres et pas de traits debug.
- Garder les assets lisibles avant d'ajouter de l'humour.

## Nommage

- Source externe : dossier ou archive sous `assets/art/source_external/`
- Source IA : dossier sous `assets/art/source_ai/`
- Travail Blender : `asset_<nom>.blend`
- Export Godot : `asset_<nom>.glb`
- Scene wrapper : `<nom>_arcade_wrapper.tscn`
- Concept image : `concept_<nom>.png`
- Materiau : `mat_arcade_<role>`
- Script generateur : `generate_<kit_ou_asset>.py`

## Checklist Avant Integration

- Silhouette lisible en moins de 2 secondes.
- Couleur conforme a la fonction gameplay.
- Danger plus visible que le detail comique.
- Pivot place logiquement.
- `VisualRoot` et `GroundAnchor` existent dans le wrapper.
- Les lanceurs declarent un `MuzzleSocket`.
- Taille coherente avec collision et hurtbox.
- Export `.glb` charge dans Godot.
- Manifest asset a jour.
