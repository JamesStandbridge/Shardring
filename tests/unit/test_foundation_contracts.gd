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
	var default_danger_director_config := (
		load("res://src/data/dangers/default_danger_director_config.tres") as DangerDirectorConfig
	)
	var basic_projectile_danger := (
		load("res://src/data/dangers/basic_projectile_danger.tres") as DangerDefinition
	)
	var basic_chaser_config := (
		load("res://src/data/enemies/basic_explosive_chaser.tres") as ExplosiveChaserConfig
	)
	var explosive_chaser_danger := (
		load("res://src/data/dangers/explosive_chaser_danger.tres") as DangerDefinition
	)
	var default_player_health := (
		load("res://src/data/combat/default_player_health.tres") as HealthConfig
	)
	var default_player_hurtbox := (
		load("res://src/data/combat/default_player_hurtbox.tres") as PlayerHurtboxConfig
	)
	var default_player_animation := (
		load("res://src/data/player/default_player_animation.tres") as PlayerAnimationConfig
	)
	var basic_projectile_damage := (
		load("res://src/data/combat/basic_projectile_damage.tres") as DamageProfile
	)
	var basic_chaser_damage := (
		load("res://src/data/combat/basic_chaser_explosion_damage.tres") as DamageProfile
	)
	var default_damage_feedback := (
		load("res://src/data/feedback/default_damage_feedback.tres") as DamageFeedbackConfig
	)
	var default_projectile_telegraph := (
		load("res://src/visual/vfx/default_projectile_telegraph.tres") as TelegraphVisualConfig
	)
	var projectile_hit_shake := (
		load("res://src/data/feedback/projectile_hit_camera_shake.tres") as CameraShakeConfig
	)
	var explosive_hit_shake := (
		load("res://src/data/feedback/explosive_hit_camera_shake.tres") as CameraShakeConfig
	)
	var mint_theme := (
		load("res://src/data/stages/themes/toybox_mint_theme.tres") as ArenaThemeConfig
	)
	var candy_theme := (
		load("res://src/data/stages/themes/toybox_candy_theme.tres") as ArenaThemeConfig
	)
	var mint_map := load("res://src/data/stages/maps/toybox_mint_map.tres") as MapDefinition
	var candy_map := load("res://src/data/stages/maps/toybox_candy_map.tres") as MapDefinition
	var stage_sequence := (
		load("res://src/data/stages/default_stage_sequence.tres") as StageSequenceConfig
	)
	var projectile_config := ProjectileConfig.new()
	var launcher_config := ProjectileLauncherConfig.new()
	var chaser_config := ExplosiveChaserConfig.new()
	var arena_theme_config := ArenaThemeConfig.new()
	var map_definition := MapDefinition.new()
	var stage_sequence_config := StageSequenceConfig.new()
	var damage_profile := DamageProfile.new()
	var health_config := HealthConfig.new()
	var hurtbox_config := PlayerHurtboxConfig.new()
	var player_animation_config := PlayerAnimationConfig.new()
	var camera_shake_config := CameraShakeConfig.new()
	var damage_feedback_config := DamageFeedbackConfig.new()
	var danger_definition := DangerDefinition.new()
	var danger_director_config := DangerDirectorConfig.new()
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
	assert_gt(arena_config.boundary_irregularity_meters, 0.0)
	assert_gt(arena_config.boundary_irregularity_control_points, 2)
	assert_gt(arena_config.surface_height_amplitude_meters, 0.0)
	assert_gt(arena_config.surface_height_frequency, 0.0)
	assert_not_null(default_arena_config)
	assert_eq(default_arena_config.radius_meters, 42.0)
	assert_eq(default_arena_config.cell_count, 72)
	assert_gt(default_arena_config.boundary_irregularity_meters, 0.0)
	assert_gt(default_arena_config.surface_height_amplitude_meters, 0.0)
	assert_not_null(basic_projectile_config)
	assert_eq(basic_projectile_config.motion_type, ProjectileConfig.MotionType.LINEAR)
	assert_gt(basic_projectile_config.speed_meters_per_second, 0.0)
	assert_gt(basic_projectile_config.lifetime_seconds, 0.0)
	assert_gt(basic_projectile_config.collision_radius_meters, 0.0)
	assert_gt(basic_projectile_config.visual_radius_meters, 0.0)
	assert_not_null(basic_projectile_config.visual_scene)
	assert_eq(
		basic_projectile_config.visual_scene.resource_path,
		"res://src/visual/assets/projectile_arcade_wrapper.tscn"
	)
	assert_true(
		(
			basic_projectile_config.collision_radius_meters
			<= basic_projectile_config.visual_radius_meters
		)
	)
	assert_true(basic_projectile_config.damage_on_contact)
	assert_not_null(basic_projectile_config.damage_profile)
	assert_same(basic_projectile_config.damage_profile, basic_projectile_damage)
	assert_eq(
		basic_projectile_config.damage_profile.damage_type, DamageProfile.DamageType.PROJECTILE
	)
	assert_gt(basic_projectile_config.damage_profile.amount, 0.0)
	assert_true(basic_projectile_config.trail_enabled)
	assert_gt(basic_projectile_config.trail_length_meters, 0.0)
	assert_gt(basic_projectile_config.trail_width_meters, 0.0)
	assert_gt(basic_projectile_config.trail_emission_energy, 0.0)
	assert_not_null(basic_launcher_config)
	assert_eq(
		basic_launcher_config.launcher_type, ProjectileLauncherConfig.LauncherType.SINGLE_SHOT
	)
	assert_same(basic_launcher_config.projectile_config, basic_projectile_config)
	assert_gt(basic_launcher_config.telegraph_duration_seconds, 0.0)
	assert_eq(basic_launcher_config.shot_count, 1)
	assert_gt(basic_launcher_config.spawn_interval_seconds, 0.0)
	assert_not_null(basic_launcher_config.launcher_scene)
	assert_eq(
		basic_launcher_config.launcher_scene.resource_path,
		"res://src/visual/assets/launcher_arcade_wrapper.tscn"
	)
	assert_not_null(basic_launcher_config.telegraph_visual_config)
	assert_same(basic_launcher_config.telegraph_visual_config, default_projectile_telegraph)
	assert_true(default_projectile_telegraph.is_valid_config())
	assert_gt(default_projectile_telegraph.segment_count, 1)
	assert_eq(
		basic_launcher_config.telegraph_mode, ProjectileLauncherConfig.TelegraphMode.TO_TARGET
	)
	assert_gt(basic_launcher_config.telegraph_visual_length_meters, 0.0)
	assert_gt(basic_launcher_config.telegraph_visual_width_meters, 0.0)
	assert_gt(basic_launcher_config.telegraph_visual_thickness_meters, 0.0)
	assert_gt(basic_launcher_config.telegraph_surface_height_meters, 0.0)
	assert_false(basic_launcher_config.muzzle_local_offset.is_zero_approx())
	assert_gt(basic_launcher_config.telegraph_muzzle_marker_radius_meters, 0.0)
	assert_gt(basic_launcher_config.telegraph_target_marker_radius_meters, 0.0)
	assert_gt(basic_launcher_config.telegraph_min_length_meters, 0.0)
	assert_true(
		(
			basic_launcher_config.telegraph_min_length_meters
			<= basic_launcher_config.telegraph_visual_length_meters
		)
	)
	assert_gt(basic_launcher_config.telegraph_target_padding_meters, 0.0)
	assert_gt(
		basic_launcher_config.launcher_charge_scale_max,
		basic_launcher_config.launcher_charge_scale_min
	)
	assert_gt(projectile_config.speed_meters_per_second, 0.0)
	assert_gt(projectile_config.lifetime_seconds, 0.0)
	assert_gt(projectile_config.collision_radius_meters, 0.0)
	assert_gt(projectile_config.visual_radius_meters, 0.0)
	assert_null(projectile_config.visual_scene)
	assert_true(projectile_config.collision_radius_meters <= projectile_config.visual_radius_meters)
	assert_eq(projectile_config.motion_type, ProjectileConfig.MotionType.LINEAR)
	assert_eq(projectile_config.death_reason, &"projectile")
	assert_not_null(projectile_config.damage_profile)
	assert_true(projectile_config.damage_profile.is_valid_profile())
	assert_true(projectile_config.damage_on_contact)
	assert_true(projectile_config.trail_enabled)
	assert_gt(projectile_config.trail_length_meters, 0.0)
	assert_gt(projectile_config.trail_width_meters, 0.0)
	assert_eq(launcher_config.launcher_type, ProjectileLauncherConfig.LauncherType.SINGLE_SHOT)
	assert_not_null(launcher_config.projectile_config)
	assert_null(launcher_config.launcher_scene)
	assert_gt(launcher_config.telegraph_duration_seconds, 0.0)
	assert_eq(launcher_config.shot_count, 1)
	assert_gt(launcher_config.shot_interval_seconds, 0.0)
	assert_gt(launcher_config.min_distance_from_player_meters, 0.0)
	assert_eq(launcher_config.telegraph_mode, ProjectileLauncherConfig.TelegraphMode.TO_TARGET)
	assert_gt(launcher_config.telegraph_visual_length_meters, 0.0)
	assert_gt(launcher_config.telegraph_visual_width_meters, 0.0)
	assert_gt(launcher_config.telegraph_visual_thickness_meters, 0.0)
	assert_gt(launcher_config.telegraph_surface_height_meters, 0.0)
	assert_false(launcher_config.muzzle_local_offset.is_zero_approx())
	assert_gt(launcher_config.telegraph_muzzle_marker_radius_meters, 0.0)
	assert_gt(launcher_config.telegraph_target_marker_radius_meters, 0.0)
	assert_true(
		(
			launcher_config.telegraph_min_length_meters
			<= launcher_config.telegraph_visual_length_meters
		)
	)
	assert_gt(launcher_config.max_active_launchers, 0)
	assert_gt(launcher_config.max_active_projectiles, launcher_config.max_active_launchers)
	assert_not_null(default_danger_director_config)
	assert_gt(default_danger_director_config.credits_per_second, 0.0)
	assert_gt(default_danger_director_config.max_stored_credits, 0.0)
	assert_gt(default_danger_director_config.decision_interval_seconds, 0.0)
	assert_not_null(default_player_health)
	assert_true(default_player_health.is_valid_config())
	assert_eq(default_player_health.max_health, 100.0)
	assert_gt(default_player_health.hit_invulnerability_seconds, 0.0)
	assert_not_null(default_player_hurtbox)
	assert_true(default_player_hurtbox.is_valid_config())
	assert_lt(default_player_hurtbox.radius_meters, 0.38)
	assert_lt(default_player_hurtbox.height_meters, 1.8)
	assert_gt(default_player_hurtbox.height_meters, 1.5)
	assert_not_null(default_player_animation)
	assert_true(default_player_animation.is_valid_config())
	assert_gt(default_player_animation.run_bob_height_meters, 0.0)
	assert_gt(default_player_animation.takeoff_stretch_scale, 0.0)
	assert_gt(default_player_animation.landing_squash_scale, 0.0)
	assert_not_null(basic_projectile_damage)
	assert_true(basic_projectile_damage.is_valid_profile())
	assert_eq(basic_projectile_damage.damage_type, DamageProfile.DamageType.PROJECTILE)
	assert_eq(basic_projectile_damage.death_reason, &"projectile")
	assert_not_null(basic_chaser_damage)
	assert_true(basic_chaser_damage.is_valid_profile())
	assert_eq(basic_chaser_damage.damage_type, DamageProfile.DamageType.EXPLOSIVE)
	assert_eq(basic_chaser_damage.death_reason, &"chaser_explosion")
	assert_not_null(default_damage_feedback)
	assert_true(default_damage_feedback.is_valid_config())
	assert_not_null(projectile_hit_shake)
	assert_true(projectile_hit_shake.is_valid_config())
	assert_not_null(explosive_hit_shake)
	assert_true(explosive_hit_shake.is_valid_config())
	assert_not_null(mint_theme)
	assert_true(mint_theme.is_valid_theme())
	assert_not_null(candy_theme)
	assert_true(candy_theme.is_valid_theme())
	assert_not_null(mint_map)
	assert_true(mint_map.is_valid_map())
	assert_not_null(candy_map)
	assert_true(candy_map.is_valid_map())
	assert_not_null(stage_sequence)
	assert_true(stage_sequence.is_valid_sequence())
	assert_eq(stage_sequence.maps.size(), 2)
	assert_same(stage_sequence.get_map_for_level(1), mint_map)
	assert_same(stage_sequence.get_map_for_level(2), candy_map)
	assert_same(stage_sequence.get_map_for_level(3), mint_map)
	assert_almost_eq(stage_sequence.get_required_threat_budget_for_level(1), 22.0, 0.001)
	assert_almost_eq(stage_sequence.get_required_threat_budget_for_level(2), 30.0, 0.001)
	assert_same(
		default_damage_feedback.get_shake_for_damage_type(DamageProfile.DamageType.PROJECTILE),
		projectile_hit_shake
	)
	assert_same(
		default_damage_feedback.get_shake_for_damage_type(DamageProfile.DamageType.EXPLOSIVE),
		explosive_hit_shake
	)
	assert_not_null(basic_projectile_danger)
	assert_true(basic_projectile_danger.is_valid_definition())
	assert_eq(basic_projectile_danger.family, DangerDefinition.DangerFamily.PROJECTILE_LAUNCHER)
	assert_same(basic_projectile_danger.specialized_config, basic_launcher_config)
	assert_not_null(basic_chaser_config)
	assert_true(basic_chaser_config.is_valid_config())
	assert_not_null(basic_chaser_config.body_scene)
	assert_eq(
		basic_chaser_config.body_scene.resource_path,
		"res://src/visual/assets/chaser_arcade_wrapper.tscn"
	)
	assert_gt(basic_chaser_config.max_active_enemies, 0)
	assert_gt(basic_chaser_config.walk_speed_meters_per_second, 0.0)
	assert_gt(basic_chaser_config.chase_speed_meters_per_second, 0.0)
	assert_gte(
		basic_chaser_config.chase_speed_meters_per_second,
		basic_chaser_config.walk_speed_meters_per_second
	)
	assert_gte(
		basic_chaser_config.run_trigger_radius_meters,
		basic_chaser_config.prime_trigger_radius_meters
	)
	assert_gt(basic_chaser_config.face_player_lerp_speed, 0.0)
	assert_eq(basic_chaser_config.visual_yaw_offset_degrees, 180.0)
	assert_gt(basic_chaser_config.prime_duration_seconds, 0.0)
	assert_gt(basic_chaser_config.explosion_radius_meters, 0.0)
	assert_gt(basic_chaser_config.movement_bob_frequency_walk_hz, 0.0)
	assert_gte(
		basic_chaser_config.movement_bob_frequency_run_hz,
		basic_chaser_config.movement_bob_frequency_walk_hz
	)
	assert_gte(basic_chaser_config.run_excitement_scale_multiplier, 1.0)
	assert_true(
		basic_chaser_config.collision_radius_meters <= basic_chaser_config.visual_radius_meters
	)
	assert_not_null(basic_chaser_config.damage_profile)
	assert_same(basic_chaser_config.damage_profile, basic_chaser_damage)
	assert_not_null(explosive_chaser_danger)
	assert_true(explosive_chaser_danger.is_valid_definition())
	assert_eq(explosive_chaser_danger.family, DangerDefinition.DangerFamily.ACTOR_ENEMY)
	assert_same(explosive_chaser_danger.specialized_config, basic_chaser_config)
	assert_true(chaser_config.is_valid_config())
	assert_null(chaser_config.body_scene)
	assert_true(damage_profile.is_valid_profile())
	assert_true(health_config.is_valid_config())
	assert_true(hurtbox_config.is_valid_config())
	assert_true(player_animation_config.is_valid_config())
	assert_true(camera_shake_config.is_valid_config())
	assert_true(damage_feedback_config.is_valid_config())
	assert_true(arena_theme_config.is_valid_theme())
	assert_true(map_definition.is_valid_map())
	assert_true(stage_sequence_config.is_valid_sequence())
	assert_true(danger_definition.is_valid_definition())
	assert_gt(danger_director_config.credits_per_second, 0.0)
	assert_gt(danger_director_config.max_total_active_dangers, 0)
	assert_gt(difficulty_config.max_intensity, difficulty_config.starting_intensity)
	assert_gt(difficulty_config.initial_spawn_interval_seconds, 0.0)
	assert_eq(upgrade_config.upgrade_id, UpgradeConfig.UpgradeId.DOUBLE_JUMP)
	assert_eq(upgrade_config.run_currency_cost, 20)
	assert_true(FileAccess.file_exists("res://assets/art/source_blender/asset_toybox_kit.blend"))
	assert_true(FileAccess.file_exists("res://assets/art/exports_godot/asset_toybox_player.glb"))
	assert_true(FileAccess.file_exists("res://assets/art/exports_godot/asset_toybox_chaser.glb"))
	assert_true(FileAccess.file_exists("res://assets/art/exports_godot/asset_toybox_launcher.glb"))
	assert_true(
		FileAccess.file_exists("res://assets/art/exports_godot/asset_toybox_projectile.glb")
	)
	assert_true(FileAccess.file_exists("res://assets/art/exports_godot/asset_toybox_exit_gate.glb"))
	assert_true(FileAccess.file_exists("res://assets/art/asset_manifest.json"))
	assert_true(FileAccess.file_exists("res://src/visual/assets/player_arcade_wrapper.tscn"))
	assert_true(FileAccess.file_exists("res://src/visual/assets/chaser_arcade_wrapper.tscn"))
	assert_true(FileAccess.file_exists("res://src/visual/assets/launcher_arcade_wrapper.tscn"))
	assert_true(FileAccess.file_exists("res://src/visual/assets/projectile_arcade_wrapper.tscn"))
	assert_true(FileAccess.file_exists("res://src/visual/assets/exit_gate_arcade_wrapper.tscn"))
	assert_true(FileAccess.file_exists("res://src/dev/playgrounds/art_review_playground.tscn"))
