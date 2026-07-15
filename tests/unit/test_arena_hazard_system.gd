extends GutTest


func test_arena_hazard_config_defaults_are_valid() -> void:
	var config := ArenaHazardConfig.new()

	assert_true(config.is_valid_config())
	assert_eq(config.hazard_type, ArenaHazardConfig.HazardType.LAVA)
	assert_eq(config.affected_cell_count_min, 2)
	assert_eq(config.affected_cell_count_max, 3)
	assert_eq(config.lava_damage_profile.damage_type, DamageProfile.DamageType.TERRAIN)
	assert_eq(config.lava_damage_profile.death_reason, &"terrain_lava")
	assert_eq(config.destroyed_damage_profile.damage_type, DamageProfile.DamageType.TERRAIN)
	assert_true(config.destroyed_damage_profile.ignores_invulnerability)
	assert_eq(config.destroyed_damage_profile.death_reason, &"terrain_destroyed")
	assert_gt(config.ice_speed_multiplier, 1.0)
	assert_lt(config.ice_acceleration_multiplier, 1.0)
	assert_lt(config.ice_deceleration_multiplier, 1.0)
	assert_lt(config.ice_turn_acceleration_multiplier, 1.0)


func test_hazard_system_respects_executor_contract_and_spawns_warning_cells() -> void:
	var runtime := await _create_runtime()
	var system := runtime["system"] as ArenaHazardSystem
	var arena := runtime["arena"] as ArenaController
	var definition := _create_definition(_create_config(ArenaHazardConfig.HazardType.LAVA))

	assert_true(system.supports_danger_family(DangerDefinition.DangerFamily.TERRAIN_HAZARD))
	assert_false(system.supports_danger_family(DangerDefinition.DangerFamily.ACTOR_ENEMY))
	assert_true(system.request_spawn_danger(definition))
	assert_eq(system.get_active_danger_count(definition), 1)
	assert_eq(system.get_total_active_danger_count(), 1)
	assert_eq(system.get_warning_cell_count(), 2)
	assert_eq(arena.get_cell_count_by_state(ArenaCell.ArenaCellState.WARNING), 2)

	_free_runtime(runtime)


func test_lava_transitions_and_applies_tick_damage_only_on_lava_cell() -> void:
	var runtime := await _create_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ArenaHazardSystem
	var config := _create_config(ArenaHazardConfig.HazardType.LAVA)
	var cell := arena.get_cells()[4]
	player.global_position = _cell_player_position(arena, cell)

	assert_true(system.force_spawn_hazard_on_cells_for_tests(config, [cell.index]))
	system.step_system_for_tests(config.warning_duration_seconds + 0.01)

	assert_eq(cell.state, ArenaCell.ArenaCellState.LAVA)
	assert_eq(system.get_lava_cell_count(), 1)

	system.step_system_for_tests(0.0)

	assert_almost_eq(health.get_current_health(), 88.0, 0.001)
	assert_eq(health.get_last_damage_type(), DamageProfile.DamageType.TERRAIN)

	var safe_cell := arena.get_cells()[8]
	player.global_position = _cell_player_position(arena, safe_cell)
	health.step_component_for_tests(config.lava_damage_tick_seconds)
	system.step_system_for_tests(config.lava_damage_tick_seconds)

	assert_almost_eq(health.get_current_health(), 88.0, 0.001)

	_free_runtime(runtime)


func test_ice_applies_and_clears_player_surface_modifier() -> void:
	var runtime := await _create_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ArenaHazardSystem
	var config := _create_config(ArenaHazardConfig.HazardType.ICE)
	var ice_cell := arena.get_cells()[6]
	var safe_cell := arena.get_cells()[9]
	player.global_position = _cell_player_position(arena, ice_cell)

	assert_true(system.force_spawn_hazard_on_cells_for_tests(config, [ice_cell.index]))
	system.step_system_for_tests(config.warning_duration_seconds + 0.01)

	assert_eq(ice_cell.state, ArenaCell.ArenaCellState.ICE)
	assert_eq(player.get_surface_modifier_id(), &"ice")
	assert_almost_eq(player.get_surface_speed_multiplier(), config.ice_speed_multiplier, 0.001)

	player.global_position = _cell_player_position(arena, safe_cell)
	system.step_system_for_tests(0.01)

	assert_eq(player.get_surface_modifier_id(), &"")
	assert_almost_eq(player.get_surface_speed_multiplier(), 1.0, 0.001)

	_free_runtime(runtime)


func test_collapse_destroys_rebuilds_and_destroyed_cell_depletes_health() -> void:
	var runtime := await _create_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ArenaHazardSystem
	var config := _create_config(ArenaHazardConfig.HazardType.COLLAPSE)
	var cell := arena.get_cells()[10]
	player.global_position = _cell_player_position(arena, cell)

	assert_true(system.force_spawn_hazard_on_cells_for_tests(config, [cell.index]))
	system.step_system_for_tests(config.warning_duration_seconds + 0.01)

	assert_eq(cell.state, ArenaCell.ArenaCellState.COLLAPSING)

	system.step_system_for_tests(config.collapsing_duration_seconds + 0.01)

	assert_eq(cell.state, ArenaCell.ArenaCellState.DESTROYED)
	assert_eq(system.get_destroyed_cell_count(), 1)

	system.step_system_for_tests(0.0)

	assert_false(health.is_alive())
	assert_eq(health.get_last_damage_reason(), &"terrain_destroyed")

	_free_runtime(runtime)

	var rebuild_runtime := await _create_runtime()
	arena = rebuild_runtime["arena"] as ArenaController
	system = rebuild_runtime["system"] as ArenaHazardSystem
	config = _create_config(ArenaHazardConfig.HazardType.COLLAPSE)
	cell = arena.get_cells()[10]
	assert_true(system.force_spawn_hazard_on_cells_for_tests(config, [cell.index]))
	system.step_system_for_tests(config.warning_duration_seconds + 0.01)
	system.step_system_for_tests(config.collapsing_duration_seconds + 0.01)
	system.step_system_for_tests(config.destroyed_duration_seconds + 0.01)
	assert_eq(cell.state, ArenaCell.ArenaCellState.REBUILDING)
	system.step_system_for_tests(config.rebuilding_duration_seconds + 0.01)
	assert_eq(cell.state, ArenaCell.ArenaCellState.NORMAL)
	assert_eq(system.get_active_hazard_count(), 0)

	_free_runtime(rebuild_runtime)


func test_falling_outside_arena_depletes_health_only_below_threshold() -> void:
	var runtime := await _create_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ArenaHazardSystem
	var outside_position := Vector3(arena.arena_config.radius_meters + 12.0, 0.0, 0.0)
	var surface_height := arena.get_surface_height_at_position(outside_position)

	system.fall_death_depth_meters = 6.0
	player.global_position = Vector3(outside_position.x, surface_height - 5.5, outside_position.z)
	system.step_system_for_tests(0.0)

	assert_true(health.is_alive())
	assert_almost_eq(health.get_current_health(), 100.0, 0.001)

	player.global_position = Vector3(outside_position.x, surface_height - 6.1, outside_position.z)
	system.step_system_for_tests(0.0)

	assert_false(health.is_alive())
	assert_eq(health.get_last_damage_reason(), &"fell_out_of_arena")
	assert_eq(health.get_last_damage_type(), DamageProfile.DamageType.TERRAIN)

	_free_runtime(runtime)


func test_clear_all_restores_cells_and_player_modifier() -> void:
	var runtime := await _create_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ArenaHazardSystem
	var config := _create_config(ArenaHazardConfig.HazardType.ICE)
	var cell := arena.get_cells()[12]
	player.global_position = _cell_player_position(arena, cell)

	assert_true(system.force_spawn_hazard_on_cells_for_tests(config, [cell.index]))
	system.step_system_for_tests(config.warning_duration_seconds + 0.01)
	assert_eq(player.get_surface_modifier_id(), &"ice")

	system.clear_all()

	assert_eq(system.get_active_hazard_count(), 0)
	assert_eq(arena.get_cell_count_by_state(ArenaCell.ArenaCellState.ICE), 0)
	assert_eq(cell.state, ArenaCell.ArenaCellState.NORMAL)
	assert_eq(player.get_surface_modifier_id(), &"")

	_free_runtime(runtime)


func _create_runtime() -> Dictionary:
	var root := Node.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var health := HealthComponent.new()
	var health_config := HealthConfig.new()
	var system := ArenaHazardSystem.new()

	root.name = "HazardRuntime"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	health.name = "HealthComponent"
	system.name = "ArenaHazardSystem"
	health_config.hit_invulnerability_seconds = 0.0
	health.health_config = health_config
	system.run_controller_path = NodePath("../RunController")
	system.arena_path = NodePath("../Arena")
	system.player_path = NodePath("../Player")
	system.health_component_path = NodePath("../HealthComponent")

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(health)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()

	return {
		"root": root,
		"run_controller": run_controller,
		"arena": arena,
		"player": player,
		"health": health,
		"system": system,
	}


func _create_definition(config: ArenaHazardConfig) -> DangerDefinition:
	var definition := DangerDefinition.new()
	definition.danger_id = StringName("test_%s" % config.get_hazard_type_name().to_lower())
	definition.family = DangerDefinition.DangerFamily.TERRAIN_HAZARD
	definition.spawn_cost = 1.0
	definition.selection_weight = 1.0
	definition.cooldown_seconds = 0.0
	definition.max_active_instances = 4
	definition.specialized_config = config
	return definition


func _create_config(hazard_type: ArenaHazardConfig.HazardType) -> ArenaHazardConfig:
	var config := ArenaHazardConfig.new()
	config.hazard_type = hazard_type
	config.affected_cell_count_min = 2
	config.affected_cell_count_max = 2
	config.warning_duration_seconds = 0.05
	config.active_duration_seconds = 0.2
	config.collapsing_duration_seconds = 0.05
	config.destroyed_duration_seconds = 0.1
	config.rebuilding_duration_seconds = 0.05
	config.min_distance_from_player_meters = 0.0
	config.center_safe_radius_meters = 0.0
	config.lava_damage_tick_seconds = 0.1
	return config


func _cell_player_position(arena: ArenaController, cell: ArenaCell) -> Vector3:
	var position := cell.get_center_position()
	position.y = arena.get_surface_height_at_position(position) + 0.9
	return position


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
