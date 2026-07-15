class_name DangerPlacementRules
extends Resource

@export var spawn_search_attempts: int = 24
@export var min_distance_from_player_meters: float = 0.0
@export var center_safe_radius_meters: float = 0.0
@export var min_distance_from_exit_gate_meters: float = 0.0
@export var avoid_warning_cells: bool = true
@export var avoid_lava_cells: bool = true
@export var avoid_destroyed_cells: bool = true
@export var avoid_rebuilding_cells: bool = true


func is_valid_rules() -> bool:
	return (
		spawn_search_attempts > 0
		and min_distance_from_player_meters >= 0.0
		and center_safe_radius_meters >= 0.0
		and min_distance_from_exit_gate_meters >= 0.0
	)
