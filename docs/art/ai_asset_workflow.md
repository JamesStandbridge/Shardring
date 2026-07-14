# Workflow Assets IA

## Objectif

Produire des assets coherents sans competence manuelle Blender avancee. L'IA peut generer ou piloter Blender, mais les assets doivent rester simples, controlables et faciles a importer dans Godot.

## Pipeline

1. Choisir un asset dans `docs/art/asset_prompts.md`.
2. Generer un modele simple dans Blender par script ou outil IA.
3. Sauvegarder la source dans `assets/art/source_blender`.
4. Exporter une version Godot dans `assets/art/exports_godot`.
5. Tester l'asset dans Godot avec la camera de jeu avant d'ajouter des details.
6. Si l'asset est important, ajouter une capture ou reference dans `assets/art/reference`.

## Regles De Production

- Commencer par primitives Blender : cube, sphere, cylindre, cone, bevel, extrusion.
- Appliquer les transforms avant export.
- Nommer les objets en `snake_case`.
- Garder une echelle simple : 1 unite Godot = 1 metre approximatif.
- Preferer `.blend` comme source et `.glb` comme export runtime.
- Ne pas importer de textures externes sans verifier leur licence.
- Garder les materiaux nommes selon `docs/art/art_direction.md`.

## Nommage

- Source Blender : `asset_<nom>.blend`
- Export Godot : `asset_<nom>.glb`
- Concept image : `concept_<nom>.png`
- Materiau : `mat_<role>`

## Checklist Avant Integration

- Silhouette lisible de loin.
- Couleur conforme a la fonction gameplay.
- Pas de details inutiles.
- Pivot place logiquement.
- Taille coherente avec joueur et arene.
- Export `.glb` ouvert dans Godot sans erreur.
- Collision a generer dans Godot ou via suffixe dedie plus tard.

