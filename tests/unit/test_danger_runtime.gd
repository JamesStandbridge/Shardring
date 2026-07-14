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
	assert_eq(director.get_last_skip_reason(), &"no_candidate")

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
	assert_almost_eq(director.get_decision_interval_pressure_multiplier(), 0.65, 0.001)

	director.set_exit_pressure_enabled(true)

	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.EXIT_PRESSURE)
	assert_true(director.is_exit_pressure_enabled())
	assert_almost_eq(director.get_credit_pressure_multiplier(), 0.55, 0.001)
	assert_almost_eq(director.get_decision_interval_pressure_multiplier(), 1.45, 0.001)
	assert_gte(director.get_next_decision_seconds(), 0.145)

	director.set_exit_pressure_enabled(false)

	assert_eq(director.get_pressure_phase(), DangerDirector.PressurePhase.BUILDUP)
	assert_false(director.is_exit_pressure_enabled())

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


func test_danger_director_ignores_family_without_executor() -> void:
	var definition := _create_chaser_danger()
	var runtime := await _create_projectile_director_runtime(definition)
	var run_controller := runtime["run_controller"] as RunController
	var director := runtime["director"] as DangerDirector

	run_controller.start_run()
	director.step_director_for_tests(1.0)

	assert_eq(director.get_last_spawned_danger_id(), &"")
	assert_eq(director.get_skipped_spawn_count(), 1)
	assert_eq(director.get_last_skip_reason(), &"no_candidate")

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


func _create_projectile_director_runtime(definition: DangerDefinition) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var projectile_system := ProjectileSystem.new()
	var director := _create_director()

	root.name = "DangerRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	projectile_system.name = "ProjectileSystem"
	director.name = "DangerDirector"

	projectile_system.automatic_spawning_enabled = false
	projectile_system.run_controller_path = NodePath("../RunController")
	projectile_system.arena_path = NodePath("../Arena")
	projectile_system.player_path = NodePath("../Player")
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


func _create_chaser_director_runtime(definition: DangerDefinition) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var chaser_system := ChaserEnemySystem.new()
	var director := _create_director()

	root.name = "ChaserDangerRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	chaser_system.name = "ChaserEnemySystem"
	director.name = "DangerDirector"

	player.position = Vector3.ZERO
	chaser_system.run_controller_path = NodePath("../RunController")
	chaser_system.arena_path = NodePath("../Arena")
	chaser_system.player_path = NodePath("../Player")
	chaser_system.chaser_config = definition.specialized_config as ExplosiveChaserConfig

	director.default_danger_definition = definition
	director.run_controller_path = NodePath("../RunController")
	director.danger_executor_paths = [NodePath("../ChaserEnemySystem")]

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
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


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
