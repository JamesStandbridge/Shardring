class_name ArenaController
extends Node3D

const TERRAIN_COLLISION_LAYER := 1 << 1
const PLAYER_SPAWN_HEIGHT_METERS := 1.05
const BOUNDARY_EPSILON_METERS := 0.14
const TERRAIN_SHADER_PATH := "res://src/gameplay/arena/terrain_surface.gdshader"
const HAZARD_SHADER_PATH := "res://src/gameplay/arena/hazard_surface.gdshader"
const WARNING_EFFECT_TEXTURE_PATH := "res://assets/art/textures/terrain/hazard_warning_stripes.png"
const LAVA_EFFECT_TEXTURE_PATH := "res://assets/art/textures/terrain/hazard_lava_flow.png"
const ICE_EFFECT_TEXTURE_PATH := "res://assets/art/textures/terrain/hazard_ice_cracks.png"
const COLLAPSE_EFFECT_TEXTURE_PATH := "res://assets/art/textures/terrain/hazard_collapse_cracks.png"

@export var arena_config: ArenaConfig = ArenaConfig.new()
@export var arena_theme: ArenaThemeConfig = ArenaThemeConfig.new()

var _cells: Array[ArenaCell] = []
var _generated_root: Node3D
var _boundary_polygon := PackedVector2Array()
var _cell_bodies: Dictionary = {}
var _cell_mesh_instances: Dictionary = {}
var _cell_collision_shapes: Dictionary = {}
var _terrain_shader: Shader
var _hazard_shader: Shader
var _hazard_effect_textures: Dictionary = {}


func _ready() -> void:
	generate_arena()


func generate_arena() -> void:
	_clear_generated_arena()
	DebugLog.info(
		&"Arena",
		(
			"generate start radius=%.2f cells=%d seed=%d"
			% [arena_config.radius_meters, arena_config.cell_count, arena_config.generation_seed]
		)
	)

	_generated_root = Node3D.new()
	_generated_root.name = "GeneratedArena"
	add_child(_generated_root)

	_cells = _build_cells()
	for cell: ArenaCell in _cells:
		_create_cell_body(cell)
	_create_arena_trim()

	DebugLog.info(
		&"Arena",
		(
			"generate done cells=%d area=%.2f children=%d"
			% [_cells.size(), _get_total_cell_area(), _generated_root.get_child_count()]
		)
	)


func configure_for_stage(
	stage_arena_config: ArenaConfig, stage_theme: ArenaThemeConfig, generation_seed: int
) -> void:
	if stage_arena_config != null:
		arena_config = stage_arena_config.duplicate(true) as ArenaConfig
		arena_config.generation_seed = generation_seed
	if stage_theme != null:
		arena_theme = stage_theme
	generate_arena()


func get_cells() -> Array[ArenaCell]:
	return _cells.duplicate()


func get_cell_at_position(world_position: Vector3) -> ArenaCell:
	for cell: ArenaCell in _cells:
		if cell.contains_horizontal_position(world_position):
			return cell
	return null


func get_cell_state_at_position(world_position: Vector3) -> ArenaCell.ArenaCellState:
	var cell := get_cell_at_position(world_position)
	if cell == null:
		return ArenaCell.ArenaCellState.DESTROYED
	return cell.state


func get_cell_state_name_at_position(world_position: Vector3) -> String:
	return ArenaCell.ArenaCellState.keys()[get_cell_state_at_position(world_position)]


func get_cells_by_state(state: ArenaCell.ArenaCellState) -> Array[ArenaCell]:
	var matching_cells: Array[ArenaCell] = []
	for cell: ArenaCell in _cells:
		if cell.state == state:
			matching_cells.append(cell)
	return matching_cells


func get_cell_count_by_state(state: ArenaCell.ArenaCellState) -> int:
	return get_cells_by_state(state).size()


func set_cell_state(cell_index: int, state: ArenaCell.ArenaCellState) -> bool:
	if cell_index < 0 or cell_index >= _cells.size():
		return false

	var cell := _cells[cell_index]
	cell.state = state
	_update_cell_runtime_state(cell)
	return true


func reset_all_cell_states() -> void:
	for cell: ArenaCell in _cells:
		set_cell_state(cell.index, ArenaCell.ArenaCellState.NORMAL)


func get_spawn_position() -> Vector3:
	var spawn_point := Vector2.ZERO
	return Vector3(
		spawn_point.x, _get_surface_height(spawn_point) + PLAYER_SPAWN_HEIGHT_METERS, spawn_point.y
	)


func get_center_ground_position() -> Vector3:
	var center := Vector2.ZERO
	return Vector3(center.x, _get_surface_height(center), center.y)


func get_random_valid_position(rng: RandomNumberGenerator) -> Vector3:
	if _cells.is_empty():
		return Vector3.ZERO

	var cell := _pick_weighted_cell(rng, true)
	if cell == null:
		cell = _pick_weighted_cell(rng, false)
	if cell == null:
		return Vector3.ZERO

	var point := _sample_point_in_cell(cell, rng)
	return Vector3(point.x, _get_surface_height(point), point.y)


func get_surface_height_at_position(world_position: Vector3) -> float:
	return _get_surface_height(Vector2(world_position.x, world_position.z))


func _build_cells() -> Array[ArenaCell]:
	var sites := _generate_sites()
	_boundary_polygon = _create_boundary_polygon()
	var built_cells: Array[ArenaCell] = []

	for site_index in range(sites.size()):
		var cell_polygon := PackedVector2Array(_boundary_polygon)
		for other_index in range(sites.size()):
			if site_index == other_index:
				continue
			cell_polygon = _clip_polygon_to_site_half_plane(
				cell_polygon, sites[site_index], sites[other_index]
			)
			if cell_polygon.size() < 3:
				break

		if cell_polygon.size() >= 3:
			built_cells.append(
				ArenaCell.new(built_cells.size(), cell_polygon, arena_config.thickness_meters)
			)

	return built_cells


func _generate_sites() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = arena_config.generation_seed

	var sites := PackedVector2Array()
	var total := maxi(arena_config.cell_count, 3)
	var attempts := 0
	var max_attempts := total * 80
	var site_spawn_radius := (
		maxf(
			arena_config.radius_meters - maxf(arena_config.boundary_irregularity_meters, 0.0),
			arena_config.radius_meters * 0.5
		)
		* 0.94
	)
	sites.append(Vector2.ZERO)

	while sites.size() < total and attempts < max_attempts:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * site_spawn_radius
		var candidate := Vector2(cos(angle), sin(angle)) * radius
		if _is_far_enough_from_existing_sites(candidate, sites):
			sites.append(candidate)

	while sites.size() < total:
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * site_spawn_radius
		sites.append(Vector2(cos(angle), sin(angle)) * radius)

	return sites


func _is_far_enough_from_existing_sites(candidate: Vector2, sites: PackedVector2Array) -> bool:
	var min_distance := arena_config.min_cell_site_distance_meters
	if min_distance <= 0.0:
		return true

	for site: Vector2 in sites:
		if candidate.distance_to(site) < min_distance:
			return false
	return true


func _create_boundary_polygon() -> PackedVector2Array:
	var boundary_polygon := PackedVector2Array()
	var vertex_count := maxi(arena_config.boundary_vertex_count, 24)
	var control_points := maxi(arena_config.boundary_irregularity_control_points, 3)
	var control_offsets := _create_boundary_control_offsets(control_points)

	for vertex_index in range(vertex_count):
		var angle := float(vertex_index) / float(vertex_count) * TAU
		var radius := _get_boundary_radius(vertex_index, vertex_count, control_offsets)
		boundary_polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return boundary_polygon


func _create_boundary_control_offsets(control_points: int) -> Array[float]:
	var rng := RandomNumberGenerator.new()
	rng.seed = arena_config.generation_seed + 7919

	var offsets: Array[float] = []
	var irregularity := maxf(arena_config.boundary_irregularity_meters, 0.0)
	for control_index in range(control_points):
		offsets.append(rng.randf_range(-irregularity, irregularity))

	return offsets


func _get_boundary_radius(
	vertex_index: int, vertex_count: int, control_offsets: Array[float]
) -> float:
	if control_offsets.is_empty():
		return arena_config.radius_meters

	var control_count := control_offsets.size()
	var control_position := float(vertex_index) / float(vertex_count) * float(control_count)
	var first_index := int(floorf(control_position)) % control_count
	var second_index := (first_index + 1) % control_count
	var blend := control_position - floorf(control_position)
	var smooth_blend := blend * blend * (3.0 - 2.0 * blend)
	var radius_offset := lerpf(
		control_offsets[first_index], control_offsets[second_index], smooth_blend
	)
	var min_radius := arena_config.radius_meters * 0.72
	return maxf(arena_config.radius_meters + radius_offset, min_radius)


func _clip_polygon_to_site_half_plane(
	polygon: PackedVector2Array, kept_site: Vector2, clipping_site: Vector2
) -> PackedVector2Array:
	if polygon.is_empty():
		return PackedVector2Array()

	var clipped := PackedVector2Array()
	var normal := clipping_site - kept_site
	var limit := (clipping_site.length_squared() - kept_site.length_squared()) * 0.5

	for vertex_index in range(polygon.size()):
		var current := polygon[vertex_index]
		var next := polygon[(vertex_index + 1) % polygon.size()]
		var current_inside := current.dot(normal) <= limit
		var next_inside := next.dot(normal) <= limit

		if current_inside and next_inside:
			clipped.append(next)
		elif current_inside and not next_inside:
			clipped.append(_intersect_segment_with_half_plane(current, next, normal, limit))
		elif not current_inside and next_inside:
			clipped.append(_intersect_segment_with_half_plane(current, next, normal, limit))
			clipped.append(next)

	return clipped


func _intersect_segment_with_half_plane(
	start: Vector2, end: Vector2, normal: Vector2, limit: float
) -> Vector2:
	var segment := end - start
	var denominator := segment.dot(normal)
	if is_zero_approx(denominator):
		return start

	var ratio := (limit - start.dot(normal)) / denominator
	return start.lerp(end, clampf(ratio, 0.0, 1.0))


func _create_cell_body(cell: ArenaCell) -> void:
	var body := StaticBody3D.new()
	body.name = "Cell%02d" % cell.index
	body.collision_layer = TERRAIN_COLLISION_LAYER
	body.collision_mask = 0

	var mesh := _create_cell_mesh(cell)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = mesh
	mesh_instance.set_surface_override_material(0, _create_floor_material(cell.index))
	if mesh.get_surface_count() > 1:
		mesh_instance.set_surface_override_material(1, _create_wall_material())
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "Collision"
	collision_shape.shape = _create_cell_collision_shape(cell)
	body.add_child(collision_shape)

	if arena_config.debug_show_cell_labels:
		body.add_child(_create_cell_label(cell))

	_generated_root.add_child(body)
	_cell_bodies[cell.index] = body
	_cell_mesh_instances[cell.index] = mesh_instance
	_cell_collision_shapes[cell.index] = collision_shape
	_update_cell_runtime_state(cell)


func _create_cell_mesh(cell: ArenaCell) -> ArrayMesh:
	var mesh := ArrayMesh.new()

	var top_surface := SurfaceTool.new()
	top_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_top_polygon_triangles(top_surface, cell.polygon)
	top_surface.commit(mesh)

	var wall_surface := SurfaceTool.new()
	wall_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_vertex_count := _add_outer_boundary_walls(wall_surface, cell)
	if wall_vertex_count > 0:
		wall_surface.generate_normals()
		wall_surface.commit(mesh)

	return mesh


func _add_top_polygon_triangles(surface_tool: SurfaceTool, polygon: PackedVector2Array) -> int:
	var added_vertices := 0
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for triangle_index in range(0, triangles.size(), 3):
		var first := polygon[triangles[triangle_index]]
		var second := polygon[triangles[triangle_index + 1]]
		var third := polygon[triangles[triangle_index + 2]]
		_add_floor_vertex(surface_tool, first)
		_add_floor_vertex(surface_tool, third)
		_add_floor_vertex(surface_tool, second)
		added_vertices += 3
	return added_vertices


func _add_floor_vertex(surface_tool: SurfaceTool, point: Vector2) -> void:
	surface_tool.set_normal(Vector3.UP)
	surface_tool.add_vertex(_to_surface_vector3(point))


func _add_outer_boundary_walls(surface_tool: SurfaceTool, cell: ArenaCell) -> int:
	var added_vertices := 0
	for vertex_index in range(cell.polygon.size()):
		var current := cell.polygon[vertex_index]
		var next := cell.polygon[(vertex_index + 1) % cell.polygon.size()]
		if not _is_outer_boundary_edge(current, next):
			continue

		var current_top := _to_surface_vector3(current)
		var next_top := _to_surface_vector3(next)
		_add_quad(
			surface_tool,
			current_top,
			current_top - Vector3.UP * cell.thickness_meters,
			next_top - Vector3.UP * cell.thickness_meters,
			next_top
		)
		added_vertices += 6
	return added_vertices


func _create_cell_collision_shape(cell: ArenaCell) -> ConcavePolygonShape3D:
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	var faces := PackedVector3Array()
	var triangles := Geometry2D.triangulate_polygon(cell.polygon)

	for triangle_index in range(0, triangles.size(), 3):
		var first := cell.polygon[triangles[triangle_index]]
		var second := cell.polygon[triangles[triangle_index + 1]]
		var third := cell.polygon[triangles[triangle_index + 2]]
		faces.append(_to_surface_vector3(first))
		faces.append(_to_surface_vector3(third))
		faces.append(_to_surface_vector3(second))

	shape.set_faces(faces)
	return shape


func _create_cell_label(cell: ArenaCell) -> Label3D:
	var label := Label3D.new()
	label.text = str(cell.index)
	var center := cell.get_center_position()
	center.y = get_surface_height_at_position(center)
	label.position = center + Vector3.UP * 0.08
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.65, 0.7, 0.78)
	return label


func _create_floor_material(cell_index: int) -> Material:
	if arena_theme == null:
		arena_theme = ArenaThemeConfig.new()
	if arena_theme.terrain_texture_enabled:
		return _create_terrain_shader_material(cell_index)

	var material := StandardMaterial3D.new()
	material.albedo_color = arena_theme.get_floor_color(cell_index)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = arena_theme.material_roughness
	return material


func _create_terrain_shader_material(cell_index: int) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _get_terrain_shader()
	var has_albedo_texture := arena_theme.terrain_albedo_texture != null
	var has_detail_texture := arena_theme.terrain_detail_texture != null
	material.set_shader_parameter("base_color", arena_theme.get_floor_color(cell_index))
	material.set_shader_parameter("secondary_color", arena_theme.terrain_secondary_color)
	material.set_shader_parameter("accent_color", arena_theme.terrain_accent_color)
	material.set_shader_parameter("use_albedo_texture", has_albedo_texture)
	material.set_shader_parameter("use_detail_texture", has_detail_texture)
	if has_albedo_texture:
		material.set_shader_parameter("albedo_texture", arena_theme.terrain_albedo_texture)
	if has_detail_texture:
		material.set_shader_parameter("detail_texture", arena_theme.terrain_detail_texture)
	material.set_shader_parameter("texture_strength", arena_theme.terrain_texture_strength)
	material.set_shader_parameter("texture_tile_meters", arena_theme.terrain_texture_tile_meters)
	material.set_shader_parameter(
		"variation_strength", arena_theme.terrain_color_variation_strength
	)
	material.set_shader_parameter("patch_scale", arena_theme.terrain_patch_scale_meters)
	material.set_shader_parameter(
		"detail_texture_strength", arena_theme.terrain_detail_texture_strength
	)
	material.set_shader_parameter(
		"detail_texture_tile_meters", arena_theme.terrain_detail_texture_tile_meters
	)
	material.set_shader_parameter("detail_scale", arena_theme.terrain_detail_scale_meters)
	material.set_shader_parameter("detail_strength", arena_theme.terrain_detail_strength)
	material.set_shader_parameter("speckle_strength", arena_theme.terrain_speckle_strength)
	material.set_shader_parameter("roughness_value", arena_theme.material_roughness)
	return material


func _get_terrain_shader() -> Shader:
	if _terrain_shader != null:
		return _terrain_shader

	_terrain_shader = load(TERRAIN_SHADER_PATH) as Shader
	return _terrain_shader


func _create_wall_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if arena_theme == null:
		arena_theme = ArenaThemeConfig.new()
	material.albedo_color = arena_theme.wall_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = arena_theme.material_roughness
	return material


func _update_cell_runtime_state(cell: ArenaCell) -> void:
	var body := _cell_bodies.get(cell.index) as StaticBody3D
	var mesh_instance := _cell_mesh_instances.get(cell.index) as MeshInstance3D
	var collision_shape := _cell_collision_shapes.get(cell.index) as CollisionShape3D
	var is_destroyed := cell.state == ArenaCell.ArenaCellState.DESTROYED

	if body != null:
		body.visible = not is_destroyed
	if collision_shape != null:
		collision_shape.disabled = is_destroyed
	if mesh_instance != null:
		mesh_instance.set_surface_override_material(0, _create_cell_state_material(cell))


func _create_cell_state_material(cell: ArenaCell) -> Material:
	if arena_theme == null:
		arena_theme = ArenaThemeConfig.new()
	if cell.state == ArenaCell.ArenaCellState.NORMAL:
		return _create_floor_material(cell.index)
	var color := arena_theme.get_floor_color(cell.index)
	var emission_energy := 0.0
	match cell.state:
		ArenaCell.ArenaCellState.WARNING:
			color = Color(1.0, 0.78, 0.18, 1.0)
			emission_energy = 0.8
		ArenaCell.ArenaCellState.LAVA:
			color = Color(1.0, 0.22, 0.08, 1.0)
			emission_energy = 1.5
		ArenaCell.ArenaCellState.ICE:
			color = Color(0.18, 0.78, 1.0, 1.0)
			emission_energy = 0.7
		ArenaCell.ArenaCellState.COLLAPSING:
			color = Color(1.0, 0.48, 0.08, 1.0)
			emission_energy = 1.0
		ArenaCell.ArenaCellState.DESTROYED:
			color = Color(0.08, 0.07, 0.06, 1.0)
		ArenaCell.ArenaCellState.REBUILDING:
			color = Color(0.2, 0.92, 0.72, 1.0)
			emission_energy = 0.6
	return _create_hazard_material(color, emission_energy, cell.state)


func _create_hazard_material(
	color: Color, emission_energy: float, state: ArenaCell.ArenaCellState
) -> Material:
	var material := ShaderMaterial.new()
	material.shader = _get_hazard_shader()
	var effect_texture := _get_hazard_effect_texture(state)
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("emission_energy", emission_energy)
	material.set_shader_parameter("use_effect_texture", effect_texture != null)
	if effect_texture != null:
		material.set_shader_parameter("effect_texture", effect_texture)
	material.set_shader_parameter("effect_mode", _get_hazard_effect_mode(state))
	material.set_shader_parameter("effect_strength", _get_hazard_effect_strength(state))
	material.set_shader_parameter("effect_tile_meters", _get_hazard_effect_tile_meters(state))
	material.set_shader_parameter("pulse_speed", _get_hazard_pulse_speed(state))
	material.set_shader_parameter("roughness_value", 0.72)
	return material


func _get_hazard_shader() -> Shader:
	if _hazard_shader != null:
		return _hazard_shader

	_hazard_shader = load(HAZARD_SHADER_PATH) as Shader
	return _hazard_shader


func _get_hazard_effect_texture(state: ArenaCell.ArenaCellState) -> Texture2D:
	var path := _get_hazard_effect_texture_path(state)
	if path.is_empty():
		return null
	if _hazard_effect_textures.has(path):
		return _hazard_effect_textures[path] as Texture2D

	var texture := load(path) as Texture2D
	_hazard_effect_textures[path] = texture
	return texture


func _get_hazard_effect_texture_path(state: ArenaCell.ArenaCellState) -> String:
	match state:
		ArenaCell.ArenaCellState.WARNING:
			return WARNING_EFFECT_TEXTURE_PATH
		ArenaCell.ArenaCellState.LAVA:
			return LAVA_EFFECT_TEXTURE_PATH
		ArenaCell.ArenaCellState.ICE:
			return ICE_EFFECT_TEXTURE_PATH
		ArenaCell.ArenaCellState.COLLAPSING:
			return COLLAPSE_EFFECT_TEXTURE_PATH
		ArenaCell.ArenaCellState.REBUILDING:
			return ICE_EFFECT_TEXTURE_PATH
	return ""


func _get_hazard_effect_mode(state: ArenaCell.ArenaCellState) -> int:
	match state:
		ArenaCell.ArenaCellState.LAVA:
			return 1
		ArenaCell.ArenaCellState.ICE:
			return 2
		ArenaCell.ArenaCellState.REBUILDING:
			return 3
	return 0


func _get_hazard_effect_strength(state: ArenaCell.ArenaCellState) -> float:
	match state:
		ArenaCell.ArenaCellState.WARNING:
			return 0.56
		ArenaCell.ArenaCellState.LAVA:
			return 0.74
		ArenaCell.ArenaCellState.ICE:
			return 0.62
		ArenaCell.ArenaCellState.COLLAPSING:
			return 0.7
		ArenaCell.ArenaCellState.REBUILDING:
			return 0.48
	return 0.0


func _get_hazard_effect_tile_meters(state: ArenaCell.ArenaCellState) -> float:
	match state:
		ArenaCell.ArenaCellState.WARNING:
			return 3.0
		ArenaCell.ArenaCellState.LAVA:
			return 5.2
		ArenaCell.ArenaCellState.ICE:
			return 4.4
		ArenaCell.ArenaCellState.COLLAPSING:
			return 4.0
		ArenaCell.ArenaCellState.REBUILDING:
			return 3.6
	return 4.0


func _get_hazard_pulse_speed(state: ArenaCell.ArenaCellState) -> float:
	match state:
		ArenaCell.ArenaCellState.WARNING:
			return 4.5
		ArenaCell.ArenaCellState.LAVA:
			return 2.0
		ArenaCell.ArenaCellState.ICE:
			return 1.1
		ArenaCell.ArenaCellState.COLLAPSING:
			return 5.4
		ArenaCell.ArenaCellState.REBUILDING:
			return 2.8
	return 1.0


func _create_trim_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	return material


func _create_arena_trim() -> void:
	if arena_theme == null:
		arena_theme = ArenaThemeConfig.new()

	var mesh := ArrayMesh.new()
	var seam_vertex_count := 0
	var border_vertex_count := 0

	var seam_surface := SurfaceTool.new()
	seam_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	seam_vertex_count = _add_arena_trim_edges(seam_surface, false, arena_theme.seam_width_meters)
	if seam_vertex_count > 0:
		seam_surface.generate_normals()
		seam_surface.commit(mesh)

	var border_surface := SurfaceTool.new()
	border_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	border_vertex_count = _add_arena_trim_edges(
		border_surface, true, arena_theme.border_width_meters
	)
	if border_vertex_count > 0:
		border_surface.generate_normals()
		border_surface.commit(mesh)

	if mesh.get_surface_count() == 0:
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ArenaTrim"
	mesh_instance.mesh = mesh
	var surface_index := 0
	if seam_vertex_count > 0:
		mesh_instance.set_surface_override_material(
			surface_index, _create_trim_material(arena_theme.seam_color)
		)
		surface_index += 1
	if border_vertex_count > 0:
		mesh_instance.set_surface_override_material(
			surface_index, _create_trim_material(arena_theme.border_color)
		)
	_generated_root.add_child(mesh_instance)


func _add_arena_trim_edges(
	surface_tool: SurfaceTool, include_outer_edges: bool, width_meters: float
) -> int:
	if width_meters <= 0.0:
		return 0

	var added_vertices := 0
	var emitted_edges := {}
	for cell: ArenaCell in _cells:
		for vertex_index in range(cell.polygon.size()):
			var current := cell.polygon[vertex_index]
			var next := cell.polygon[(vertex_index + 1) % cell.polygon.size()]
			var is_outer := _is_outer_boundary_edge(current, next)
			if is_outer != include_outer_edges:
				continue

			var edge_key := _create_edge_key(current, next)
			if emitted_edges.has(edge_key):
				continue

			emitted_edges[edge_key] = true
			added_vertices += _add_edge_strip(surface_tool, current, next, width_meters)

	return added_vertices


func _add_edge_strip(
	surface_tool: SurfaceTool, first: Vector2, second: Vector2, width_meters: float
) -> int:
	var segment := second - first
	if segment.length_squared() <= 0.0001:
		return 0

	var direction := segment.normalized()
	var normal := Vector2(-direction.y, direction.x)
	var half_width := width_meters * 0.5
	var first_left := first + normal * half_width
	var first_right := first - normal * half_width
	var second_left := second + normal * half_width
	var second_right := second - normal * half_width

	surface_tool.add_vertex(_to_trim_vector3(first_left))
	surface_tool.add_vertex(_to_trim_vector3(second_left))
	surface_tool.add_vertex(_to_trim_vector3(second_right))
	surface_tool.add_vertex(_to_trim_vector3(first_left))
	surface_tool.add_vertex(_to_trim_vector3(second_right))
	surface_tool.add_vertex(_to_trim_vector3(first_right))
	return 6


func _create_edge_key(first: Vector2, second: Vector2) -> String:
	var first_key := _rounded_point_key(first)
	var second_key := _rounded_point_key(second)
	if first_key < second_key:
		return "%s|%s" % [first_key, second_key]
	return "%s|%s" % [second_key, first_key]


func _rounded_point_key(point: Vector2) -> String:
	return "%d,%d" % [roundi(point.x * 100.0), roundi(point.y * 100.0)]


func _get_total_cell_area() -> float:
	var total_area := 0.0
	for cell: ArenaCell in _cells:
		total_area += cell.get_area()
	return total_area


func _pick_weighted_cell(rng: RandomNumberGenerator, safe_only: bool = false) -> ArenaCell:
	var candidate_cells: Array[ArenaCell] = []
	for cell: ArenaCell in _cells:
		if safe_only and not _is_cell_safe_for_spawn(cell):
			continue
		if not safe_only and cell.state == ArenaCell.ArenaCellState.DESTROYED:
			continue
		candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return null

	var total_area := 0.0
	for cell: ArenaCell in candidate_cells:
		total_area += cell.get_area()

	var target_area := rng.randf_range(0.0, total_area)
	var cumulative_area := 0.0
	for cell: ArenaCell in candidate_cells:
		cumulative_area += cell.get_area()
		if cumulative_area >= target_area:
			return cell

	return candidate_cells.back()


func _is_cell_safe_for_spawn(cell: ArenaCell) -> bool:
	return cell.state == ArenaCell.ArenaCellState.NORMAL


func _sample_point_in_cell(cell: ArenaCell, rng: RandomNumberGenerator) -> Vector2:
	var triangles := Geometry2D.triangulate_polygon(cell.polygon)
	if triangles.size() < 3:
		var fallback := cell.get_center_position()
		return Vector2(fallback.x, fallback.z)

	var triangle_areas: Array[float] = []
	var total_area := 0.0
	for triangle_index in range(0, triangles.size(), 3):
		var first := cell.polygon[triangles[triangle_index]]
		var second := cell.polygon[triangles[triangle_index + 1]]
		var third := cell.polygon[triangles[triangle_index + 2]]
		var area := absf((second - first).cross(third - first)) * 0.5
		triangle_areas.append(area)
		total_area += area

	var selected_area := rng.randf_range(0.0, total_area)
	var cumulative_area := 0.0
	var selected_triangle := 0
	for area_index in range(triangle_areas.size()):
		cumulative_area += triangle_areas[area_index]
		if cumulative_area >= selected_area:
			selected_triangle = area_index
			break

	var index_offset := selected_triangle * 3
	var a := cell.polygon[triangles[index_offset]]
	var b := cell.polygon[triangles[index_offset + 1]]
	var c := cell.polygon[triangles[index_offset + 2]]
	var first_random := sqrt(rng.randf())
	var second_random := rng.randf()

	return (
		a * (1.0 - first_random)
		+ b * (first_random * (1.0 - second_random))
		+ c * (first_random * second_random)
	)


func _is_outer_boundary_edge(first: Vector2, second: Vector2) -> bool:
	return _is_point_on_boundary(first) and _is_point_on_boundary(second)


func _is_point_on_boundary(point: Vector2) -> bool:
	if _boundary_polygon.size() < 2:
		return false

	for vertex_index in range(_boundary_polygon.size()):
		var first := _boundary_polygon[vertex_index]
		var second := _boundary_polygon[(vertex_index + 1) % _boundary_polygon.size()]
		if _distance_to_segment(point, first, second) <= BOUNDARY_EPSILON_METERS:
			return true

	return false


func _distance_to_segment(point: Vector2, first: Vector2, second: Vector2) -> float:
	var segment := second - first
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_to(first)

	var ratio := clampf((point - first).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(first + segment * ratio)


func _add_quad(
	surface_tool: SurfaceTool, first: Vector3, second: Vector3, third: Vector3, fourth: Vector3
) -> void:
	surface_tool.add_vertex(first)
	surface_tool.add_vertex(second)
	surface_tool.add_vertex(third)
	surface_tool.add_vertex(first)
	surface_tool.add_vertex(third)
	surface_tool.add_vertex(fourth)


func _to_surface_vector3(point: Vector2) -> Vector3:
	return Vector3(point.x, _get_surface_height(point), point.y)


func _to_trim_vector3(point: Vector2) -> Vector3:
	var height_offset := 0.04
	if arena_theme != null:
		height_offset = arena_theme.trim_height_offset_meters
	return Vector3(point.x, _get_surface_height(point) + height_offset, point.y)


func _get_surface_height(point: Vector2) -> float:
	var amplitude := maxf(arena_config.surface_height_amplitude_meters, 0.0)
	if is_zero_approx(amplitude):
		return 0.0

	var frequency := maxf(arena_config.surface_height_frequency, 0.001)
	var seed_offset := float(arena_config.generation_seed % 997)
	var first_wave := sin(point.x * frequency + seed_offset * 0.17) * 0.5
	var second_wave := cos(point.y * frequency * 0.83 - seed_offset * 0.11) * 0.35
	var diagonal_wave := sin((point.x + point.y) * frequency * 0.47 + seed_offset * 0.07) * 0.15
	return (first_wave + second_wave + diagonal_wave) * amplitude


func _clear_generated_arena() -> void:
	if _generated_root != null:
		remove_child(_generated_root)
		_generated_root.free()
		_generated_root = null
	_cells.clear()
	_cell_bodies.clear()
	_cell_mesh_instances.clear()
	_cell_collision_shapes.clear()
