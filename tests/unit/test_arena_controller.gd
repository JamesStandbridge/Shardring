extends GutTest


func test_generation_is_deterministic_with_same_seed() -> void:
	var first_arena := _build_arena_with_seed(123)
	var second_arena := _build_arena_with_seed(123)

	var first_cells := first_arena.get_cells()
	var second_cells := second_arena.get_cells()

	assert_eq(first_cells.size(), second_cells.size())
	for index in range(first_cells.size()):
		var first_cell := first_cells[index]
		var second_cell := second_cells[index]
		assert_eq(first_cell.polygon.size(), second_cell.polygon.size())
		assert_true(is_equal_approx(first_cell.get_area(), second_cell.get_area()))
		for vertex_index in range(first_cell.polygon.size()):
			assert_true(
				first_cell.polygon[vertex_index].is_equal_approx(second_cell.polygon[vertex_index])
			)

	first_arena.free()
	second_arena.free()


func test_cell_count_matches_config() -> void:
	var config := ArenaConfig.new()
	config.cell_count = 16
	var arena := ArenaController.new()
	arena.arena_config = config

	arena.generate_arena()

	assert_eq(arena.get_cells().size(), config.cell_count)

	arena.free()


func test_cells_are_irregular_polygons_inside_arena_disk() -> void:
	var config := ArenaConfig.new()
	config.radius_meters = 16.0
	config.cell_count = 24
	config.thickness_meters = 1.25
	config.boundary_irregularity_meters = 1.5
	var arena := ArenaController.new()
	arena.arena_config = config

	arena.generate_arena()

	var max_vertex_count := 0
	var has_irregular_boundary_vertex := false
	for cell: ArenaCell in arena.get_cells():
		max_vertex_count = maxi(max_vertex_count, cell.polygon.size())
		assert_gte(cell.polygon.size(), 3)
		assert_gt(cell.get_area(), 0.01)
		assert_eq(cell.thickness_meters, config.thickness_meters)
		assert_eq(cell.state, ArenaCell.ArenaCellState.NORMAL)
		for vertex: Vector2 in cell.polygon:
			assert_lte(
				vertex.length(), config.radius_meters + config.boundary_irregularity_meters + 0.01
			)
			if vertex.length() > config.radius_meters + 0.25:
				has_irregular_boundary_vertex = true

	assert_gte(max_vertex_count, 5)
	assert_true(has_irregular_boundary_vertex)

	arena.free()


func test_spawn_and_random_positions_are_on_valid_cells() -> void:
	var arena := _build_arena_with_seed(789)
	var rng := RandomNumberGenerator.new()
	rng.seed = 88

	var spawn_position := arena.get_spawn_position()
	assert_true(_is_inside_any_cell(spawn_position, arena.get_cells()))
	assert_gt(spawn_position.y, 0.0)

	for index in range(20):
		var valid_position := arena.get_random_valid_position(rng)
		assert_true(_is_inside_any_cell(valid_position, arena.get_cells()))
		assert_almost_eq(
			valid_position.y, arena.get_surface_height_at_position(valid_position), 0.001
		)

	arena.free()


func test_surface_height_is_deterministic_and_subtle() -> void:
	var first_arena := _build_arena_with_seed(321)
	var second_arena := _build_arena_with_seed(321)
	var sample_position := Vector3(8.0, 0.0, -11.0)

	var first_height := first_arena.get_surface_height_at_position(sample_position)
	var second_height := second_arena.get_surface_height_at_position(sample_position)

	assert_almost_eq(first_height, second_height, 0.001)
	assert_lte(absf(first_height), first_arena.arena_config.surface_height_amplitude_meters + 0.001)

	first_arena.free()
	second_arena.free()


func test_cell_state_api_updates_visual_collision_and_lookup() -> void:
	var arena := _build_arena_with_seed(42)
	var cell := arena.get_cells()[0]
	var cell_position := cell.get_center_position()
	var body := arena.get_node("GeneratedArena/Cell00") as StaticBody3D
	var collision_shape := arena.get_node("GeneratedArena/Cell00/Collision") as CollisionShape3D

	assert_same(arena.get_cell_at_position(cell_position), cell)
	assert_eq(arena.get_cell_state_at_position(cell_position), ArenaCell.ArenaCellState.NORMAL)
	assert_true(body.visible)
	assert_false(collision_shape.disabled)

	assert_true(arena.set_cell_state(cell.index, ArenaCell.ArenaCellState.DESTROYED))

	assert_eq(cell.state, ArenaCell.ArenaCellState.DESTROYED)
	assert_eq(arena.get_cell_count_by_state(ArenaCell.ArenaCellState.DESTROYED), 1)
	assert_false(body.visible)
	assert_true(collision_shape.disabled)

	arena.reset_all_cell_states()

	assert_eq(cell.state, ArenaCell.ArenaCellState.NORMAL)
	assert_true(body.visible)
	assert_false(collision_shape.disabled)

	arena.free()


func test_random_valid_position_avoids_dangerous_cells_when_possible() -> void:
	var arena := _build_arena_with_seed(77)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	for cell: ArenaCell in arena.get_cells():
		arena.set_cell_state(cell.index, ArenaCell.ArenaCellState.LAVA)
	arena.set_cell_state(3, ArenaCell.ArenaCellState.NORMAL)

	for sample_index in range(10):
		var position := arena.get_random_valid_position(rng)
		var sampled_cell := arena.get_cell_at_position(position)
		assert_not_null(sampled_cell)
		assert_eq(sampled_cell.state, ArenaCell.ArenaCellState.NORMAL)

	arena.free()


func test_default_arena_theme_does_not_render_internal_cell_seams() -> void:
	var theme := load("res://src/data/stages/themes/toybox_mint_theme.tres") as ArenaThemeConfig
	var warning_texture := (
		load("res://assets/art/textures/terrain/hazard_warning_stripes.png") as Texture2D
	)
	var arena := _build_arena_with_seed(42, theme)
	var trim := arena.get_node("GeneratedArena/ArenaTrim") as MeshInstance3D
	var first_cell_mesh := arena.get_node("GeneratedArena/Cell00/Mesh") as MeshInstance3D
	var normal_material := first_cell_mesh.get_surface_override_material(0) as ShaderMaterial

	assert_eq(arena.arena_theme.seam_width_meters, 0.0)
	assert_not_null(trim)
	assert_eq(trim.mesh.get_surface_count(), 1)
	assert_true(arena.arena_theme.terrain_texture_enabled)
	assert_not_null(normal_material)
	assert_not_null(normal_material.shader)
	assert_eq(
		normal_material.get_shader_parameter("base_color"), arena.arena_theme.get_floor_color(0)
	)
	assert_true(normal_material.get_shader_parameter("use_albedo_texture"))
	assert_true(normal_material.get_shader_parameter("use_detail_texture"))
	assert_eq(
		normal_material.get_shader_parameter("albedo_texture").resource_path,
		theme.terrain_albedo_texture.resource_path
	)
	assert_eq(
		normal_material.get_shader_parameter("detail_texture").resource_path,
		theme.terrain_detail_texture.resource_path
	)

	assert_true(arena.set_cell_state(0, ArenaCell.ArenaCellState.WARNING))
	var warning_material := first_cell_mesh.get_surface_override_material(0) as ShaderMaterial
	assert_not_null(warning_material)
	assert_not_null(warning_material.shader)
	assert_true(warning_material.get_shader_parameter("use_effect_texture"))
	assert_eq(
		warning_material.get_shader_parameter("effect_texture").resource_path,
		warning_texture.resource_path
	)
	arena.reset_all_cell_states()

	assert_true(first_cell_mesh.get_surface_override_material(0) is ShaderMaterial)

	arena.free()


func _build_arena_with_seed(
	generation_seed_value: int, theme_override: ArenaThemeConfig = null
) -> ArenaController:
	var config := ArenaConfig.new()
	config.generation_seed = generation_seed_value
	var arena := ArenaController.new()
	arena.arena_config = config
	if theme_override != null:
		arena.arena_theme = theme_override
	arena.generate_arena()
	return arena


func _is_inside_any_cell(position: Vector3, cells: Array[ArenaCell]) -> bool:
	for cell: ArenaCell in cells:
		if cell.contains_horizontal_position(position):
			return true
	return false
