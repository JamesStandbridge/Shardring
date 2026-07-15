set shell := ["bash", "-euo", "pipefail", "-c"]

godot_bin := env_var_or_default("GODOT_BIN", ".tools/godot/4.7-stable/Godot.app/Contents/MacOS/Godot")
player_playground := "res://src/dev/playgrounds/player_movement_playground.tscn"
arena_playground := "res://src/dev/playgrounds/arena_playground.tscn"
projectile_playground := "res://src/dev/playgrounds/projectile_playground.tscn"
chaser_playground := "res://src/dev/playgrounds/chaser_enemy_playground.tscn"
hazard_playground := "res://src/dev/playgrounds/hazard_playground.tscn"
art_review_playground := "res://src/dev/playgrounds/art_review_playground.tscn"
blender_bin := env_var_or_default("BLENDER_BIN", "/Applications/Blender.app/Contents/MacOS/Blender")

alias b := bootstrap
alias c := check
alias t := test
alias r := run
alias e := editor
alias p := playground
alias a := arena
alias pr := projectiles
alias ch := chaser
alias hz := hazards
alias ak := art-kit
alias ar := art-review
alias kc := kenney-catalog
alias kva := kenney-v1-assets
alias tt := terrain-textures

default:
	@just --list

bootstrap:
	scripts/bootstrap_macos.sh

check:
	scripts/check.sh

test:
	scripts/run_tests.sh

import:
	"{{godot_bin}}" --headless --import --path .

run:
	"{{godot_bin}}" --path .

editor:
	"{{godot_bin}}" --editor --path .

playground:
	"{{godot_bin}}" --path . --scene "{{player_playground}}"

arena:
	"{{godot_bin}}" --path . --scene "{{arena_playground}}"

projectiles:
	"{{godot_bin}}" --path . --scene "{{projectile_playground}}"

chaser:
	"{{godot_bin}}" --path . --scene "{{chaser_playground}}"

hazards:
	"{{godot_bin}}" --path . --scene "{{hazard_playground}}"

art-review:
	"{{godot_bin}}" --path . --scene "{{art_review_playground}}"

kenney-catalog:
	python3 scripts/art/catalog_kenney_assets.py

kenney-v1-assets:
	"{{blender_bin}}" --background --python scripts/art/prepare_kenney_v1_assets.py

terrain-textures:
	python3 scripts/art/generate_terrain_textures.py

debug-collisions:
	"{{godot_bin}}" --path . --debug-collisions

art-kit:
	"{{blender_bin}}" --background --python scripts/art/generate_toybox_kit.py

format:
	gdformat src tests
