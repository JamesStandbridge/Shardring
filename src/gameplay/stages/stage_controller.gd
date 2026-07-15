class_name StageController
extends Node

signal stage_started(level_index: int, map_id: StringName, required_shards: int)
signal stage_progress_changed(survived_threat_budget: float, required_threat_budget: float)
signal stage_exit_available(level_index: int, map_id: StringName)
signal stage_transitioned(level_index: int, map_id: StringName)

enum StageState {
	SURVIVING,
	EXIT_AVAILABLE,
	TRANSITIONING,
}

@export var stage_sequence_config: StageSequenceConfig = StageSequenceConfig.new()
@export var run_controller_path: NodePath
@export var arena_path: NodePath
@export var player_path: NodePath
@export var danger_director_path: NodePath
@export var shard_objective_path: NodePath
@export var exit_gate_path: NodePath
@export var world_environment_path: NodePath
@export var key_light_path: NodePath
@export var fill_light_path: NodePath

var _run_controller: RunController
var _arena: ArenaController
var _player: PlayerController
var _danger_director: DangerDirector
var _shard_objective: ShardObjectiveController
var _exit_gate: ExitGateController
var _world_environment: WorldEnvironment
var _key_light: DirectionalLight3D
var _fill_light: OmniLight3D
var _stage_state := StageState.SURVIVING
var _level_index: int = 1
var _required_threat_budget: float = 0.0
var _survived_threat_budget: float = 0.0
var _overstay_seconds: float = 0.0
var _current_map: MapDefinition


func _ready() -> void:
	_resolve_nodes()
	_connect_runtime_signals()
	DebugLog.info(&"Stage", "ready maps=%d" % stage_sequence_config.maps.size())


func _process(delta: float) -> void:
	if _stage_state != StageState.EXIT_AVAILABLE:
		return
	if _run_controller == null or not _run_controller.is_playing():
		return
	_overstay_seconds += delta


func get_stage_state() -> StageState:
	return _stage_state


func get_stage_state_name() -> String:
	match _stage_state:
		StageState.SURVIVING:
			return "SURVIVING"
		StageState.EXIT_AVAILABLE:
			return "EXIT_AVAILABLE"
		StageState.TRANSITIONING:
			return "TRANSITIONING"
	return "UNKNOWN"


func get_level_index() -> int:
	return _level_index


func get_current_map_id() -> StringName:
	if _current_map == null:
		return &""
	return _current_map.map_id


func get_current_map_name() -> String:
	if _current_map == null:
		return ""
	return _current_map.display_name


func get_required_threat_budget() -> float:
	return _required_threat_budget


func get_survived_threat_budget() -> float:
	return _survived_threat_budget


func get_required_shards() -> int:
	if _shard_objective == null:
		return 0
	return _shard_objective.get_required_shards()


func get_collected_shards() -> int:
	if _shard_objective == null:
		return 0
	return _shard_objective.get_collected_shards()


func get_current_shard_risk_tier() -> int:
	if _shard_objective == null:
		return 0
	return _shard_objective.get_current_risk_tier()


func get_overstay_seconds() -> float:
	return _overstay_seconds


func get_risk_bonus_multiplier() -> float:
	if _stage_state != StageState.EXIT_AVAILABLE:
		return 1.0
	return 1.0 + _overstay_seconds * 0.025


func is_exit_available() -> bool:
	return _stage_state == StageState.EXIT_AVAILABLE


func request_advance_stage() -> bool:
	if _stage_state != StageState.EXIT_AVAILABLE:
		return false

	_stage_state = StageState.TRANSITIONING
	_level_index += 1
	_start_current_stage(true)
	stage_transitioned.emit(_level_index, get_current_map_id())
	return true


func force_complete_stage_for_tests() -> void:
	_make_exit_available()


func register_threat_spawned_for_tests(spent_cost: float) -> void:
	_on_danger_spawned(&"test", DangerDefinition.DangerFamily.SPECIAL_EVENT, spent_cost)


func _resolve_nodes() -> void:
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_danger_director = get_node_or_null(danger_director_path) as DangerDirector
	_shard_objective = get_node_or_null(shard_objective_path) as ShardObjectiveController
	_exit_gate = get_node_or_null(exit_gate_path) as ExitGateController
	_world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	_key_light = get_node_or_null(key_light_path) as DirectionalLight3D
	_fill_light = get_node_or_null(fill_light_path) as OmniLight3D


func _connect_runtime_signals() -> void:
	if _run_controller != null:
		_run_controller.run_started.connect(_on_run_started)
		_run_controller.run_restarted.connect(_on_run_restarted)
		_run_controller.run_died.connect(_on_run_died)
	if _danger_director != null:
		_danger_director.danger_spawned.connect(_on_danger_spawned)
	if _shard_objective != null:
		_shard_objective.shard_collected.connect(_on_shard_collected)
		_shard_objective.objective_completed.connect(_on_shard_objective_completed)
	if _exit_gate != null:
		_exit_gate.gate_entered.connect(_on_exit_gate_entered)


func _on_run_started() -> void:
	_level_index = 1
	_start_current_stage(true)


func _on_run_restarted() -> void:
	_hide_exit_gate()


func _on_run_died(_reason: StringName) -> void:
	_hide_exit_gate()


func _on_danger_spawned(
	_danger_id: StringName, _family: DangerDefinition.DangerFamily, spent_cost: float
) -> void:
	if _stage_state != StageState.SURVIVING:
		return
	if _run_controller == null or not _run_controller.is_playing():
		return
	if spent_cost <= 0.0:
		return

	_survived_threat_budget = minf(_survived_threat_budget + spent_cost, _required_threat_budget)
	stage_progress_changed.emit(_survived_threat_budget, _required_threat_budget)


func _on_shard_collected(collected_shards: int, _required_shards: int, _risk_tier: int) -> void:
	if _danger_director == null or _shard_objective == null:
		return
	_danger_director.set_objective_intensity_bonus(_shard_objective.get_objective_intensity_bonus())
	_danger_director.force_peak(
		stage_sequence_config.shard_objective_config.post_collect_peak_duration_seconds
	)
	DebugLog.info(&"Stage", "shard collected count=%d" % collected_shards)


func _on_shard_objective_completed(_required_shards: int) -> void:
	_make_exit_available()


func _on_exit_gate_entered() -> void:
	request_advance_stage()


func _start_current_stage(clear_active_dangers: bool) -> void:
	if not stage_sequence_config.is_valid_sequence():
		DebugLog.warn(&"Stage", "invalid stage sequence config")
		return

	if clear_active_dangers and _danger_director != null:
		_danger_director.clear_active_dangers()

	_current_map = stage_sequence_config.get_map_for_level(_level_index)
	_required_threat_budget = stage_sequence_config.get_required_threat_budget_for_level(
		_level_index
	)
	_survived_threat_budget = 0.0
	_overstay_seconds = 0.0
	_stage_state = StageState.SURVIVING
	_apply_current_map()
	if _danger_director != null:
		_danger_director.set_exit_pressure_enabled(false)
		_danger_director.set_objective_intensity_bonus(0.0)
	_hide_exit_gate()
	_place_player_at_spawn()
	_start_shard_objective()
	stage_started.emit(_level_index, get_current_map_id(), get_required_shards())
	stage_progress_changed.emit(_survived_threat_budget, _required_threat_budget)
	DebugLog.info(
		&"Stage",
		(
			"started level=%d map=%s required_shards=%d"
			% [_level_index, get_current_map_id(), get_required_shards()]
		)
	)


func _apply_current_map() -> void:
	if _current_map == null:
		return

	var generation_seed := stage_sequence_config.get_generation_seed_for_level(
		_current_map, _level_index
	)
	if _arena != null:
		_arena.configure_for_stage(
			_current_map.arena_config, _current_map.arena_theme, generation_seed
		)
	if _danger_director != null:
		_danger_director.configure_for_stage(
			_current_map.director_config,
			_current_map.difficulty_config,
			_current_map.default_danger_definition,
			_current_map.get_danger_definitions(),
			stage_sequence_config.get_starting_intensity_for_level(_current_map, _level_index)
		)
	_apply_theme(_current_map.arena_theme)


func _apply_theme(theme: ArenaThemeConfig) -> void:
	if theme == null:
		return

	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment.background_color = theme.background_color
		_world_environment.environment.ambient_light_color = theme.ambient_light_color
		_world_environment.environment.ambient_light_energy = theme.ambient_light_energy
	if _key_light != null:
		_key_light.light_color = theme.key_light_color
		_key_light.light_energy = theme.key_light_energy
	if _fill_light != null:
		_fill_light.light_color = theme.fill_light_color
		_fill_light.light_energy = theme.fill_light_energy


func _make_exit_available() -> void:
	if _stage_state != StageState.SURVIVING:
		return

	_stage_state = StageState.EXIT_AVAILABLE
	if _danger_director != null:
		_danger_director.set_exit_pressure_enabled(true)
	if _exit_gate != null:
		_exit_gate.set_gate_available(true, _get_exit_gate_position())
	stage_exit_available.emit(_level_index, get_current_map_id())
	DebugLog.info(&"Stage", "exit available level=%d map=%s" % [_level_index, get_current_map_id()])


func _start_shard_objective() -> void:
	if _shard_objective == null:
		return
	_shard_objective.start_objective(_level_index, stage_sequence_config.shard_objective_config)


func _hide_exit_gate() -> void:
	if _exit_gate != null:
		_exit_gate.set_gate_available(false, Vector3.ZERO)


func _place_player_at_spawn() -> void:
	if _arena == null or _player == null:
		return

	var spawn_transform := _player.global_transform
	spawn_transform.origin = _arena.get_spawn_position()
	_player.set_spawn_transform(spawn_transform)
	_player.reset_to_spawn()


func _get_exit_gate_position() -> Vector3:
	if _arena == null:
		return Vector3.ZERO
	return _arena.get_center_ground_position()
