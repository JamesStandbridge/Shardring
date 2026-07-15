extends GutTest


func test_projectile_near_miss_emits_once_without_creating_nodes() -> void:
	var runtime := await _create_projectile_damage_runtime(100.0, 0.0)
	var player := runtime["player"] as PlayerController
	var health := runtime["health"] as HealthComponent
	var system := runtime["system"] as ProjectileSystem
	var initial_node_count := system._get_runtime_node_count_for_tests()
	var projectile_radius := system.launcher_config.projectile_config.collision_radius_meters
	var near_miss_position := (
		player.global_position
		+ Vector3(player.get_hurtbox_radius() + projectile_radius + 0.28, 0.0, 0.0)
	)
	var near_miss_events := [0]
	var near_miss_strength := [0.0]
	system.projectile_near_missed.connect(
		func(_position: Vector3, _distance: float, strength: float) -> void:
			near_miss_events[0] += 1
			near_miss_strength[0] = strength
	)

	assert_true(system.force_spawn_projectile(near_miss_position, Vector3.RIGHT))

	system.step_system_for_tests(0.0)
	system.step_system_for_tests(0.0)

	assert_eq(near_miss_events[0], 1)
	assert_gt(near_miss_strength[0], 0.0)
	assert_almost_eq(health.get_current_health(), 100.0, 0.001)
	assert_eq(system.get_active_projectile_count(), 1)
	assert_eq(system._get_runtime_node_count_for_tests(), initial_node_count)

	_free_runtime(runtime)


func _create_projectile_damage_runtime(
	max_health: float, invulnerability_seconds: float
) -> Dictionary:
	var root := Node3D.new()
	var run_controller := RunController.new()
	var player := PlayerController.new()
	var health := _create_health_component(max_health, invulnerability_seconds)
	var system := ProjectileSystem.new()

	root.name = "ProjectileNearMissRuntimeRoot"
	run_controller.name = "RunController"
	player.name = "Player"
	health.name = "HealthComponent"
	system.name = "ProjectileSystem"
	system.launcher_config = ProjectileLauncherConfig.new()
	system.launcher_config.projectile_config.damage_profile = _create_projectile_damage_profile()
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


func _free_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
