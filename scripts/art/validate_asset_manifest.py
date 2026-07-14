#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT_DIR / "assets" / "art" / "asset_manifest.json"
CONFIG_PATHS_WITHOUT_RAW_GLB = [
	ROOT_DIR / "src" / "data" / "projectiles" / "basic_linear_projectile.tres",
	ROOT_DIR / "src" / "data" / "projectiles" / "basic_single_shot_launcher.tres",
	ROOT_DIR / "src" / "data" / "enemies" / "basic_explosive_chaser.tres",
	ROOT_DIR / "src" / "main" / "main.tscn",
]
REQUIRED_FIELDS = [
	"id",
	"category",
	"status",
	"source_kind",
	"source_url",
	"license",
	"raw_path",
	"working_blend",
	"export_glb",
	"wrapper_scene",
	"preview_png",
]


def main() -> None:
	errors: list[str] = []
	if not MANIFEST_PATH.exists():
		raise SystemExit(f"Missing asset manifest: {MANIFEST_PATH}")

	manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
	assets = manifest.get("assets", [])
	if not isinstance(assets, list) or len(assets) == 0:
		errors.append("assets must be a non-empty list")

	seen_ids: set[str] = set()
	for index, asset in enumerate(assets):
		asset_id = str(asset.get("id", f"#{index}"))
		if asset_id in seen_ids:
			errors.append(f"{asset_id}: duplicate asset id")
		seen_ids.add(asset_id)
		errors.extend(validate_asset(asset_id, asset))

	errors.extend(validate_no_runtime_configs_reference_raw_glb())

	if errors:
		for error in errors:
			print(f"asset manifest error: {error}")
		raise SystemExit(1)

	print(f"asset manifest ok: {len(assets)} assets")


def validate_asset(asset_id: str, asset: object) -> list[str]:
	if not isinstance(asset, dict):
		return [f"{asset_id}: asset entry must be an object"]

	errors: list[str] = []
	for field in REQUIRED_FIELDS:
		if field not in asset:
			errors.append(f"{asset_id}: missing field {field}")

	license_value = str(asset.get("license", "")).strip()
	if license_value == "":
		errors.append(f"{asset_id}: license must be documented")

	source_kind = str(asset.get("source_kind", "")).strip()
	source_url = str(asset.get("source_url", "")).strip()
	if source_kind not in ["scripted_placeholder", "cc0", "procured", "ai_generated"]:
		errors.append(f"{asset_id}: unsupported source_kind {source_kind}")
	if source_kind != "scripted_placeholder" and source_url == "":
		errors.append(f"{asset_id}: non-placeholder assets require source_url")

	for field in ["raw_path", "working_blend", "export_glb", "wrapper_scene"]:
		errors.extend(validate_existing_path(asset_id, field, str(asset.get(field, ""))))

	preview_path = str(asset.get("preview_png", "")).strip()
	if preview_path != "":
		errors.extend(validate_existing_path(asset_id, "preview_png", preview_path))

	wrapper_path = ROOT_DIR / str(asset.get("wrapper_scene", ""))
	if wrapper_path.exists():
		wrapper_text = wrapper_path.read_text(encoding="utf-8")
		for required_node in ["VisualRoot", "GroundAnchor"]:
			if required_node not in wrapper_text:
				errors.append(f"{asset_id}: wrapper missing {required_node}")
		if asset.get("category") == "launcher" and "MuzzleSocket" not in wrapper_text:
			errors.append(f"{asset_id}: launcher wrapper missing MuzzleSocket")

	return errors


def validate_existing_path(asset_id: str, field: str, raw_path: str) -> list[str]:
	if raw_path.strip() == "":
		return [f"{asset_id}: {field} must not be empty"]
	path = ROOT_DIR / raw_path
	if not path.exists():
		return [f"{asset_id}: {field} does not exist: {raw_path}"]
	return []


def validate_no_runtime_configs_reference_raw_glb() -> list[str]:
	errors: list[str] = []
	raw_glb_marker = "assets/art/exports_godot/"
	for path in CONFIG_PATHS_WITHOUT_RAW_GLB:
		if not path.exists():
			errors.append(f"missing runtime config checked by manifest validator: {path}")
			continue
		text = path.read_text(encoding="utf-8")
		if raw_glb_marker in text:
			errors.append(f"{path.relative_to(ROOT_DIR)} references raw GLB instead of wrapper scene")
	return errors


if __name__ == "__main__":
	main()
