class_name ArenaController
extends Node3D

const TERRAIN_COLLISION_LAYER := 1 << 1
const PLAYER_SPAWN_HEIGHT_METERS := 1.05
const BOUNDARY_EPSILON_METERS := 0.08

@export var arena_config: ArenaConfig = ArenaConfig.new()

var _cells: Array[ArenaCell] = []
var _generated_root: Node3D


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

	DebugLog.info(
		&"Arena",
		(
			"generate done cells=%d area=%.2f children=%d"
			% [_cells.size(), _get_total_cell_area(), _generated_root.get_child_count()]
		)
	)


func get_cells() -> Array[ArenaCell]:
	return _cells.duplicate()


func get_spawn_position() -> Vector3:
	return Vector3(0.0, PLAYER_SPAWN_HEIGHT_METERS, 0.0)


func get_random_valid_position(rng: RandomNumberGenerator) -> Vector3:
	if _cells.is_empty():
		return Vector3.ZERO

	var cell := _pick_weighted_cell(rng)
	var point := _sample_point_in_cell(cell, rng)
	return Vector3(point.x, 0.0, point.y)


func _build_cells() -> Array[ArenaCell]:
	var sites := _generate_sites()
	var boundary_polygon := _create_boundary_polygon()
	var built_cells: Array[ArenaCell] = []

	for site_index in range(sites.size()):
		var cell_polygon := PackedVector2Array(boundary_polygon)
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
	sites.append(Vector2.ZERO)

	while sites.size() < total and attempts < max_attempts:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * arena_config.radius_meters * 0.92
		var candidate := Vector2(cos(angle), sin(angle)) * radius
		if _is_far_enough_from_existing_sites(candidate, sites):
			sites.append(candidate)

	while sites.size() < total:
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * arena_config.radius_meters * 0.92
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

	for vertex_index in range(vertex_count):
		var angle := float(vertex_index) / float(vertex_count) * TAU
		boundary_polygon.append(Vector2(cos(angle), sin(angle)) * arena_config.radius_meters)

	return boundary_polygon


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
	mesh_instance.set_surface_override_material(0, _create_cell_material(cell.index))
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "Collision"
	collision_shape.shape = _create_cell_collision_shape(cell)
	body.add_child(collision_shape)

	if arena_config.debug_show_cell_labels:
		body.add_child(_create_cell_label(cell))

	_generated_root.add_child(body)


func _create_cell_mesh(cell: ArenaCell) -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_top_polygon_triangles(surface_tool, cell.polygon, 0.0)
	_add_outer_boundary_walls(surface_tool, cell)

	surface_tool.generate_normals()
	return surface_tool.commit()


func _add_top_polygon_triangles(
	surface_tool: SurfaceTool, polygon: PackedVector2Array, y: float
) -> void:
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for triangle_index in range(0, triangles.size(), 3):
		var first := polygon[triangles[triangle_index]]
		var second := polygon[triangles[triangle_index + 1]]
		var third := polygon[triangles[triangle_index + 2]]
		surface_tool.add_vertex(_to_vector3(first, y))
		surface_tool.add_vertex(_to_vector3(third, y))
		surface_tool.add_vertex(_to_vector3(second, y))


func _add_outer_boundary_walls(surface_tool: SurfaceTool, cell: ArenaCell) -> void:
	var bottom_y := -cell.thickness_meters
	for vertex_index in range(cell.polygon.size()):
		var current := cell.polygon[vertex_index]
		var next := cell.polygon[(vertex_index + 1) % cell.polygon.size()]
		if not _is_outer_boundary_edge(current, next):
			continue

		_add_quad(
			surface_tool,
			_to_vector3(current, 0.0),
			_to_vector3(current, bottom_y),
			_to_vector3(next, bottom_y),
			_to_vector3(next, 0.0)
		)


func _create_cell_collision_shape(cell: ArenaCell) -> ConcavePolygonShape3D:
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	var faces := PackedVector3Array()
	var triangles := Geometry2D.triangulate_polygon(cell.polygon)

	for triangle_index in range(0, triangles.size(), 3):
		var first := cell.polygon[triangles[triangle_index]]
		var second := cell.polygon[triangles[triangle_index + 1]]
		var third := cell.polygon[triangles[triangle_index + 2]]
		faces.append(_to_vector3(first, 0.0))
		faces.append(_to_vector3(third, 0.0))
		faces.append(_to_vector3(second, 0.0))

	shape.set_faces(faces)
	return shape


func _create_cell_label(cell: ArenaCell) -> Label3D:
	var label := Label3D.new()
	label.text = str(cell.index)
	label.position = cell.get_center_position() + Vector3.UP * 0.08
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.65, 0.7, 0.78)
	return label


func _create_cell_material(cell_index: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var shade_offset := 0.026 * float(cell_index % 5)
	material.albedo_color = Color(0.3 + shade_offset, 0.34 + shade_offset, 0.41 + shade_offset, 1.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.78
	return material


func _get_total_cell_area() -> float:
	var total_area := 0.0
	for cell: ArenaCell in _cells:
		total_area += cell.get_area()
	return total_area


func _pick_weighted_cell(rng: RandomNumberGenerator) -> ArenaCell:
	var total_area := 0.0
	for cell: ArenaCell in _cells:
		total_area += cell.get_area()

	var target_area := rng.randf_range(0.0, total_area)
	var cumulative_area := 0.0
	for cell: ArenaCell in _cells:
		cumulative_area += cell.get_area()
		if cumulative_area >= target_area:
			return cell

	return _cells.back()


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
	return (
		first.length() >= arena_config.radius_meters - BOUNDARY_EPSILON_METERS
		and second.length() >= arena_config.radius_meters - BOUNDARY_EPSILON_METERS
	)


func _add_quad(
	surface_tool: SurfaceTool, first: Vector3, second: Vector3, third: Vector3, fourth: Vector3
) -> void:
	surface_tool.add_vertex(first)
	surface_tool.add_vertex(second)
	surface_tool.add_vertex(third)
	surface_tool.add_vertex(first)
	surface_tool.add_vertex(third)
	surface_tool.add_vertex(fourth)


func _to_vector3(point: Vector2, y: float) -> Vector3:
	return Vector3(point.x, y, point.y)


func _clear_generated_arena() -> void:
	if _generated_root != null:
		remove_child(_generated_root)
		_generated_root.free()
		_generated_root = null
	_cells.clear()
