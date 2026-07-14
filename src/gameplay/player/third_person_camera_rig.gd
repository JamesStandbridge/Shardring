class_name ThirdPersonCameraRig
extends Node3D

@export var target_path: NodePath
@export var mouse_sensitivity: float = 0.0025
@export var follow_lerp_speed: float = 18.0
@export var min_pitch_degrees: float = -70.0
@export var max_pitch_degrees: float = -8.0
@export var initial_pitch_degrees: float = -22.0

var _yaw_radians: float = 0.0
var _pitch_radians: float = 0.0


func _ready() -> void:
	_pitch_radians = deg_to_rad(initial_pitch_degrees)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_rotation()


func _process(delta: float) -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		return

	var interpolation_weight := clampf(follow_lerp_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target.global_position, interpolation_weight)


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
	return $SpringArm3D/Camera3D as Camera3D


func _apply_rotation() -> void:
	rotation = Vector3(_pitch_radians, _yaw_radians, 0.0)
