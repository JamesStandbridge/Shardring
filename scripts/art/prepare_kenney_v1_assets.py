#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


ROOT_DIR = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT_DIR / "assets" / "art" / "source_external" / "kenney"
WORKING_DIR = ROOT_DIR / "assets" / "art" / "working_blender"
EXPORT_DIR = ROOT_DIR / "assets" / "art" / "exports_godot"


ASSETS = [
	{
		"id": "player",
		"source": SOURCE_ROOT
		/ "blocky_characters"
		/ "Models"
		/ "GLB format"
		/ "character-a.glb",
		"blend": WORKING_DIR / "asset_kenney_player_blocky_character.blend",
		"export": EXPORT_DIR / "asset_kenney_player_blocky_character.glb",
		"target_height": 1.75,
		"rotate_z_degrees": 180.0,
		"material": None,
	},
	{
		"id": "chaser",
		"source": SOURCE_ROOT / "cube_pets" / "Models" / "GLB format" / "animal-bee.glb",
		"blend": WORKING_DIR / "asset_kenney_chaser_bee.blend",
		"export": EXPORT_DIR / "asset_kenney_chaser_bee.glb",
		"target_height": 1.05,
		"rotate_z_degrees": 180.0,
		"material": {
			"name": "mat_kenney_chaser_danger",
			"color": (1.0, 0.46, 0.12, 1.0),
			"emission": 0.35,
		},
	},
	{
		"id": "launcher",
		"source": SOURCE_ROOT / "pirate_kit" / "Models" / "GLB format" / "cannon-mobile.glb",
		"blend": WORKING_DIR / "asset_kenney_launcher_cannon_mobile.blend",
		"export": EXPORT_DIR / "asset_kenney_launcher_cannon_mobile.glb",
		"target_height": 1.1,
		"rotate_z_degrees": 180.0,
		"material": None,
	},
	{
		"id": "projectile",
		"source": SOURCE_ROOT / "pirate_kit" / "Models" / "GLB format" / "cannon-ball.glb",
		"blend": WORKING_DIR / "asset_kenney_projectile_cannon_ball.blend",
		"export": EXPORT_DIR / "asset_kenney_projectile_cannon_ball.glb",
		"target_height": 0.78,
		"rotate_z_degrees": 0.0,
		"material": {
			"name": "mat_kenney_projectile_danger",
			"color": (1.0, 0.16, 0.07, 1.0),
			"emission": 0.85,
		},
	},
	{
		"id": "exit_gate_frame",
		"source": SOURCE_ROOT
		/ "factory_kit"
		/ "Models"
		/ "GLB format"
		/ "structure-doorway-wide.glb",
		"blend": WORKING_DIR / "asset_kenney_exit_gate_frame.blend",
		"export": EXPORT_DIR / "asset_kenney_exit_gate_frame.glb",
		"target_height": 2.1,
		"rotate_z_degrees": 0.0,
		"material": None,
	},
	{
		"id": "exit_gate_panel",
		"source": SOURCE_ROOT / "factory_kit" / "Models" / "GLB format" / "door.glb",
		"blend": WORKING_DIR / "asset_kenney_exit_gate_panel.blend",
		"export": EXPORT_DIR / "asset_kenney_exit_gate_panel.glb",
		"target_height": 1.78,
		"rotate_z_degrees": 0.0,
		"material": None,
	},
]


def main() -> None:
	WORKING_DIR.mkdir(parents=True, exist_ok=True)
	EXPORT_DIR.mkdir(parents=True, exist_ok=True)
	for asset in ASSETS:
		prepare_asset(asset)


def prepare_asset(asset: dict) -> None:
	source_path = asset["source"]
	if not source_path.exists():
		raise SystemExit(f"Missing source asset for {asset['id']}: {source_path}")

	clear_scene()
	bpy.ops.import_scene.gltf(filepath=str(source_path))
	meshes = get_mesh_objects()
	if not meshes:
		raise SystemExit(f"No mesh imported for {asset['id']}: {source_path}")

	if not math.isclose(asset["rotate_z_degrees"], 0.0):
		rotate_scene_z(math.radians(asset["rotate_z_degrees"]))

	joined = join_meshes(asset["id"])
	normalize_mesh_to_height(joined, asset["target_height"])

	if asset["material"] is not None:
		apply_single_material(joined, asset["material"])

	bpy.ops.wm.save_as_mainfile(filepath=str(asset["blend"]))
	bpy.ops.export_scene.gltf(
		filepath=str(asset["export"]),
		export_format="GLB",
		export_apply=True,
	)
	print(f"prepared {asset['id']}: {asset['export'].relative_to(ROOT_DIR)}")


def clear_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()


def get_mesh_objects() -> list[bpy.types.Object]:
	return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def rotate_scene_z(angle_radians: float) -> None:
	rotation_matrix = Matrix.Rotation(angle_radians, 4, "Z")
	for obj in get_mesh_objects():
		obj.location = rotation_matrix @ obj.location
		obj.rotation_euler.rotate_axis("Z", angle_radians)


def join_meshes(asset_id: str) -> bpy.types.Object:
	meshes = get_mesh_objects()
	bpy.ops.object.select_all(action="DESELECT")
	for obj in meshes:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = meshes[0]
	bpy.ops.object.join()
	joined = bpy.context.view_layer.objects.active
	joined.name = f"asset_kenney_{asset_id}_mesh"
	joined.data.name = f"mesh_kenney_{asset_id}"
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	return joined


def normalize_mesh_to_height(obj: bpy.types.Object, target_height: float) -> None:
	min_bound, max_bound = get_local_mesh_bounds(obj)
	size = max_bound - min_bound
	if size.z <= 0.0:
		raise SystemExit(f"Cannot normalize {obj.name} with zero height")

	center = (min_bound + max_bound) * 0.5
	scale = target_height / size.z
	for vertex in obj.data.vertices:
		vertex.co = (vertex.co - center) * scale
	obj.location = Vector((0.0, 0.0, 0.0))
	bpy.context.view_layer.objects.active = obj
	obj.select_set(True)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def get_local_mesh_bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
	points = [vertex.co.copy() for vertex in obj.data.vertices]
	min_bound = Vector(
		(
			min(point.x for point in points),
			min(point.y for point in points),
			min(point.z for point in points),
		)
	)
	max_bound = Vector(
		(
			max(point.x for point in points),
			max(point.y for point in points),
			max(point.z for point in points),
		)
	)
	return min_bound, max_bound


def apply_single_material(obj: bpy.types.Object, material_data: dict) -> None:
	material = bpy.data.materials.new(material_data["name"])
	material.use_nodes = True
	principled = material.node_tree.nodes.get("Principled BSDF")
	if principled is not None:
		principled.inputs["Base Color"].default_value = material_data["color"]
		principled.inputs["Roughness"].default_value = 0.68
		principled.inputs["Emission Color"].default_value = material_data["color"]
		principled.inputs["Emission Strength"].default_value = material_data["emission"]

	obj.data.materials.clear()
	obj.data.materials.append(material)
	for polygon in obj.data.polygons:
		polygon.material_index = 0


if __name__ == "__main__":
	main()
