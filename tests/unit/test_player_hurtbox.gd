extends GutTest


func test_player_hurtbox_config_defaults_are_valid_and_fair() -> void:
	var config := PlayerHurtboxConfig.new()
	var preset := load("res://src/data/combat/default_player_hurtbox.tres") as PlayerHurtboxConfig

	assert_true(config.is_valid_config())
	assert_not_null(preset)
	assert_true(preset.is_valid_config())
	assert_lt(preset.radius_meters, 0.38)
	assert_lt(preset.height_meters, 1.8)
	assert_gt(preset.height_meters, 1.5)


func test_player_hurtbox_matches_lower_body_without_punishing_near_misses() -> void:
	var player := PlayerController.new()
	add_child(player)
	await get_tree().process_frame
	player.global_position = Vector3(0.0, 1.05, 0.0)

	var projectile_radius := 0.34
	var lower_body_position := player.global_position + Vector3(0.0, -0.65, 0.0)
	var near_miss_position := (
		player.global_position
		+ Vector3(player.get_hurtbox_radius() + projectile_radius + 0.05, 0.0, 0.0)
	)

	assert_true(player.is_sphere_intersecting_hurtbox(lower_body_position, projectile_radius))
	assert_false(player.is_sphere_intersecting_hurtbox(near_miss_position, projectile_radius))

	remove_child(player)
	player.free()
