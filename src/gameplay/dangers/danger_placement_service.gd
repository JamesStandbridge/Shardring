class_name DangerPlacementService
extends Node

@export var arena_path: NodePath
@export var player_path: NodePath
@export var exit_gate_path: NodePath

var _arena: ArenaController
var _player: PlayerController
var _exit_gate: ExitGateController


func _ready() -> void:
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_exit_gate = get_node_or_null(exit_gate_path) as ExitGateController


func get_random_fair_position(rng: RandomNumberGenerator, rules: DangerPlacementRules) -> Vector3:
	if _arena == null:
		return Vector3.INF

	var effective_rules := _get_effective_rules(rules)
	for attempt in range(effective_rules.spawn_search_attempts):
		var candidate := _arena.get_random_valid_position(rng)
		if is_position_allowed(candidate, effective_rules):
			return candidate

	return Vector3.INF


func is_position_allowed(position: Vector3, rules: DangerPlacementRules) -> bool:
	var effective_rules := _get_effective_rules(rules)
	var is_allowed := effective_rules.is_valid_rules() and _arena != null
	is_allowed = is_allowed and not _is_too_close_to_center(position, effective_rules)
	is_allowed = is_allowed and not _is_too_close_to_player(position, effective_rules)
	is_allowed = is_allowed and not _is_too_close_to_exit_gate(position, effective_rules)
	is_allowed = is_allowed and not _is_on_forbidden_cell(position, effective_rules)
	return is_allowed


func _get_effective_rules(rules: DangerPlacementRules) -> DangerPlacementRules:
	if rules != null:
		return rules
	return DangerPlacementRules.new()


func _is_too_close_to_center(position: Vector3, rules: DangerPlacementRules) -> bool:
	if rules.center_safe_radius_meters <= 0.0:
		return false
	return Vector2(position.x, position.z).length() < rules.center_safe_radius_meters


func _is_too_close_to_player(position: Vector3, rules: DangerPlacementRules) -> bool:
	if _player == null or rules.min_distance_from_player_meters <= 0.0:
		return false
	return (
		_get_horizontal_distance(position, _player.global_position)
		< rules.min_distance_from_player_meters
	)


func _is_too_close_to_exit_gate(position: Vector3, rules: DangerPlacementRules) -> bool:
	if _exit_gate == null or rules.min_distance_from_exit_gate_meters <= 0.0:
		return false
	if not _exit_gate.is_gate_available():
		return false
	return (
		_get_horizontal_distance(position, _exit_gate.global_position)
		< rules.min_distance_from_exit_gate_meters
	)


func _is_on_forbidden_cell(position: Vector3, rules: DangerPlacementRules) -> bool:
	var cell := _arena.get_cell_at_position(position)
	if cell == null:
		return true

	var is_forbidden := false
	match cell.state:
		ArenaCell.ArenaCellState.WARNING:
			is_forbidden = rules.avoid_warning_cells
		ArenaCell.ArenaCellState.COLLAPSING:
			is_forbidden = rules.avoid_warning_cells
		ArenaCell.ArenaCellState.LAVA:
			is_forbidden = rules.avoid_lava_cells
		ArenaCell.ArenaCellState.DESTROYED:
			is_forbidden = rules.avoid_destroyed_cells
		ArenaCell.ArenaCellState.REBUILDING:
			is_forbidden = rules.avoid_rebuilding_cells
	return is_forbidden


func _get_horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x, first.z).distance_to(Vector2(second.x, second.z))
