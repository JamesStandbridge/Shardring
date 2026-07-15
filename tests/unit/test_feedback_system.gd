extends GutTest


func test_feedback_configs_are_valid_and_route_damage_types() -> void:
	var camera_shake_config := CameraShakeConfig.new()
	var damage_feedback_config := DamageFeedbackConfig.new()
	var default_feedback := (
		load("res://src/data/feedback/default_damage_feedback.tres") as DamageFeedbackConfig
	)
	var projectile_shake := (
		load("res://src/data/feedback/projectile_hit_camera_shake.tres") as CameraShakeConfig
	)
	var explosive_shake := (
		load("res://src/data/feedback/explosive_hit_camera_shake.tres") as CameraShakeConfig
	)

	assert_true(camera_shake_config.is_valid_config())
	assert_true(damage_feedback_config.is_valid_config())
	assert_not_null(default_feedback)
	assert_true(default_feedback.is_valid_config())
	assert_same(
		default_feedback.get_shake_for_damage_type(DamageProfile.DamageType.PROJECTILE),
		projectile_shake
	)
	assert_same(
		default_feedback.get_shake_for_damage_type(DamageProfile.DamageType.EXPLOSIVE),
		explosive_shake
	)
	assert_gt(default_feedback.health_flash_duration_seconds, 0.0)
	assert_lte(default_feedback.reference_damage_amount, 25.0)
	assert_lte(default_feedback.min_strength_multiplier, default_feedback.max_strength_multiplier)
	assert_gte(projectile_shake.amplitude_meters, 0.18)
	assert_gte(projectile_shake.angular_amplitude_degrees, 0.8)
	assert_gte(explosive_shake.amplitude_meters, projectile_shake.amplitude_meters)


func test_camera_shake_offsets_camera_and_decays() -> void:
	var camera_rig := ThirdPersonCameraRig.new()
	var spring_arm := SpringArm3D.new()
	var camera_shake_pivot := Node3D.new()
	var camera := Camera3D.new()
	spring_arm.name = "SpringArm3D"
	camera_shake_pivot.name = "CameraShakePivot"
	camera.name = "Camera3D"
	camera_shake_pivot.add_child(camera)
	spring_arm.add_child(camera_shake_pivot)
	camera_rig.add_child(spring_arm)
	add_child(camera_rig)
	await get_tree().process_frame
	var spring_arm_managed_pivot_position := camera_shake_pivot.position
	var base_camera_position := camera.position

	var shake_config := CameraShakeConfig.new()
	shake_config.duration_seconds = 0.12
	shake_config.amplitude_meters = 0.12
	shake_config.angular_amplitude_degrees = 1.0
	shake_config.frequency_hz = 17.0

	camera_rig.request_shake(shake_config)
	camera_rig.step_camera_shake_for_tests(0.016)

	assert_true(camera_rig.is_shaking())
	assert_gt(camera_rig.get_current_shake_intensity(), 0.0)
	_assert_vector3_almost_eq(camera_shake_pivot.position, spring_arm_managed_pivot_position, 0.001)
	assert_gt(camera.position.distance_to(base_camera_position), 0.0)
	assert_gt(camera.rotation.length(), 0.0)

	camera_rig.step_camera_shake_for_tests(1.0)

	assert_false(camera_rig.is_shaking())
	_assert_vector3_almost_eq(camera_shake_pivot.position, spring_arm_managed_pivot_position, 0.001)
	_assert_vector3_almost_eq(camera.position, base_camera_position, 0.001)
	assert_almost_eq(camera.rotation.length(), 0.0, 0.001)

	remove_child(camera_rig)
	camera_rig.free()


func test_gameplay_juice_controller_routes_near_miss_to_camera_and_hud() -> void:
	var runtime := await _create_juice_runtime()
	var chaser_system := runtime["chaser_system"] as ChaserEnemySystem
	var camera_rig := runtime["camera_rig"] as ThirdPersonCameraRig
	var health_hud := runtime["health_hud"] as HealthHud
	var juice := runtime["juice"] as GameplayJuiceController

	chaser_system.chaser_near_missed.emit(Vector3.ZERO, 3.0, 0.85)

	assert_eq(juice.get_last_event_name(), &"chaser_near_miss")
	assert_gt(juice.get_last_event_strength(), 0.0)
	assert_true(camera_rig.is_shaking())
	assert_true(health_hud.is_callout_visible())
	assert_eq(health_hud.get_callout_text(), "DODGE")

	_free_juice_runtime(runtime)


func test_gameplay_juice_controller_routes_shard_and_exit_callouts() -> void:
	var runtime := await _create_juice_runtime()
	var objective := runtime["objective"] as ShardObjectiveController
	var health_hud := runtime["health_hud"] as HealthHud
	var juice := runtime["juice"] as GameplayJuiceController

	objective.shard_collected.emit(1, 3, 1)

	assert_eq(juice.get_last_event_name(), &"shard_collected")
	assert_true(health_hud.is_callout_visible())
	assert_eq(health_hud.get_callout_text(), "SHARD")

	objective.objective_completed.emit(3)

	assert_eq(juice.get_last_event_name(), &"objective_completed")
	assert_true(health_hud.is_callout_visible())
	assert_eq(health_hud.get_callout_text(), "EXIT READY")

	_free_juice_runtime(runtime)


func _assert_vector3_almost_eq(actual: Vector3, expected: Vector3, epsilon: float) -> void:
	assert_almost_eq(actual.x, expected.x, epsilon)
	assert_almost_eq(actual.y, expected.y, epsilon)
	assert_almost_eq(actual.z, expected.z, epsilon)


func _create_juice_runtime() -> Dictionary:
	var root := Node3D.new()
	var chaser_system := ChaserEnemySystem.new()
	var projectile_system := ProjectileSystem.new()
	var objective := ShardObjectiveController.new()
	var camera_rig := ThirdPersonCameraRig.new()
	var spring_arm := SpringArm3D.new()
	var camera_shake_pivot := Node3D.new()
	var camera := Camera3D.new()
	var health_hud := HealthHud.new()
	var callout_label := Label.new()
	var juice := GameplayJuiceController.new()

	root.name = "JuiceRuntimeRoot"
	chaser_system.name = "ChaserEnemySystem"
	projectile_system.name = "ProjectileSystem"
	objective.name = "ShardObjective"
	camera_rig.name = "ThirdPersonCameraRig"
	spring_arm.name = "SpringArm3D"
	camera_shake_pivot.name = "CameraShakePivot"
	camera.name = "Camera3D"
	health_hud.name = "HealthHud"
	callout_label.name = "CalloutLabel"
	juice.name = "GameplayJuiceController"

	camera_shake_pivot.add_child(camera)
	spring_arm.add_child(camera_shake_pivot)
	camera_rig.add_child(spring_arm)
	health_hud.add_child(callout_label)

	juice.chaser_enemy_system_path = NodePath("../ChaserEnemySystem")
	juice.projectile_system_path = NodePath("../ProjectileSystem")
	juice.shard_objective_path = NodePath("../ShardObjective")
	juice.camera_rig_path = NodePath("../ThirdPersonCameraRig")
	juice.health_hud_path = NodePath("../HealthHud")

	root.add_child(chaser_system)
	root.add_child(projectile_system)
	root.add_child(objective)
	root.add_child(camera_rig)
	root.add_child(health_hud)
	root.add_child(juice)
	add_child(root)
	await get_tree().process_frame

	return {
		"root": root,
		"chaser_system": chaser_system,
		"projectile_system": projectile_system,
		"objective": objective,
		"camera_rig": camera_rig,
		"health_hud": health_hud,
		"juice": juice,
	}


func _free_juice_runtime(runtime: Dictionary) -> void:
	var root := runtime["root"] as Node
	remove_child(root)
	root.free()
