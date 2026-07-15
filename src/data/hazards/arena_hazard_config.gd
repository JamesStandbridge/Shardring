class_name ArenaHazardConfig
extends Resource

enum HazardType {
	LAVA,
	ICE,
	COLLAPSE,
}

@export var hazard_type: HazardType = HazardType.LAVA
@export var affected_cell_count_min: int = 2
@export var affected_cell_count_max: int = 3
@export var warning_duration_seconds: float = 1.1
@export var active_duration_seconds: float = 5.0
@export var collapsing_duration_seconds: float = 0.6
@export var destroyed_duration_seconds: float = 8.0
@export var rebuilding_duration_seconds: float = 1.0
@export var min_distance_from_player_meters: float = 5.0
@export var center_safe_radius_meters: float = 4.5
@export var lava_damage_tick_seconds: float = 0.45
@export var lava_damage_profile: DamageProfile = DamageProfile.new()
@export var destroyed_damage_profile: DamageProfile = DamageProfile.new()
@export var ice_speed_multiplier: float = 1.05
@export var ice_acceleration_multiplier: float = 0.45
@export var ice_deceleration_multiplier: float = 0.16
@export var ice_turn_acceleration_multiplier: float = 0.3


func _init() -> void:
	lava_damage_profile.amount = 12.0
	lava_damage_profile.damage_type = DamageProfile.DamageType.TERRAIN
	lava_damage_profile.death_reason = &"terrain_lava"
	lava_damage_profile.hit_label = &"Lava"
	destroyed_damage_profile.amount = 999.0
	destroyed_damage_profile.damage_type = DamageProfile.DamageType.TERRAIN
	destroyed_damage_profile.death_reason = &"terrain_destroyed"
	destroyed_damage_profile.hit_label = &"Destroyed Terrain"
	destroyed_damage_profile.ignores_invulnerability = true


func is_valid_config() -> bool:
	return (
		affected_cell_count_min > 0
		and affected_cell_count_max >= affected_cell_count_min
		and warning_duration_seconds > 0.0
		and active_duration_seconds > 0.0
		and collapsing_duration_seconds > 0.0
		and destroyed_duration_seconds > 0.0
		and rebuilding_duration_seconds > 0.0
		and min_distance_from_player_meters >= 0.0
		and center_safe_radius_meters >= 0.0
		and lava_damage_tick_seconds > 0.0
		and lava_damage_profile != null
		and lava_damage_profile.is_valid_profile()
		and destroyed_damage_profile != null
		and destroyed_damage_profile.is_valid_profile()
		and ice_speed_multiplier > 0.0
		and ice_acceleration_multiplier >= 0.0
		and ice_deceleration_multiplier >= 0.0
		and ice_turn_acceleration_multiplier >= 0.0
	)


func get_hazard_type_name() -> String:
	return HazardType.keys()[hazard_type]
