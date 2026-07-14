# Asset Sourcing Shortlist

Date de recherche : 2026-07-14.

## Objectif

Remplacer les placeholders actuels par une base visuelle plus professionnelle,
sans bloquer le gameplay et sans introduire de risque de licence.

La priorite V1 est de trouver une source coherente pour :

- le joueur ;
- le chaser explosif ;
- le lanceur/turret ;
- le projectile simple ;
- la porte de sortie ;
- les materiaux d'arene et VFX simples.

## Regle De Selection

- Priorite aux assets CC0 avec usage commercial explicite.
- Preferer des packs coherents plutot qu'un collage de modeles isoles.
- Les assets doivent etre nettoyables dans Blender et testables dans
  `art_review_playground`.
- Les configs runtime doivent rester branchees sur des wrappers Godot, jamais
  sur des GLB bruts.
- Les assets IA ou marketplace a licence variable sont exclus de cette V1.

## Sources Licences Verifiees

- Kenney : les assets des pages d'assets sont CC0, utilisables en projet
  commercial, attribution non requise.
  Source : https://kenney.nl/support
- Quaternius : les packs retenus annoncent CC0 et usage personnel/commercial.
  Source : https://quaternius.com/
- Poly Haven : textures, HDRI et modeles sous CC0.
  Source : https://polyhaven.com/license

## Shortlist Recommandee

### Sources Supplementaires Solides

**KayKit**

- URL : https://kaylousberg.itch.io/
- Licence : plusieurs packs annoncent CC0 ; verifier pack par pack avant
  import.
- Usage Shardring : tres bonne source secondaire pour personnages, props,
  portes, donjons stylises, bits sci-fi et assets modulaires.
- Raison : style plus propre et plus moderne que beaucoup de packs gratuits,
  souvent compatible Godot via `.gltf`/`.fbx`.
- Attention : certains packs sont payants ou ont des tiers source `.blend`.
  Toujours documenter le pack exact dans le manifest.

**Quaternius - Universal Animation Library**

- URL : https://quaternius.com/packs/universalanimationlibrary.html
- Licence : CC0.
- Usage Shardring : locomotion, sprint, death, emotes, animations a retargeter
  sur le joueur ou des ennemis humanoides.
- Raison : peut ameliorer rapidement le ressenti sans changer les modeles.

**Quaternius - Universal Animation Library 2**

- URL : https://quaternius.com/packs/universalanimationlibrary2.html
- Licence : CC0.
- Usage Shardring : parkour, zombie locomotion, mouvements plus varies,
  comportements d'ennemis futurs.
- Raison : utile pour enrichir l'animation systemique long terme.

**Adobe Mixamo**

- URL : https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- Licence : royalty-free pour projets personnels, commerciaux et non-profit
  selon la FAQ Adobe, avec compte Adobe requis.
- Usage Shardring : solution de secours pour animations humanoides.
- Attention : ce n'est pas CC0 ; ne pas redistribuer les assets comme pack
  standalone. A documenter comme source externe non-CC0 si utilise.

**Synty POLYGON**

- URL : https://syntystore.com/
- Licence : payante/procuree, a verifier au moment de l'achat.
- Usage Shardring : option premium si les packs CC0 ne suffisent pas.
- Raison : gros saut qualitatif possible, grande coherence de gamme.
- Attention : risque de style reconnaissable/generique et cout de licence.
  Ne pas melanger avec trop de CC0 stylises sans direction claire.

### Pack Principal Conseille

**Quaternius - Toon Shooter Game Kit**

- URL : https://quaternius.com/packs/toonshootergamekit.html
- Licence : CC0.
- Formats : FBX, OBJ, Blend, glTF.
- Usage Shardring : base coherente pour joueur, ennemis simples, props et
  style arcade third-person.
- Raison : c'est la meilleure base unique pour remplacer rapidement les
  placeholders par un rendu plus professionnel sans changer tout le pipeline.

### Joueur

Option A - **Quaternius - Toon Shooter Game Kit**

- URL : https://quaternius.com/packs/toonshootergamekit.html
- Usage : personnage joueur principal, animations de course/saut/idle.
- Avantage : style plus proche arcade/action que les placeholders actuels.

Option B - **Kenney - Animated Characters Protagonists**

- URL : https://kenney.nl/assets/animated-characters-protagonists
- Licence : CC0.
- Usage : alternative joueur si les personnages Quaternius sont trop armes ou
  trop shooter.

Option C - **KayKit - Character Pack : Adventurers**

- URL : https://kaylousberg.itch.io/kaykit-adventurers
- Licence : a verifier sur la page du pack au moment du telechargement.
- Usage : alternative stylisee, riggee/animee, potentiellement plus propre
  pour un joueur non-shooter.

Option D - **Quaternius - Universal Base Characters**

- URL : https://quaternius.com/packs/universalbasecharacters.html
- Licence : CC0.
- Usage : base humanoide personnalisable, compatible avec les animations
  Quaternius Universal Animation Library.
- Raison : meilleure option long terme si on veut une pipeline d'animation
  retargetable propre.

### Chaser Explosif

Option A - **Quaternius - Cute Animated Monsters Pack**

- URL : https://quaternius.com/packs/cutemonsters.html
- Licence : CC0.
- Usage : base de silhouette pour chaser, a recolorer orange danger et
  simplifier en Blender.
- Attention : garder le cote "danger explosif", ne pas rendre l'ennemi trop
  mignon ou peu menacant.

Option B - **Quaternius - Animated Monster Pack**

- URL : https://quaternius.com/packs/animatedmonster.html
- Licence : CC0.
- Usage : alternative plus simple, moins variee, mais facile a evaluer.

Option C - **KayKit - Character Pack : Skeletons**

- URL : https://godotengine.org/asset-library/asset?user=KayKit+Game+Assets
- Licence : CC0 indiquee dans la Godot Asset Library pour les packs KayKit
  listes.
- Usage : base d'ennemi simple si on veut rester sur du Godot-friendly.
- Attention : theme squelette a eviter si la map ne le justifie pas.

### Lanceur / Turret

Option A - **Quaternius - Cyberpunk Game Kit**

- URL : https://quaternius.com/packs/cyberpunkgamekit.html
- Licence : CC0.
- Usage : turrets, pieces mecaniques, base de lanceur lisible.
- Raison : contient des elements plus techniques et des turrets, meilleure
  direction pour un lanceur de danger que nos primitives actuelles.

Option B - **Quaternius - Sci-Fi Essentials Kit**

- URL : https://quaternius.com/packs/scifiessentialskit.html
- Licence : CC0.
- Usage : robots, guns, props sci-fi, potentiellement Godot-ready.
- Attention : risque de tirer la DA vers trop sci-fi si non recolore/nettoye.

Option C - **Kenney - Tower Defense Kit**

- URL : https://kenney.nl/assets/tower-defense-kit
- Licence : CC0.
- Usage : silhouettes de tourelles simples.
- Attention : style medieval/castle, donc a utiliser seulement comme base de
  forme ou a fortement restyliser.

Option D - **T Allen Studios - Turret Pack 01**

- URL : https://itch.io/game-assets/free/tag-3d/tag-science-fiction?page=2
- Licence : a verifier sur la page exacte avant import.
- Usage : option gratuite specialisee turret.
- Attention : ne pas importer sans trace de licence explicite ; Itch liste
  beaucoup de contenus avec licences variables.

Option E - **Synty POLYGON Sci-Fi / Prototype**

- URL : https://syntystore.com/
- Licence : payante/procuree, a verifier avant achat.
- Usage : lanceur/turret premium si les options CC0 restent trop faibles.

### Projectile Simple

Option A - **Kenney - Blaster Kit**

- URL : https://kenney.nl/assets/blaster-kit
- Licence : CC0.
- Usage : props d'armes, cibles, projectiles ou bases de mesh lisible.

Option B - Mesh interne + VFX Godot

- Usage : conserver un mesh tres simple pour les projectiles high-volume, mais
  produire un vrai materiau emission/trail.
- Raison : le projectile doit rester tres lisible et peu couteux ; un bon VFX
  vaut souvent mieux qu'un modele detaille.

### Porte De Sortie

Option A - **Kenney - Mini Arena**

- URL : https://kenney.nl/assets/mini-arena
- Licence : CC0.
- Usage : elements d'arche/porte stylises a adapter.

Option B - **Kenney - Modular Dungeon Kit**

- URL : https://kenney.nl/assets/modular-dungeon-kit
- Licence : CC0 annoncee sur les pages Kenney.
- Usage : porte/arche plus lisible comme sortie.
- Attention : risque de theme dungeon ; a recolorer cyan/interactable.

Option C - **KayKit - Dungeon Remastered Pack**

- URL : https://kaylousberg.itch.io/kaykit-dungeon-remastered
- Licence : a verifier sur la page du pack au moment du telechargement.
- Usage : portes, arches, battants, props de sortie.
- Raison : tres bon candidat pour remplacer notre porte actuelle sans repartir
  de primitives.

Option D - **KayKit - Space Base Bits**

- URL : https://kaylousberg.com/game-assets
- Licence : a verifier pack par pack.
- Usage : porte/interactable plus arcade/sci-fi, potentiellement meilleure
  pour une sortie de niveau cyan.

### Arena / Materials / Ambiance

Option A - **Kenney - Prototype Textures**

- URL : https://kenney.nl/assets/prototype-textures
- Licence : CC0.
- Usage : lisibilite gameplay, tests arene et contraste.

Option B - **Poly Haven**

- URL : https://polyhaven.com/textures/
- Licence : CC0.
- Usage : textures de sol stylisees apres reduction du detail et recolor.
- Attention : beaucoup de materiaux sont photorealistes ; a styliser dans
  Blender/Godot pour rester arcade.

Option C - **KayKit - Prototype Bits**

- URL : https://kaylousberg.itch.io/prototype-bits
- Licence : CC0 annoncee sur la page.
- Usage : props simples, supports, obstacles, blocs de test propres.

Option D - **Kenney - Mini Arena**

- URL : https://kenney.nl/assets/mini-arena
- Licence : CC0.
- Usage : arche/ambiance arena, pieces de decor stylisees.

### VFX / Shaders

Option A - **Kenney - Particle Pack**

- URL : https://kenney.nl/assets/particle-pack
- Licence : CC0.
- Usage : sprites VFX 2D pour impacts, smoke, sparks, warning helpers.

Option B - **Godot Ultimate Toon Shader**

- URL : https://itch.io/game-assets/assets-cc0/tag-godot
- Licence : a verifier sur la page exacte avant usage.
- Usage : base shader stylisee si l'on veut une coherence plus marquee.
- Attention : un shader externe ajoute une dependance technique ; a preferer
  apres stabilisation des assets.

Option C - **VFX Godot packs Itch.io**

- URL : https://itch.io/game-assets/free/tag-godot/tag-vfx
- Licence : variable.
- Usage : inspiration ou base ponctuelle pour explosions/impacts.
- Attention : la plupart des VFX devront quand meme etre adaptes a notre
  architecture high-volume.

## Selection V1 Proposee

Pour remplacer rapidement les placeholders sans casser la coherence :

1. Telecharger **Quaternius Toon Shooter Game Kit** comme pack principal.
2. Telecharger **Quaternius Cyberpunk Game Kit** pour trouver une turret.
3. Telecharger **Quaternius Cute Animated Monsters Pack** pour le chaser.
4. Telecharger **Kenney Blaster Kit** pour props/projectile/targets.
5. Telecharger **Quaternius Universal Animation Library** si le joueur ou les
   ennemis humanoides doivent passer par une animation retargetable.
6. Evaluer **KayKit Dungeon Remastered** pour remplacer la porte actuelle.
7. Garder **Poly Haven** seulement pour HDRI/textures d'ambiance, pas pour les
   personnages.

Cette selection limite le nombre de styles melanges tout en couvrant les
besoins actuels.

## Selection Alternative Si Le Style Quaternius Ne Convient Pas

1. **KayKit Character Pack : Adventurers** pour le joueur.
2. **KayKit Dungeon Remastered** pour porte/props.
3. **KayKit Prototype Bits** pour props neutres.
4. **Kenney Blaster Kit** pour projectile/cible.
5. **Kenney Particle Pack** pour VFX simples.

Cette voie est probablement plus goofy/stylisee, mais moins directement
orientee action roguelite que Quaternius.

## Option Payante A Garder Sous Le Coude

Si les assets gratuits ne passent pas la quality bar dans `just art-review`,
evaluer une acquisition Synty POLYGON ciblee :

- un pack prototype/generaliste pour joueur/props ;
- un pack sci-fi/cyberpunk pour turrets et dangers ;
- eventuellement un pack VFX si compatible Godot via export.

Ne pas acheter plusieurs packs avant d'avoir valide une seule scene de revue :
risque de depense inutile et de DA trop generique.

## Prochaine Passe Technique

Quand les packs sont choisis :

1. Copier les archives dans `assets/art/source_external/`.
2. Extraire seulement les modeles candidats dans un sous-dossier par source.
3. Creer une scene de revue ou remplacer les wrappers un par un.
4. Ajouter les entrees candidates dans `assets/art/asset_manifest.json`.
5. Normaliser dans Blender : scale, orientation, pivots, sockets.
6. Exporter vers `assets/art/exports_godot/`.
7. Tester dans `just art-review`.

## Passe Locale Realisee

Les packs `Toon Shooter`, `Cyberpunk` et `Cute Animated Monsters` ont ete
extraits dans `assets/art/source_external/quaternius/`.

Le catalogue complet est genere par `scripts/art/catalog_external_assets.py` et
ecrit dans `assets/art/source_external/quaternius/asset_catalog.json`.

Les cinq candidats primaires ont ete prepares en `candidate_review` :

- `player_quaternius_robot_2legs` ;
- `chaser_quaternius_cyclops` ;
- `launcher_quaternius_turret_cannon` ;
- `projectile_quaternius_grenade` ;
- `exit_gate_quaternius_door`.

Leur revue se fait via `just external-art-review`.

Analyse visuelle : les assets humanoides `Character_Soldier` et `Character`
ne sont pas retenus comme joueur, car ils exposent des formes de rig/equipement
parasites en import. Le candidat joueur local est donc temporairement le robot
`Enemy_2Legs`, a recolorer avant integration gameplay.
