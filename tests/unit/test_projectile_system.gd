extends GutTest


func test_launcher_config_defaults_prepare_single_shot_and_future_multi_shot() -> void:
	var config := ProjectileLauncherConfig.new()

	assert_eq(config.launcher_type, ProjectileLauncherConfig.LauncherType.SINGLE_SHOT)
	assert_not_null(config.projectile_config)
	assert_eq(config.shot_count, 1)
	assert_gt(config.shot_interval_seconds, 0.0)
	assert_gt(config.linger_after_last_shot_seconds, 0.0)
	assert_gt(config.launcher_lifetime_seconds, 0.0)
	assert_gt(config.max_active_projectiles, config.max_active_launchers)


func test_launcher_transitions_from_telegraph_to_shot_and_linger() -> void:
	var system := _create_projectile_system()
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3(3.0, 0.55, 0.0)))
	assert_eq(system.get_active_launcher_count(), 1)
	assert_eq(system.get_active_projectile_count(), 0)
	assert_eq(system.get_first_active_launcher_state(), ProjectileSystem.LauncherState.TELEGRAPHING)

	system.step_system_for_tests(0.06)

	assert_eq(system.get_active_projectile_count(), 1)
	assert_eq(system.get_first_active_launcher_state(), ProjectileSystem.LauncherState.LINGERING)

	system.step_system_for_tests(0.55)

	assert_eq(system.get_active_launcher_count(), 0)

	remove_child(system)
	system.free()


func test_projectile_linear_motion_uses_direction_speed_and_delta() -> void:
	var system := _create_projectile_system()
	system.launcher_config.projectile_config.speed_meters_per_second = 10.0
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_projectile(Vector3.ZERO, Vector3.RIGHT))

	system.step_system_for_tests(0.25)

	var position := system.get_first_active_projectile_position()
	assert_almost_eq(position.x, 2.5, 0.001)
	assert_almost_eq(position.y, 0.0, 0.001)
	assert_almost_eq(position.z, 0.0, 0.001)

	remove_child(system)
	system.free()


func test_projectile_lifetime_expiration_deactivates_projectile() -> void:
	var system := _create_projectile_system()
	system.launcher_config.projectile_config.lifetime_seconds = 0.1
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_projectile(Vector3.ZERO, Vector3.RIGHT))

	system.step_system_for_tests(0.11)

	assert_eq(system.get_active_projectile_count(), 0)

	remove_child(system)
	system.free()


func test_damage_disabled_does_not_kill_player() -> void:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var player := PlayerController.new()
	var system := _create_projectile_system()

	run_controller.name = "RunController"
	player.name = "Player"
	system.name = "ProjectileSystem"
	system.run_controller_path = NodePath("../RunController")
	system.player_path = NodePath("../Player")
	system.launcher_config.projectile_config.damage_on_contact = false

	root.add_child(run_controller)
	root.add_child(player)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()
	assert_true(system.force_spawn_projectile(Vector3(0.0, 0.7, 0.0), Vector3.RIGHT))

	system.step_system_for_tests(0.01)

	assert_true(run_controller.is_playing())
	assert_eq(run_controller.get_last_death_reason(), &"")

	remove_child(root)
	root.free()


func test_projectile_capacity_increments_skipped_spawn_count() -> void:
	var system := _create_projectile_system()
	system.launcher_config.max_active_projectiles = 1
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_projectile(Vector3.ZERO, Vector3.RIGHT))
	assert_false(system.force_spawn_projectile(Vector3.ONE, Vector3.RIGHT))
	assert_eq(system.get_skipped_spawn_count(), 1)

	remove_child(system)
	system.free()


func test_projectile_system_keeps_runtime_node_count_bounded_for_many_projectiles() -> void:
	var system := _create_projectile_system()
	system.launcher_config.max_active_projectiles = 1200
	add_child(system)
	await get_tree().process_frame

	var initial_node_count := system.get_runtime_node_count()
	for projectile_index in range(1000):
		var angle := float(projectile_index) * 0.013
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		assert_true(system.force_spawn_projectile(Vector3.ZERO, direction))

	assert_eq(system.get_active_projectile_count(), 1000)
	assert_eq(system.get_runtime_node_count(), initial_node_count)
	assert_true(system.get_runtime_node_count() <= 3)

	remove_child(system)
	system.free()


func _create_projectile_system() -> ProjectileSystem:
	var system := ProjectileSystem.new()
	system.launcher_config = ProjectileLauncherConfig.new()
	system.launcher_config.telegraph_duration_seconds = 0.05
	system.launcher_config.linger_after_last_shot_seconds = 0.5
	system.launcher_config.launcher_lifetime_seconds = 5.0
	system.launcher_config.initial_spawn_delay_seconds = 100.0
	system.launcher_config.spawn_interval_seconds = 100.0
	return system
