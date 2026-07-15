extends GutTest


func test_camera_rig_follows_target_with_vertical_offset() -> void:
	var root := Node3D.new()
	var target := Node3D.new()
	var camera_rig := ThirdPersonCameraRig.new()
	var spring_arm := SpringArm3D.new()
	var camera := Camera3D.new()

	target.name = "Target"
	camera_rig.name = "CameraRig"
	spring_arm.name = "SpringArm3D"
	camera.name = "Camera3D"

	target.position = Vector3(2.0, 1.0, -3.0)
	camera_rig.target_path = NodePath("../Target")
	camera_rig.target_offset = Vector3(0.0, 1.35, 0.0)
	camera_rig.follow_lerp_speed = 1000.0

	spring_arm.add_child(camera)
	camera_rig.add_child(spring_arm)
	root.add_child(target)
	root.add_child(camera_rig)
	add_child(root)
	await get_tree().process_frame

	_assert_vector3_almost_eq(
		camera_rig.global_position, target.global_position + camera_rig.target_offset, 0.001
	)

	target.position = Vector3(-4.0, 2.0, 6.0)
	camera_rig.step_follow_for_tests(0.1)

	_assert_vector3_almost_eq(
		camera_rig.global_position, target.global_position + camera_rig.target_offset, 0.001
	)

	remove_child(root)
	root.free()


func _assert_vector3_almost_eq(actual: Vector3, expected: Vector3, epsilon: float) -> void:
	assert_almost_eq(actual.x, expected.x, epsilon)
	assert_almost_eq(actual.y, expected.y, epsilon)
	assert_almost_eq(actual.z, expected.z, epsilon)
