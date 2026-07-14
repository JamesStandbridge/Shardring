class_name DangerDirector
extends Node

signal danger_spawned(
	danger_id: StringName, family: DangerDefinition.DangerFamily, spent_cost: float
)

enum PressurePhase {
	BUILDUP,
	PEAK,
	RECOVERY,
	EXIT_PRESSURE,
}

const DEFAULT_SKIP_REASON := &"no_candidate"

@export var director_config: DangerDirectorConfig = DangerDirectorConfig.new()
@export var difficulty_config: DifficultyConfig = DifficultyConfig.new()
@export var default_danger_definition: DangerDefinition
@export var danger_definitions: Array[DangerDefinition] = []
@export var run_controller_path: NodePath
@export var danger_executor_paths: Array[NodePath] = []
@export var projectile_system_path: NodePath
@export var generation_seed: int = 4242

var _run_controller: RunController
var _danger_executors: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _available_credits: float = 0.0
var _decision_timer_seconds: float = 0.0
var _cooldowns: Dictionary = {}
var _skipped_spawn_count: int = 0
var _last_logged_skip_count: int = 0
var _last_spawned_danger_id: StringName = &""
var _last_skip_reason: StringName = &""
var _pressure_phase := PressurePhase.BUILDUP
var _pressure_phase_timer_seconds: float = 0.0
var _exit_pressure_enabled := false


func _ready() -> void:
	_rng.seed = generation_seed
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_resolve_danger_executors()
	_initialize_cooldowns()
	_connect_run_controller()
	_reset_runtime_state()
	DebugLog.info(
		&"DangerDirector",
		(
			"ready definitions=%d executors=%d seed=%d"
			% [_get_all_definitions().size(), _danger_executors.size(), generation_seed]
		)
	)


func _physics_process(delta: float) -> void:
	step_director_for_tests(delta)


func step_director_for_tests(delta: float) -> void:
	if not _is_run_playing():
		return

	_update_pressure_phase(delta)
	_accumulate_credits(delta)
	_update_cooldowns(delta)
	_update_decision_timer(delta)


func get_available_credits() -> float:
	return _available_credits


func get_current_intensity() -> float:
	if _run_controller == null:
		return difficulty_config.starting_intensity

	var gained_intensity := (
		_run_controller.get_survival_time_seconds()
		/ 60.0
		* difficulty_config.intensity_gain_per_minute
	)
	return minf(
		difficulty_config.starting_intensity + gained_intensity, difficulty_config.max_intensity
	)


func get_next_decision_seconds() -> float:
	return maxf(_decision_timer_seconds, 0.0)


func get_active_danger_count() -> int:
	var active_count := 0
	for executor: Node in _danger_executors:
		if executor.has_method("get_total_active_danger_count"):
			active_count += int(executor.call("get_total_active_danger_count"))
	return active_count


func get_skipped_spawn_count() -> int:
	return _skipped_spawn_count


func get_last_spawned_danger_id() -> StringName:
	return _last_spawned_danger_id


func get_last_skip_reason() -> StringName:
	return _last_skip_reason


func get_pressure_phase() -> PressurePhase:
	return _pressure_phase


func get_pressure_phase_name() -> String:
	match _pressure_phase:
		PressurePhase.BUILDUP:
			return "BUILDUP"
		PressurePhase.PEAK:
			return "PEAK"
		PressurePhase.RECOVERY:
			return "RECOVERY"
		PressurePhase.EXIT_PRESSURE:
			return "EXIT_PRESSURE"
	return "UNKNOWN"


func get_pressure_phase_seconds_remaining() -> float:
	return maxf(_pressure_phase_timer_seconds, 0.0)


func get_credit_pressure_multiplier() -> float:
	return _get_credit_pressure_multiplier()


func get_decision_interval_pressure_multiplier() -> float:
	return _get_decision_interval_pressure_multiplier()


func is_exit_pressure_enabled() -> bool:
	return _exit_pressure_enabled


func set_exit_pressure_enabled(enabled: bool) -> void:
	if _exit_pressure_enabled == enabled:
		return

	_exit_pressure_enabled = enabled
	if enabled:
		_set_pressure_phase(PressurePhase.EXIT_PRESSURE, 0.0)
	else:
		_set_pressure_phase(PressurePhase.BUILDUP, director_config.first_peak_delay_seconds)


func reset_director() -> void:
	_reset_runtime_state()


func configure_for_stage(
	stage_director_config: DangerDirectorConfig,
	stage_difficulty_config: DifficultyConfig,
	stage_default_danger_definition: DangerDefinition,
	stage_danger_definitions: Array[DangerDefinition],
	starting_intensity_override: float
) -> void:
	if stage_director_config != null:
		director_config = stage_director_config.duplicate(true) as DangerDirectorConfig
	if stage_difficulty_config != null:
		difficulty_config = stage_difficulty_config.duplicate(true) as DifficultyConfig
		difficulty_config.starting_intensity = starting_intensity_override
	default_danger_definition = stage_default_danger_definition
	danger_definitions = stage_danger_definitions.duplicate()
	_reset_runtime_state()


func clear_active_dangers() -> void:
	for executor: Node in _danger_executors:
		if executor.has_method("clear_all"):
			executor.call("clear_all")


func _resolve_danger_executors() -> void:
	_danger_executors.clear()
	for executor_path: NodePath in danger_executor_paths:
		_add_danger_executor(get_node_or_null(executor_path))

	# Backward compatibility for older scenes/tests while migrating to executor paths.
	if _danger_executors.is_empty() and not projectile_system_path.is_empty():
		_add_danger_executor(get_node_or_null(projectile_system_path))


func _add_danger_executor(executor: Node) -> void:
	if executor == null or _danger_executors.has(executor):
		return
	_danger_executors.append(executor)


func _connect_run_controller() -> void:
	if _run_controller == null:
		if not run_controller_path.is_empty():
			DebugLog.warn(&"DangerDirector", "missing run controller path")
		return

	_run_controller.run_started.connect(_on_run_started)
	_run_controller.run_died.connect(_on_run_died)
	_run_controller.run_restarted.connect(_on_run_restarted)


func _on_run_started() -> void:
	_reset_runtime_state()


func _on_run_died(_reason: StringName) -> void:
	_reset_runtime_state()


func _on_run_restarted() -> void:
	_reset_runtime_state()


func _reset_runtime_state() -> void:
	_available_credits = 0.0
	_decision_timer_seconds = director_config.initial_decision_delay_seconds
	_skipped_spawn_count = 0
	_last_logged_skip_count = 0
	_last_spawned_danger_id = &""
	_last_skip_reason = &""
	_exit_pressure_enabled = false
	_pressure_phase = PressurePhase.BUILDUP
	_pressure_phase_timer_seconds = director_config.first_peak_delay_seconds
	_initialize_cooldowns()


func _initialize_cooldowns() -> void:
	_cooldowns.clear()
	for definition: DangerDefinition in _get_all_definitions():
		if definition != null:
			_cooldowns[definition.danger_id] = 0.0


func _is_run_playing() -> bool:
	return _run_controller != null and _run_controller.is_playing()


func _accumulate_credits(delta: float) -> void:
	var earned_credits := (
		director_config.credits_per_second
		* get_current_intensity()
		* _get_credit_pressure_multiplier()
		* delta
	)
	_available_credits = minf(
		_available_credits + earned_credits, director_config.max_stored_credits
	)


func _update_cooldowns(delta: float) -> void:
	for danger_id: StringName in _cooldowns:
		_cooldowns[danger_id] = maxf(float(_cooldowns[danger_id]) - delta, 0.0)


func _update_decision_timer(delta: float) -> void:
	_decision_timer_seconds -= delta
	if _decision_timer_seconds > 0.0:
		return

	_decision_timer_seconds = maxf(
		director_config.decision_interval_seconds * _get_decision_interval_pressure_multiplier(),
		0.01
	)
	_try_spawn_danger()


func _try_spawn_danger() -> bool:
	var candidates := _collect_candidates()
	if candidates.is_empty():
		_increment_skipped_spawn(DEFAULT_SKIP_REASON)
		return false

	var definition := _pick_weighted_candidate(candidates)
	if definition == null:
		_increment_skipped_spawn(DEFAULT_SKIP_REASON)
		return false

	if not _execute_danger(definition):
		_increment_skipped_spawn(&"spawn_failed")
		return false

	_available_credits = maxf(_available_credits - definition.spawn_cost, 0.0)
	_cooldowns[definition.danger_id] = definition.cooldown_seconds
	_last_spawned_danger_id = definition.danger_id
	_last_skip_reason = &""
	danger_spawned.emit(definition.danger_id, definition.family, definition.spawn_cost)
	(
		DebugLog
		. info(
			&"DangerDirector",
			(
				"spawned danger=%s phase=%s credits=%.2f active=%d"
				% [
					definition.danger_id,
					get_pressure_phase_name(),
					_available_credits,
					get_active_danger_count(),
				]
			)
		)
	)
	return true


func _update_pressure_phase(delta: float) -> void:
	if _exit_pressure_enabled:
		if _pressure_phase != PressurePhase.EXIT_PRESSURE:
			_set_pressure_phase(PressurePhase.EXIT_PRESSURE, 0.0)
		return

	_pressure_phase_timer_seconds -= delta
	if _pressure_phase_timer_seconds > 0.0:
		return

	match _pressure_phase:
		PressurePhase.BUILDUP:
			_set_pressure_phase(PressurePhase.PEAK, director_config.peak_duration_seconds)
		PressurePhase.PEAK:
			_set_pressure_phase(PressurePhase.RECOVERY, director_config.recovery_duration_seconds)
		PressurePhase.RECOVERY:
			_set_pressure_phase(PressurePhase.BUILDUP, director_config.first_peak_delay_seconds)
		PressurePhase.EXIT_PRESSURE:
			_set_pressure_phase(PressurePhase.BUILDUP, director_config.first_peak_delay_seconds)


func _set_pressure_phase(phase: PressurePhase, duration_seconds: float) -> void:
	_pressure_phase = phase
	_pressure_phase_timer_seconds = maxf(duration_seconds, 0.0)
	var phase_decision_interval := maxf(
		director_config.decision_interval_seconds * _get_decision_interval_pressure_multiplier(),
		0.01
	)
	if phase == PressurePhase.PEAK:
		_decision_timer_seconds = minf(_decision_timer_seconds, phase_decision_interval)
	else:
		_decision_timer_seconds = maxf(_decision_timer_seconds, phase_decision_interval)


func _get_credit_pressure_multiplier() -> float:
	match _pressure_phase:
		PressurePhase.PEAK:
			return director_config.peak_credit_multiplier
		PressurePhase.RECOVERY:
			return director_config.recovery_credit_multiplier
		PressurePhase.EXIT_PRESSURE:
			return director_config.exit_credit_multiplier
	return 1.0


func _get_decision_interval_pressure_multiplier() -> float:
	match _pressure_phase:
		PressurePhase.PEAK:
			return director_config.peak_decision_interval_multiplier
		PressurePhase.EXIT_PRESSURE:
			return director_config.exit_decision_interval_multiplier
	return 1.0


func _collect_candidates() -> Array[DangerDefinition]:
	var candidates: Array[DangerDefinition] = []
	var total_active := get_active_danger_count()
	if total_active >= director_config.max_total_active_dangers:
		return candidates

	for definition: DangerDefinition in _get_all_definitions():
		if _can_spawn_definition(definition):
			candidates.append(definition)

	return candidates


func _can_spawn_definition(definition: DangerDefinition) -> bool:
	if definition == null or not definition.is_valid_definition():
		return false
	if not definition.can_unlock_at_intensity(get_current_intensity()):
		return false
	if _available_credits < definition.spawn_cost:
		return false
	if _get_cooldown_seconds(definition.danger_id) > 0.0:
		return false
	if _get_active_count_for_definition(definition) >= definition.max_active_instances:
		return false

	return _is_supported_definition(definition)


func _is_supported_definition(definition: DangerDefinition) -> bool:
	return _find_executor_for_definition(definition) != null


func _execute_danger(definition: DangerDefinition) -> bool:
	var executor := _find_executor_for_definition(definition)
	if executor == null or not executor.has_method("request_spawn_danger"):
		return false

	return bool(executor.call("request_spawn_danger", definition))


func _pick_weighted_candidate(candidates: Array[DangerDefinition]) -> DangerDefinition:
	var total_weight := 0.0
	for definition: DangerDefinition in candidates:
		total_weight += maxf(definition.selection_weight, 0.0)

	if total_weight <= 0.0:
		return null

	var selected_weight := _rng.randf_range(0.0, total_weight)
	var cumulative_weight := 0.0
	for definition: DangerDefinition in candidates:
		cumulative_weight += maxf(definition.selection_weight, 0.0)
		if cumulative_weight >= selected_weight:
			return definition

	return candidates.back()


func _get_all_definitions() -> Array[DangerDefinition]:
	var definitions: Array[DangerDefinition] = []
	if default_danger_definition != null:
		definitions.append(default_danger_definition)

	for definition: DangerDefinition in danger_definitions:
		if definition != null and not definitions.has(definition):
			definitions.append(definition)

	return definitions


func _get_cooldown_seconds(danger_id: StringName) -> float:
	if not _cooldowns.has(danger_id):
		_cooldowns[danger_id] = 0.0
	return float(_cooldowns[danger_id])


func _get_active_count_for_definition(definition: DangerDefinition) -> int:
	var executor := _find_executor_for_definition(definition)
	if executor == null or not executor.has_method("get_active_danger_count"):
		return 0

	return int(executor.call("get_active_danger_count", definition))


func _find_executor_for_definition(definition: DangerDefinition) -> Node:
	if definition == null:
		return null

	for executor: Node in _danger_executors:
		if not executor.has_method("supports_danger_family"):
			continue
		if bool(executor.call("supports_danger_family", definition.family)):
			return executor

	return null


func _increment_skipped_spawn(reason: StringName) -> void:
	_skipped_spawn_count += 1
	_last_skip_reason = reason
	if _skipped_spawn_count - _last_logged_skip_count < maxi(director_config.skip_log_interval, 1):
		return

	_last_logged_skip_count = _skipped_spawn_count
	DebugLog.info(&"DangerDirector", "skipped spawns=%d reason=%s" % [_skipped_spawn_count, reason])
