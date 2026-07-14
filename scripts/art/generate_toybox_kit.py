from __future__ import annotations

import math
from pathlib import Path

import bpy


ROOT_DIR = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT_DIR / "assets" / "art" / "source_blender"
EXPORT_DIR = ROOT_DIR / "assets" / "art" / "exports_godot"

SOURCE_BLEND = SOURCE_DIR / "asset_toybox_kit.blend"

EXPORTS = {
	"toybox_player": EXPORT_DIR / "asset_toybox_player.glb",
	"toybox_chaser": EXPORT_DIR / "asset_toybox_chaser.glb",
	"toybox_launcher": EXPORT_DIR / "asset_toybox_launcher.glb",
	"toybox_projectile": EXPORT_DIR / "asset_toybox_projectile.glb",
	"toybox_exit_gate": EXPORT_DIR / "asset_toybox_exit_gate.glb",
}


def main() -> None:
	SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	EXPORT_DIR.mkdir(parents=True, exist_ok=True)
	clear_scene()
	create_camera_and_light()

	player = create_player()
	chaser = create_chaser()
	launcher = create_launcher()
	projectile = create_projectile()
	exit_gate = create_exit_gate()

	bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_BLEND))

	export_asset(player, EXPORTS["toybox_player"])
	export_asset(chaser, EXPORTS["toybox_chaser"])
	export_asset(launcher, EXPORTS["toybox_launcher"])
	export_asset(projectile, EXPORTS["toybox_projectile"])
	export_scene_asset(exit_gate, EXPORTS["toybox_exit_gate"])

	print("Toybox kit generated:")
	print(f"- {SOURCE_BLEND}")
	for path in EXPORTS.values():
		print(f"- {path}")


def clear_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()

	for block in (
		bpy.data.meshes,
		bpy.data.materials,
		bpy.data.images,
		bpy.data.collections,
	):
		for item in list(block):
			if item.users == 0:
				block.remove(item)


def create_camera_and_light() -> None:
	bpy.ops.object.light_add(type="AREA", location=(0.0, -6.0, 7.0))
	light = bpy.context.object
	light.name = "preview_area_light"
	light.data.energy = 500.0
	light.data.size = 5.0

	bpy.ops.object.camera_add(location=(4.0, -7.5, 4.0), rotation=(math.radians(62.0), 0.0, math.radians(28.0)))
	bpy.context.scene.camera = bpy.context.object


def material(name: str, color: tuple[float, float, float, float], emission: float = 0.0) -> bpy.types.Material:
	mat = bpy.data.materials.new(name)
	mat.diffuse_color = color
	mat.use_nodes = True
	node = mat.node_tree.nodes.get("Principled BSDF")
	if node is not None:
		set_input(node, "Base Color", color)
		set_input(node, "Roughness", 0.72)
		set_input(node, "Metallic", 0.0)
		if emission > 0.0:
			set_input(node, "Emission Color", color)
			set_input(node, "Emission Strength", emission)
	return mat


def set_input(node: bpy.types.Node, input_name: str, value: object) -> None:
	if input_name in node.inputs:
		node.inputs[input_name].default_value = value


def create_uv_sphere(
	name: str,
	radius: float,
	location: tuple[float, float, float],
	scale: tuple[float, float, float],
	mat: bpy.types.Material,
	segments: int = 24,
	rings: int = 12,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_uv_sphere_add(
		segments=segments,
		ring_count=rings,
		radius=radius,
		location=location,
	)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	obj.data.materials.append(mat)
	apply_transform(obj)
	return obj


def create_cylinder(
	name: str,
	radius: float,
	depth: float,
	location: tuple[float, float, float],
	mat: bpy.types.Material,
	vertices: int = 24,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
	obj = bpy.context.object
	obj.name = name
	obj.data.materials.append(mat)
	apply_transform(obj)
	return obj


def create_cube(
	name: str,
	location: tuple[float, float, float],
	scale: tuple[float, float, float],
	mat: bpy.types.Material,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	obj.data.materials.append(mat)
	apply_transform(obj)
	return obj


def create_cone(
	name: str,
	radius1: float,
	radius2: float,
	depth: float,
	location: tuple[float, float, float],
	rotation: tuple[float, float, float],
	mat: bpy.types.Material,
	vertices: int = 24,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cone_add(
		vertices=vertices,
		radius1=radius1,
		radius2=radius2,
		depth=depth,
		location=location,
		rotation=rotation,
	)
	obj = bpy.context.object
	obj.name = name
	obj.data.materials.append(mat)
	apply_transform(obj)
	return obj


def create_torus(
	name: str,
	major_radius: float,
	minor_radius: float,
	location: tuple[float, float, float],
	rotation: tuple[float, float, float],
	mat: bpy.types.Material,
) -> bpy.types.Object:
	bpy.ops.mesh.primitive_torus_add(
		major_segments=32,
		minor_segments=10,
		major_radius=major_radius,
		minor_radius=minor_radius,
		location=location,
		rotation=rotation,
	)
	obj = bpy.context.object
	obj.name = name
	obj.data.materials.append(mat)
	apply_transform(obj)
	return obj


def apply_transform(obj: bpy.types.Object) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def bevel(obj: bpy.types.Object, amount: float, segments: int = 2) -> None:
	modifier = obj.modifiers.new("soft_bevel", "BEVEL")
	modifier.width = amount
	modifier.segments = segments
	modifier.affect = "EDGES"
	normal = obj.modifiers.new("soft_normals", "WEIGHTED_NORMAL")
	normal.keep_sharp = True
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.modifier_apply(modifier=modifier.name)
	bpy.ops.object.modifier_apply(modifier=normal.name)


def join_objects(name: str, objects: list[bpy.types.Object]) -> bpy.types.Object:
	bpy.ops.object.select_all(action="DESELECT")
	for obj in objects:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = objects[0]
	bpy.ops.object.join()
	joined = bpy.context.object
	joined.name = name
	joined.data.name = f"{name}_mesh"
	return joined


def create_empty(name: str, location: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
	obj = bpy.data.objects.new(name, None)
	obj.empty_display_type = "PLAIN_AXES"
	obj.empty_display_size = 0.2
	obj.location = location
	bpy.context.collection.objects.link(obj)
	return obj


def parent_to(child: bpy.types.Object, parent: bpy.types.Object) -> None:
	child.parent = parent


def shade_smooth(obj: bpy.types.Object) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.shade_smooth()


def create_player() -> bpy.types.Object:
	periwinkle = material("mat_toybox_player_periwinkle", (0.38, 0.48, 0.95, 1.0))
	cream = material("mat_toybox_player_face_cream", (0.93, 0.96, 0.88, 1.0))
	mint = material("mat_toybox_mint_direction", (0.30, 0.88, 0.79, 1.0), 0.25)
	cheek = material("mat_toybox_cheek", (1.0, 0.55, 0.60, 1.0))
	eye = material("mat_toybox_eye_black", (0.05, 0.06, 0.08, 1.0))
	shadow = material("mat_toybox_player_soft_shadow", (0.13, 0.16, 0.22, 1.0))

	body = create_uv_sphere("player_body_vinyl_capsule", 1.0, (0.0, 0.0, 0.0), (0.48, 0.42, 0.88), periwinkle)
	face_patch = create_uv_sphere("player_face_patch", 1.0, (0.0, -0.38, 0.63), (0.32, 0.045, 0.28), cream)
	head = create_uv_sphere("player_head_soft_cap", 1.0, (0.0, -0.03, 0.72), (0.44, 0.39, 0.34), periwinkle)
	left_eye = create_uv_sphere("player_left_eye", 1.0, (-0.16, -0.39, 0.78), (0.045, 0.025, 0.065), eye, 16, 8)
	right_eye = create_uv_sphere("player_right_eye", 1.0, (0.16, -0.39, 0.78), (0.045, 0.025, 0.065), eye, 16, 8)
	left_cheek = create_uv_sphere("player_left_cheek", 1.0, (-0.28, -0.37, 0.66), (0.055, 0.018, 0.04), cheek, 12, 6)
	right_cheek = create_uv_sphere("player_right_cheek", 1.0, (0.28, -0.37, 0.66), (0.055, 0.018, 0.04), cheek, 12, 6)
	direction = create_cube("player_direction_badge", (0.0, -0.46, 0.15), (0.16, 0.035, 0.13), mint)
	foot_shadow = create_uv_sphere("player_foot_shadow_band", 1.0, (0.0, 0.03, -0.77), (0.36, 0.32, 0.05), shadow, 16, 6)
	bevel(direction, 0.035, 2)

	for obj in [body, face_patch, head, left_eye, right_eye, left_cheek, right_cheek, foot_shadow]:
		shade_smooth(obj)
	return join_objects(
		"asset_toybox_player",
		[body, face_patch, head, left_eye, right_eye, left_cheek, right_cheek, direction, foot_shadow],
	)


def create_chaser() -> bpy.types.Object:
	orange = material("mat_toybox_chaser_orange", (1.0, 0.42, 0.18, 1.0), 0.18)
	yellow = material("mat_toybox_chaser_warning_yellow", (1.0, 0.78, 0.20, 1.0), 0.6)
	black = material("mat_toybox_chaser_eye_black", (0.05, 0.05, 0.06, 1.0))
	cream = material("mat_toybox_chaser_eye_cream", (1.0, 0.94, 0.84, 1.0))

	body = create_uv_sphere("chaser_bouncy_bomb_body", 1.0, (0.0, 0.0, 0.0), (0.46, 0.46, 0.46), orange)
	fuse = create_cylinder("chaser_squiggly_fuse", 0.055, 0.42, (0.0, 0.0, 0.56), yellow, 12)
	fuse.rotation_euler[0] = math.radians(18.0)
	apply_transform(fuse)
	left_eye_white = create_uv_sphere("chaser_left_eye_white", 1.0, (-0.14, -0.41, 0.15), (0.105, 0.04, 0.12), cream, 16, 8)
	right_eye_white = create_uv_sphere("chaser_right_eye_white", 1.0, (0.14, -0.41, 0.15), (0.105, 0.04, 0.12), cream, 16, 8)
	left_eye = create_uv_sphere("chaser_left_pupil", 1.0, (-0.14, -0.445, 0.14), (0.04, 0.018, 0.055), black, 12, 6)
	right_eye = create_uv_sphere("chaser_right_pupil", 1.0, (0.14, -0.445, 0.14), (0.04, 0.018, 0.055), black, 12, 6)
	foot_left = create_uv_sphere("chaser_left_stub_foot", 1.0, (-0.24, -0.02, -0.40), (0.13, 0.18, 0.07), black, 12, 6)
	foot_right = create_uv_sphere("chaser_right_stub_foot", 1.0, (0.24, -0.02, -0.40), (0.13, 0.18, 0.07), black, 12, 6)

	for obj in [body, left_eye_white, right_eye_white, left_eye, right_eye, foot_left, foot_right]:
		shade_smooth(obj)
	return join_objects(
		"asset_toybox_chaser",
		[body, fuse, left_eye_white, right_eye_white, left_eye, right_eye, foot_left, foot_right],
	)


def create_launcher() -> bpy.types.Object:
	coral = material("mat_toybox_launcher_coral", (1.0, 0.35, 0.28, 1.0), 0.2)
	cream = material("mat_toybox_launcher_cream", (0.97, 0.90, 0.78, 1.0))
	dark = material("mat_toybox_launcher_dark", (0.08, 0.09, 0.11, 1.0))
	red = material("mat_toybox_launcher_muzzle_red", (1.0, 0.08, 0.16, 1.0), 1.1)
	gold = material("mat_toybox_launcher_gold_warning", (1.0, 0.72, 0.18, 1.0), 0.25)

	base = create_cylinder("launcher_round_base", 0.42, 0.18, (0.0, 0.0, -0.36), dark, 32)
	turret_body = create_uv_sphere(
		"launcher_squat_turret_body",
		1.0,
		(0.0, 0.0, 0.0),
		(0.52, 0.46, 0.36),
		coral,
		24,
		12,
	)
	barrel = create_cylinder("launcher_forward_barrel", 0.16, 0.72, (0.0, -0.47, 0.10), dark, 32)
	barrel.rotation_euler[0] = math.radians(90.0)
	apply_transform(barrel)
	muzzle_ring = create_torus(
		"launcher_muzzle_warning_ring",
		0.18,
		0.035,
		(0.0, -0.84, 0.10),
		(math.radians(90.0), 0.0, 0.0),
		red,
	)
	muzzle_core = create_cylinder("launcher_muzzle_glow_core", 0.105, 0.045, (0.0, -0.86, 0.10), red, 24)
	muzzle_core.rotation_euler[0] = math.radians(90.0)
	apply_transform(muzzle_core)
	left_eye = create_uv_sphere("launcher_left_eye", 1.0, (-0.20, -0.36, 0.27), (0.055, 0.025, 0.075), cream, 12, 6)
	right_eye = create_uv_sphere("launcher_right_eye", 1.0, (0.20, -0.36, 0.27), (0.055, 0.025, 0.075), cream, 12, 6)
	left_brow = create_cube("launcher_left_warning_brow", (-0.20, -0.39, 0.39), (0.12, 0.018, 0.025), gold)
	left_brow.rotation_euler[1] = math.radians(-12.0)
	apply_transform(left_brow)
	right_brow = create_cube("launcher_right_warning_brow", (0.20, -0.39, 0.39), (0.12, 0.018, 0.025), gold)
	right_brow.rotation_euler[1] = math.radians(12.0)
	apply_transform(right_brow)
	side_left = create_uv_sphere("launcher_left_side_knob", 1.0, (-0.48, -0.02, 0.02), (0.08, 0.08, 0.12), gold, 12, 6)
	side_right = create_uv_sphere("launcher_right_side_knob", 1.0, (0.48, -0.02, 0.02), (0.08, 0.08, 0.12), gold, 12, 6)
	foot_left = create_cube("launcher_left_foot", (-0.27, 0.02, -0.50), (0.16, 0.18, 0.055), dark)
	foot_right = create_cube("launcher_right_foot", (0.27, 0.02, -0.50), (0.16, 0.18, 0.055), dark)
	bevel(foot_left, 0.04, 2)
	bevel(foot_right, 0.04, 2)

	for obj in [base, turret_body, left_eye, right_eye, side_left, side_right]:
		shade_smooth(obj)
	return join_objects(
		"asset_toybox_launcher",
		[
			base,
			turret_body,
			barrel,
			muzzle_ring,
			muzzle_core,
			left_eye,
			right_eye,
			left_brow,
			right_brow,
			side_left,
			side_right,
			foot_left,
			foot_right,
		],
	)


def create_projectile() -> bpy.types.Object:
	red = material("mat_toybox_projectile_gummy_red", (1.0, 0.12, 0.14, 1.0), 0.8)
	pink = material("mat_toybox_projectile_hot_core", (1.0, 0.36, 0.48, 1.0), 1.6)
	dark = material("mat_toybox_projectile_face", (0.08, 0.03, 0.04, 1.0))

	body = create_uv_sphere("projectile_gummy_blob", 1.0, (0.0, 0.0, 0.0), (0.34, 0.34, 0.26), red, 24, 12)
	core = create_uv_sphere("projectile_emissive_core", 1.0, (0.0, -0.30, 0.0), (0.13, 0.045, 0.11), pink, 16, 8)
	angry_left = create_cube("projectile_left_angry_eye", (-0.12, -0.335, 0.08), (0.08, 0.014, 0.026), dark)
	angry_left.rotation_euler[1] = math.radians(-18.0)
	apply_transform(angry_left)
	angry_right = create_cube("projectile_right_angry_eye", (0.12, -0.335, 0.08), (0.08, 0.014, 0.026), dark)
	angry_right.rotation_euler[1] = math.radians(18.0)
	apply_transform(angry_right)

	for obj in [body, core]:
		shade_smooth(obj)
	return join_objects(
		"asset_toybox_projectile",
		[body, core, angry_left, angry_right],
	)


def create_exit_gate() -> bpy.types.Object:
	cyan = material("mat_toybox_gate_cyan", (0.13, 0.82, 0.88, 1.0), 0.45)
	deep_cyan = material("mat_toybox_gate_deep_cyan", (0.08, 0.46, 0.58, 1.0), 0.15)
	cream = material("mat_toybox_gate_cream_doors", (0.98, 0.88, 0.62, 1.0))
	coral = material("mat_toybox_gate_coral_panels", (1.0, 0.42, 0.34, 1.0), 0.08)
	gold = material("mat_toybox_gate_gold_hardware", (1.0, 0.76, 0.25, 1.0), 0.2)
	pink = material("mat_toybox_gate_cheek_pink", (1.0, 0.45, 0.62, 1.0))
	dark = material("mat_toybox_gate_eye_dark", (0.06, 0.07, 0.09, 1.0))
	shadow = material("mat_toybox_gate_opening_shadow", (0.08, 0.12, 0.18, 1.0))
	white = material("mat_toybox_gate_exit_letters", (1.0, 0.96, 0.82, 1.0), 0.65)

	root = create_empty("asset_toybox_exit_gate")

	opening_shadow = create_cube("exit_gate_dark_opening", (0.0, 0.07, 1.34), (1.02, 0.035, 1.16), shadow)
	left_post = create_cube("exit_gate_left_post", (-1.32, 0.0, 1.35), (0.24, 0.22, 1.36), cyan)
	right_post = create_cube("exit_gate_right_post", (1.32, 0.0, 1.35), (0.24, 0.22, 1.36), cyan)
	top = create_cube("exit_gate_top_beam", (0.0, 0.0, 2.70), (1.58, 0.24, 0.26), cyan)
	inner_top = create_cube("exit_gate_inner_top_shadow", (0.0, -0.02, 2.35), (1.02, 0.05, 0.12), shadow)
	bottom = create_cube("exit_gate_threshold_step", (0.0, -0.28, 0.08), (1.52, 0.52, 0.10), deep_cyan)
	for obj in [opening_shadow, left_post, right_post, top, inner_top, bottom]:
		bevel(obj, 0.08, 3)
		parent_to(obj, root)

	sign_board = create_cube("exit_gate_exit_sign_board", (0.0, -0.19, 2.95), (0.74, 0.055, 0.22), deep_cyan)
	bevel(sign_board, 0.055, 3)
	parent_to(sign_board, root)
	exit_text = create_text_mesh(
		"exit_gate_exit_text",
		"EXIT",
		(0.0, -0.255, 2.88),
		0.34,
		white,
	)
	parent_to(exit_text, root)

	left_eye = create_uv_sphere("exit_gate_left_eye", 1.0, (-0.23, -0.265, 2.73), (0.055, 0.018, 0.055), dark, 12, 6)
	right_eye = create_uv_sphere("exit_gate_right_eye", 1.0, (0.23, -0.265, 2.73), (0.055, 0.018, 0.055), dark, 12, 6)
	left_cheek = create_uv_sphere("exit_gate_left_cheek", 1.0, (-0.52, -0.24, 2.58), (0.065, 0.018, 0.045), pink, 12, 6)
	right_cheek = create_uv_sphere("exit_gate_right_cheek", 1.0, (0.52, -0.24, 2.58), (0.065, 0.018, 0.045), pink, 12, 6)
	for obj in [left_eye, right_eye, left_cheek, right_cheek]:
		shade_smooth(obj)
		parent_to(obj, root)

	left_pivot = create_empty("exit_gate_left_pivot", (-1.05, -0.18, 1.30))
	right_pivot = create_empty("exit_gate_right_pivot", (1.05, -0.18, 1.30))
	parent_to(left_pivot, root)
	parent_to(right_pivot, root)

	left_door = create_cube("exit_gate_left_door_panel", (-0.53, -0.18, 1.30), (0.52, 0.085, 1.08), cream)
	right_door = create_cube("exit_gate_right_door_panel", (0.53, -0.18, 1.30), (0.52, 0.085, 1.08), cream)
	bevel(left_door, 0.055, 3)
	bevel(right_door, 0.055, 3)
	parent_to(left_door, left_pivot)
	parent_to(right_door, right_pivot)

	left_inset = create_cube("exit_gate_left_door_inset", (-0.53, -0.275, 1.46), (0.34, 0.022, 0.42), coral)
	right_inset = create_cube("exit_gate_right_door_inset", (0.53, -0.275, 1.46), (0.34, 0.022, 0.42), coral)
	left_lower_inset = create_cube("exit_gate_left_lower_inset", (-0.53, -0.276, 0.78), (0.32, 0.02, 0.24), coral)
	right_lower_inset = create_cube("exit_gate_right_lower_inset", (0.53, -0.276, 0.78), (0.32, 0.02, 0.24), coral)
	for obj in [left_inset, right_inset, left_lower_inset, right_lower_inset]:
		bevel(obj, 0.035, 2)

	left_handle = create_uv_sphere("exit_gate_left_handle", 1.0, (-0.12, -0.31, 1.22), (0.06, 0.03, 0.06), gold, 12, 6)
	right_handle = create_uv_sphere("exit_gate_right_handle", 1.0, (0.12, -0.31, 1.22), (0.06, 0.03, 0.06), gold, 12, 6)
	for obj in [left_handle, right_handle]:
		shade_smooth(obj)
	for obj in [left_inset, left_lower_inset, left_handle]:
		parent_to(obj, left_pivot)
	for obj in [right_inset, right_lower_inset, right_handle]:
		parent_to(obj, right_pivot)

	for hinge_z in [0.72, 1.30, 1.88]:
		left_hinge = create_cylinder(
			f"exit_gate_left_hinge_{int(hinge_z * 100)}",
			0.055,
			0.28,
			(-1.12, -0.29, hinge_z),
			gold,
			16,
		)
		right_hinge = create_cylinder(
			f"exit_gate_right_hinge_{int(hinge_z * 100)}",
			0.055,
			0.28,
			(1.12, -0.29, hinge_z),
			gold,
			16,
		)
		for obj in [left_hinge, right_hinge]:
			shade_smooth(obj)
			parent_to(obj, root)

	return root


def create_text_mesh(
	name: str,
	text: str,
	location: tuple[float, float, float],
	size: float,
	mat: bpy.types.Material,
) -> bpy.types.Object:
	bpy.ops.object.text_add(location=location, rotation=(math.radians(90.0), 0.0, 0.0))
	obj = bpy.context.object
	obj.name = name
	obj.data.body = text
	obj.data.align_x = "CENTER"
	obj.data.align_y = "CENTER"
	obj.data.size = size
	obj.data.extrude = 0.012
	obj.data.materials.append(mat)
	bpy.ops.object.convert(target="MESH")
	obj = bpy.context.object
	obj.name = name
	return obj


def export_asset(asset: bpy.types.Object, filepath: Path) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	asset.select_set(True)
	bpy.context.view_layer.objects.active = asset
	bpy.ops.export_scene.gltf(
		filepath=str(filepath),
		export_format="GLB",
		use_selection=True,
		export_apply=True,
	)


def export_scene_asset(root: bpy.types.Object, filepath: Path) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	for obj in [root, *root.children_recursive]:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = root
	bpy.ops.export_scene.gltf(
		filepath=str(filepath),
		export_format="GLB",
		use_selection=True,
		export_apply=True,
	)


if __name__ == "__main__":
	main()
