class_name ThirdPersonCameraRig
extends Node3D

@export var target_path: NodePath
@export var mouse_sensitivity: float = 0.0025
@export var follow_lerp_speed: float = 18.0
@export var min_pitch_degrees: float = -70.0
@export var max_pitch_degrees: float = -8.0
@export var initial_pitch_degrees: float = -22.0
@export var target_offset: Vector3 = Vector3(0.0, 1.35, 0.0)

var _yaw_radians: float = 0.0
var _pitch_radians: float = 0.0
var _camera: Camera3D
var _shake_target: Node3D
var _base_shake_target_local_position := Vector3.ZERO
var _base_shake_target_local_rotation := Vector3.ZERO
var _shake_timer_seconds: float = 0.0
var _shake_duration_seconds: float = 0.0
var _shake_amplitude_meters: float = 0.0
var _shake_angular_amplitude_radians: float = 0.0
var _shake_frequency_hz: float = 0.0
var _shake_decay_power: float = 1.0
var _shake_vertical_axis_ratio: float = 0.65
var _shake_sequence: int = 0
var _current_shake_offset := Vector3.ZERO
var _current_shake_rotation := Vector3.ZERO


func _ready() -> void:
	_pitch_radians = deg_to_rad(initial_pitch_degrees)
	_camera = get_node_or_null("SpringArm3D/CameraShakePivot/Camera3D") as Camera3D
	if _camera == null:
		_camera = get_node_or_null("SpringArm3D/Camera3D") as Camera3D
	_shake_target = _camera
	if _shake_target != null:
		_base_shake_target_local_position = _shake_target.position
		_base_shake_target_local_rotation = _shake_target.rotation
	_snap_to_target()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_rotation()


func _process(delta: float) -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target != null:
		var target_position := target.global_position + target_offset
		var interpolation_weight := clampf(follow_lerp_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(target_position, interpolation_weight)

	_update_camera_shake(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		_yaw_radians -= mouse_motion.relative.x * mouse_sensitivity
		_pitch_radians -= mouse_motion.relative.y * mouse_sensitivity
		_pitch_radians = clampf(
			_pitch_radians, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees)
		)
		_apply_rotation()


func get_camera() -> Camera3D:
	if _camera != null:
		return _camera
	return get_node_or_null("SpringArm3D/CameraShakePivot/Camera3D") as Camera3D


func get_target_offset() -> Vector3:
	return target_offset


func request_shake(config: CameraShakeConfig, strength_multiplier: float = 1.0) -> void:
	if config == null or not config.is_valid_config():
		return

	var requested_amplitude := config.amplitude_meters * maxf(strength_multiplier, 0.0)
	var requested_angular_amplitude := (
		deg_to_rad(config.angular_amplitude_degrees) * maxf(strength_multiplier, 0.0)
	)
	if requested_amplitude <= 0.0 and requested_angular_amplitude <= 0.0:
		return

	_shake_sequence += 1
	_shake_duration_seconds = config.duration_seconds
	_shake_timer_seconds = maxf(_shake_timer_seconds, config.duration_seconds)
	_shake_amplitude_meters = maxf(_shake_amplitude_meters, requested_amplitude)
	_shake_angular_amplitude_radians = maxf(
		_shake_angular_amplitude_radians, requested_angular_amplitude
	)
	_shake_frequency_hz = config.frequency_hz
	_shake_decay_power = config.decay_power
	_shake_vertical_axis_ratio = config.vertical_axis_ratio


func step_camera_shake_for_tests(delta: float) -> void:
	_update_camera_shake(delta)


func is_shaking() -> bool:
	return _shake_timer_seconds > 0.0


func get_current_shake_intensity() -> float:
	return _current_shake_offset.length()


func get_current_shake_offset() -> Vector3:
	return _current_shake_offset


func get_current_shake_rotation() -> Vector3:
	return _current_shake_rotation


func _apply_rotation() -> void:
	rotation = Vector3(_pitch_radians, _yaw_radians, 0.0)


func _snap_to_target() -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		return

	global_position = target.global_position + target_offset


func _update_camera_shake(delta: float) -> void:
	if _shake_target == null:
		return

	if _shake_timer_seconds <= 0.0:
		_current_shake_offset = Vector3.ZERO
		_current_shake_rotation = Vector3.ZERO
		_shake_target.position = _base_shake_target_local_position
		_shake_target.rotation = _base_shake_target_local_rotation
		return

	_shake_timer_seconds = maxf(_shake_timer_seconds - delta, 0.0)
	var elapsed_seconds := _shake_duration_seconds - _shake_timer_seconds
	var progress := clampf(elapsed_seconds / maxf(_shake_duration_seconds, 0.001), 0.0, 1.0)
	var envelope := pow(1.0 - progress, _shake_decay_power)
	var phase := elapsed_seconds * _shake_frequency_hz * TAU
	var sequence_offset := float(_shake_sequence) * 1.618
	_current_shake_offset = (
		Vector3(
			sin(phase + sequence_offset),
			sin(phase * 1.37 + sequence_offset * 0.73) * _shake_vertical_axis_ratio,
			0.0
		)
		* _shake_amplitude_meters
		* envelope
	)
	_current_shake_rotation = (
		Vector3(
			sin(phase * 1.11 + sequence_offset * 0.41) * 0.35,
			sin(phase * 1.29 + sequence_offset * 0.67) * 0.24,
			sin(phase * 0.93 + sequence_offset)
		)
		* _shake_angular_amplitude_radians
		* envelope
	)
	_shake_target.position = _base_shake_target_local_position + _current_shake_offset
	_shake_target.rotation = _base_shake_target_local_rotation + _current_shake_rotation

	if _shake_timer_seconds <= 0.0:
		_shake_amplitude_meters = 0.0
		_shake_angular_amplitude_radians = 0.0
		_current_shake_offset = Vector3.ZERO
		_current_shake_rotation = Vector3.ZERO
		_shake_target.position = _base_shake_target_local_position
		_shake_target.rotation = _base_shake_target_local_rotation
