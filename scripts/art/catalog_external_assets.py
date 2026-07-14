#!/usr/bin/env python3
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT_DIR / "assets" / "art" / "source_external" / "quaternius"
OUTPUT_PATH = SOURCE_ROOT / "asset_catalog.json"

PACKS = {
	"toon_shooter_game_kit": {
		"display_name": "Quaternius Toon Shooter Game Kit",
		"source_url": "https://quaternius.com/packs/toonshootergamekit.html",
		"license": "CC0 1.0 Universal; documented from Quaternius source page",
	},
	"cyberpunk_game_kit": {
		"display_name": "Quaternius Cyberpunk Game Kit",
		"source_url": "https://quaternius.com/packs/cyberpunkgamekit.html",
		"license": "CC0 1.0 Universal; archive includes License.txt",
	},
	"cute_animated_monsters": {
		"display_name": "Quaternius Cute Animated Monsters",
		"source_url": "https://quaternius.com/packs/cutemonsters.html",
		"license": "CC0 1.0 Universal; documented from Quaternius source page",
	},
}

MODEL_EXTENSIONS = {".blend", ".fbx", ".gltf", ".glb", ".obj"}
TEXTURE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".tga"}
PREVIEW_NAMES = {"preview.jpg", "preview.png", "thumbnail.jpg", "thumbnail.png"}

PRIMARY_SELECTION = {
	"player": "cyberpunk_game_kit:enemy_2legs",
	"chaser": "cute_animated_monsters:cyclops",
	"launcher": "cyberpunk_game_kit:turret_cannon",
	"projectile": "toon_shooter_game_kit:grenade",
	"exit_gate": "cyberpunk_game_kit:door",
}

BACKUP_SELECTIONS = {
	"player": [
		"cyberpunk_game_kit:character",
		"toon_shooter_game_kit:character_hazmat",
		"toon_shooter_game_kit:character_soldier",
	],
	"chaser": [
		"cute_animated_monsters:demon",
		"cute_animated_monsters:alien",
		"cute_animated_monsters:greendemon",
		"cute_animated_monsters:mushroom",
	],
	"launcher": [
		"cyberpunk_game_kit:turret_gun",
		"cyberpunk_game_kit:turret_gundouble",
	],
	"projectile": ["toon_shooter_game_kit:firegrenade"],
	"exit_gate": [
		"cyberpunk_game_kit:platform_2x2",
		"cyberpunk_game_kit:rail_long",
		"cyberpunk_game_kit:light_square",
	],
}


def main() -> None:
	if not SOURCE_ROOT.exists():
		raise SystemExit(f"Missing extracted source root: {SOURCE_ROOT}")

	catalog = {
		"schema_version": 1,
		"source_root": str(SOURCE_ROOT.relative_to(ROOT_DIR)),
		"generated_by": "scripts/art/catalog_external_assets.py",
		"packs": [],
		"primary_selection": PRIMARY_SELECTION,
		"backup_selections": BACKUP_SELECTIONS,
	}

	for pack_id in sorted(PACKS.keys()):
		catalog["packs"].append(catalog_pack(pack_id))

	OUTPUT_PATH.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	print(f"catalog ok: {OUTPUT_PATH.relative_to(ROOT_DIR)}")


def catalog_pack(pack_id: str) -> dict:
	pack_dir = SOURCE_ROOT / pack_id
	if not pack_dir.exists():
		raise SystemExit(f"Missing extracted pack: {pack_dir}")

	grouped_models: dict[str, dict] = {}
	textures: list[str] = []
	previews: list[str] = []
	raw_counts: defaultdict[str, int] = defaultdict(int)

	for path in sorted(pack_dir.rglob("*")):
		if not path.is_file():
			continue
		extension = path.suffix.lower()
		raw_counts[extension or "<none>"] += 1
		relative_path = str(path.relative_to(ROOT_DIR))
		if extension in MODEL_EXTENSIONS:
			asset_key = normalize_asset_key(path.stem)
			entry = grouped_models.setdefault(
				asset_key,
				{
					"id": f"{pack_id}:{asset_key}",
					"asset_name": path.stem,
					"pack_id": pack_id,
					"role_guess": guess_role(pack_id, path),
					"formats": {},
					"recommended_source_path": "",
					"notes": [],
				},
			)
			entry["formats"].setdefault(extension.removeprefix("."), []).append(relative_path)
		elif extension in TEXTURE_EXTENSIONS:
			if path.name.lower() in PREVIEW_NAMES:
				previews.append(relative_path)
			else:
				textures.append(relative_path)

	assets = sorted(grouped_models.values(), key=lambda item: (item["role_guess"], item["asset_name"]))
	for asset in assets:
		asset["recommended_source_path"] = choose_recommended_source(asset["formats"])
		if asset["id"] in PRIMARY_SELECTION.values():
			asset["notes"].append("primary_v1_candidate")
		for role, backup_ids in BACKUP_SELECTIONS.items():
			if asset["id"] in backup_ids:
				asset["notes"].append(f"backup_v1_candidate:{role}")

	return {
		"id": pack_id,
		"display_name": PACKS[pack_id]["display_name"],
		"source_url": PACKS[pack_id]["source_url"],
		"license": PACKS[pack_id]["license"],
		"root_path": str(pack_dir.relative_to(ROOT_DIR)),
		"raw_counts": dict(sorted(raw_counts.items())),
		"preview_paths": sorted(previews),
		"texture_count": len(textures),
		"assets": assets,
	}


def normalize_asset_key(name: str) -> str:
	return name.strip().replace(" ", "_").replace("-", "_").lower()


def guess_role(pack_id: str, path: Path) -> str:
	name = normalize_asset_key(path.stem)
	path_text = str(path).lower()
	if "turret" in name:
		return "launcher"
	if name in {"door"}:
		return "exit_gate"
	if name == "character" and pack_id == "cyberpunk_game_kit":
		return "player"
	if name == "enemy_2legs" and pack_id == "cyberpunk_game_kit":
		return "player"
	if "character" in name and pack_id == "toon_shooter_game_kit":
		return "player"
	if pack_id == "cute_animated_monsters":
		return "chaser" if name in {"cyclops", "demon", "alien", "greendemon", "mushroom"} else "future_enemy"
	if any(token in name for token in ["grenade", "rocket", "cannon", "landmine", "barrel"]):
		return "projectile"
	if any(token in path_text for token in ["enemy", "character"]):
		return "future_enemy"
	return "prop"


def choose_recommended_source(formats: dict) -> str:
	for preferred_format in ["gltf", "blend", "fbx", "glb", "obj"]:
		paths = formats.get(preferred_format, [])
		if paths:
			return sorted(paths)[0]
	return ""


if __name__ == "__main__":
	main()
