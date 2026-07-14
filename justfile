set shell := ["bash", "-euo", "pipefail", "-c"]

godot_bin := env_var_or_default("GODOT_BIN", ".tools/godot/4.7-stable/Godot.app/Contents/MacOS/Godot")
player_playground := "res://src/dev/playgrounds/player_movement_playground.tscn"
arena_playground := "res://src/dev/playgrounds/arena_playground.tscn"
projectile_playground := "res://src/dev/playgrounds/projectile_playground.tscn"

alias b := bootstrap
alias c := check
alias t := test
alias r := run
alias e := editor
alias p := playground
alias a := arena
alias pr := projectiles

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

debug-collisions:
	"{{godot_bin}}" --path . --debug-collisions

format:
	gdformat src tests
