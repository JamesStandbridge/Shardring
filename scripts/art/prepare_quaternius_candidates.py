from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT_DIR = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT_DIR / "assets" / "art" / "source_external" / "quaternius"
WORKING_DIR = ROOT_DIR / "assets" / "art" / "working_blender"
EXPORT_DIR = ROOT_DIR / "assets" / "art" / "exports_godot"
PREVIEW_DIR = ROOT_DIR / "assets" / "art" / "previews"

CANDIDATES = [
	{
		"id": "player_quaternius_robot_2legs",
		"source": SOURCE_ROOT / "cyberpunk_game_kit" / "Enemies" / "Enemy_2Legs.gltf",
		"working": WORKING_DIR / "asset_quaternius_player_robot_2legs.blend",
		"export": EXPORT_DIR / "asset_quaternius_player_robot_2legs.glb",
		"preview": PREVIEW_DIR / "asset_quaternius_player_robot_2legs.png",
		"target_height": 1.75,
	},
	{
		"id": "chaser_quaternius_cyclops",
		"source": SOURCE_ROOT / "cute_animated_monsters" / "glTF" / "Cyclops.gltf",
		"working": WORKING_DIR / "asset_quaternius_chaser_cyclops.blend",
		"export": EXPORT_DIR / "asset_quaternius_chaser_cyclops.glb",
		"preview": PREVIEW_DIR / "asset_quaternius_chaser_cyclops.png",
		"target_height": 1.15,
	},
	{
		"id": "launcher_quaternius_turret_cannon",
		"source": SOURCE_ROOT / "cyberpunk_game_kit" / "Enemies" / "Turret_Cannon.gltf",
		"working": WORKING_DIR / "asset_quaternius_launcher_turret_cannon.blend",
		"export": EXPORT_DIR / "asset_quaternius_launcher_turret_cannon.glb",
		"preview": PREVIEW_DIR / "asset_quaternius_launcher_turret_cannon.png",
		"target_height": 1.05,
	},
	{
		"id": "projectile_quaternius_grenade",
		"source": SOURCE_ROOT / "toon_shooter_game_kit" / "Guns" / "glTF" / "Grenade.gltf",
		"working": WORKING_DIR / "asset_quaternius_projectile_grenade.blend",
		"export": EXPORT_DIR / "asset_quaternius_projectile_grenade.glb",
		"preview": PREVIEW_DIR / "asset_quaternius_projectile_grenade.png",
		"target_height": 0.38,
	},
	{
		"id": "exit_gate_quaternius_door",
		"source": SOURCE_ROOT / "cyberpunk_game_kit" / "Platforms" / "Door.gltf",
		"working": WORKING_DIR / "asset_quaternius_exit_gate_door.blend",
		"export": EXPORT_DIR / "asset_quaternius_exit_gate_door.glb",
		"preview": PREVIEW_DIR / "asset_quaternius_exit_gate_door.png",
		"target_height": 2.25,
	},
]


def main() -> None:
	WORKING_DIR.mkdir(parents=True, exist_ok=True)
	EXPORT_DIR.mkdir(parents=True, exist_ok=True)
	PREVIEW_DIR.mkdir(parents=True, exist_ok=True)

	for candidate in CANDIDATES:
		prepare_candidate(candidate)


def prepare_candidate(candidate: dict) -> None:
	source_path = candidate["source"]
	if not source_path.exists():
		raise SystemExit(f"Missing source blend: {source_path}")

	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=str(source_path))
	remove_existing_cameras_and_lights()
	apply_candidate_cleanup(candidate)
	normalize_scene(candidate["id"], candidate["target_height"])
	add_preview_camera_and_light()
	save_and_export(candidate)
	render_preview(candidate)
	print(f"prepared {candidate['id']}")


def remove_existing_cameras_and_lights() -> None:
	for obj in list(bpy.context.scene.objects):
		if obj.type in {"CAMERA", "LIGHT"}:
			bpy.data.objects.remove(obj, do_unlink=True)


def apply_candidate_cleanup(candidate: dict) -> None:
	keep_mesh_names = set(candidate.get("keep_mesh_names", []))
	if keep_mesh_names:
		for obj in list(bpy.context.scene.objects):
			if obj.type == "MESH" and obj.name not in keep_mesh_names:
				bpy.data.objects.remove(obj, do_unlink=True)

	material_colors = candidate.get("material_colors", {})
	for material_name, color in material_colors.items():
		replace_material_color(material_name, color)


def replace_material_color(material_name: str, color: tuple[float, float, float, float]) -> None:
	material = bpy.data.materials.get(material_name)
	if material is None:
		return
	material.diffuse_color = color
	material.use_nodes = True
	node = material.node_tree.nodes.get("Principled BSDF")
	if node is None:
		return
	if "Base Color" in node.inputs:
		node.inputs["Base Color"].default_value = color


def normalize_scene(asset_id: str, target_height: float) -> None:
	mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	if not mesh_objects:
		raise SystemExit(f"No mesh objects found for {asset_id}")

	for obj in mesh_objects:
		set_materials_rough(obj)

	center, _size = calculate_bounds(mesh_objects)
	for obj in mesh_objects:
		obj.location.x -= center.x
		obj.location.y -= center.y

	min_corner, max_corner = calculate_min_max(mesh_objects)
	height = max(max_corner.z - min_corner.z, 0.001)
	scale_factor = target_height / height
	for obj in mesh_objects:
		obj.location *= scale_factor
		obj.scale *= scale_factor

	min_corner, max_corner = calculate_min_max(mesh_objects)
	center = min_corner + (max_corner - min_corner) * 0.5
	for obj in mesh_objects:
		obj.location.x -= center.x
		obj.location.y -= center.y
		obj.location.z -= min_corner.z


def set_materials_rough(obj: bpy.types.Object) -> None:
	for mat in obj.data.materials:
		if mat is None:
			continue
		mat.use_nodes = True
		node = mat.node_tree.nodes.get("Principled BSDF")
		if node is None:
			continue
		if "Roughness" in node.inputs:
			node.inputs["Roughness"].default_value = 0.72
		if "Metallic" in node.inputs:
			node.inputs["Metallic"].default_value = 0.0


def calculate_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
	min_corner, max_corner = calculate_min_max(objects)
	size = max_corner - min_corner
	center = min_corner + size * 0.5
	return center, size


def calculate_min_max(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
	min_corner = Vector((math.inf, math.inf, math.inf))
	max_corner = Vector((-math.inf, -math.inf, -math.inf))
	for obj in objects:
		for corner in obj.bound_box:
			world = obj.matrix_world @ Vector(corner)
			min_corner.x = min(min_corner.x, world.x)
			min_corner.y = min(min_corner.y, world.y)
			min_corner.z = min(min_corner.z, world.z)
			max_corner.x = max(max_corner.x, world.x)
			max_corner.y = max(max_corner.y, world.y)
			max_corner.z = max(max_corner.z, world.z)
	return min_corner, max_corner


def add_preview_camera_and_light() -> None:
	mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	center, size = calculate_bounds(mesh_objects)
	radius = max(size.x, size.y, size.z, 1.0)
	camera_distance = radius * 2.4

	light_data = bpy.data.lights.new("asset_preview_area_light", type="AREA")
	light = bpy.data.objects.new("asset_preview_area_light", light_data)
	light.location = (0.0, -camera_distance, radius * 1.8)
	bpy.context.scene.collection.objects.link(light)
	light.name = "asset_preview_area_light"
	light.data.energy = 650.0
	light.data.size = max(radius, 3.0)

	camera_location = Vector((camera_distance * 0.7, -camera_distance, radius * 0.82))
	camera_data = bpy.data.cameras.new("asset_preview_camera")
	camera = bpy.data.objects.new("asset_preview_camera", camera_data)
	camera.location = camera_location
	bpy.context.scene.collection.objects.link(camera)
	look_at(camera, center + Vector((0.0, 0.0, size.z * 0.08)))
	camera.data.lens = 48.0
	bpy.context.scene.camera = camera

	bpy.context.scene.render.resolution_x = 1024
	bpy.context.scene.render.resolution_y = 1024
	bpy.context.scene.eevee.taa_render_samples = 64
	bpy.context.scene.view_settings.view_transform = "Filmic"
	bpy.context.scene.view_settings.look = "Medium High Contrast"
	if bpy.context.scene.world is None:
		bpy.context.scene.world = bpy.data.worlds.new("asset_preview_world")
	bpy.context.scene.world.color = (0.78, 0.86, 0.9)


def look_at(obj: bpy.types.Object, target: Vector) -> None:
	direction = target - obj.location
	obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def save_and_export(candidate: dict) -> None:
	bpy.ops.wm.save_as_mainfile(filepath=str(candidate["working"]))
	bpy.ops.export_scene.gltf(
		filepath=str(candidate["export"]),
		export_format="GLB",
		export_apply=True,
		export_cameras=False,
		export_lights=False,
	)


def render_preview(candidate: dict) -> None:
	bpy.context.scene.render.filepath = str(candidate["preview"])
	bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
	main()
