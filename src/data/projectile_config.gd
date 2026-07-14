class_name ProjectileConfig
extends Resource

enum MotionType {
	LINEAR,
	HOMING,
	WARNING_INSTANT,
}

@export var motion_type: MotionType = MotionType.LINEAR
@export var speed_meters_per_second: float = 9.5
@export var lifetime_seconds: float = 8.5
@export var warning_duration_seconds: float = 0.4
@export var explosion_radius_meters: float = 0.0
@export var collision_radius_meters: float = 0.34
@export var visual_radius_meters: float = 0.42
@export var visual_scene: PackedScene
@export var danger_color: Color = Color(1.0, 0.12, 0.08, 1.0)
@export var emission_energy: float = 2.2
@export var damage_profile: DamageProfile = DamageProfile.new()
@export var death_reason: StringName = &"projectile"
@export var damage_on_contact: bool = true
@export var trail_enabled: bool = true
@export var trail_length_meters: float = 1.1
@export var trail_width_meters: float = 0.14
@export var trail_color: Color = Color(1.0, 0.34, 0.08, 1.0)
@export var trail_emission_energy: float = 1.2
