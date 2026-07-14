class_name PlayerVisualAnimator
extends Node3D

@export var player_path: NodePath
@export var animation_config: PlayerAnimationConfig = PlayerAnimationConfig.new()

var _player: PlayerController
var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _base_scale := Vector3.ONE
var _stride_phase_radians: float = 0.0
var _was_grounded: bool = false
var _takeoff_timer_seconds: float = 0.0
var _landing_timer_seconds: float = 0.0


func _ready() -> void:
	_base_position = position
	_base_rotation = rotation
	_base_scale = scale
	_player = _resolve_player()
	if _player != null:
		_was_grounded = _player.is_grounded()


func _process(delta: float) -> void:
	_update_visual(delta)


func step_animation_for_tests(delta: float) -> void:
	_update_visual(delta)


func get_resolved_player() -> PlayerController:
	return _player


func get_base_rotation() -> Vector3:
	return _base_rotation


func _update_visual(delta: float) -> void:
	var config := _get_config()
	if _player == null:
		_player = _resolve_player()
	if _player == null:
		_return_to_base(delta, config)
		return

	var grounded := _player.is_grounded()
	var vertical_speed := _player.get_vertical_speed()
	_update_jump_timers(delta, grounded, vertical_speed)

	var speed := _player.get_horizontal_speed()
	var speed_ratio := clampf(speed / config.run_speed_reference_meters_per_second, 0.0, 1.25)
	var target_position := _base_position
	var target_rotation := _base_rotation
	var target_scale := _base_scale

	if grounded and speed > config.movement_speed_threshold_meters_per_second:
		var run_animation := _get_run_animation(delta, speed_ratio, config)
		target_position += run_animation["position"] as Vector3
		target_rotation += run_animation["rotation"] as Vector3
	elif grounded:
		target_position += _get_idle_position_offset(delta, config)
	else:
		var airborne_animation := _get_airborne_animation(vertical_speed, config)
		target_position += airborne_animation["position"] as Vector3
		target_rotation += airborne_animation["rotation"] as Vector3
		target_scale *= airborne_animation["scale"] as Vector3

	target_scale *= _get_jump_impulse_scale(config)
	_apply_targets(delta, target_position, target_rotation, target_scale, config)
	_was_grounded = grounded


func _update_jump_timers(delta: float, grounded: bool, vertical_speed: float) -> void:
	if _was_grounded and not grounded and vertical_speed > 0.1:
		_takeoff_timer_seconds = _get_config().takeoff_stretch_duration_seconds
	if not _was_grounded and grounded:
		_landing_timer_seconds = _get_config().landing_squash_duration_seconds

	_takeoff_timer_seconds = maxf(_takeoff_timer_seconds - delta, 0.0)
	_landing_timer_seconds = maxf(_landing_timer_seconds - delta, 0.0)


func _get_run_animation(
	delta: float, speed_ratio: float, config: PlayerAnimationConfig
) -> Dictionary:
	var frequency := lerpf(config.walk_bob_frequency_hz, config.run_bob_frequency_hz, speed_ratio)
	_stride_phase_radians = fposmod(_stride_phase_radians + delta * frequency * TAU, TAU)
	var step_wave := sin(_stride_phase_radians)
	var lift_wave := absf(step_wave)
	var position_offset := Vector3(
		step_wave * config.side_sway_meters * speed_ratio,
		lift_wave * config.run_bob_height_meters * speed_ratio,
		0.0
	)
	var rotation_offset := Vector3(
		(
			deg_to_rad(-config.forward_lean_degrees * speed_ratio)
			+ cos(_stride_phase_radians) * deg_to_rad(config.run_pitch_bounce_degrees) * speed_ratio
		),
		0.0,
		step_wave * deg_to_rad(config.run_roll_degrees) * speed_ratio
	)

	return {
		"position": position_offset,
		"rotation": rotation_offset,
	}


func _get_idle_position_offset(delta: float, config: PlayerAnimationConfig) -> Vector3:
	_stride_phase_radians = fposmod(
		_stride_phase_radians + delta * config.idle_bob_frequency_hz * TAU, TAU
	)
	return Vector3(0.0, sin(_stride_phase_radians) * config.idle_bob_height_meters, 0.0)


func _get_airborne_animation(vertical_speed: float, config: PlayerAnimationConfig) -> Dictionary:
	var vertical_ratio := clampf(
		vertical_speed / config.airborne_reference_speed_meters_per_second, -1.0, 1.0
	)
	var scale_multiplier := Vector3.ONE
	if vertical_ratio >= 0.0:
		scale_multiplier = _get_stretch_scale(vertical_ratio * config.jump_stretch_scale)
	else:
		scale_multiplier = _get_squash_scale(absf(vertical_ratio) * config.fall_squash_scale)

	return {
		"position": Vector3(0.0, config.airborne_float_offset_meters, 0.0),
		"rotation": Vector3(deg_to_rad(-config.airborne_pitch_degrees * vertical_ratio), 0.0, 0.0),
		"scale": scale_multiplier,
	}


func _get_jump_impulse_scale(config: PlayerAnimationConfig) -> Vector3:
	var scale_multiplier := Vector3.ONE
	if _takeoff_timer_seconds > 0.0:
		var takeoff_ratio := _takeoff_timer_seconds / config.takeoff_stretch_duration_seconds
		scale_multiplier *= _get_stretch_scale(config.takeoff_stretch_scale * takeoff_ratio)

	if _landing_timer_seconds > 0.0:
		var landing_ratio := _landing_timer_seconds / config.landing_squash_duration_seconds
		scale_multiplier *= _get_squash_scale(config.landing_squash_scale * landing_ratio)

	return scale_multiplier


func _get_stretch_scale(amount: float) -> Vector3:
	var clamped := clampf(amount, 0.0, 0.35)
	return Vector3(1.0 - clamped * 0.35, 1.0 + clamped, 1.0 - clamped * 0.35)


func _get_squash_scale(amount: float) -> Vector3:
	var clamped := clampf(amount, 0.0, 0.35)
	return Vector3(1.0 + clamped * 0.38, 1.0 - clamped, 1.0 + clamped * 0.38)


func _apply_targets(
	delta: float,
	target_position: Vector3,
	target_rotation: Vector3,
	target_scale: Vector3,
	config: PlayerAnimationConfig
) -> void:
	var weight := clampf(config.animation_lerp_speed * delta, 0.0, 1.0)
	position = position.lerp(target_position, weight)
	rotation = Vector3(
		lerp_angle(rotation.x, target_rotation.x, weight),
		lerp_angle(rotation.y, target_rotation.y, weight),
		lerp_angle(rotation.z, target_rotation.z, weight)
	)
	scale = scale.lerp(target_scale, weight)


func _return_to_base(delta: float, config: PlayerAnimationConfig) -> void:
	_apply_targets(delta, _base_position, _base_rotation, _base_scale, config)


func _resolve_player() -> PlayerController:
	if not player_path.is_empty():
		return get_node_or_null(player_path) as PlayerController
	return get_parent() as PlayerController


func _get_config() -> PlayerAnimationConfig:
	if animation_config != null and animation_config.is_valid_config():
		return animation_config
	return PlayerAnimationConfig.new()
