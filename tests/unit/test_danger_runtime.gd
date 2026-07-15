extends GutTest


func test_danger_definition_defaults_are_valid() -> void:
	var definition := DangerDefinition.new()
	var director_config := DangerDirectorConfig.new()

	assert_true(definition.is_valid_definition())
	assert_eq(definition.family, DangerDefinition.DangerFamily.PROJECTILE_LAUNCHER)
	assert_gt(definition.spawn_cost, 0.0)
	assert_gt(definition.selection_weight, 0.0)
	assert_gt(definition.max_active_instances, 0)
	assert_true(definition.can_unlock_at_intensity(definition.minimum_intensity))
	assert_gt(director_config.credits_per_second, 0.0)
	assert_gt(director_config.max_stored_credits, 0.0)
	assert_gt(director_config.decision_interval_seconds, 0.0)
	assert_gt(director_config.max_total_active_dangers, 0)
	assert_gt(director_config.first_peak_delay_seconds, 0.0)
	assert_gt(director_config.peak_duration_seconds, 0.0)
	assert_gt(director_config.recovery_duration_seconds, 0.0)
	assert_gt(director_config.peak_credit_multiplier, 1.0)
	assert_lt(director_config.peak_decision_interval_multiplier, 1.0)
	assert_lt(director_config.recovery_credit_multiplier, 1.0)
	assert_lt(director_config.exit_credit_multiplier, 1.0)
	assert_gt(director_config.exit_decision_interval_multiplier, 1.0)
	assert_true(director_config.is_valid_config())
	assert_eq(director_config.max_readability_pressure, 5)
	assert_eq(director_config.exit_max_readability_pressure, 3)
	assert_eq(director_config.peak_max_readability_pressure, 7)

	var placement_rules := DangerPlacementRules.new()
	assert_true(placement_rules.is_valid_rules())
	assert_eq(placement_rules.spawn_search_attempts, 24)
	assert_true(placement_rules.avoid_warning_cells)
	assert_true(placement_rules.avoid_lava_cells)
	assert_true(placement_rules.avoid_destroyed_cells)
	assert_true(placement_rules.avoid_rebuilding_cells)


func test_danger_director_accumulates_credits_only_while_playing() -> void:
	var root := Node.new()
	var run_controller := RunController.new()
	var director := _create_director()

	run_controller.name = "RunController"
	director.run_controller_path = NodePath("../RunController")

	root.add_child(run_controller)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	director.step_director_for_tests(1.0)
	assert_almost_eq(director.get_available_credits(), 0.0, 0.001)

	run_controller.start_run()
	director.step_director_for_tests(1.0)
	assert_gt(director.get_available_credits(), 0.0)

	run_controller.register_death(&"test")
	director.step_director_for_tests(1.0)
	assert_almost_eq(director.get_available_credits(), 0.0, 0.001)

	remove_child(root)
	root.free()


func test_danger_director_does_not_spawn_while_ready_or_dead() -> void:
	var runtime := await _create_projectile_director_runtime(_create_projectile_danger())
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var projectile_system := runtime["projectile_system"] as ProjectileSystem

	director.step_director_for_tests(1.0)

	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_eq(director.get_last_spawned_danger_id(), &"")

	run_controller.start_run()
	run_controller.register_death(&"test")
	director.step_director_for_tests(1.0)

	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_eq(director.get_last_spawned_danger_id(), &"")

	_free_runtime(runtime)


func test_danger_director_skips_danger_that_is_too_expensive() -> void:
	var definition := _create_projectile_danger()
	definition.spawn_cost = 10.0
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(director.get_last_spawned_danger_id(), &"")
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"credits")

	_free_runtime(runtime)


func test_danger_director_emits_spawned_signal_after_successful_spawn() -> void:
	var definition := _create_projectile_danger()
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector

	var spawned_events: Array[Dictionary] = []
	director.danger_spawned.connect(
		func(
			danger_id: StringName, family: DangerDefinition.DangerFamily, spent_cost: float
		) -> void:
			spawned_events.append({"id": danger_id, "family": family, "spent_cost": spent_cost})
	)

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(spawned_events.size(), 1)
	assert_eq(spawned_events[0]["id"], &"test_projectile")
	assert_eq(spawned_events[0]["family"], DangerDefinition.DangerFamily.PROJECTILE_LAUNCHER)
	assert_almost_eq(float(spawned_events[0]["spent_cost"]), 1.0, 0.001)

	_free_runtime(runtime)


func test_danger_director_respects_definition_cooldown() -> void:
	var definition := _create_projectile_danger()
	definition.cooldown_seconds = 5.0
	definition.max_active_instances = 8
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var projectile_system := runtime["projectile_system"] as ProjectileSystem

	run_controller.start_run()
	director.step_director_for_tests(1.0)
	var first_count := projectile_system.get_active_launcher_count()
	director.step_director_for_tests(1.0)

	assert_eq(first_count, 1)
	assert_eq(projectile_system.get_active_launcher_count(), first_count)
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"cooldown")

	_free_runtime(runtime)


func test_danger_director_respects_max_active_instances() -> void:
	var definition := _create_projectile_danger()
	definition.cooldown_seconds = 0.0
	definition.max_active_instances = 1
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var projectile_system := runtime["projectile_system"] as ProjectileSystem

	run_controller.start_run()
	director.step_director_for_tests(1.0)
	director.step_director_for_tests(1.0)

	assert_eq(projectile_system.get_active_launcher_count(), 1)
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"active_cap")

	_free_runtime(runtime)


func test_danger_director_cycles_build_peak_and_recovery_phases() -> void:
	var root := Node.new()
	var run_controller := RunController.new()
	var director := _create_director()

	run_controller.name = "RunController"
	director.run_controller_path = NodePath("../RunController")
	director.director_config.first_peak_delay_seconds = 2.0
	director.director_config.peak_duration_seconds = 3.0
	director.director_config.recovery_duration_seconds = 1.5

	root.add_child(run_controller)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.BUILDUP)

	director.step_director_for_tests(2.1)
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.PEAK)

	director.step_director_for_tests(3.1)
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.RECOVERY)

	director.step_director_for_tests(1.6)
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.BUILDUP)

	remove_child(root)
	root.free()


func test_danger_director_peak_and_exit_pressure_change_runtime_multipliers() -> void:
	var root := Node.new()
	var run_controller := RunController.new()
	var director := _create_director()

	run_controller.name = "RunController"
	director.run_controller_path = NodePath("../RunController")
	director.director_config.first_peak_delay_seconds = 0.0
	director.director_config.peak_credit_multiplier = 1.75
	director.director_config.peak_decision_interval_multiplier = 0.65
	director.director_config.exit_credit_multiplier = 0.55
	director.director_config.exit_decision_interval_multiplier = 1.45

	root.add_child(run_controller)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()
	director.step_director_for_tests(0.01)

	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.PEAK)
	assert_almost_eq(director.get_credit_pressure_multiplier(), 1.75, 0.001)

	director.set_exit_pressure_enabled(true)

	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.EXIT_PRESSURE)
	assert_true(director.is_exit_pressure_enabled())
	assert_eq(director.get_readability_pressure_limit(), 3)
	assert_almost_eq(director.get_credit_pressure_multiplier(), 0.55, 0.001)
	assert_gte(director.get_next_decision_seconds(), 0.145)

	director.set_exit_pressure_enabled(false)

	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.BUILDUP)
	assert_false(director.is_exit_pressure_enabled())
	assert_eq(director.get_readability_pressure_limit(), 5)

	remove_child(root)
	root.free()


func test_danger_director_objective_bonus_and_forced_peak_affect_intensity() -> void:
	var root := Node.new()
	var run_controller := RunController.new()
	var director := _create_director()

	run_controller.name = "RunController"
	director.run_controller_path = NodePath("../RunController")
	director.difficulty_config.starting_intensity = 1.0
	director.difficulty_config.max_intensity = 2.0
	director.director_config.first_peak_delay_seconds = 30.0

	root.add_child(run_controller)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()
	assert_almost_eq(director.get_current_intensity(), 1.0, 0.001)

	director.set_objective_intensity_bonus(0.7)
	assert_almost_eq(director.get_current_intensity(), 1.7, 0.001)

	director.set_objective_intensity_bonus(8.0)
	assert_almost_eq(director.get_current_intensity(), 2.0, 0.001)

	director.force_peak(4.0)
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.PEAK)
	assert_almost_eq(director.get_pressure_phase_seconds_remaining(), 4.0, 0.001)

	director.set_exit_pressure_enabled(true)
	director.force_peak(4.0)
	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.EXIT_PRESSURE)

	remove_child(root)
	root.free()


func test_danger_director_routes_actor_enemy_through_executor_contract() -> void:
	var definition := _create_chaser_danger()
	var runtime := await _create_chaser_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var chaser_system := runtime["chaser_system"] as ChaserEnemySystem

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(director.get_last_spawned_danger_id(), &"test_chaser")
	assert_eq(chaser_system.get_active_enemy_count(), 1)
	assert_eq(director.get_active_danger_count(), 1)

	_free_runtime(runtime)


func test_danger_director_routes_terrain_hazard_through_executor_contract() -> void:
	var definition := _create_hazard_danger()
	var runtime := await _create_hazard_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var hazard_system := runtime["hazard_system"] as ArenaHazardSystem

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(director.get_last_spawned_danger_id(), &"test_lava_hazard")
	assert_eq(hazard_system.get_active_hazard_count(), 1)
	assert_eq(hazard_system.get_warning_cell_count(), 2)
	assert_eq(director.get_active_danger_count(), 1)

	_free_runtime(runtime)


func test_danger_director_ignores_family_without_executor() -> void:
	var definition := _create_chaser_danger()
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(director.get_last_spawned_danger_id(), &"")
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"unsupported")

	_free_runtime(runtime)


func test_placement_service_rejects_unfair_positions() -> void:
	var runtime := await _create_placement_runtime()
	var arena := runtime["arena"] as ArenaController
	var player := runtime["player"] as PlayerController
	var exit_gate := runtime["exit_gate"] as ExitGateController
	var service := runtime["service"] as DangerPlacementService
	var rules := DangerPlacementRules.new()
	rules.min_distance_from_player_meters = 8.0
	rules.center_safe_radius_meters = 5.0
	rules.min_distance_from_exit_gate_meters = 4.0

	player.global_position = Vector3.ZERO
	exit_gate.set_gate_available(true, Vector3(12.0, 0.0, 0.0))
	assert_false(service.is_position_allowed(Vector3(2.0, 0.0, 0.0), rules))
	assert_false(service.is_position_allowed(Vector3(12.5, 0.0, 0.0), rules))

	var dangerous_cell := arena.get_cells()[8]
	arena.set_cell_state(dangerous_cell.index, ArenaCell.ArenaCellState.WARNING)
	assert_false(service.is_position_allowed(dangerous_cell.get_center_position(), rules))

	var safe_position := Vector3(18.0, 0.0, 0.0)
	assert_true(service.is_position_allowed(safe_position, rules))

	_free_runtime(runtime)


func test_director_blocks_spawns_when_readability_pressure_is_capped() -> void:
	var definition := _create_projectile_danger()
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var projectile_system := runtime["projectile_system"] as ProjectileSystem

	director.director_config.max_readability_pressure = 0
	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"readability_pressure_capped")

	_free_runtime(runtime)


func test_executor_uses_definition_placement_rules_when_available() -> void:
	var definition := _create_projectile_danger()
	var placement_rules := DangerPlacementRules.new()
	placement_rules.min_distance_from_player_meters = 999.0
	placement_rules.spawn_search_attempts = 3
	definition.placement_rules = placement_rules
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector
	var projectile_system := runtime["projectile_system"] as ProjectileSystem

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_eq(projectile_system.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"placement_failed")

	_free_runtime(runtime)


func _create_director() -> DangerDirector:
	var director := DangerDirector.new()
	director.director_config = DangerDirectorConfig.new()
	director.director_config.credits_per_second = 2.0
	director.director_config.max_stored_credits = 4.0
	director.director_config.initial_decision_delay_seconds = 0.0
	director.director_config.decision_interval_seconds = 0.1
	director.director_config.max_total_active_dangers = 64
	director.difficulty_config = DifficultyConfig.new()
	return director


func _create_projectile_danger() -> DangerDefinition:
	var launcher_config := ProjectileLauncherConfig.new()
	launcher_config.min_distance_from_player_meters = 0.0
	launcher_config.spawn_search_attempts = 8
	launcher_config.telegraph_duration_seconds = 2.0
	launcher_config.launcher_lifetime_seconds = 5.0

	var definition := DangerDefinition.new()
	definition.danger_id = &"test_projectile"
	definition.family = DangerDefinition.DangerFamily.PROJECTILE_LAUNCHER
	definition.spawn_cost = 1.0
	definition.selection_weight = 1.0
	definition.cooldown_seconds = 0.0
	definition.minimum_intensity = 1.0
	definition.max_active_instances = 8
	definition.specialized_config = launcher_config
	return definition


func _create_chaser_danger() -> DangerDefinition:
	var chaser_config := ExplosiveChaserConfig.new()
	chaser_config.max_active_enemies = 4
	chaser_config.min_spawn_distance_from_player_meters = 0.0
	chaser_config.spawn_search_attempts = 8
	chaser_config.prime_duration_seconds = 0.2
	chaser_config.explosion_linger_seconds = 0.1

	var definition := DangerDefinition.new()
	definition.danger_id = &"test_chaser"
	definition.family = DangerDefinition.DangerFamily.ACTOR_ENEMY
	definition.spawn_cost = 1.0
	definition.selection_weight = 1.0
	definition.cooldown_seconds = 0.0
	definition.minimum_intensity = 1.0
	definition.max_active_instances = 8
	definition.specialized_config = chaser_config
	return definition


func _create_hazard_danger() -> DangerDefinition:
	var hazard_config := ArenaHazardConfig.new()
	hazard_config.hazard_type = ArenaHazardConfig.HazardType.LAVA
	hazard_config.affected_cell_count_min = 2
	hazard_config.affected_cell_count_max = 2
	hazard_config.min_distance_from_player_meters = 0.0
	hazard_config.center_safe_radius_meters = 0.0

	var definition := DangerDefinition.new()
	definition.danger_id = &"test_lava_hazard"
	definition.family = DangerDefinition.DangerFamily.TERRAIN_HAZARD
	definition.spawn_cost = 1.0
	definition.selection_weight = 1.0
	definition.cooldown_seconds = 0.0
	definition.minimum_intensity = 1.0
	definition.max_active_instances = 8
	definition.specialized_config = hazard_config
	return definition


func _create_projectile_director_runtime(definition: DangerDefinition) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var placement_service := DangerPlacementService.new()
	var projectile_system := ProjectileSystem.new()
	var director := _create_director()

	root.name = "DangerRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	placement_service.name = "DangerPlacementService"
	projectile_system.name = "ProjectileSystem"
	director.name = "DangerDirector"

	placement_service.arena_path = NodePath("../Arena")
	placement_service.player_path = NodePath("../Player")
	projectile_system.automatic_spawning_enabled = false
	projectile_system.run_controller_path = NodePath("../RunController")
	projectile_system.arena_path = NodePath("../Arena")
	projectile_system.player_path = NodePath("../Player")
	projectile_system.placement_service_path = NodePath("../DangerPlacementService")
	var launcher_config := definition.specialized_config as ProjectileLauncherConfig
	if launcher_config == null:
		launcher_config = ProjectileLauncherConfig.new()
	projectile_system.launcher_config = launcher_config

	director.default_danger_definition = definition
	director.run_controller_path = NodePath("../RunController")
	director.danger_executor_paths = [NodePath("../ProjectileSystem")]

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(placement_service)
	root.add_child(projectile_system)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"projectile_system": projectile_system,
		"director": director,
	}


func _create_hazard_director_runtime(definition: DangerDefinition) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var health := HealthComponent.new()
	var placement_service := DangerPlacementService.new()
	var hazard_system := ArenaHazardSystem.new()
	var director := _create_director()

	root.name = "HazardDangerRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	health.name = "HealthComponent"
	placement_service.name = "DangerPlacementService"
	hazard_system.name = "ArenaHazardSystem"
	director.name = "DangerDirector"

	player.position = Vector3.ZERO
	placement_service.arena_path = NodePath("../Arena")
	placement_service.player_path = NodePath("../Player")
	hazard_system.run_controller_path = NodePath("../RunController")
	hazard_system.arena_path = NodePath("../Arena")
	hazard_system.player_path = NodePath("../Player")
	hazard_system.health_component_path = NodePath("../HealthComponent")
	hazard_system.placement_service_path = NodePath("../DangerPlacementService")

	director.default_danger_definition = definition
	director.run_controller_path = NodePath("../RunController")
	director.danger_executor_paths = [NodePath("../ArenaHazardSystem")]

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(health)
	root.add_child(placement_service)
	root.add_child(hazard_system)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"hazard_system": hazard_system,
		"director": director,
	}


func _create_chaser_director_runtime(definition: DangerDefinition) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var placement_service := DangerPlacementService.new()
	var chaser_system := ChaserEnemySystem.new()
	var director := _create_director()

	root.name = "ChaserDangerRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	placement_service.name = "DangerPlacementService"
	chaser_system.name = "ChaserEnemySystem"
	director.name = "DangerDirector"

	player.position = Vector3.ZERO
	placement_service.arena_path = NodePath("../Arena")
	placement_service.player_path = NodePath("../Player")
	chaser_system.run_controller_path = NodePath("../RunController")
	chaser_system.arena_path = NodePath("../Arena")
	chaser_system.player_path = NodePath("../Player")
	chaser_system.placement_service_path = NodePath("../DangerPlacementService")
	chaser_system.chaser_config = definition.specialized_config as ExplosiveChaserConfig

	director.default_danger_definition = definition
	director.run_controller_path = NodePath("../RunController")
	director.danger_executor_paths = [NodePath("../ChaserEnemySystem")]

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(placement_service)
	root.add_child(chaser_system)
	root.add_child(director)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"chaser_system": chaser_system,
		"director": director,
	}


func _create_placement_runtime() -> Dictionary:
	var root := Node3D.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var exit_gate := ExitGateController.new()
	var service := DangerPlacementService.new()

	root.name = "PlacementRuntimeRoot"
	arena.name = "Arena"
	player.name = "Player"
	exit_gate.name = "ExitGate"
	service.name = "DangerPlacementService"

	exit_gate.player_path = NodePath("../Player")
	service.arena_path = NodePath("../Arena")
	service.player_path = NodePath("../Player")
	service.exit_gate_path = NodePath("../ExitGate")

	root.add_child(arena)
	root.add_child(player)
	root.add_child(exit_gate)
	root.add_child(service)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"arena": arena,
		"player": player,
		"exit_gate": exit_gate,
		"service": service,
	}


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
