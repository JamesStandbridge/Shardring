#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT_DIR / "assets" / "art" / "source_external" / "kenney"
CATALOG_PATH = SOURCE_ROOT / "asset_catalog.json"

PACKS = {
	"blocky_characters": {
		"display_name": "Kenney Blocky Characters",
		"source_url": "https://kenney.nl/assets/blocky-characters",
		"archive_path": "~/Downloads/kenney_blocky-characters_20.zip",
		"theme_fit": "primary_player_candidates",
	},
	"cube_pets": {
		"display_name": "Kenney Cube Pets",
		"source_url": "https://kenney.nl/assets/cube-pets",
		"archive_path": "~/Downloads/kenney_cube-pets_1.0.zip",
		"theme_fit": "goofy_actor_enemy_candidates",
	},
	"factory_kit": {
		"display_name": "Kenney Factory Kit",
		"source_url": "https://kenney.nl/assets/factory-kit",
		"archive_path": "~/Downloads/kenney_factory-kit_3.0.zip",
		"theme_fit": "arena_props_hazards_gate_candidates",
	},
	"graveyard_kit": {
		"display_name": "Kenney Graveyard Kit",
		"source_url": "https://kenney.nl/assets/graveyard-kit",
		"archive_path": "~/Downloads/kenney_graveyard-kit_5.0.zip",
		"theme_fit": "future_spooky_map_candidates",
	},
	"pirate_kit": {
		"display_name": "Kenney Pirate Kit",
		"source_url": "https://kenney.nl/assets/pirate-kit",
		"archive_path": "~/Downloads/kenney_pirate-kit.zip",
		"theme_fit": "cannon_projectile_gate_map_candidates",
	},
	"platformer_kit": {
		"display_name": "Kenney Platformer Kit",
		"source_url": "https://kenney.nl/assets/platformer-kit",
		"archive_path": "~/Downloads/kenney_platformer-kit.zip",
		"theme_fit": "arena_tile_and_readable_hazard_candidates",
	},
}

FORMAT_DIRS = {
	"glb": "GLB format",
	"fbx": "FBX format",
	"obj": "OBJ format",
}

ROLE_KEYWORDS = {
	"launcher": (
		"cannon",
		"turret",
		"machine",
		"robot-arm",
		"crane",
		"blaster",
		"catapult",
	),
	"projectile": (
		"cannon-ball",
		"ball",
		"bomb",
		"barrel",
		"arrow",
		"crate",
		"box",
		"cog",
	),
	"exit_gate": (
		"door",
		"gate",
		"portal",
		"crypt-door",
		"fence-gate",
	),
	"arena": (
		"floor",
		"block",
		"platform",
		"catwalk",
		"road",
		"terrain",
		"ground",
	),
	"hazard": (
		"spike",
		"lava",
		"warning",
		"conveyor",
		"cog",
		"fire",
		"hole",
		"trap",
	),
	"prop": (
		"tree",
		"rock",
		"fence",
		"barrel",
		"crate",
		"light",
		"sign",
		"pumpkin",
		"grave",
		"wall",
		"pipe",
		"rail",
	),
}

RECOMMENDED = {
	"player": (
		"blocky_characters:character-a",
		"blocky_characters:character-c",
		"blocky_characters:character-e",
		"blocky_characters:character-f",
	),
	"chaser": (
		"cube_pets:animal-bee",
		"cube_pets:animal-crab",
		"cube_pets:animal-caterpillar",
		"cube_pets:animal-dog",
		"cube_pets:animal-fox",
	),
	"launcher": (
		"pirate_kit:cannon",
		"pirate_kit:cannon-mobile",
		"factory_kit:machine",
		"factory_kit:robot-arm-a",
	),
	"projectile": (
		"pirate_kit:cannon-ball",
		"factory_kit:cog-a",
		"factory_kit:box-small",
		"factory_kit:arrow-basic",
	),
	"exit_gate": (
		"factory_kit:door-wide-closed",
		"factory_kit:door-wide-half",
		"pirate_kit:castle-gate",
		"graveyard_kit:fence-gate",
	),
	"arena": (
		"platformer_kit:block-grass",
		"platformer_kit:block-snow",
		"factory_kit:floor-large",
		"pirate_kit:platform",
	),
}


def rel(path: Path) -> str:
	return path.relative_to(ROOT_DIR).as_posix()


def read_license(pack_root: Path) -> str:
	license_path = pack_root / "License.txt"
	if not license_path.exists():
		return "CC0 1.0 Universal; Kenney license expected, local License.txt missing"

	text = license_path.read_text(encoding="utf-8", errors="replace")
	for line in text.splitlines():
		clean = line.strip()
		if clean.startswith("License:"):
			return "CC0 1.0 Universal; local Kenney License.txt"
	return "CC0 1.0 Universal; local Kenney License.txt"


def collect_assets(pack_id: str, pack_root: Path) -> list[dict]:
	models_root = pack_root / "Models"
	if not models_root.exists():
		return []

	names: set[str] = set()
	for format_dir in FORMAT_DIRS.values():
		for file_path in (models_root / format_dir).glob("*.*"):
			if file_path.is_file() and file_path.suffix.lower() in (".glb", ".fbx", ".obj"):
				names.add(file_path.stem)

	assets: list[dict] = []
	for asset_name in sorted(names):
		paths = {}
		for format_name, format_dir in FORMAT_DIRS.items():
			candidate = models_root / format_dir / f"{asset_name}.{format_name}"
			if candidate.exists():
				paths[format_name] = rel(candidate)

		preview = pack_root / "Previews" / f"{asset_name}.png"
		roles = guess_roles(pack_id, asset_name)
		key = f"{pack_id}:{asset_name}"
		assets.append(
			{
				"id": f"{pack_id}_{asset_name}".replace("-", "_"),
				"pack_id": pack_id,
				"asset_name": asset_name,
				"roles": roles,
				"recommended_for": recommended_roles_for(key),
				"preferred_runtime_source": paths.get("glb", paths.get("fbx", paths.get("obj", ""))),
				"paths": paths,
				"preview_png": rel(preview) if preview.exists() else "",
			}
		)
	return assets


def guess_roles(pack_id: str, asset_name: str) -> list[str]:
	lower_name = asset_name.lower()
	roles: list[str] = []

	if pack_id == "blocky_characters" and lower_name.startswith("character-"):
		roles.append("player_candidate")
		roles.append("npc_candidate")
	if pack_id == "cube_pets" and lower_name.startswith("animal-"):
		roles.append("chaser_candidate")
		roles.append("future_enemy")
	if pack_id == "graveyard_kit" and lower_name.startswith("character-"):
		roles.append("future_enemy")
		if lower_name in ("character-keeper",):
			roles.append("npc_candidate")

	for role, keywords in ROLE_KEYWORDS.items():
		if any(matches_keyword(lower_name, keyword) for keyword in keywords):
			roles.append(role)

	if lower_name == "cannon-ball" and "launcher" in roles:
		roles.remove("launcher")

	if not roles:
		roles.append("uncategorized")

	return sorted(set(roles))


def matches_keyword(asset_name: str, keyword: str) -> bool:
	if "-" in keyword:
		return (
			asset_name == keyword
			or asset_name.startswith(f"{keyword}-")
			or asset_name.endswith(f"-{keyword}")
			or f"-{keyword}-" in asset_name
		)

	tokens = asset_name.split("-")
	return keyword in tokens or asset_name.startswith(keyword)


def recommended_roles_for(key: str) -> list[str]:
	roles: list[str] = []
	for role, keys in RECOMMENDED.items():
		if key in keys:
			roles.append(role)
	return roles


def build_catalog() -> dict:
	packs = []
	all_assets = []
	for pack_id, metadata in PACKS.items():
		pack_root = SOURCE_ROOT / pack_id
		assets = collect_assets(pack_id, pack_root)
		license_text = read_license(pack_root)
		pack_entry = {
			"id": pack_id,
			"display_name": metadata["display_name"],
			"source_url": metadata["source_url"],
			"archive_path": metadata["archive_path"],
			"theme_fit": metadata["theme_fit"],
			"root_path": rel(pack_root) if pack_root.exists() else "",
			"license": license_text,
			"asset_count": len(assets),
			"preview_count": len(list((pack_root / "Previews").glob("*.png"))) if pack_root.exists() else 0,
		}
		packs.append(pack_entry)
		all_assets.extend(assets)

	role_counts: dict[str, int] = {}
	for asset in all_assets:
		for role in asset["roles"]:
			role_counts[role] = role_counts.get(role, 0) + 1

	recommendations = {}
	for role, keys in RECOMMENDED.items():
		recommendations[role] = [
			asset
			for asset in all_assets
			if f"{asset['pack_id']}:{asset['asset_name']}" in keys
		]

	return {
		"schema_version": 1,
		"source_kind": "kenney_cc0_local_archives",
		"source_root": rel(SOURCE_ROOT),
		"packs": packs,
		"summary": {
			"pack_count": len(packs),
			"asset_count": len(all_assets),
			"role_counts": dict(sorted(role_counts.items())),
		},
		"recommendations": recommendations,
		"assets": all_assets,
	}


def main() -> None:
	if not SOURCE_ROOT.exists():
		raise SystemExit(f"Kenney source root does not exist: {SOURCE_ROOT}")
	catalog = build_catalog()
	CATALOG_PATH.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	print(f"Wrote {CATALOG_PATH.relative_to(ROOT_DIR)}")
	print(
		f"Catalogued {catalog['summary']['asset_count']} assets from "
		f"{catalog['summary']['pack_count']} Kenney packs"
	)


if __name__ == "__main__":
	main()
