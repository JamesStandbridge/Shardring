extends GutTest


func test_player_visual_animator_resolves_parent_player_and_keeps_base_rotation() -> void:
	var player := PlayerController.new()
	var animator := PlayerVisualAnimator.new()

	player.name = "Player"
	animator.name = "PlayerVisualAnimator"
	animator.rotation.y = PI

	player.add_child(animator)
	add_child(player)
	await get_tree().process_frame

	assert_same(animator.get_resolved_player(), player)
	assert_almost_eq(animator.get_base_rotation().y, PI, 0.001)

	remove_child(player)
	player.free()


func test_player_visual_animator_stretches_during_jump_motion() -> void:
	var player := PlayerController.new()
	var animator := PlayerVisualAnimator.new()
	var config := PlayerAnimationConfig.new()

	player.name = "Player"
	animator.name = "PlayerVisualAnimator"
	animator.animation_config = config
	player.add_child(animator)
	add_child(player)
	await get_tree().process_frame

	player.velocity.y = config.airborne_reference_speed_meters_per_second
	animator.step_animation_for_tests(0.1)

	assert_gt(animator.scale.y, 1.0)
	assert_lt(animator.scale.x, 1.0)

	remove_child(player)
	player.free()
