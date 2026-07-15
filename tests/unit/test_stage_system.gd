extends GutTest


func test_stage_resource_defaults_are_valid() -> void:
	var theme := ArenaThemeConfig.new()
	var map := MapDefinition.new()
	var sequence := StageSequenceConfig.new()
	var shard_config := ShardObjectiveConfig.new()

	assert_true(theme.is_valid_theme())
	assert_true(map.is_valid_map())
	assert_true(sequence.is_valid_sequence())
	assert_true(shard_config.is_valid_config())


func test_stage_sequence_cycles_maps_for_infinite_levels() -> void:
	var first_map := _create_map(&"first_map", "First Map", 11)
	var second_map := _create_map(&"second_map", "Second Map", 22)
	var sequence := _create_sequence([first_map, second_map])

	assert_same(sequence.get_map_for_level(1), first_map)
	assert_same(sequence.get_map_for_level(2), second_map)
	assert_same(sequence.get_map_for_level(3), first_map)
	assert_same(sequence.get_map_for_level(4), second_map)


func test_stage_sequence_threat_budget_and_intensity_grow_with_level() -> void:
	var first_map := _create_map(&"first_map", "First Map", 11)
	var sequence := _create_sequence([first_map])
	sequence.base_required_threat_budget = 22.0
	sequence.threat_budget_per_level = 8.0
	sequence.difficulty_intensity_per_level = 0.25

	assert_almost_eq(sequence.get_required_threat_budget_for_level(1), 22.0, 0.001)
	assert_almost_eq(sequence.get_required_threat_budget_for_level(3), 38.0, 0.001)
	assert_almost_eq(sequence.get_starting_intensity_for_level(first_map, 1), 1.0, 0.001)
	assert_almost_eq(sequence.get_starting_intensity_for_level(first_map, 3), 1.5, 0.001)
	assert_eq(sequence.shard_objective_config.get_required_shards_for_level(1), 3)
	assert_eq(sequence.shard_objective_config.get_required_shards_for_level(3), 4)


func test_stage_tracks_threat_budget_without_completing_level() -> void:
	var sequence := _create_sequence([_create_map(&"first_map", "First Map", 11)])
	sequence.base_required_threat_budget = 3.0
	sequence.threat_budget_per_level = 0.0
	var runtime := await _create_stage_runtime(sequence)
	var run_controller := runtime["run_controller"] as RunController
	var stage := runtime["stage"] as StageController
	var gate := runtime["gate"] as ExitGateController
	var danger_director := runtime["danger_director"] as DangerDirector

	stage.register_threat_spawned_for_tests(2.0)
	assert_almost_eq(stage.get_survived_threat_budget(), 0.0, 0.001)

	run_controller.start_run()
	stage.register_threat_spawned_for_tests(1.0)

	assert_almost_eq(stage.get_survived_threat_budget(), 1.0, 0.001)
	assert_eq(stage.get_stage_state(), StageController.StageState.SURVIVING)
	assert_false(gate.is_gate_available())

	stage.register_threat_spawned_for_tests(2.0)

	assert_almost_eq(stage.get_survived_threat_budget(), 3.0, 0.001)
	assert_eq(stage.get_stage_state(), StageController.StageState.SURVIVING)
	assert_false(gate.is_gate_available())
	assert_false(danger_director.is_exit_pressure_enabled())

	stage.register_threat_spawned_for_tests(99.0)
	assert_almost_eq(stage.get_survived_threat_budget(), 3.0, 0.001)

	run_controller.register_death(&"test")
	stage.register_threat_spawned_for_tests(99.0)
	assert_almost_eq(stage.get_survived_threat_budget(), 3.0, 0.001)

	_free_runtime(runtime)


func test_stage_shard_objective_reveals_exit_and_updates_difficulty() -> void:
	var sequence := _create_sequence([_create_map(&"first_map", "First Map", 11)])
	sequence.shard_objective_config.base_required_shards = 2
	sequence.shard_objective_config.max_required_shards = 2
	sequence.shard_objective_config.spawn_delay_after_collect_seconds = 0.01
	var runtime := await _create_stage_runtime(sequence)
	var run_controller := runtime["run_controller"] as RunController
	var stage := runtime["stage"] as StageController
	var gate := runtime["gate"] as ExitGateController
	var danger_director := runtime["danger_director"] as DangerDirector
	var objective := runtime["objective"] as ShardObjectiveController
	var player := runtime["player"] as PlayerController

	run_controller.start_run()
	assert_eq(stage.get_collected_shards(), 0)
	assert_eq(stage.get_required_shards(), 2)
	assert_true(objective.has_active_shard())

	_collect_active_shard(objective, player)
	assert_eq(stage.get_collected_shards(), 1)
	assert_almost_eq(danger_director.get_current_intensity(), 1.45, 0.001)
	assert_eq(danger_director.get_pressure_phase(), DangerDirector.PressurePhase.PEAK)
	assert_false(gate.is_gate_available())

	objective.step_objective_for_tests(0.02)
	_collect_active_shard(objective, player)

	assert_eq(stage.get_stage_state(), StageController.StageState.EXIT_AVAILABLE)
	assert_true(gate.is_gate_available())
	assert_true(danger_director.is_exit_pressure_enabled())
	assert_eq(stage.get_collected_shards(), 2)

	_free_runtime(runtime)


func test_stage_transition_advances_level_resets_shards_and_regenerates_map() -> void:
	var first_map := _create_map(&"first_map", "First Map", 11)
	var second_map := _create_map(&"second_map", "Second Map", 22)
	var sequence := _create_sequence([first_map, second_map])
	sequence.base_required_threat_budget = 3.0
	sequence.threat_budget_per_level = 2.0
	sequence.map_seed_stride = 1009
	sequence.shard_objective_config.base_required_shards = 2
	sequence.shard_objective_config.max_required_shards = 2
	var runtime := await _create_stage_runtime(sequence)
	var run_controller := runtime["run_controller"] as RunController
	var stage := runtime["stage"] as StageController
	var arena := runtime["arena"] as ArenaController
	var gate := runtime["gate"] as ExitGateController
	var danger_director := runtime["danger_director"] as DangerDirector

	run_controller.start_run()
	stage.force_complete_stage_for_tests()

	assert_true(stage.request_advance_stage())

	assert_eq(stage.get_level_index(), 2)
	assert_eq(stage.get_current_map_id(), &"second_map")
	assert_almost_eq(stage.get_required_threat_budget(), 5.0, 0.001)
	assert_almost_eq(stage.get_survived_threat_budget(), 0.0, 0.001)
	assert_eq(stage.get_collected_shards(), 0)
	assert_eq(stage.get_required_shards(), 2)
	assert_eq(stage.get_stage_state(), StageController.StageState.SURVIVING)
	assert_false(gate.is_gate_available())
	assert_false(danger_director.is_exit_pressure_enabled())
	assert_eq(arena.arena_config.generation_seed, 22 + 1009)
	assert_same(arena.arena_theme, second_map.arena_theme)

	_free_runtime(runtime)


func test_exit_gate_opens_closes_and_emits_entered_when_crossed() -> void:
	var root := Node3D.new()
	var player := PlayerController.new()
	var gate := ExitGateController.new()

	player.name = "Player"
	gate.name = "ExitGate"
	gate.player_path = NodePath("../Player")
	gate.open_distance_meters = 5.0
	gate.close_distance_meters = 6.0
	gate.transition_distance_meters = 0.7
	gate.open_speed = 10.0

	root.add_child(player)
	root.add_child(gate)
	add_child(root)
	await get_tree().process_frame

	var entered_count := [0]
	gate.gate_entered.connect(func() -> void: entered_count[0] += 1)

	player.global_position = Vector3(0.0, 0.2, 0.0)
	gate.set_gate_available(true, Vector3.ZERO)
	gate.step_gate_for_tests(0.1)

	assert_gt(gate.get_open_amount(), 0.8)
	assert_eq(entered_count[0], 1)

	gate.set_gate_available(true, Vector3.ZERO)
	player.global_position = Vector3(10.0, 0.0, 0.0)
	gate.step_gate_for_tests(0.2)

	assert_eq(gate.get_target_open_amount(), 0.0)
	assert_lt(gate.get_open_amount(), 0.8)

	remove_child(root)
	root.free()


func _create_sequence(maps: Array[MapDefinition]) -> StageSequenceConfig:
	var sequence := StageSequenceConfig.new()
	sequence.maps = maps
	sequence.base_required_threat_budget = 22.0
	sequence.threat_budget_per_level = 8.0
	sequence.difficulty_intensity_per_level = 0.25
	sequence.map_seed_stride = 1009
	sequence.shard_objective_config = ShardObjectiveConfig.new()
	return sequence


func _create_map(map_id: StringName, display_name: String, generation_seed: int) -> MapDefinition:
	var arena_config := ArenaConfig.new()
	arena_config.generation_seed = generation_seed

	var theme := ArenaThemeConfig.new()
	theme.theme_id = map_id
	theme.display_name = display_name

	var difficulty := DifficultyConfig.new()
	difficulty.starting_intensity = 1.0
	difficulty.max_intensity = 10.0

	var map := MapDefinition.new()
	map.map_id = map_id
	map.display_name = display_name
	map.arena_config = arena_config
	map.arena_theme = theme
	map.director_config = DangerDirectorConfig.new()
	map.difficulty_config = difficulty
	map.default_danger_definition = DangerDefinition.new()
	map.danger_definitions = []
	return map


func _create_stage_runtime(sequence: StageSequenceConfig) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var arena := ArenaController.new()
	var player := PlayerController.new()
	var danger_director := DangerDirector.new()
	var objective := ShardObjectiveController.new()
	var stage := StageController.new()
	var gate := ExitGateController.new()

	root.name = "StageRuntimeRoot"
	run_controller.name = "RunController"
	arena.name = "Arena"
	player.name = "Player"
	danger_director.name = "DangerDirector"
	objective.name = "ShardObjective"
	stage.name = "StageController"
	gate.name = "ExitGate"

	danger_director.run_controller_path = NodePath("../RunController")
	objective.run_controller_path = NodePath("../RunController")
	objective.arena_path = NodePath("../Arena")
	objective.player_path = NodePath("../Player")
	stage.stage_sequence_config = sequence
	stage.run_controller_path = NodePath("../RunController")
	stage.arena_path = NodePath("../Arena")
	stage.player_path = NodePath("../Player")
	stage.danger_director_path = NodePath("../DangerDirector")
	stage.shard_objective_path = NodePath("../ShardObjective")
	stage.exit_gate_path = NodePath("../ExitGate")
	gate.player_path = NodePath("../Player")
	gate.stage_controller_path = NodePath("../StageController")

	root.add_child(run_controller)
	root.add_child(arena)
	root.add_child(player)
	root.add_child(danger_director)
	root.add_child(objective)
	root.add_child(stage)
	root.add_child(gate)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"arena": arena,
		"player": player,
		"danger_director": danger_director,
		"objective": objective,
		"stage": stage,
		"gate": gate,
	}


func _collect_active_shard(objective: ShardObjectiveController, player: PlayerController) -> void:
	player.global_position = objective.get_current_shard_position()
	objective.step_objective_for_tests(0.0)


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
