extends GutTest


func test_explosive_chaser_config_defaults_are_valid() -> void:
	var config := ExplosiveChaserConfig.new()

	assert_true(config.is_valid_config())
	assert_gt(config.max_active_enemies, 0)
	assert_gt(config.walk_speed_meters_per_second, 0.0)
	assert_gt(config.chase_speed_meters_per_second, 0.0)
	assert_gte(config.chase_speed_meters_per_second, config.walk_speed_meters_per_second)
	assert_gte(config.agitated_radius_meters, config.dash_trigger_radius_meters)
	assert_gt(config.dash_trigger_radius_meters, 0.0)
	assert_gt(config.dash_windup_seconds, 0.0)
	assert_gt(config.dash_duration_seconds, 0.0)
	assert_gte(config.dash_speed_meters_per_second, config.chase_speed_meters_per_second)
	assert_gte(config.dash_cooldown_seconds, 0.0)
	assert_gte(config.dash_recovery_seconds, 0.0)
	assert_gte(config.run_trigger_radius_meters, config.prime_trigger_radius_meters)
	assert_gt(config.excitement_ramp_exponent, 0.0)
	assert_gte(config.weave_strength_meters_per_second, 0.0)
	assert_gte(config.weave_frequency_hz, 0.0)
	assert_gte(config.face_player_lerp_speed, 0.0)
	assert_gt(config.prime_duration_seconds, 0.0)
	assert_gt(config.explosion_radius_meters, 0.0)
	assert_gt(config.near_miss_radius_meters, 0.0)
	assert_gte(config.near_miss_min_distance_from_damage_radius, 0.0)
	assert_gte(config.spawn_pop_duration_seconds, 0.0)
	assert_gte(config.spawn_pop_height_meters, 0.0)
	assert_gt(config.movement_bob_frequency_walk_hz, 0.0)
	assert_gte(config.movement_bob_frequency_run_hz, config.movement_bob_frequency_walk_hz)
	assert_gte(config.movement_bob_height_meters, 0.0)
	assert_gte(config.run_excitement_scale_multiplier, 1.0)
	assert_true(config.collision_radius_meters <= config.visual_radius_meters)
	assert_not_null(config.damage_profile)
	assert_true(config.damage_profile.is_valid_profile())


func test_chaser_system_respects_pool_capacity_and_skips() -> void:
	var config := _create_test_config()
	config.max_active_enemies = 1
	var runtime := await _create_chaser_runtime(config)
	var system := runtime["system"] as ChaserEnemySystem
	var initial_node_count := system._get_runtime_node_count_for_tests()

	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	assert_false(system.force_spawn_enemy_at(Vector3.RIGHT))
	assert_eq(system.get_active_enemy_count(), 1)
	assert_eq(system.get_skipped_spawn_count(), 1)
	assert_eq(system._get_runtime_node_count_for_tests(), initial_node_count)

	_free_runtime(runtime)


func test_chaser_spawn_uses_valid_arena_position_far_from_player() -> void:
	var config := _create_test_config()
	config.min_spawn_distance_from_player_meters = 8.0
	config.spawn_search_attempts = 24
	var definition := _create_chaser_definition(config)
	var runtime := await _create_chaser_runtime(config, true)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3.ZERO
	assert_true(system.request_spawn_danger(definition))

	var enemy_position := system.get_first_active_enemy_position()
	var horizontal_distance := Vector2(enemy_position.x, enemy_position.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z)
	)
	assert_gte(horizontal_distance, config.min_spawn_distance_from_player_meters)
	assert_gt(enemy_position.y, 0.0)

	_free_runtime(runtime)


func test_chaser_moves_toward_player_while_chasing() -> void:
	var config := _create_test_config()
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 0.5
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))

	system.step_system_for_tests(0.25)

	assert_gt(system.get_first_active_enemy_position().x, 0.0)
	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.CHASING)

	_free_runtime(runtime)


func test_chaser_runs_when_close_to_player() -> void:
	var far_config := _create_test_config()
	far_config.gravity_multiplier = 0.0
	far_config.walk_speed_meters_per_second = 1.0
	far_config.chase_speed_meters_per_second = 6.0
	far_config.chase_acceleration_meters_per_second_squared = 1000.0
	far_config.run_trigger_radius_meters = 4.0
	far_config.prime_trigger_radius_meters = 0.2
	var far_runtime := await _create_chaser_runtime(far_config)
	var far_player := far_runtime["player"] as PlayerController
	var far_system := far_runtime["system"] as ChaserEnemySystem

	far_player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(far_system.force_spawn_enemy_at(Vector3.ZERO))
	far_system.step_system_for_tests(0.2)
	var far_horizontal_speed := far_system._get_first_active_enemy_horizontal_speed_for_tests()
	_free_runtime(far_runtime)

	var close_config := _create_test_config()
	close_config.gravity_multiplier = 0.0
	close_config.walk_speed_meters_per_second = 1.0
	close_config.chase_speed_meters_per_second = 6.0
	close_config.chase_acceleration_meters_per_second_squared = 1000.0
	close_config.run_trigger_radius_meters = 4.0
	close_config.prime_trigger_radius_meters = 0.2
	var close_runtime := await _create_chaser_runtime(close_config)
	var close_player := close_runtime["player"] as PlayerController
	var close_system := close_runtime["system"] as ChaserEnemySystem

	close_player.global_position = Vector3(1.5, 0.0, 0.0)
	assert_true(close_system.force_spawn_enemy_at(Vector3.ZERO))
	close_system.step_system_for_tests(0.2)

	assert_gt(
		close_system._get_first_active_enemy_horizontal_speed_for_tests(),
		far_horizontal_speed * 2.0
	)
	assert_eq(close_system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.CHASING)

	_free_runtime(close_runtime)


func test_chaser_movement_updates_visual_pose_without_moving_collision_shape() -> void:
	var config := _create_test_config()
	config.gravity_multiplier = 0.0
	config.walk_speed_meters_per_second = 1.0
	config.chase_speed_meters_per_second = 6.0
	config.chase_acceleration_meters_per_second_squared = 1000.0
	config.run_trigger_radius_meters = 4.0
	config.prime_trigger_radius_meters = 0.2
	config.spawn_pop_duration_seconds = 0.0
	config.movement_bob_height_meters = 0.12
	config.movement_bob_frequency_run_hz = 5.0
	config.run_excitement_scale_multiplier = 1.2
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(3.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	system.step_system_for_tests(0.05)

	assert_gt(system._get_first_active_enemy_visual_local_position_for_tests().y, 0.05)
	assert_gt(system._get_first_active_enemy_visual_scale_for_tests().y, 1.0)
	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.CHASING)

	_free_runtime(runtime)


func test_chaser_weaves_while_still_advancing_toward_player() -> void:
	var config := _create_test_config()
	config.gravity_multiplier = 0.0
	config.walk_speed_meters_per_second = 4.0
	config.chase_speed_meters_per_second = 4.0
	config.chase_acceleration_meters_per_second_squared = 1000.0
	config.run_trigger_radius_meters = 20.0
	config.prime_trigger_radius_meters = 0.2
	config.weave_strength_meters_per_second = 3.0
	config.weave_frequency_hz = 2.0
	config.movement_bob_frequency_walk_hz = 4.0
	config.movement_bob_frequency_run_hz = 4.0
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	var max_lateral_offset := 0.0
	for frame_index in range(6):
		system.step_system_for_tests(0.1)
		max_lateral_offset = maxf(
			max_lateral_offset, absf(system.get_first_active_enemy_position().z)
		)

	var enemy_position := system.get_first_active_enemy_position()
	assert_gt(enemy_position.x, 0.12)
	assert_gt(max_lateral_offset, 0.006)

	_free_runtime(runtime)


func test_chaser_spawn_pop_animates_visual_without_moving_collision_shape() -> void:
	var config := _create_test_config()
	config.spawn_pop_duration_seconds = 0.2
	config.spawn_pop_height_meters = 0.3
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 0.2
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	var initial_body_position := system.get_first_active_enemy_position()
	system.step_system_for_tests(0.1)

	assert_eq(system.get_first_active_enemy_position().y, initial_body_position.y)
	assert_gt(system._get_first_active_enemy_visual_local_position_for_tests().y, 0.2)
	assert_gt(system._get_first_active_enemy_visual_scale_for_tests().x, 1.0)

	_free_runtime(runtime)


func test_chaser_faces_player_while_chasing() -> void:
	var config := _create_test_config()
	config.face_player_lerp_speed = 1000.0
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 0.5
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))

	system.step_system_for_tests(0.016)

	assert_gt(system._get_first_active_enemy_forward_direction_for_tests().dot(Vector3.RIGHT), 0.99)

	_free_runtime(runtime)


func test_chaser_visual_yaw_offset_does_not_change_logical_facing() -> void:
	var config := _create_test_config()
	config.face_player_lerp_speed = 1000.0
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 0.5
	config.visual_yaw_offset_degrees = 180.0
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	system.step_system_for_tests(0.016)

	assert_gt(system._get_first_active_enemy_forward_direction_for_tests().dot(Vector3.RIGHT), 0.99)
	assert_almost_eq(system._get_first_active_enemy_visual_local_rotation_for_tests().y, PI, 0.001)

	_free_runtime(runtime)


func test_chaser_transitions_from_chase_to_prime_to_explosion_to_inactive() -> void:
	var config := _create_test_config()
	config.damage_on_explosion = false
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 3.0
	config.prime_duration_seconds = 0.05
	config.explosion_linger_seconds = 0.05
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem
	var resolved_count := [0]
	system.actor_enemy_resolved.connect(
		func(_family: DangerDefinition.DangerFamily, _reason: StringName) -> void:
			resolved_count[0] += 1
	)

	player.global_position = Vector3(1.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))

	system.step_system_for_tests(0.01)
	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.PRIMING)
	assert_eq(system.get_priming_enemy_count(), 1)

	system.step_system_for_tests(0.06)
	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.EXPLODING)
	assert_eq(system.get_triggered_explosion_count(), 1)

	system.step_system_for_tests(0.06)
	assert_eq(system.get_active_enemy_count(), 0)
	assert_eq(resolved_count[0], 1)

	_free_runtime(runtime)


func test_chaser_windup_dash_uses_player_snapshot_then_recovers() -> void:
	var config := _create_test_config()
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 0.2
	config.dash_trigger_radius_meters = 8.0
	config.dash_windup_seconds = 0.05
	config.dash_duration_seconds = 0.1
	config.dash_recovery_seconds = 0.05
	config.dash_speed_meters_per_second = 10.0
	config.dash_cooldown_seconds = 1.0
	config.chase_acceleration_meters_per_second_squared = 1000.0
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem
	var dash_events := [0]
	system.chaser_dash_started.connect(func(_position: Vector3) -> void: dash_events[0] += 1)

	player.global_position = Vector3(6.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	system.step_system_for_tests(0.01)

	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.WINDUP)
	assert_eq(system.get_windup_enemy_count(), 1)

	player.global_position = Vector3(-8.0, 0.0, 0.0)
	system.step_system_for_tests(0.06)

	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.DASHING)
	assert_eq(system.get_dashing_enemy_count(), 1)
	assert_eq(dash_events[0], 1)
	assert_gt(system._get_first_active_enemy_forward_direction_for_tests().dot(Vector3.RIGHT), 0.95)

	system.step_system_for_tests(0.11)

	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.RECOVERING)

	system.step_system_for_tests(0.06)

	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.CHASING)

	_free_runtime(runtime)


func test_chaser_near_miss_emits_when_explosion_is_narrowly_escaped() -> void:
	var config := _create_test_config()
	config.gravity_multiplier = 0.0
	config.prime_trigger_radius_meters = 10.0
	config.prime_duration_seconds = 0.01
	config.explosion_radius_meters = 2.0
	config.near_miss_radius_meters = 3.0
	config.near_miss_min_distance_from_damage_radius = 0.2
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ChaserEnemySystem
	var near_miss_events := [0]
	var near_miss_strength := [0.0]
	system.chaser_near_missed.connect(
		func(_position: Vector3, _distance: float, strength: float) -> void:
			near_miss_events[0] += 1
			near_miss_strength[0] = strength
	)

	player.global_position = Vector3(3.1, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	system.step_system_for_tests(0.01)
	system.step_system_for_tests(0.02)

	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.EXPLODING)
	assert_eq(near_miss_events[0], 1)
	assert_gt(near_miss_strength[0], 0.0)
	assert_almost_eq(health.get_current_health(), 100.0, 0.001)

	_free_runtime(runtime)


func test_chaser_lifetime_expiration_triggers_explosion() -> void:
	var config := _create_test_config()
	config.damage_on_explosion = false
	config.gravity_multiplier = 0.0
	config.lifetime_seconds = 0.05
	config.prime_trigger_radius_meters = 0.2
	config.explosion_linger_seconds = 0.1
	var runtime := await _create_chaser_runtime(config)
	var player := runtime["player"] as PlayerController
	var system := runtime["system"] as ChaserEnemySystem

	player.global_position = Vector3(10.0, 0.0, 0.0)
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))

	system.step_system_for_tests(0.06)
	assert_eq(system.get_first_active_enemy_state(), ChaserEnemySystem.ChaserState.EXPLODING)
	assert_eq(system.get_triggered_explosion_count(), 1)
	assert_eq(system.get_active_enemy_count(), 1)

	system.step_system_for_tests(0.11)
	assert_eq(system.get_active_enemy_count(), 0)

	_free_runtime(runtime)


func test_chaser_explosion_kills_only_inside_radius() -> void:
	var lethal_config := _create_test_config()
	lethal_config.gravity_multiplier = 0.0
	lethal_config.prime_trigger_radius_meters = 3.0
	lethal_config.prime_duration_seconds = 0.01
	lethal_config.explosion_radius_meters = 2.0
	var lethal_runtime := await _create_chaser_runtime(lethal_config, false, 65.0)
	var lethal_run := lethal_runtime["run_controller"] as RunController
	var lethal_player := lethal_runtime["player"] as PlayerController
	var lethal_health := lethal_runtime["health"] as HealthComponent
	var lethal_system := lethal_runtime["system"] as ChaserEnemySystem

	lethal_run.start_run()
	lethal_player.global_position = Vector3(1.0, 0.0, 0.0)
	assert_true(lethal_system.force_spawn_enemy_at(Vector3.ZERO))
	lethal_system.step_system_for_tests(0.01)
	lethal_system.step_system_for_tests(0.02)

	assert_eq(lethal_run.get_state(), RunController.RunState.DEAD)
	assert_eq(lethal_run.get_last_death_reason(), &"chaser_explosion")
	assert_eq(lethal_health.get_last_damage_type(), DamageProfile.DamageType.EXPLOSIVE)
	_free_runtime(lethal_runtime)

	var safe_config := _create_test_config()
	safe_config.gravity_multiplier = 0.0
	safe_config.prime_trigger_radius_meters = 10.0
	safe_config.prime_duration_seconds = 0.01
	safe_config.explosion_radius_meters = 1.0
	var safe_runtime := await _create_chaser_runtime(safe_config)
	var safe_run := safe_runtime["run_controller"] as RunController
	var safe_player := safe_runtime["player"] as PlayerController
	var safe_health := safe_runtime["health"] as HealthComponent
	var safe_system := safe_runtime["system"] as ChaserEnemySystem

	safe_run.start_run()
	safe_player.global_position = Vector3(5.0, 0.0, 0.0)
	assert_true(safe_system.force_spawn_enemy_at(Vector3.ZERO))
	safe_system.step_system_for_tests(0.01)
	safe_system.step_system_for_tests(0.02)

	assert_eq(safe_run.get_state(), RunController.RunState.PLAYING)
	assert_eq(safe_run.get_last_death_reason(), &"")
	assert_almost_eq(safe_health.get_current_health(), 100.0, 0.001)
	_free_runtime(safe_runtime)


func test_chaser_cleanup_on_restart_and_death() -> void:
	var config := _create_test_config()
	var runtime := await _create_chaser_runtime(config)
	var run_controller := runtime["run_controller"] as RunController
	var system := runtime["system"] as ChaserEnemySystem

	run_controller.start_run()
	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	assert_eq(system.get_active_enemy_count(), 1)

	run_controller.restart_run()
	assert_eq(system.get_active_enemy_count(), 0)

	assert_true(system.force_spawn_enemy_at(Vector3.ZERO))
	run_controller.register_death(&"test")
	assert_eq(system.get_active_enemy_count(), 0)

	_free_runtime(runtime)


func _create_test_config() -> ExplosiveChaserConfig:
	var config := ExplosiveChaserConfig.new()
	config.max_active_enemies = 4
	config.min_spawn_distance_from_player_meters = 0.0
	config.spawn_search_attempts = 8
	config.lifetime_seconds = 10.0
	config.walk_speed_meters_per_second = 2.0
	config.chase_speed_meters_per_second = 4.0
	config.chase_acceleration_meters_per_second_squared = 20.0
	config.agitated_radius_meters = 5.0
	config.dash_trigger_radius_meters = 0.0
	config.dash_windup_seconds = 0.05
	config.dash_duration_seconds = 0.1
	config.dash_speed_meters_per_second = 8.0
	config.dash_cooldown_seconds = 1.0
	config.dash_recovery_seconds = 0.05
	config.run_trigger_radius_meters = 5.0
	config.face_player_lerp_speed = 1000.0
	config.prime_trigger_radius_meters = 2.0
	config.prime_duration_seconds = 0.1
	config.explosion_linger_seconds = 0.1
	config.explosion_radius_meters = 2.0
	config.near_miss_radius_meters = 3.0
	config.near_miss_min_distance_from_damage_radius = 0.2
	config.spawn_pop_duration_seconds = 0.0
	config.damage_profile = _create_explosive_damage_profile()
	return config


func _create_chaser_definition(config: ExplosiveChaserConfig) -> DangerDefinition:
	var definition := DangerDefinition.new()
	definition.danger_id = &"test_chaser"
	definition.family = DangerDefinition.DangerFamily.ACTOR_ENEMY
	definition.spawn_cost = 1.0
	definition.selection_weight = 1.0
	definition.cooldown_seconds = 0.0
	definition.minimum_intensity = 1.0
	definition.max_active_instances = config.max_active_enemies
	definition.specialized_config = config
	return definition


func _create_chaser_runtime(
	config: ExplosiveChaserConfig, include_arena: bool = false, max_health: float = 100.0
) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var player := PlayerController.new()
	var health := _create_health_component(max_health, 0.0)
	var system := ChaserEnemySystem.new()

	root.name = "ChaserRuntimeRoot"
	run_controller.name = "RunController"
	player.name = "Player"
	health.name = "HealthComponent"
	system.name = "ChaserEnemySystem"

	system.chaser_config = config
	system.run_controller_path = NodePath("../RunController")
	system.player_path = NodePath("../Player")
	system.health_component_path = NodePath("../HealthComponent")
	health.depleted.connect(run_controller.register_death)

	root.add_child(run_controller)
	if include_arena:
		var arena := ArenaController.new()
		arena.name = "Arena"
		system.arena_path = NodePath("../Arena")
		root.add_child(arena)
	root.add_child(player)
	root.add_child(health)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"run_controller": run_controller,
		"player": player,
		"health": health,
		"system": system,
	}


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()


func _create_health_component(max_health: float, invulnerability_seconds: float) -> HealthComponent:
	var config := HealthConfig.new()
	config.max_health = max_health
	config.hit_invulnerability_seconds = invulnerability_seconds

	var health := HealthComponent.new()
	health.health_config = config
	return health


func _create_explosive_damage_profile() -> DamageProfile:
	var profile := DamageProfile.new()
	profile.amount = 65.0
	profile.damage_type = DamageProfile.DamageType.EXPLOSIVE
	profile.death_reason = &"chaser_explosion"
	profile.hit_label = &"Explosion"
	return profile
