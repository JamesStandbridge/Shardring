# Toolchain

## Versions verrouillees

- Godot standard non-.NET : `4.7-stable`
- GUT : `9.7.1`, compatible Godot `4.7.x`
- gdtoolkit : `4.5.0`
- just : gestion des raccourcis projet

## Installation macOS

```bash
scripts/bootstrap_macos.sh
```

Le script utilise Homebrew pour installer `pipx`, `git-lfs` et `just` si
necessaire. Godot est telecharge dans `.tools/godot/4.7-stable/` et n'est pas
versionne.

Les templates d'export ne sont pas installes par defaut. Le script connait leur URL officielle pour le moment ou l'export desktop devient necessaire.

Les fichiers `.uid` generes par Godot 4.4+ sont des sidecars de ressources. Ils doivent etre versionnes avec les scripts et scenes correspondants.

## Verification

```bash
scripts/check.sh
```

Cette commande lance le format-check, le lint, le parse GDScript et les tests GUT en mode headless.

Les memes controles sont accessibles via :

```bash
just check
```
