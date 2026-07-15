extends GutTest


func test_shard_objective_config_defaults_are_valid() -> void:
	var config := ShardObjectiveConfig.new()

	assert_true(config.is_valid_config())
	assert_eq(config.get_required_shards_for_level(1), 3)
	assert_eq(config.get_required_shards_for_level(2), 3)
	assert_eq(config.get_required_shards_for_level(3), 4)
	assert_eq(config.get_required_shards_for_level(9), 7)
	assert_gt(config.pickup_radius_meters, 0.0)
	assert_gt(config.min_distance_from_player_meters, 0.0)
	assert_gt(config.intensity_bonus_per_collected_shard, 0.0)


func test_shard_spawns_far_from_player_and_outside_center_safe_radius() -> void:
	var runtime := await _create_objective_runtime()
	var run_controller := runtime["run_controller"] as RunController
	var player := runtime["player"] as PlayerController
	var objective := runtime["objective"] as ShardObjectiveController
	var config := objective.objective_config

	run_controller.start_run()
	objective.start_objective(1, config)

	assert_true(objective.has_active_shard())
	assert_eq(objective.get_required_shards(), 3)
	assert_gte(
		_get_horizontal_distance(objective.get_current_shard_position(), player.global_position),
		config.min_distance_from_player_meters
	)
	assert_gte(
		(
			Vector2(
				objective.get_current_shard_position().x, objective.get_current_shard_position().z
			)
			. length()
		),
		config.center_safe_radius_meters
	)

	_free_runtime(runtime)


func test_collecting_shard_progresses_once_then_respawns_after_delay() -> void:
	var runtime := await _create_objective_runtime()
	var run_controller := runtime["run_controller"] as RunController
	var player := runtime["player"] as PlayerController
	var objective := runtime["objective"] as ShardObjectiveController
	var config := objective.objective_config
	var collected_events := [0]

	objective.shard_collected.connect(
		func(_collected: int, _required: int, _risk_tier: int) -> void: collected_events[0] += 1
	)

	run_controller.start_run()
	objective.start_objective(1, config)
	player.global_position = objective.get_current_shard_position()
	objective.step_objective_for_tests(0.0)
	objective.step_objective_for_tests(0.0)

	assert_eq(objective.get_collected_shards(), 1)
	assert_eq(collected_events[0], 1)
	assert_false(objective.has_active_shard())

	objective.step_objective_for_tests(config.spawn_delay_after_collect_seconds - 0.05)
	assert_false(objective.has_active_shard())

	objective.step_objective_for_tests(0.1)
	assert_true(objective.has_active_shard())

	_free_runtime(runtime)


func test_collecting_last_shard_completes_objective_without_respawn() -> void:
	var runtime := await _create_objective_runtime()
	var run_controller := runtime["run_controller"] as RunController
	var player := runtime["player"] as PlayerController
	var objective := runtime["objective"] as ShardObjectiveController
	var config := objective.objective_config
	var completed_events := [0]

	config.base_required_shards = 2
	config.max_required_shards = 2
	config.spawn_delay_after_collect_seconds = 0.01
	objective.objective_completed.connect(func(_required: int) -> void: completed_events[0] += 1)

	run_controller.start_run()
	objective.start_objective(1, config)
	_collect_active_shard(objective, player)
	objective.step_objective_for_tests(0.02)
	_collect_active_shard(objective, player)
	objective.step_objective_for_tests(1.0)

	assert_eq(objective.get_collected_shards(), 2)
	assert_true(objective.is_objective_completed())
	assert_false(objective.has_active_shard())
	assert_eq(completed_events[0], 1)

	_free_runtime(runtime)


func test_restart_and_death_clear_shard_objective() -> void:
	var runtime := await _create_objective_runtime()
	var run_controller := runtime["run_controller"] as RunController
	var objective := runtime["objective"] as ShardObjectiveController

	run_controller.start_run()
	objective.start_objective(1, objective.objective_config)
	assert_true(objective.has_active_shard())

	run_controller.register_death(&"test")
	assert_false(objective.has_active_shard())
	assert_eq(objective.get_required_shards(), 0)

	run_controller.restart_run()
	objective.start_objective(1, objective.objective_config)
	assert_true(objective.has_active_shard())

	run_controller.restart_run()
	assert_false(objective.has_active_shard())

	_free_runtime(runtime)


func _create_objective_runtime() -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var objective := ShardObjectiveController.new()
	var config := ShardObjectiveConfig.new()

	root.name = "ShardObjectiveRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	objective.name = "ShardObjective"
	player.position = Vector3.ZERO
	objective.objective_config = config
	objective.run_controller_path = NodePath("../RunController")
	objective.arena_path = NodePath("../Arena")
	objective.player_path = NodePath("../Player")

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(objective)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"arena": arena,
		"player": player,
		"objective": objective,
	}


func _collect_active_shard(objective: ShardObjectiveController, player: PlayerController) -> void:
	player.global_position = objective.get_current_shard_position()
	objective.step_objective_for_tests(0.0)


func _get_horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x, first.z).distance_to(Vector2(second.x, second.z))


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
