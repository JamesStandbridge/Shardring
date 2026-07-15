class_name ArenaHazardSystem
extends Node

enum HazardRuntimeState {
	WARNING,
	ACTIVE,
	COLLAPSING,
	DESTROYED,
	REBUILDING,
}


class ActiveHazard:
	var definition_id: StringName
	var config: ArenaHazardConfig
	var state: HazardRuntimeState
	var timer_seconds: float
	var lava_tick_timer_seconds: float
	var cell_indices: Array[int]


@export var run_controller_path: NodePath
@export var arena_path: NodePath
@export var player_path: NodePath
@export var health_component_path: NodePath
@export var placement_service_path: NodePath
@export var fall_damage_profile: DamageProfile
@export var fall_death_depth_meters: float = 6.0
@export var generation_seed: int = 9091

var _run_controller: RunController
var _arena: ArenaController
var _player: PlayerController
var _health_component: HealthComponent
var _placement_service: DangerPlacementService
var _rng := RandomNumberGenerator.new()
var _active_hazards: Array[ActiveHazard] = []
var _skipped_spawn_count: int = 0
var _last_spawned_hazard_type: StringName = &""


func _ready() -> void:
	_rng.seed = generation_seed
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_health_component = get_node_or_null(health_component_path) as HealthComponent
	_placement_service = get_node_or_null(placement_service_path) as DangerPlacementService
	_connect_run_controller()
	DebugLog.info(&"ArenaHazards", "ready seed=%d" % generation_seed)


func _physics_process(delta: float) -> void:
	step_system_for_tests(delta)


func step_system_for_tests(delta: float) -> void:
	if _run_controller != null and not _run_controller.is_playing():
		return

	_update_hazards(delta)
	_apply_player_surface_effects()
	_apply_player_damage(delta)


func supports_danger_family(family: DangerDefinition.DangerFamily) -> bool:
	return family == DangerDefinition.DangerFamily.TERRAIN_HAZARD


func request_spawn_danger(definition: DangerDefinition) -> bool:
	if definition == null or not definition.is_valid_definition():
		_increment_skipped_spawn()
		return false

	var config := definition.specialized_config as ArenaHazardConfig
	if config == null or not config.is_valid_config():
		_increment_skipped_spawn()
		return false

	return _spawn_hazard(definition.danger_id, config, definition.placement_rules)


func get_active_danger_count(definition: DangerDefinition) -> int:
	if definition == null:
		return 0

	var count := 0
	for hazard: ActiveHazard in _active_hazards:
		if hazard.definition_id == definition.danger_id:
			count += 1
	return count


func get_total_active_danger_count() -> int:
	return _active_hazards.size()


func get_active_readability_pressure() -> int:
	return get_warning_cell_count() + _get_collapsing_cell_count()


func get_active_hazard_count() -> int:
	return _active_hazards.size()


func get_skipped_spawn_count() -> int:
	return _skipped_spawn_count


func get_last_spawned_hazard_type_name() -> String:
	return str(_last_spawned_hazard_type)


func get_warning_cell_count() -> int:
	return _get_cell_count(ArenaCell.ArenaCellState.WARNING)


func get_lava_cell_count() -> int:
	return _get_cell_count(ArenaCell.ArenaCellState.LAVA)


func get_ice_cell_count() -> int:
	return _get_cell_count(ArenaCell.ArenaCellState.ICE)


func get_destroyed_cell_count() -> int:
	return _get_cell_count(ArenaCell.ArenaCellState.DESTROYED)


func get_cell_state_under_player_name() -> String:
	if _arena == null or _player == null:
		return "UNKNOWN"
	return _arena.get_cell_state_name_at_position(_player.global_position)


func clear_all() -> void:
	_active_hazards.clear()
	if _arena != null:
		_arena.reset_all_cell_states()
	if _player != null:
		_player.clear_surface_movement_modifier()


func force_spawn_hazard_for_tests(config: ArenaHazardConfig) -> bool:
	return _spawn_hazard(&"test_hazard", config)


func force_spawn_hazard_on_cells_for_tests(
	config: ArenaHazardConfig, cell_indices: Array[int]
) -> bool:
	if config == null or not config.is_valid_config() or cell_indices.is_empty():
		return false

	_register_hazard(&"test_hazard", config, cell_indices)
	return true


func _connect_run_controller() -> void:
	if _run_controller == null:
		if not run_controller_path.is_empty():
			DebugLog.warn(&"ArenaHazards", "missing run controller path")
		return

	_run_controller.run_started.connect(_on_run_started)
	_run_controller.run_restarted.connect(_on_run_restarted)
	_run_controller.run_died.connect(_on_run_died)


func _on_run_started() -> void:
	clear_all()


func _on_run_restarted() -> void:
	clear_all()


func _on_run_died(_reason: StringName) -> void:
	clear_all()


func _spawn_hazard(
	definition_id: StringName,
	config: ArenaHazardConfig,
	placement_rules: DangerPlacementRules = null
) -> bool:
	if _arena == null:
		_increment_skipped_spawn()
		return false

	var cell_indices := _select_hazard_cells(config, placement_rules)
	if cell_indices.is_empty():
		_increment_skipped_spawn()
		return false

	_register_hazard(definition_id, config, cell_indices)
	return true


func _register_hazard(
	definition_id: StringName, config: ArenaHazardConfig, cell_indices: Array[int]
) -> void:
	var hazard := ActiveHazard.new()
	hazard.definition_id = definition_id
	hazard.config = config
	hazard.state = HazardRuntimeState.WARNING
	hazard.timer_seconds = config.warning_duration_seconds
	hazard.lava_tick_timer_seconds = 0.0
	hazard.cell_indices = cell_indices.duplicate()
	_active_hazards.append(hazard)
	_last_spawned_hazard_type = StringName(config.get_hazard_type_name())
	_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.WARNING)
	DebugLog.info(
		&"ArenaHazards", "spawned type=%s cells=%s" % [config.get_hazard_type_name(), cell_indices]
	)


func _select_hazard_cells(
	config: ArenaHazardConfig, placement_rules: DangerPlacementRules = null
) -> Array[int]:
	var candidates := _collect_candidate_cells(config, placement_rules)
	if candidates.size() < config.affected_cell_count_min:
		return []

	var seed_cell := candidates[_rng.randi_range(0, candidates.size() - 1)]
	candidates.sort_custom(
		func(first: ArenaCell, second: ArenaCell) -> bool:
			var seed_center := seed_cell.get_center_position()
			return (
				first.get_center_position().distance_squared_to(seed_center)
				< second.get_center_position().distance_squared_to(seed_center)
			)
	)

	var desired_count := _rng.randi_range(
		config.affected_cell_count_min, mini(config.affected_cell_count_max, candidates.size())
	)
	var selected_indices: Array[int] = []
	for candidate_index in range(desired_count):
		selected_indices.append(candidates[candidate_index].index)
	return selected_indices


func _collect_candidate_cells(
	config: ArenaHazardConfig, placement_rules: DangerPlacementRules = null
) -> Array[ArenaCell]:
	var candidates: Array[ArenaCell] = []
	var player_position := Vector3.ZERO
	if _player != null:
		player_position = _player.global_position
	var effective_rules := _create_fallback_rules(config)
	if placement_rules != null:
		effective_rules = placement_rules

	for cell: ArenaCell in _arena.get_cells():
		if cell.state != ArenaCell.ArenaCellState.NORMAL:
			continue

		var center := cell.get_center_position()
		if _placement_service != null:
			if not _placement_service.is_position_allowed(center, effective_rules):
				continue
		else:
			if Vector2(center.x, center.z).length() < effective_rules.center_safe_radius_meters:
				continue
			if (
				_player != null
				and (
					center.distance_to(player_position)
					< effective_rules.min_distance_from_player_meters
				)
			):
				continue
		candidates.append(cell)

	return candidates


func _create_fallback_rules(config: ArenaHazardConfig) -> DangerPlacementRules:
	var rules := DangerPlacementRules.new()
	rules.spawn_search_attempts = maxi(config.affected_cell_count_max, 1)
	rules.min_distance_from_player_meters = config.min_distance_from_player_meters
	rules.center_safe_radius_meters = config.center_safe_radius_meters
	return rules


func _update_hazards(delta: float) -> void:
	for hazard_index in range(_active_hazards.size() - 1, -1, -1):
		var hazard := _active_hazards[hazard_index]
		hazard.timer_seconds -= delta
		if hazard.config.hazard_type == ArenaHazardConfig.HazardType.LAVA:
			hazard.lava_tick_timer_seconds = maxf(hazard.lava_tick_timer_seconds - delta, 0.0)
		if hazard.timer_seconds <= 0.0 and _advance_hazard(hazard):
			_active_hazards.remove_at(hazard_index)


func _advance_hazard(hazard: ActiveHazard) -> bool:
	match hazard.state:
		HazardRuntimeState.WARNING:
			_activate_hazard(hazard)
		HazardRuntimeState.ACTIVE:
			_start_rebuilding(hazard)
		HazardRuntimeState.COLLAPSING:
			_start_destroyed(hazard)
		HazardRuntimeState.DESTROYED:
			_start_rebuilding(hazard)
		HazardRuntimeState.REBUILDING:
			_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.NORMAL)
			return true
	return false


func _activate_hazard(hazard: ActiveHazard) -> void:
	match hazard.config.hazard_type:
		ArenaHazardConfig.HazardType.LAVA:
			hazard.state = HazardRuntimeState.ACTIVE
			hazard.timer_seconds = hazard.config.active_duration_seconds
			hazard.lava_tick_timer_seconds = 0.0
			_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.LAVA)
		ArenaHazardConfig.HazardType.ICE:
			hazard.state = HazardRuntimeState.ACTIVE
			hazard.timer_seconds = hazard.config.active_duration_seconds
			_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.ICE)
		ArenaHazardConfig.HazardType.COLLAPSE:
			hazard.state = HazardRuntimeState.COLLAPSING
			hazard.timer_seconds = hazard.config.collapsing_duration_seconds
			_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.COLLAPSING)


func _start_destroyed(hazard: ActiveHazard) -> void:
	hazard.state = HazardRuntimeState.DESTROYED
	hazard.timer_seconds = hazard.config.destroyed_duration_seconds
	_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.DESTROYED)


func _start_rebuilding(hazard: ActiveHazard) -> void:
	hazard.state = HazardRuntimeState.REBUILDING
	hazard.timer_seconds = hazard.config.rebuilding_duration_seconds
	_set_hazard_cells_state(hazard, ArenaCell.ArenaCellState.REBUILDING)


func _set_hazard_cells_state(hazard: ActiveHazard, state: ArenaCell.ArenaCellState) -> void:
	if _arena == null:
		return

	for cell_index: int in hazard.cell_indices:
		_arena.set_cell_state(cell_index, state)


func _apply_player_surface_effects() -> void:
	if _arena == null or _player == null:
		return

	var cell := _arena.get_cell_at_position(_player.global_position)
	if cell != null and cell.state == ArenaCell.ArenaCellState.ICE:
		var ice_config := _get_first_config_for_type(ArenaHazardConfig.HazardType.ICE)
		if ice_config == null:
			ice_config = ArenaHazardConfig.new()
		_player.set_surface_movement_modifier(
			&"ice",
			ice_config.ice_speed_multiplier,
			ice_config.ice_acceleration_multiplier,
			ice_config.ice_deceleration_multiplier,
			ice_config.ice_turn_acceleration_multiplier
		)
		return

	_player.clear_surface_movement_modifier()


func _apply_player_damage(_delta: float) -> void:
	if _arena == null or _player == null or _health_component == null:
		return

	var player_cell := _arena.get_cell_at_position(_player.global_position)
	if player_cell == null:
		_apply_fall_damage_if_below_arena()
		return

	if player_cell.state == ArenaCell.ArenaCellState.DESTROYED:
		_health_component.apply_damage(_get_destroyed_damage_profile(), _player.global_position)
		return

	if player_cell.state != ArenaCell.ArenaCellState.LAVA:
		return

	for hazard: ActiveHazard in _active_hazards:
		if hazard.config.hazard_type != ArenaHazardConfig.HazardType.LAVA:
			continue
		if hazard.state != HazardRuntimeState.ACTIVE:
			continue
		if not hazard.cell_indices.has(player_cell.index):
			continue
		if hazard.lava_tick_timer_seconds > 0.0:
			continue

		_health_component.apply_damage(hazard.config.lava_damage_profile, _player.global_position)
		hazard.lava_tick_timer_seconds = hazard.config.lava_damage_tick_seconds
		break


func _get_first_config_for_type(hazard_type: ArenaHazardConfig.HazardType) -> ArenaHazardConfig:
	for hazard: ActiveHazard in _active_hazards:
		if hazard.config.hazard_type == hazard_type:
			return hazard.config
	return null


func _get_destroyed_damage_profile() -> DamageProfile:
	var collapse_config := _get_first_config_for_type(ArenaHazardConfig.HazardType.COLLAPSE)
	if collapse_config != null:
		return collapse_config.destroyed_damage_profile

	return ArenaHazardConfig.new().destroyed_damage_profile


func _apply_fall_damage_if_below_arena() -> void:
	var surface_height := _arena.get_surface_height_at_position(_player.global_position)
	if _player.global_position.y > surface_height - fall_death_depth_meters:
		return

	_health_component.apply_damage(_get_fall_damage_profile(), _player.global_position)


func _get_fall_damage_profile() -> DamageProfile:
	if fall_damage_profile != null and fall_damage_profile.is_valid_profile():
		return fall_damage_profile

	var profile := DamageProfile.new()
	profile.amount = 999.0
	profile.damage_type = DamageProfile.DamageType.TERRAIN
	profile.death_reason = &"fell_out_of_arena"
	profile.hit_label = &"Fall"
	profile.ignores_invulnerability = true
	return profile


func _get_cell_count(state: ArenaCell.ArenaCellState) -> int:
	if _arena == null:
		return 0
	return _arena.get_cell_count_by_state(state)


func _get_collapsing_cell_count() -> int:
	return _get_cell_count(ArenaCell.ArenaCellState.COLLAPSING)


func _increment_skipped_spawn() -> void:
	_skipped_spawn_count += 1
