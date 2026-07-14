class_name PlayerMovementConfig
extends Resource

@export var run_speed_meters_per_second: float = 10.4
@export var ground_acceleration_meters_per_second_squared: float = 68.0
@export var ground_deceleration_meters_per_second_squared: float = 86.0
@export var ground_turn_acceleration_meters_per_second_squared: float = 126.0
@export var air_acceleration_meters_per_second_squared: float = 36.0
@export var air_deceleration_meters_per_second_squared: float = 10.0
@export var air_control_ratio: float = 0.68
@export var apex_air_acceleration_multiplier: float = 1.22
@export var rotation_lerp_speed: float = 20.0
@export var jump_velocity_meters_per_second: float = 7.65
@export var jump_takeoff_horizontal_boost_meters_per_second: float = 1.25
@export var jump_takeoff_max_speed_multiplier: float = 1.08
@export var gravity_multiplier: float = 1.65
@export var fall_gravity_multiplier: float = 2.45
@export var jump_apex_gravity_multiplier: float = 0.78
@export var jump_apex_velocity_threshold_meters_per_second: float = 0.55
@export var jump_cut_velocity_multiplier: float = 0.32
@export var jump_cut_min_velocity_meters_per_second: float = 1.35
@export var coyote_time_seconds: float = 0.11
@export var jump_buffer_seconds: float = 0.12
@export var max_fall_speed_meters_per_second: float = 34.0
@export var floor_snap_length_meters: float = 0.34
@export var safe_margin_meters: float = 0.035
@export var floor_constant_speed_enabled: bool = true
@export var max_slide_count: int = 8
@export var max_jump_count: int = 1
@export var quick_slide_speed_multiplier: float = 1.6
@export var quick_slide_duration_seconds: float = 0.28
