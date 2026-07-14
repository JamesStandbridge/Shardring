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
	var arena := ArenaController.new()
	arena.arena_config = config

	arena.generate_arena()

	var max_vertex_count := 0
	for cell: ArenaCell in arena.get_cells():
		max_vertex_count = maxi(max_vertex_count, cell.polygon.size())
		assert_gte(cell.polygon.size(), 3)
		assert_gt(cell.get_area(), 0.01)
		assert_eq(cell.thickness_meters, config.thickness_meters)
		assert_eq(cell.state, ArenaCell.ArenaCellState.NORMAL)
		for vertex: Vector2 in cell.polygon:
			assert_lte(vertex.length(), config.radius_meters + 0.01)

	assert_gte(max_vertex_count, 5)

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
		assert_eq(valid_position.y, 0.0)

	arena.free()


func _build_arena_with_seed(generation_seed_value: int) -> ArenaController:
	var config := ArenaConfig.new()
	config.generation_seed = generation_seed_value
	var arena := ArenaController.new()
	arena.arena_config = config
	arena.generate_arena()
	return arena


func _is_inside_any_cell(position: Vector3, cells: Array[ArenaCell]) -> bool:
	for cell: ArenaCell in cells:
		if cell.contains_horizontal_position(position):
			return true
	return false
