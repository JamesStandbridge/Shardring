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
	assert_eq(config.telegraph_mode, ProjectileLauncherConfig.TelegraphMode.TO_TARGET)
	assert_gt(config.telegraph_visual_length_meters, 0.0)
	assert_gt(config.telegraph_visual_width_meters, 0.0)
	assert_gt(config.telegraph_visual_thickness_meters, 0.0)
	assert_gte(config.telegraph_visual_thickness_meters, 0.12)
	assert_false(config.muzzle_local_offset.is_zero_approx())
	assert_gt(config.telegraph_muzzle_marker_radius_meters, 0.0)
	assert_gt(config.telegraph_target_marker_radius_meters, 0.0)
	config.telegraph_visual_config = TelegraphVisualConfig.new()
	assert_true(config.telegraph_visual_config.is_valid_config())
	assert_gt(config.telegraph_visual_config.segment_count, 1)
	assert_gt(config.launcher_charge_scale_max, config.launcher_charge_scale_min)
	assert_true(config.projectile_config.trail_enabled)
	assert_gt(config.projectile_config.trail_length_meters, 0.0)
	assert_gt(config.projectile_config.trail_width_meters, 0.0)


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


func test_launcher_telegraph_tracks_player_and_shot_uses_that_direction() -> void:
	var root := Node3D.new()
	var player := PlayerController.new()
	var system := _create_projectile_system()

	player.name = "Player"
	player.position = Vector3(0.0, 1.05, 8.0)
	system.name = "ProjectileSystem"
	system.player_path = NodePath("../Player")
	system.launcher_config.telegraph_duration_seconds = 0.2
	system.launcher_config.projectile_config.speed_meters_per_second = 10.0
	system.launcher_config.telegraph_visual_length_meters = 30.0
	system.launcher_config.telegraph_target_padding_meters = 0.0

	root.add_child(player)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3(0.0, 0.55, 0.0)))
	assert_eq(system.get_active_telegraph_count(), 1)
	assert_gt(system.get_first_active_launcher_direction().z, 0.99)

	player.global_position = Vector3(8.0, 1.05, 0.0)
	system.step_system_for_tests(0.1)

	var fired_direction := system.get_first_active_launcher_direction()
	assert_gt(fired_direction.x, 0.99)

	system.step_system_for_tests(0.11)

	assert_eq(system.get_active_projectile_count(), 1)
	var shot_origin: Vector3 = system.call("_get_launcher_muzzle_position", 0)
	var projectile_travel := (
		(system.get_first_active_projectile_position() - shot_origin).normalized()
	)
	assert_gt(projectile_travel.dot(fired_direction), 0.98)

	remove_child(root)
	root.free()


func test_telegraph_length_progresses_with_charge() -> void:
	var root := Node3D.new()
	var player := PlayerController.new()
	var system := _create_projectile_system()

	player.name = "Player"
	player.position = Vector3(0.0, 1.05, 12.0)
	system.name = "ProjectileSystem"
	system.player_path = NodePath("../Player")
	system.launcher_config.telegraph_duration_seconds = 1.0
	system.launcher_config.telegraph_visual_length_meters = 20.0
	system.launcher_config.telegraph_min_length_meters = 2.0
	system.launcher_config.telegraph_target_padding_meters = 1.0

	root.add_child(player)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3.ZERO))
	var initial_length := system.get_first_active_launcher_telegraph_length()
	var initial_charge := system.get_first_active_launcher_charge_ratio()

	system.step_system_for_tests(0.5)

	assert_gt(system.get_first_active_launcher_telegraph_length(), initial_length)
	assert_gt(system.get_first_active_launcher_charge_ratio(), initial_charge)
	assert_true(
		(
			system.get_first_active_launcher_telegraph_length()
			<= system.launcher_config.telegraph_visual_length_meters
		)
	)

	remove_child(root)
	root.free()


func test_telegraph_visual_uses_launcher_muzzle_position() -> void:
	var system := _create_projectile_system()
	system.launcher_config.telegraph_duration_seconds = 1.0
	system.launcher_config.telegraph_visual_length_meters = 12.0
	system.launcher_config.telegraph_min_length_meters = 4.0
	system.launcher_config.spawn_height_meters = 0.55
	system.launcher_config.shot_height_meters = 1.25
	system.launcher_config.muzzle_local_offset = Vector3(0.0, 0.2, -0.8)
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3(2.0, 0.55, -3.0)))
	await get_tree().process_frame

	var shot_position: Vector3 = system.call("_get_launcher_muzzle_position", 0)
	var telegraph_start: Vector3 = system.call("_get_telegraph_origin_position", 0)
	assert_almost_eq(telegraph_start.x, shot_position.x, 0.001)
	assert_almost_eq(telegraph_start.y, shot_position.y, 0.001)
	assert_almost_eq(telegraph_start.z, shot_position.z, 0.001)

	var telegraph_batch := system.get_node("TelegraphBatch") as MultiMeshInstance3D
	var muzzle_marker_batch := system.get_node("TelegraphMuzzleMarkerBatch") as MultiMeshInstance3D
	var target_marker_batch := system.get_node("TelegraphTargetMarkerBatch") as MultiMeshInstance3D
	assert_not_null(telegraph_batch)
	assert_not_null(muzzle_marker_batch)
	assert_not_null(target_marker_batch)
	assert_eq(telegraph_batch.multimesh.visible_instance_count, 1)
	assert_eq(muzzle_marker_batch.multimesh.visible_instance_count, 1)
	assert_eq(target_marker_batch.multimesh.visible_instance_count, 1)

	remove_child(system)
	system.free()


func test_telegraph_visual_config_renders_segmented_batched_beam() -> void:
	var system := _create_projectile_system()
	var visual_config := TelegraphVisualConfig.new()
	visual_config.segment_count = 5
	visual_config.segment_gap_ratio = 0.35
	system.launcher_config.telegraph_visual_config = visual_config
	add_child(system)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3(2.0, 0.55, -3.0)))
	await get_tree().process_frame

	var telegraph_batch := system.get_node("TelegraphBatch") as MultiMeshInstance3D
	var muzzle_marker_batch := system.get_node("TelegraphMuzzleMarkerBatch") as MultiMeshInstance3D
	var target_marker_batch := system.get_node("TelegraphTargetMarkerBatch") as MultiMeshInstance3D
	assert_eq(telegraph_batch.multimesh.visible_instance_count, 5)
	assert_eq(muzzle_marker_batch.multimesh.visible_instance_count, 1)
	assert_eq(target_marker_batch.multimesh.visible_instance_count, 1)

	remove_child(system)
	system.free()


func test_projectile_spawns_from_announced_muzzle_position() -> void:
	var root := Node3D.new()
	var player := PlayerController.new()
	var system := _create_projectile_system()

	player.name = "Player"
	player.position = Vector3(7.0, 1.05, 0.0)
	system.name = "ProjectileSystem"
	system.player_path = NodePath("../Player")
	system.launcher_config.telegraph_duration_seconds = 0.05
	system.launcher_config.muzzle_local_offset = Vector3(0.0, 0.15, -0.75)
	system.launcher_config.projectile_config.speed_meters_per_second = 0.0

	root.add_child(player)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	assert_true(system.force_spawn_launcher_at(Vector3(0.0, 0.55, 0.0)))
	var announced_muzzle: Vector3 = system.call("_get_launcher_muzzle_position", 0)

	system.step_system_for_tests(0.06)

	assert_eq(system.get_active_projectile_count(), 1)
	var projectile_position := system.get_first_active_projectile_position()
	assert_almost_eq(projectile_position.x, announced_muzzle.x, 0.001)
	assert_almost_eq(projectile_position.y, announced_muzzle.y, 0.001)
	assert_almost_eq(projectile_position.z, announced_muzzle.z, 0.001)

	remove_child(root)
	root.free()


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
	var health := _create_health_component(100.0, 0.0)
	var system := _create_projectile_system()

	run_controller.name = "RunController"
	player.name = "Player"
	health.name = "HealthComponent"
	system.name = "ProjectileSystem"
	system.run_controller_path = NodePath("../RunController")
	system.player_path = NodePath("../Player")
	system.health_component_path = NodePath("../HealthComponent")
	system.launcher_config.projectile_config.damage_on_contact = false

	root.add_child(run_controller)
	root.add_child(player)
	root.add_child(health)
	root.add_child(system)
	add_child(root)
	await get_tree().process_frame

	run_controller.start_run()
	assert_true(system.force_spawn_projectile(Vector3(0.0, 0.7, 0.0), Vector3.RIGHT))

	system.step_system_for_tests(0.01)

	assert_true(run_controller.is_playing())
	assert_eq(run_controller.get_last_death_reason(), &"")
	assert_almost_eq(health.get_current_health(), 100.0, 0.001)

	remove_child(root)
	root.free()


func test_projectile_damage_reduces_health_without_killing_player() -> void:
	var runtime := await _create_projectile_damage_runtime(100.0, 0.0)
	var run_controller := runtime["run_controller"] as RunController
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem

	run_controller.start_run()
	assert_true(
		system.force_spawn_projectile(player.global_position + Vector3.UP * 0.7, Vector3.RIGHT)
	)

	system.step_system_for_tests(0.0)

	assert_eq(run_controller.get_state(), RunController.RunState.PLAYING)
	assert_almost_eq(health.get_current_health(), 75.0, 0.001)
	assert_eq(health.get_last_damage_type(), DamageProfile.DamageType.PROJECTILE)
	assert_eq(system.get_active_projectile_count(), 0)

	_free_runtime(runtime)


func test_projectile_damage_uses_player_capsule_hurtbox() -> void:
	var runtime := await _create_projectile_damage_runtime(100.0, 0.0)
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem

	assert_true(
		system.force_spawn_projectile(
			player.global_position + Vector3(0.0, -0.65, 0.0), Vector3.RIGHT
		)
	)

	system.step_system_for_tests(0.0)

	assert_almost_eq(health.get_current_health(), 75.0, 0.001)
	assert_eq(system.get_active_projectile_count(), 0)

	_free_runtime(runtime)


func test_projectile_damage_preserves_fair_near_misses() -> void:
	var runtime := await _create_projectile_damage_runtime(100.0, 0.0)
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem
	var projectile_radius := system.launcher_config.projectile_config.collision_radius_meters
	var near_miss_position := (
		player.global_position
		+ Vector3(player.get_hurtbox_radius() + projectile_radius + 0.05, 0.0, 0.0)
	)

	assert_true(system.force_spawn_projectile(near_miss_position, Vector3.RIGHT))

	system.step_system_for_tests(0.0)

	assert_almost_eq(health.get_current_health(), 100.0, 0.001)
	assert_eq(system.get_active_projectile_count(), 1)

	_free_runtime(runtime)


func test_projectile_damage_depletes_health_and_registers_run_death() -> void:
	var runtime := await _create_projectile_damage_runtime(25.0, 0.0)
	var run_controller := runtime["run_controller"] as RunController
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem

	run_controller.start_run()
	assert_true(
		system.force_spawn_projectile(player.global_position + Vector3.UP * 0.7, Vector3.RIGHT)
	)

	system.step_system_for_tests(0.0)

	assert_eq(run_controller.get_state(), RunController.RunState.DEAD)
	assert_eq(run_controller.get_last_death_reason(), &"projectile")
	assert_false(health.is_alive())
	assert_eq(system.get_active_projectile_count(), 0)

	_free_runtime(runtime)


func test_many_projectile_hits_accept_one_damage_during_invulnerability() -> void:
	var runtime := await _create_projectile_damage_runtime(100.0, 0.25)
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem
	var initial_node_count := system.get_runtime_node_count()

	for projectile_index in range(1000):
		assert_true(
			system.force_spawn_projectile(
				player.global_position + Vector3.UP * 0.7,
				Vector3.RIGHT.rotated(Vector3.UP, float(projectile_index) * 0.01)
			)
		)

	system.step_system_for_tests(0.0)

	assert_almost_eq(health.get_current_health(), 75.0, 0.001)
	assert_eq(health.get_last_damage_type(), DamageProfile.DamageType.PROJECTILE)
	assert_eq(system.get_active_projectile_count(), 0)
	assert_eq(system.get_runtime_node_count(), initial_node_count)

	_free_runtime(runtime)


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
	assert_true(system.get_runtime_node_count() <= 6)

	remove_child(system)
	system.free()


func test_custom_visual_scenes_keep_projectile_runtime_batched() -> void:
	var visual_scene := _create_mesh_packed_scene(BoxMesh.new())
	var system := _create_projectile_system()
	system.launcher_config.launcher_scene = visual_scene
	system.launcher_config.projectile_config.visual_scene = visual_scene
	system.launcher_config.max_active_projectiles = 32
	add_child(system)
	await get_tree().process_frame

	var initial_node_count := system.get_runtime_node_count()
	assert_true(system.force_spawn_launcher_at(Vector3(2.0, 0.5, 0.0)))
	for projectile_index in range(16):
		var angle := float(projectile_index) * 0.25
		assert_true(
			system.force_spawn_projectile(Vector3.ZERO, Vector3(cos(angle), 0.0, sin(angle)))
		)

	assert_eq(system.get_runtime_node_count(), initial_node_count)
	assert_true(system.get_runtime_node_count() <= 6)

	remove_child(system)
	system.free()


func _create_projectile_system() -> ProjectileSystem:
	var system := ProjectileSystem.new()
	system.launcher_config = ProjectileLauncherConfig.new()
	system.launcher_config.projectile_config.damage_profile = _create_projectile_damage_profile()
	system.launcher_config.telegraph_duration_seconds = 0.05
	system.launcher_config.linger_after_last_shot_seconds = 0.5
	system.launcher_config.launcher_lifetime_seconds = 5.0
	system.launcher_config.initial_spawn_delay_seconds = 100.0
	system.launcher_config.spawn_interval_seconds = 100.0
	return system


func _create_projectile_damage_runtime(
	max_health: float, invulnerability_seconds: float
) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var player := PlayerController.new()
	var health := _create_health_component(max_health, invulnerability_seconds)
	var system := _create_projectile_system()

	root.name = "ProjectileDamageRuntimeRoot"
	run_controller.name = "RunController"
	player.name = "Player"
	health.name = "HealthComponent"
	system.name = "ProjectileSystem"

	system.run_controller_path = NodePath("../RunController")
	system.player_path = NodePath("../Player")
	system.health_component_path = NodePath("../HealthComponent")
	health.depleted.connect(run_controller.register_death)

	root.add_child(run_controller)
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


func _create_health_component(max_health: float, invulnerability_seconds: float) -> HealthComponent:
	var config := HealthConfig.new()
	config.max_health = max_health
	config.hit_invulnerability_seconds = invulnerability_seconds

	var health := HealthComponent.new()
	health.health_config = config
	return health


func _create_projectile_damage_profile() -> DamageProfile:
	var profile := DamageProfile.new()
	profile.amount = 25.0
	profile.damage_type = DamageProfile.DamageType.PROJECTILE
	profile.death_reason = &"projectile"
	profile.hit_label = &"Projectile"
	return profile


func _create_mesh_packed_scene(mesh: Mesh) -> PackedScene:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	root.add_child(mesh_instance)
	mesh_instance.owner = root
	var scene := PackedScene.new()
	assert_eq(scene.pack(root), OK)
	root.free()
	return scene


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
