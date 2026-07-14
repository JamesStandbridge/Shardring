extends GutTest


func test_initial_input_actions_are_registered() -> void:
	var action_names := PackedStringArray(
		[
			"move_forward",
			"move_backward",
			"move_left",
			"move_right",
			"jump",
			"interact",
			"restart_run",
			"debug_toggle",
		]
	)

	for action_name: String in action_names:
		assert_true(InputMap.has_action(action_name), "%s must exist." % action_name)


func test_initial_3d_physics_layers_are_named() -> void:
	var expected_layers := {
		1: "player",
		2: "terrain",
		3: "danger",
		4: "pickup",
		5: "shop",
	}

	for layer_index: int in expected_layers:
		var setting_path := "layer_names/3d_physics/layer_%d" % layer_index
		assert_eq(ProjectSettings.get_setting(setting_path), expected_layers[layer_index])


func test_initial_3d_rendering_stays_sharp_for_gameplay_readability() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"), 2)
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa"), 0)
	assert_false(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa"))
	assert_false(
		ProjectSettings.get_setting(
			"rendering/anti_aliasing/screen_space_roughness_limiter/enabled"
		)
	)
	assert_eq(ProjectSettings.get_setting("rendering/scaling_3d/mode"), 0)
	assert_eq(ProjectSettings.get_setting("rendering/scaling_3d/mode.macos"), 0)
	assert_almost_eq(ProjectSettings.get_setting("rendering/scaling_3d/scale"), 1.0, 0.001)


func test_foundation_resource_defaults_are_playable() -> void:
	var player_config := PlayerMovementConfig.new()
	var arena_config := ArenaConfig.new()
	var default_arena_config := (
		load("res://src/data/arena/default_arena_config.tres") as ArenaConfig
	)
	var basic_projectile_config := (
		load("res://src/data/projectiles/basic_linear_projectile.tres") as ProjectileConfig
	)
	var basic_launcher_config := (
		load("res://src/data/projectiles/basic_single_shot_launcher.tres")
		as ProjectileLauncherConfig
	)
	var projectile_config := ProjectileConfig.new()
	var launcher_config := ProjectileLauncherConfig.new()
	var difficulty_config := DifficultyConfig.new()
	var upgrade_config := UpgradeConfig.new()

	assert_gt(player_config.run_speed_meters_per_second, 0.0)
	assert_eq(player_config.max_jump_count, 1)
	assert_gt(player_config.ground_acceleration_meters_per_second_squared, 0.0)
	assert_gt(
		player_config.ground_deceleration_meters_per_second_squared,
		player_config.ground_acceleration_meters_per_second_squared
	)
	assert_gt(
		player_config.ground_turn_acceleration_meters_per_second_squared,
		player_config.ground_acceleration_meters_per_second_squared
	)
	assert_gt(player_config.air_acceleration_meters_per_second_squared, 0.0)
	assert_gt(player_config.air_deceleration_meters_per_second_squared, 0.0)
	assert_true(player_config.air_control_ratio >= 0.0)
	assert_true(player_config.air_control_ratio <= 1.0)
	assert_gt(player_config.apex_air_acceleration_multiplier, 1.0)
	assert_gt(player_config.jump_velocity_meters_per_second, 0.0)
	assert_gt(player_config.jump_takeoff_horizontal_boost_meters_per_second, 0.0)
	assert_gt(player_config.jump_takeoff_max_speed_multiplier, 1.0)
	assert_gt(player_config.gravity_multiplier, 0.0)
	assert_gt(player_config.fall_gravity_multiplier, 1.0)
	assert_gt(player_config.jump_apex_gravity_multiplier, 0.0)
	assert_lt(player_config.jump_apex_gravity_multiplier, 1.0)
	assert_gt(player_config.jump_apex_velocity_threshold_meters_per_second, 0.0)
	assert_gt(player_config.jump_cut_velocity_multiplier, 0.0)
	assert_lt(player_config.jump_cut_velocity_multiplier, 1.0)
	assert_gt(player_config.coyote_time_seconds, 0.0)
	assert_gt(player_config.jump_buffer_seconds, 0.0)
	assert_gt(
		player_config.max_fall_speed_meters_per_second,
		player_config.jump_velocity_meters_per_second
	)
	assert_gt(player_config.floor_snap_length_meters, 0.0)
	assert_gt(player_config.safe_margin_meters, 0.0)
	assert_true(player_config.floor_constant_speed_enabled)
	assert_gt(player_config.max_slide_count, 0)
	assert_gt(arena_config.radius_meters, 0.0)
	assert_gt(arena_config.cell_count, 0)
	assert_eq(arena_config.thickness_meters, 1.0)
	assert_not_null(default_arena_config)
	assert_eq(default_arena_config.radius_meters, 24.0)
	assert_eq(default_arena_config.cell_count, 36)
	assert_not_null(basic_projectile_config)
	assert_eq(basic_projectile_config.motion_type, ProjectileConfig.MotionType.LINEAR)
	assert_gt(basic_projectile_config.speed_meters_per_second, 0.0)
	assert_gt(basic_projectile_config.lifetime_seconds, 0.0)
	assert_gt(basic_projectile_config.collision_radius_meters, 0.0)
	assert_gt(basic_projectile_config.visual_radius_meters, 0.0)
	assert_true(basic_projectile_config.damage_on_contact)
	assert_not_null(basic_launcher_config)
	assert_eq(
		basic_launcher_config.launcher_type, ProjectileLauncherConfig.LauncherType.SINGLE_SHOT
	)
	assert_same(basic_launcher_config.projectile_config, basic_projectile_config)
	assert_gt(basic_launcher_config.telegraph_duration_seconds, 0.0)
	assert_eq(basic_launcher_config.shot_count, 1)
	assert_gt(basic_launcher_config.spawn_interval_seconds, 0.0)
	assert_gt(projectile_config.speed_meters_per_second, 0.0)
	assert_gt(projectile_config.lifetime_seconds, 0.0)
	assert_gt(projectile_config.collision_radius_meters, 0.0)
	assert_gt(projectile_config.visual_radius_meters, 0.0)
	assert_eq(projectile_config.motion_type, ProjectileConfig.MotionType.LINEAR)
	assert_eq(projectile_config.death_reason, &"projectile")
	assert_true(projectile_config.damage_on_contact)
	assert_eq(launcher_config.launcher_type, ProjectileLauncherConfig.LauncherType.SINGLE_SHOT)
	assert_not_null(launcher_config.projectile_config)
	assert_gt(launcher_config.telegraph_duration_seconds, 0.0)
	assert_eq(launcher_config.shot_count, 1)
	assert_gt(launcher_config.shot_interval_seconds, 0.0)
	assert_gt(launcher_config.min_distance_from_player_meters, 0.0)
	assert_gt(launcher_config.max_active_launchers, 0)
	assert_gt(launcher_config.max_active_projectiles, launcher_config.max_active_launchers)
	assert_gt(difficulty_config.max_intensity, difficulty_config.starting_intensity)
	assert_gt(difficulty_config.initial_spawn_interval_seconds, 0.0)
	assert_eq(upgrade_config.upgrade_id, UpgradeConfig.UpgradeId.DOUBLE_JUMP)
	assert_eq(upgrade_config.run_currency_cost, 20)
