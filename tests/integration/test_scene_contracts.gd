extends GutTest

const MAIN_SCENE_PATH := "res://src/main/main.tscn"
const ARENA_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/arena_playground.tscn"
const PROJECTILE_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/projectile_playground.tscn"
const CHASER_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/chaser_enemy_playground.tscn"
const HAZARD_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/hazard_playground.tscn"
const ART_REVIEW_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/art_review_playground.tscn"


func test_main_scene_contains_arena_and_player_collision_contract() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().process_frame

	var arena := instance.get_node_or_null("Arena") as ArenaController
	var player := instance.get_node_or_null("Player") as PlayerController
	var player_visual_animator := (
		instance.get_node_or_null("Player/PlayerVisualAnimator") as PlayerVisualAnimator
	)
	var player_arcade_visual := (
		instance.get_node_or_null("Player/PlayerVisualAnimator/PlayerArcadeVisual") as Node3D
	)
	var graybox_player_body := instance.get_node_or_null("Player/Body") as MeshInstance3D
	var projectile_system := instance.get_node_or_null("ProjectileSystem") as ProjectileSystem
	var chaser_enemy_system := instance.get_node_or_null("ChaserEnemySystem") as ChaserEnemySystem
	var arena_hazard_system := instance.get_node_or_null("ArenaHazardSystem") as ArenaHazardSystem
	var danger_director := instance.get_node_or_null("DangerDirector") as DangerDirector
	var danger_placement_service := (
		instance.get_node_or_null("DangerPlacementService") as DangerPlacementService
	)
	var stage_controller := instance.get_node_or_null("StageController") as StageController
	var shard_objective := instance.get_node_or_null("ShardObjective") as ShardObjectiveController
	var exit_gate := instance.get_node_or_null("ExitGate") as ExitGateController
	var health_component := instance.get_node_or_null("Player/HealthComponent") as HealthComponent
	var health_hud := instance.get_node_or_null("HealthHud") as HealthHud
	var health_panel := instance.get_node_or_null("HealthHud/Panel") as Panel
	var health_label := instance.get_node_or_null("HealthHud/Panel/HealthLabel") as Label
	var stage_label := instance.get_node_or_null("HealthHud/Panel/StageLabel") as Label
	var objective_label := instance.get_node_or_null("HealthHud/Panel/ObjectiveLabel") as Label
	var speed_label := instance.get_node_or_null("HealthHud/Panel/SpeedLabel") as Label
	var jump_label := instance.get_node_or_null("HealthHud/Panel/JumpLabel") as Label
	var peak_label := instance.get_node_or_null("HealthHud/PeakLabel") as Label
	var damage_feedback := (
		instance.get_node_or_null("DamageFeedbackController") as DamageFeedbackController
	)
	var gameplay_juice := (
		instance.get_node_or_null("GameplayJuiceController") as GameplayJuiceController
	)
	var callout_label := instance.get_node_or_null("HealthHud/CalloutLabel") as Label
	var debug_label := instance.get_node_or_null("DebugOverlay/DebugLabel") as Label
	var camera_rig := instance.get_node_or_null("ThirdPersonCameraRig") as ThirdPersonCameraRig
	var camera_arm := instance.get_node_or_null("ThirdPersonCameraRig/SpringArm3D") as SpringArm3D
	var camera_shake_pivot := (
		instance.get_node_or_null("ThirdPersonCameraRig/SpringArm3D/CameraShakePivot") as Node3D
	)
	var camera := (
		instance.get_node_or_null("ThirdPersonCameraRig/SpringArm3D/CameraShakePivot/Camera3D")
		as Camera3D
	)
	var run_feedback_overlay := (
		instance.get_node_or_null("RunFeedbackOverlay") as RunFeedbackOverlay
	)

	assert_not_null(arena)
	assert_not_null(player)
	assert_not_null(player_visual_animator)
	assert_not_null(player_arcade_visual)
	assert_not_null(graybox_player_body)
	assert_false(graybox_player_body.visible)
	assert_almost_eq(player_visual_animator.rotation.y, PI, 0.001)
	assert_eq(player_visual_animator.player_path, NodePath(".."))
	assert_not_null(player_visual_animator.animation_config)
	assert_eq(
		player_visual_animator.animation_config.resource_path,
		"res://src/data/player/default_player_animation.tres"
	)
	assert_not_null(projectile_system)
	assert_not_null(chaser_enemy_system)
	assert_not_null(arena_hazard_system)
	assert_not_null(danger_director)
	assert_not_null(danger_placement_service)
	assert_not_null(stage_controller)
	assert_not_null(shard_objective)
	assert_not_null(exit_gate)
	assert_not_null(health_component)
	assert_not_null(health_hud)
	assert_not_null(health_panel)
	assert_not_null(health_label)
	assert_not_null(stage_label)
	assert_not_null(objective_label)
	assert_not_null(speed_label)
	assert_not_null(jump_label)
	assert_not_null(peak_label)
	assert_not_null(damage_feedback)
	assert_not_null(gameplay_juice)
	assert_not_null(callout_label)
	assert_not_null(debug_label)
	assert_not_null(camera_rig)
	assert_not_null(camera_shake_pivot)
	assert_not_null(camera)
	assert_not_null(player.hurtbox_config)
	assert_true(player.hurtbox_config.is_valid_config())
	assert_not_null(run_feedback_overlay)
	assert_not_null(projectile_system.launcher_config)
	assert_not_null(projectile_system.launcher_config.projectile_config)
	assert_not_null(chaser_enemy_system.chaser_config)
	assert_not_null(damage_feedback.feedback_config)
	assert_eq(gameplay_juice.chaser_enemy_system_path, NodePath("../ChaserEnemySystem"))
	assert_eq(gameplay_juice.projectile_system_path, NodePath("../ProjectileSystem"))
	assert_eq(gameplay_juice.shard_objective_path, NodePath("../ShardObjective"))
	assert_eq(gameplay_juice.camera_rig_path, NodePath("../ThirdPersonCameraRig"))
	assert_eq(gameplay_juice.health_hud_path, NodePath("../HealthHud"))
	assert_false(projectile_system.automatic_spawning_enabled)
	assert_eq(projectile_system.placement_service_path, NodePath("../DangerPlacementService"))
	assert_eq(chaser_enemy_system.placement_service_path, NodePath("../DangerPlacementService"))
	assert_eq(arena_hazard_system.placement_service_path, NodePath("../DangerPlacementService"))
	assert_eq(danger_placement_service.arena_path, NodePath("../Arena"))
	assert_eq(danger_placement_service.player_path, NodePath("../Player"))
	assert_eq(danger_placement_service.exit_gate_path, NodePath("../ExitGate"))
	assert_not_null(danger_director.default_danger_definition)
	assert_not_null(danger_director.director_config)
	assert_true(danger_director.director_config.is_valid_config())
	assert_eq(danger_director.director_config.max_readability_pressure, 5)
	assert_eq(danger_director.director_config.exit_max_readability_pressure, 3)
	assert_eq(danger_director.director_config.peak_max_readability_pressure, 7)
	assert_eq(danger_director.danger_executor_paths.size(), 3)
	assert_eq(danger_director.danger_definitions.size(), 4)
	assert_not_null(stage_controller.stage_sequence_config)
	assert_eq(
		stage_controller.stage_sequence_config.resource_path,
		"res://src/data/stages/default_stage_sequence.tres"
	)
	assert_eq(stage_controller.shard_objective_path, NodePath("../ShardObjective"))
	assert_not_null(stage_controller.stage_sequence_config.shard_objective_config)
	assert_eq(
		stage_controller.stage_sequence_config.shard_objective_config.resource_path,
		"res://src/data/objectives/default_shard_objective_config.tres"
	)
	assert_eq(shard_objective.run_controller_path, NodePath("../RunController"))
	assert_eq(shard_objective.arena_path, NodePath("../Arena"))
	assert_eq(shard_objective.player_path, NodePath("../Player"))
	assert_not_null(shard_objective.objective_config)
	assert_eq(
		shard_objective.objective_config.resource_path,
		"res://src/data/objectives/default_shard_objective_config.tres"
	)
	assert_not_null(shard_objective.shard_scene)
	assert_eq(
		shard_objective.shard_scene.resource_path,
		"res://src/visual/assets/shard_arcade_wrapper.tscn"
	)
	assert_not_null(exit_gate.gate_scene)
	assert_eq(
		exit_gate.gate_scene.resource_path, "res://src/visual/assets/exit_gate_arcade_wrapper.tscn"
	)
	assert_true(exit_gate.is_using_gate_scene_visual())
	assert_eq(
		danger_director.default_danger_definition.resource_path,
		"res://src/data/dangers/basic_projectile_danger.tres"
	)
	assert_not_null(danger_director.default_danger_definition.placement_rules)
	assert_eq(
		danger_director.default_danger_definition.placement_rules.resource_path,
		"res://src/data/dangers/basic_projectile_placement.tres"
	)
	assert_almost_eq(
		danger_director.default_danger_definition.placement_rules.min_distance_from_player_meters,
		10.0,
		0.001
	)
	assert_eq(
		danger_director.danger_definitions[0].resource_path,
		"res://src/data/dangers/explosive_chaser_danger.tres"
	)
	assert_eq(
		danger_director.danger_definitions[0].placement_rules.resource_path,
		"res://src/data/dangers/basic_chaser_placement.tres"
	)
	assert_almost_eq(
		danger_director.danger_definitions[0].placement_rules.min_distance_from_player_meters,
		11.0,
		0.001
	)
	assert_eq(
		danger_director.danger_definitions[1].resource_path,
		"res://src/data/dangers/basic_lava_hazard_danger.tres"
	)
	assert_eq(
		danger_director.danger_definitions[1].placement_rules.resource_path,
		"res://src/data/dangers/basic_hazard_placement.tres"
	)
	assert_eq(
		danger_director.danger_definitions[2].resource_path,
		"res://src/data/dangers/basic_ice_hazard_danger.tres"
	)
	assert_eq(
		danger_director.danger_definitions[2].placement_rules.resource_path,
		"res://src/data/dangers/basic_hazard_placement.tres"
	)
	assert_eq(
		danger_director.danger_definitions[3].resource_path,
		"res://src/data/dangers/basic_collapse_hazard_danger.tres"
	)
	assert_eq(
		danger_director.danger_definitions[3].placement_rules.resource_path,
		"res://src/data/dangers/basic_hazard_placement.tres"
	)
	assert_almost_eq(
		danger_director.danger_definitions[3].placement_rules.center_safe_radius_meters, 6.0, 0.001
	)
	assert_eq(
		projectile_system.launcher_config.resource_path,
		"res://src/data/projectiles/basic_single_shot_launcher.tres"
	)
	assert_eq(
		projectile_system.launcher_config.launcher_scene.resource_path,
		"res://src/visual/assets/launcher_arcade_wrapper.tscn"
	)
	assert_not_null(projectile_system.launcher_config.telegraph_visual_config)
	assert_eq(
		projectile_system.launcher_config.telegraph_visual_config.resource_path,
		"res://src/visual/vfx/default_projectile_telegraph.tres"
	)
	assert_eq(
		projectile_system.launcher_config.projectile_config.resource_path,
		"res://src/data/projectiles/basic_linear_projectile.tres"
	)
	assert_eq(
		projectile_system.launcher_config.projectile_config.visual_scene.resource_path,
		"res://src/visual/assets/projectile_arcade_wrapper.tscn"
	)
	var projectile_wrapper := (
		projectile_system.launcher_config.projectile_config.visual_scene.instantiate()
	)
	var projectile_visual_root := projectile_wrapper.get_node_or_null("VisualRoot") as Node3D
	assert_not_null(projectile_visual_root)
	assert_not_null(projectile_wrapper.get_node_or_null("VisualRoot/Asset") as Node3D)
	assert_true(
		ResourceLoader.exists(
			"res://assets/art/exports_godot/asset_kenney_projectile_cannon_ball.glb"
		)
	)
	assert_almost_eq(
		projectile_visual_root.scale.x,
		projectile_system.launcher_config.projectile_config.visual_radius_meters,
		0.001
	)
	assert_almost_eq(
		projectile_visual_root.scale.y,
		projectile_system.launcher_config.projectile_config.visual_radius_meters,
		0.001
	)
	assert_almost_eq(
		projectile_visual_root.scale.z,
		projectile_system.launcher_config.projectile_config.visual_radius_meters,
		0.001
	)
	projectile_wrapper.free()
	assert_eq(
		projectile_system.launcher_config.projectile_config.damage_profile.resource_path,
		"res://src/data/combat/basic_projectile_damage.tres"
	)
	assert_eq(
		chaser_enemy_system.chaser_config.resource_path,
		"res://src/data/enemies/basic_explosive_chaser.tres"
	)
	assert_eq(
		chaser_enemy_system.chaser_config.body_scene.resource_path,
		"res://src/visual/assets/chaser_arcade_wrapper.tscn"
	)
	assert_eq(
		chaser_enemy_system.chaser_config.damage_profile.resource_path,
		"res://src/data/combat/basic_chaser_explosion_damage.tres"
	)
	assert_eq(arena_hazard_system.arena_path, NodePath("../Arena"))
	assert_eq(arena_hazard_system.player_path, NodePath("../Player"))
	assert_eq(arena_hazard_system.health_component_path, NodePath("../Player/HealthComponent"))
	assert_not_null(arena_hazard_system.fall_damage_profile)
	assert_eq(
		arena_hazard_system.fall_damage_profile.resource_path,
		"res://src/data/combat/fall_out_of_arena_damage.tres"
	)
	assert_eq(
		health_component.health_config.resource_path,
		"res://src/data/combat/default_player_health.tres"
	)
	assert_eq(health_hud.player_path, NodePath("../Player"))
	assert_eq(health_hud.stage_controller_path, NodePath("../StageController"))
	assert_eq(health_hud.danger_director_path, NodePath("../DangerDirector"))
	assert_false(peak_label.visible)
	assert_eq(peak_label.text, "PEAK")
	assert_false(callout_label.visible)
	assert_eq(callout_label.text, "DODGE")
	assert_eq(health_panel.anchor_top, 1.0)
	assert_eq(health_panel.anchor_bottom, 1.0)
	assert_lt(health_panel.offset_top, 0.0)
	assert_gte(health_label.get_theme_font_size("font_size"), 24)
	assert_true(stage_label.text.begins_with("LEVEL"))
	assert_true(objective_label.text.begins_with("SHARDS"))
	assert_true(speed_label.text.begins_with("SPEED"))
	assert_true(jump_label.text.begins_with("JUMPS"))
	assert_eq(debug_label.anchor_left, 1.0)
	assert_eq(debug_label.anchor_right, 1.0)
	assert_lt(debug_label.offset_left, 0.0)
	assert_lt(debug_label.offset_right, 0.0)
	assert_eq(debug_label.horizontal_alignment, HORIZONTAL_ALIGNMENT_RIGHT)
	assert_eq(
		player.hurtbox_config.resource_path, "res://src/data/combat/default_player_hurtbox.tres"
	)
	assert_eq(
		damage_feedback.feedback_config.resource_path,
		"res://src/data/feedback/default_damage_feedback.tres"
	)
	assert_not_null(camera_arm)
	assert_gte(camera_rig.target_offset.y, 1.0)
	assert_gte(camera_rig.follow_lerp_speed, 250.0)
	assert_gte(camera_arm.spring_length, 8.0)
	assert_eq(player.collision_layer, 1)
	assert_true((player.collision_mask & 2) != 0)
	assert_false((camera_arm.collision_mask & 1) != 0)
	assert_true((camera_arm.collision_mask & 2) != 0)

	remove_child(instance)
	instance.free()


func test_arena_playground_scene_loads() -> void:
	var packed_scene := load(ARENA_PLAYGROUND_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	assert_not_null(instance.get_node_or_null("Arena") as ArenaController)
	assert_not_null(instance.get_node_or_null("Player") as PlayerController)
	assert_not_null(instance.get_node_or_null("ThirdPersonCameraRig") as ThirdPersonCameraRig)

	instance.free()


func test_projectile_playground_scene_loads() -> void:
	var packed_scene := load(PROJECTILE_PLAYGROUND_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	assert_not_null(instance.get_node_or_null("ProjectileSystem") as ProjectileSystem)
	assert_not_null(instance.get_node_or_null("Arena") as ArenaController)
	assert_not_null(instance.get_node_or_null("Player") as PlayerController)

	instance.free()


func test_chaser_enemy_playground_scene_loads() -> void:
	var packed_scene := load(CHASER_PLAYGROUND_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	assert_not_null(instance.get_node_or_null("ChaserEnemySystem") as ChaserEnemySystem)
	assert_not_null(instance.get_node_or_null("Arena") as ArenaController)
	assert_not_null(instance.get_node_or_null("Player") as PlayerController)

	instance.free()


func test_hazard_playground_scene_loads() -> void:
	var packed_scene := load(HAZARD_PLAYGROUND_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	assert_not_null(instance.get_node_or_null("ArenaHazardSystem") as ArenaHazardSystem)
	assert_not_null(instance.get_node_or_null("Arena") as ArenaController)
	assert_not_null(instance.get_node_or_null("Player") as PlayerController)

	instance.free()


func test_art_review_playground_scene_loads() -> void:
	var packed_scene := load(ART_REVIEW_PLAYGROUND_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	assert_not_null(instance.get_node_or_null("PlayerPreview") as Node3D)
	assert_not_null(instance.get_node_or_null("ChaserPreview") as Node3D)
	assert_not_null(instance.get_node_or_null("LauncherPreview") as Node3D)
	assert_not_null(instance.get_node_or_null("ProjectilePreview") as Node3D)
	assert_not_null(instance.get_node_or_null("ExitGatePreview") as Node3D)
	assert_not_null(instance.get_node_or_null("TelegraphPreview") as Node3D)

	instance.free()


func test_main_scene_spawns_danger_through_director() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var danger_director := instance.get_node("DangerDirector") as DangerDirector
	var stage := instance.get_node("StageController") as StageController

	danger_director.step_director_for_tests(1.1)

	assert_ne(danger_director.get_last_spawned_danger_id(), &"")
	assert_gt(danger_director.get_active_danger_count(), 0)
	assert_gt(stage.get_survived_threat_budget(), 0.0)
	assert_false(stage.is_exit_available())

	remove_child(instance)
	instance.free()


func test_stage_completion_reveals_exit_gate_and_transition_preserves_health() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var player := instance.get_node("Player") as PlayerController
	var health := instance.get_node("Player/HealthComponent") as HealthComponent
	var danger_director := instance.get_node("DangerDirector") as DangerDirector
	var stage := instance.get_node("StageController") as StageController
	var exit_gate := instance.get_node("ExitGate") as ExitGateController
	var damage := DamageProfile.new()
	damage.amount = 25.0

	health.apply_damage(damage, player.global_position)
	stage.force_complete_stage_for_tests()

	assert_eq(stage.get_stage_state(), StageController.StageState.EXIT_AVAILABLE)
	assert_true(exit_gate.is_gate_available())
	assert_true(danger_director.is_exit_pressure_enabled())
	assert_almost_eq(health.get_current_health(), 75.0, 0.001)

	player.global_position = exit_gate.global_position + Vector3.UP * 0.25
	for frame in range(20):
		exit_gate.step_gate_for_tests(0.05)
		if stage.get_level_index() == 2:
			break

	assert_eq(stage.get_level_index(), 2)
	assert_eq(stage.get_current_map_id(), &"kenney_clay_yard")
	assert_eq(stage.get_stage_state(), StageController.StageState.SURVIVING)
	assert_false(exit_gate.is_gate_available())
	assert_false(danger_director.is_exit_pressure_enabled())
	assert_eq(stage.get_collected_shards(), 0)
	assert_eq(stage.get_required_shards(), 3)
	assert_almost_eq(health.get_current_health(), 75.0, 0.001)

	remove_child(instance)
	instance.free()


func test_collecting_main_scene_shards_reveals_exit_gate() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var stage := instance.get_node("StageController") as StageController
	var objective := instance.get_node("ShardObjective") as ShardObjectiveController
	var exit_gate := instance.get_node("ExitGate") as ExitGateController
	var danger_director := instance.get_node("DangerDirector") as DangerDirector

	assert_true(objective.has_active_shard())
	assert_eq(stage.get_required_shards(), 3)

	for shard_index in range(stage.get_required_shards()):
		objective.force_collect_current_shard_for_tests()
		if not stage.is_exit_available():
			objective.step_objective_for_tests(
				objective.objective_config.spawn_delay_after_collect_seconds + 0.05
			)

	assert_eq(stage.get_collected_shards(), stage.get_required_shards())
	assert_eq(stage.get_stage_state(), StageController.StageState.EXIT_AVAILABLE)
	assert_true(exit_gate.is_gate_available())
	assert_true(danger_director.is_exit_pressure_enabled())
	assert_false(objective.has_active_shard())

	remove_child(instance)
	instance.free()


func test_player_applies_movement_config_to_character_body_settings() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().process_frame

	var player := instance.get_node("Player") as PlayerController
	var config := player.movement_config

	assert_almost_eq(player.floor_snap_length, config.floor_snap_length_meters, 0.001)
	assert_almost_eq(player.safe_margin, config.safe_margin_meters, 0.001)
	assert_eq(player.floor_constant_speed, config.floor_constant_speed_enabled)
	assert_true(player.floor_stop_on_slope)
	assert_eq(player.max_slides, config.max_slide_count)

	remove_child(instance)
	instance.free()


func test_forced_projectile_hit_updates_health_without_immediate_death() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var run_controller := instance.get_node("RunController") as RunController
	var player := instance.get_node("Player") as PlayerController
	var health := instance.get_node("Player/HealthComponent") as HealthComponent
	var health_hud := instance.get_node("HealthHud") as HealthHud
	var camera_rig := instance.get_node("ThirdPersonCameraRig") as ThirdPersonCameraRig
	var damage_feedback := instance.get_node("DamageFeedbackController") as DamageFeedbackController
	var projectile_system := instance.get_node("ProjectileSystem") as ProjectileSystem
	var run_feedback_overlay := instance.get_node("RunFeedbackOverlay") as RunFeedbackOverlay

	var projectile_position := player.global_position + Vector3.UP * 0.7
	assert_true(projectile_system.force_spawn_projectile(projectile_position, Vector3.RIGHT))

	projectile_system.step_system_for_tests(0.0)
	camera_rig.step_camera_shake_for_tests(0.016)

	assert_eq(run_controller.get_state(), RunController.RunState.PLAYING)
	assert_eq(run_controller.get_last_death_reason(), &"")
	assert_almost_eq(health.get_current_health(), 75.0, 0.001)
	assert_true(health_hud.get_health_text().contains("75"))
	assert_true(health_hud.is_flashing())
	assert_true(camera_rig.is_shaking())
	assert_eq(damage_feedback.get_last_feedback_damage_type_name(), "PROJECTILE")
	assert_gt(damage_feedback.get_last_feedback_strength(), 0.0)
	assert_eq(projectile_system.get_active_projectile_count(), 0)
	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_false(run_feedback_overlay.visible)

	remove_child(instance)
	instance.free()


func test_health_depletion_triggers_run_death_and_restart_resets_health() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var run_controller := instance.get_node("RunController") as RunController
	var player := instance.get_node("Player") as PlayerController
	var health := instance.get_node("Player/HealthComponent") as HealthComponent
	var projectile_system := instance.get_node("ProjectileSystem") as ProjectileSystem
	var run_feedback_overlay := instance.get_node("RunFeedbackOverlay") as RunFeedbackOverlay

	var lethal_profile := (
		projectile_system.launcher_config.projectile_config.damage_profile.duplicate()
		as DamageProfile
	)
	lethal_profile.amount = 100.0
	projectile_system.launcher_config.projectile_config.damage_profile = lethal_profile
	var projectile_position := player.global_position + Vector3.UP * 0.7
	assert_true(projectile_system.force_spawn_projectile(projectile_position, Vector3.RIGHT))

	projectile_system.step_system_for_tests(0.0)

	assert_eq(run_controller.get_state(), RunController.RunState.DEAD)
	assert_eq(run_controller.get_last_death_reason(), &"projectile")
	assert_eq(projectile_system.get_active_projectile_count(), 0)
	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_true(run_feedback_overlay.visible)
	assert_true(run_feedback_overlay.get_message_text().contains("projectile"))

	run_controller.restart_run()

	assert_eq(run_controller.get_state(), RunController.RunState.PLAYING)
	assert_almost_eq(health.get_current_health(), health.get_max_health(), 0.001)
	assert_eq(projectile_system.get_active_projectile_count(), 0)
	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_false(run_feedback_overlay.visible)

	remove_child(instance)
	instance.free()


func test_falling_outside_arena_triggers_run_death() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var run_controller := instance.get_node("RunController") as RunController
	var arena := instance.get_node("Arena") as ArenaController
	var player := instance.get_node("Player") as PlayerController
	var health := instance.get_node("Player/HealthComponent") as HealthComponent
	var arena_hazard_system := instance.get_node("ArenaHazardSystem") as ArenaHazardSystem
	var run_feedback_overlay := instance.get_node("RunFeedbackOverlay") as RunFeedbackOverlay
	var outside_position := Vector3(arena.arena_config.radius_meters + 12.0, 0.0, 0.0)
	var surface_height := arena.get_surface_height_at_position(outside_position)

	player.global_position = Vector3(outside_position.x, surface_height - 6.1, outside_position.z)
	arena_hazard_system.step_system_for_tests(0.0)

	assert_eq(run_controller.get_state(), RunController.RunState.DEAD)
	assert_eq(run_controller.get_last_death_reason(), &"fell_out_of_arena")
	assert_false(health.is_alive())
	assert_true(run_feedback_overlay.visible)
	assert_true(run_feedback_overlay.get_message_text().contains("fell_out_of_arena"))

	remove_child(instance)
	instance.free()


func test_arena_collision_shapes_are_walk_surfaces_without_internal_walls() -> void:
	var arena := ArenaController.new()
	add_child(arena)
	await get_tree().physics_frame

	var first_cell_shape := _get_collision_shape(arena, "GeneratedArena/Cell00/Collision")
	assert_not_null(first_cell_shape)
	assert_true(first_cell_shape.backface_collision)
	_assert_shape_faces_are_subtle_walk_surfaces(first_cell_shape, arena.arena_config)

	remove_child(arena)
	arena.free()


func test_player_lands_on_generated_arena() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)

	for frame in range(90):
		await get_tree().physics_frame

	var player := instance.get_node("Player") as PlayerController
	assert_true(player.is_grounded())
	assert_gt(player.global_position.y, 0.5)

	remove_child(instance)
	instance.free()


func _get_collision_shape(root: Node, path: NodePath) -> ConcavePolygonShape3D:
	var collision_shape := root.get_node_or_null(path) as CollisionShape3D
	if collision_shape == null:
		return null
	return collision_shape.shape as ConcavePolygonShape3D


func _assert_shape_faces_are_subtle_walk_surfaces(
	shape: ConcavePolygonShape3D, arena_config: ArenaConfig
) -> void:
	var has_height_variation := false
	for vertex: Vector3 in shape.get_faces():
		assert_lte(absf(vertex.y), arena_config.surface_height_amplitude_meters + 0.001)
		if absf(vertex.y) > 0.001:
			has_height_variation = true

	assert_true(has_height_variation)
