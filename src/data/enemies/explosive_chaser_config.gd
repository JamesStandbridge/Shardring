class_name ExplosiveChaserConfig
extends Resource

@export var max_active_enemies: int = 24
@export var spawn_search_attempts: int = 18
@export var min_spawn_distance_from_player_meters: float = 11.0
@export var spawn_height_offset_meters: float = 0.95
@export var visual_radius_meters: float = 0.42
@export var body_scene: PackedScene
@export var collision_radius_meters: float = 0.36
@export var collision_height_meters: float = 1.05
@export var walk_speed_meters_per_second: float = 2.35
@export var chase_speed_meters_per_second: float = 4.6
@export var chase_acceleration_meters_per_second_squared: float = 18.0
@export var run_trigger_radius_meters: float = 7.0
@export var excitement_ramp_exponent: float = 0.65
@export var weave_strength_meters_per_second: float = 0.75
@export var weave_frequency_hz: float = 1.35
@export var face_player_lerp_speed: float = 22.0
@export var visual_yaw_offset_degrees: float = 0.0
@export var gravity_multiplier: float = 2.2
@export var max_fall_speed_meters_per_second: float = 24.0
@export var prime_trigger_radius_meters: float = 2.15
@export var prime_duration_seconds: float = 0.85
@export var priming_scale_multiplier: float = 1.35
@export var explosion_radius_meters: float = 3.2
@export var explosion_linger_seconds: float = 0.18
@export var lifetime_seconds: float = 18.0
@export var spawn_pop_duration_seconds: float = 0.22
@export var spawn_pop_height_meters: float = 0.22
@export var movement_bob_height_meters: float = 0.08
@export var movement_bob_frequency_walk_hz: float = 2.1
@export var movement_bob_frequency_run_hz: float = 5.2
@export var movement_roll_degrees: float = 7.5
@export var run_excitement_scale_multiplier: float = 1.12
@export var damage_on_explosion: bool = true
@export var damage_profile: DamageProfile = DamageProfile.new()
@export var death_reason: StringName = &"chaser_explosion"
@export var body_color: Color = Color(0.95, 0.27, 0.11, 1.0)
@export var priming_color: Color = Color(1.0, 0.62, 0.08, 1.0)
@export var explosion_color: Color = Color(1.0, 0.12, 0.04, 0.78)
@export var emission_energy: float = 1.35


func is_valid_config() -> bool:
	return (
		max_active_enemies > 0
		and spawn_search_attempts > 0
		and min_spawn_distance_from_player_meters >= 0.0
		and spawn_height_offset_meters >= 0.0
		and visual_radius_meters > 0.0
		and collision_radius_meters > 0.0
		and collision_radius_meters <= visual_radius_meters
		and collision_height_meters > 0.0
		and walk_speed_meters_per_second > 0.0
		and chase_speed_meters_per_second > 0.0
		and chase_speed_meters_per_second >= walk_speed_meters_per_second
		and chase_acceleration_meters_per_second_squared > 0.0
		and run_trigger_radius_meters >= prime_trigger_radius_meters
		and excitement_ramp_exponent > 0.0
		and weave_strength_meters_per_second >= 0.0
		and weave_frequency_hz >= 0.0
		and face_player_lerp_speed >= 0.0
		and gravity_multiplier >= 0.0
		and max_fall_speed_meters_per_second > 0.0
		and prime_trigger_radius_meters > 0.0
		and prime_duration_seconds > 0.0
		and priming_scale_multiplier >= 1.0
		and explosion_radius_meters > 0.0
		and explosion_linger_seconds > 0.0
		and lifetime_seconds > 0.0
		and spawn_pop_duration_seconds >= 0.0
		and spawn_pop_height_meters >= 0.0
		and movement_bob_height_meters >= 0.0
		and movement_bob_frequency_walk_hz > 0.0
		and movement_bob_frequency_run_hz >= movement_bob_frequency_walk_hz
		and movement_roll_degrees >= 0.0
		and run_excitement_scale_multiplier >= 1.0
		and damage_profile != null
		and damage_profile.is_valid_profile()
		and not death_reason.is_empty()
	)
