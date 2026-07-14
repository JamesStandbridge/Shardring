    

Projet long terme d'un jeu 3D en vue a la troisieme personne, developpe avec Godot 4.7 et GDScript type.

## Demarrage

```bash
scripts/bootstrap_macos.sh
scripts/check.sh
```

Le bootstrap installe ou verifie les outils locaux, telecharge Godot 4.7 stable dans `.tools/`, installe GUT et configure Git LFS.

## Raccourcis

```bash
just
just check
just run
just playground
just editor
```

Les raccourcis `just` appellent les scripts officiels du projet et le binaire
Godot local. `GODOT_BIN` peut etre surcharge si necessaire.

## Documentation

- [Vision jeu](GAME.md)
- [Regles du jeu](RULES.md)
- [Architecture](docs/architecture.md)
- [Roadmap durable](docs/roadmap.md)
- [Ordre de developpement](docs/technical_design/development_order.md)
- [Direction artistique](docs/art/art_direction.md)
- [Workflow assets IA](docs/art/ai_asset_workflow.md)
- [Prompts assets IA](docs/art/asset_prompts.md)
- [Toolchain](docs/toolchain.md)
- [Decision moteur/langage](docs/decisions/0001-engine-and-language.md)
- [Decision direction jeu](docs/decisions/0002-game-direction.md)
- [Decision direction artistique](docs/decisions/0003-art-direction.md)
