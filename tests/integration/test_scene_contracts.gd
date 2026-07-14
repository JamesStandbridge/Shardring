extends GutTest

const MAIN_SCENE_PATH := "res://src/main/main.tscn"
const ARENA_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/arena_playground.tscn"
const PROJECTILE_PLAYGROUND_SCENE_PATH := "res://src/dev/playgrounds/projectile_playground.tscn"


func test_main_scene_contains_arena_and_player_collision_contract() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()

	var arena := instance.get_node_or_null("Arena") as ArenaController
	var player := instance.get_node_or_null("Player") as PlayerController
	var projectile_system := instance.get_node_or_null("ProjectileSystem") as ProjectileSystem
	var camera_arm := instance.get_node_or_null("ThirdPersonCameraRig/SpringArm3D") as SpringArm3D
	var run_feedback_overlay := (
		instance.get_node_or_null("RunFeedbackOverlay") as RunFeedbackOverlay
	)

	assert_not_null(arena)
	assert_not_null(player)
	assert_not_null(projectile_system)
	assert_not_null(run_feedback_overlay)
	assert_not_null(projectile_system.launcher_config)
	assert_not_null(projectile_system.launcher_config.projectile_config)
	assert_eq(
		projectile_system.launcher_config.resource_path,
		"res://src/data/projectiles/basic_single_shot_launcher.tres"
	)
	assert_eq(
		projectile_system.launcher_config.projectile_config.resource_path,
		"res://src/data/projectiles/basic_linear_projectile.tres"
	)
	assert_not_null(camera_arm)
	assert_eq(player.collision_layer, 1)
	assert_true((player.collision_mask & 2) != 0)
	assert_false((camera_arm.collision_mask & 1) != 0)
	assert_true((camera_arm.collision_mask & 2) != 0)

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


func test_forced_projectile_hit_kills_player_and_restart_cleans_projectiles() -> void:
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	var instance := packed_scene.instantiate()
	add_child(instance)
	await get_tree().physics_frame

	var run_controller := instance.get_node("RunController") as RunController
	var player := instance.get_node("Player") as PlayerController
	var projectile_system := instance.get_node("ProjectileSystem") as ProjectileSystem
	var run_feedback_overlay := instance.get_node("RunFeedbackOverlay") as RunFeedbackOverlay

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
	assert_eq(projectile_system.get_active_projectile_count(), 0)
	assert_eq(projectile_system.get_active_launcher_count(), 0)
	assert_false(run_feedback_overlay.visible)

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
