class_name PlayerAnimationConfig
extends Resource

@export var movement_speed_threshold_meters_per_second: float = 0.25
@export var run_speed_reference_meters_per_second: float = 10.4
@export var walk_bob_frequency_hz: float = 2.4
@export var run_bob_frequency_hz: float = 4.6
@export var idle_bob_frequency_hz: float = 0.75
@export var idle_bob_height_meters: float = 0.012
@export var run_bob_height_meters: float = 0.085
@export var side_sway_meters: float = 0.035
@export var forward_lean_degrees: float = 5.0
@export var run_roll_degrees: float = 5.5
@export var run_pitch_bounce_degrees: float = 2.2
@export var airborne_float_offset_meters: float = 0.04
@export var airborne_pitch_degrees: float = 8.0
@export var airborne_reference_speed_meters_per_second: float = 8.0
@export var jump_stretch_scale: float = 0.12
@export var fall_squash_scale: float = 0.08
@export var takeoff_stretch_scale: float = 0.18
@export var takeoff_stretch_duration_seconds: float = 0.12
@export var landing_squash_scale: float = 0.20
@export var landing_squash_duration_seconds: float = 0.16
@export var animation_lerp_speed: float = 18.0


func is_valid_config() -> bool:
	return (
		movement_speed_threshold_meters_per_second >= 0.0
		and run_speed_reference_meters_per_second > 0.0
		and walk_bob_frequency_hz > 0.0
		and run_bob_frequency_hz >= walk_bob_frequency_hz
		and idle_bob_frequency_hz > 0.0
		and idle_bob_height_meters >= 0.0
		and run_bob_height_meters >= 0.0
		and side_sway_meters >= 0.0
		and forward_lean_degrees >= 0.0
		and run_roll_degrees >= 0.0
		and run_pitch_bounce_degrees >= 0.0
		and airborne_float_offset_meters >= 0.0
		and airborne_pitch_degrees >= 0.0
		and airborne_reference_speed_meters_per_second > 0.0
		and jump_stretch_scale >= 0.0
		and fall_squash_scale >= 0.0
		and takeoff_stretch_scale >= 0.0
		and takeoff_stretch_duration_seconds > 0.0
		and landing_squash_scale >= 0.0
		and landing_squash_duration_seconds > 0.0
		and animation_lerp_speed > 0.0
	)
