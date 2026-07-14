class_name PlayerController
extends CharacterBody3D

@export var movement_config: PlayerMovementConfig = PlayerMovementConfig.new()
@export var hurtbox_config: PlayerHurtboxConfig = PlayerHurtboxConfig.new()
@export var camera_path: NodePath

var _movement_enabled: bool = true
var _spawn_transform: Transform3D
var _remaining_jumps: int = 1
var _coyote_timer_seconds: float = 0.0
var _jump_buffer_timer_seconds: float = 0.0
var _jump_cut_applied: bool = false


func _ready() -> void:
	_spawn_transform = global_transform
	_remaining_jumps = movement_config.max_jump_count
	_apply_character_body_settings()
	var debug_message := (
		"ready spawn=%s run_speed=%.2f jump_velocity=%.2f snap=%.2f"
		% [
			_spawn_transform.origin,
			movement_config.run_speed_meters_per_second,
			movement_config.jump_velocity_meters_per_second,
			movement_config.floor_snap_length_meters,
		]
	)
	DebugLog.info(&"Player", debug_message)


func _physics_process(delta: float) -> void:
	if not _movement_enabled:
		velocity = Vector3.ZERO
		return

	_update_jump_input(delta)
	_update_ground_contact(delta)
	_apply_horizontal_movement(delta)
	_apply_buffered_jump()
	_apply_variable_jump_cut()
	_apply_gravity(delta)
	move_and_slide()
	_update_ground_contact_after_move()


func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not _movement_enabled:
		velocity = Vector3.ZERO
	DebugLog.info(&"Player", "movement_enabled=%s" % enabled)


func set_spawn_transform(spawn_transform: Transform3D) -> void:
	_spawn_transform = spawn_transform


func reset_to_spawn() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_remaining_jumps = movement_config.max_jump_count
	_coyote_timer_seconds = 0.0
	_jump_buffer_timer_seconds = 0.0
	_jump_cut_applied = false
	DebugLog.info(&"Player", "reset_to_spawn position=%s" % global_position)


func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_vertical_speed() -> float:
	return velocity.y


func get_remaining_jumps() -> int:
	return _remaining_jumps


func is_movement_enabled() -> bool:
	return _movement_enabled


func is_grounded() -> bool:
	return is_on_floor()


func get_hurtbox_radius() -> float:
	return _get_hurtbox_config().radius_meters


func get_hurtbox_height() -> float:
	return _get_hurtbox_config().height_meters


func get_hurtbox_center() -> Vector3:
	return global_position + (global_basis * _get_hurtbox_config().center_offset)


func get_hurtbox_segment_start() -> Vector3:
	return (
		get_hurtbox_center() - Vector3.UP * _get_hurtbox_config().get_capsule_segment_half_length()
	)


func get_hurtbox_segment_end() -> Vector3:
	return (
		get_hurtbox_center() + Vector3.UP * _get_hurtbox_config().get_capsule_segment_half_length()
	)


func is_sphere_intersecting_hurtbox(sphere_position: Vector3, sphere_radius: float) -> bool:
	var hurtbox := _get_hurtbox_config()
	var hit_distance := maxf(sphere_radius, 0.0) + hurtbox.radius_meters
	var distance := _distance_point_to_hurtbox_segment(
		sphere_position, get_hurtbox_segment_start(), get_hurtbox_segment_end()
	)
	return distance <= hit_distance


func _update_jump_input(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer_seconds = movement_config.jump_buffer_seconds
		return

	_jump_buffer_timer_seconds = maxf(_jump_buffer_timer_seconds - delta, 0.0)


func _update_ground_contact(delta: float) -> void:
	if is_on_floor():
		_coyote_timer_seconds = movement_config.coyote_time_seconds
		_remaining_jumps = movement_config.max_jump_count
		if velocity.y < 0.0:
			velocity.y = 0.0
		return

	_coyote_timer_seconds = maxf(_coyote_timer_seconds - delta, 0.0)
	if is_zero_approx(_coyote_timer_seconds) and _remaining_jumps == movement_config.max_jump_count:
		_remaining_jumps = maxi(movement_config.max_jump_count - 1, 0)


func _update_ground_contact_after_move() -> void:
	if not is_on_floor():
		return

	_coyote_timer_seconds = movement_config.coyote_time_seconds
	_remaining_jumps = movement_config.max_jump_count
	if velocity.y < 0.0:
		velocity.y = 0.0


func _apply_horizontal_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var desired_direction := _get_camera_relative_direction(input_vector)
	var input_strength := clampf(input_vector.length(), 0.0, 1.0)
	var target_horizontal_velocity := (
		desired_direction * movement_config.run_speed_meters_per_second * input_strength
	)
	var current_horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var acceleration := _get_horizontal_acceleration(
		current_horizontal_velocity, target_horizontal_velocity, input_strength > 0.0
	)

	current_horizontal_velocity = current_horizontal_velocity.move_toward(
		target_horizontal_velocity, acceleration * delta
	)
	velocity.x = current_horizontal_velocity.x
	velocity.z = current_horizontal_velocity.z

	_rotate_toward_movement(current_horizontal_velocity, delta)


func _apply_character_body_settings() -> void:
	floor_snap_length = movement_config.floor_snap_length_meters
	safe_margin = movement_config.safe_margin_meters
	floor_constant_speed = movement_config.floor_constant_speed_enabled
	floor_stop_on_slope = true
	max_slides = movement_config.max_slide_count


func _get_horizontal_acceleration(
	current_horizontal_velocity: Vector3, target_horizontal_velocity: Vector3, has_input: bool
) -> float:
	if is_on_floor():
		if not has_input:
			return movement_config.ground_deceleration_meters_per_second_squared
		if _is_reversing_direction(current_horizontal_velocity, target_horizontal_velocity):
			return movement_config.ground_turn_acceleration_meters_per_second_squared
		return movement_config.ground_acceleration_meters_per_second_squared

	var acceleration: float
	if not has_input:
		acceleration = movement_config.air_deceleration_meters_per_second_squared
	else:
		acceleration = (
			movement_config.air_acceleration_meters_per_second_squared
			* movement_config.air_control_ratio
		)

	if _is_in_jump_apex_window():
		acceleration *= movement_config.apex_air_acceleration_multiplier
	return acceleration


func _is_reversing_direction(
	current_horizontal_velocity: Vector3, target_horizontal_velocity: Vector3
) -> bool:
	if current_horizontal_velocity.length_squared() < 0.25:
		return false
	if target_horizontal_velocity.length_squared() < 0.25:
		return false

	return (
		current_horizontal_velocity.normalized().dot(target_horizontal_velocity.normalized()) < 0.15
	)


func _apply_buffered_jump() -> void:
	if _jump_buffer_timer_seconds <= 0.0:
		return
	if not _can_jump():
		return

	velocity.y = movement_config.jump_velocity_meters_per_second
	_apply_jump_takeoff_boost()
	_remaining_jumps = maxi(_remaining_jumps - 1, 0)
	_coyote_timer_seconds = 0.0
	_jump_buffer_timer_seconds = 0.0
	_jump_cut_applied = false
	DebugLog.info(&"Player", "jump remaining=%d velocity_y=%.2f" % [_remaining_jumps, velocity.y])


func _can_jump() -> bool:
	if _remaining_jumps <= 0:
		return false
	if is_on_floor() or _coyote_timer_seconds > 0.0:
		return true

	return _remaining_jumps < movement_config.max_jump_count


func _apply_variable_jump_cut() -> void:
	if _jump_cut_applied:
		return
	if Input.is_action_pressed("jump"):
		return
	if velocity.y <= movement_config.jump_cut_min_velocity_meters_per_second:
		return

	velocity.y *= movement_config.jump_cut_velocity_multiplier
	_jump_cut_applied = true


func _apply_jump_takeoff_boost() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var desired_direction := _get_camera_relative_direction(input_vector)
	if desired_direction.is_zero_approx():
		return

	var current_horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	current_horizontal_velocity += (
		desired_direction * movement_config.jump_takeoff_horizontal_boost_meters_per_second
	)
	var max_takeoff_speed := (
		movement_config.run_speed_meters_per_second
		* movement_config.jump_takeoff_max_speed_multiplier
	)
	if current_horizontal_velocity.length() > max_takeoff_speed:
		current_horizontal_velocity = current_horizontal_velocity.normalized() * max_takeoff_speed

	velocity.x = current_horizontal_velocity.x
	velocity.z = current_horizontal_velocity.z


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y <= 0.0:
		return

	var default_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var gravity_multiplier := movement_config.gravity_multiplier
	if _is_in_jump_apex_window() and Input.is_action_pressed("jump"):
		gravity_multiplier *= movement_config.jump_apex_gravity_multiplier
	elif velocity.y < 0.0:
		gravity_multiplier *= movement_config.fall_gravity_multiplier

	velocity.y -= default_gravity * gravity_multiplier * delta
	velocity.y = maxf(velocity.y, -movement_config.max_fall_speed_meters_per_second)


func _is_in_jump_apex_window() -> bool:
	return (
		velocity.y > 0.0
		and velocity.y <= movement_config.jump_apex_velocity_threshold_meters_per_second
	)


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.is_zero_approx():
		return Vector3.ZERO

	var camera := get_node_or_null(camera_path) as Camera3D
	var reference_basis := Basis.IDENTITY
	if camera != null:
		reference_basis = camera.global_basis

	var forward := -reference_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := reference_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction := right * input_vector.x + forward * -input_vector.y
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction


func _rotate_toward_movement(horizontal_velocity: Vector3, delta: float) -> void:
	if horizontal_velocity.length_squared() < 0.04:
		return

	var direction := horizontal_velocity.normalized()
	var target_yaw := atan2(-direction.x, -direction.z)
	var interpolation_weight := clampf(movement_config.rotation_lerp_speed * delta, 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, target_yaw, interpolation_weight)


func _get_hurtbox_config() -> PlayerHurtboxConfig:
	if hurtbox_config != null and hurtbox_config.is_valid_config():
		return hurtbox_config
	return PlayerHurtboxConfig.new()


func _distance_point_to_hurtbox_segment(
	point: Vector3, segment_start: Vector3, segment_end: Vector3
) -> float:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_to(segment_start)

	var ratio := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest_point := segment_start + segment * ratio
	return point.distance_to(closest_point)
