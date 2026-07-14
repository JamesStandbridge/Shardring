class_name RunController
extends Node

signal run_started
signal run_died(reason: StringName)
signal run_restarted
signal run_state_changed(previous_state: RunState, current_state: RunState)

enum RunState {
	READY,
	PLAYING,
	DEAD,
}

var _state: RunState = RunState.READY
var _survival_time_seconds: float = 0.0
var _last_death_reason: StringName = &""


func _physics_process(delta: float) -> void:
	if _state == RunState.PLAYING:
		_survival_time_seconds += delta


func start_run() -> void:
	_survival_time_seconds = 0.0
	_last_death_reason = &""
	_set_state(RunState.PLAYING)
	DebugLog.info(&"Run", "started")
	run_started.emit()


func register_death(reason: StringName) -> void:
	if _state != RunState.PLAYING:
		return

	_last_death_reason = reason
	_set_state(RunState.DEAD)
	DebugLog.info(&"Run", "died reason=%s time=%.2f" % [reason, _survival_time_seconds])
	run_died.emit(reason)


func restart_run() -> void:
	DebugLog.info(&"Run", "restart requested")
	run_restarted.emit()
	start_run()


func reset_to_ready() -> void:
	_survival_time_seconds = 0.0
	_last_death_reason = &""
	_set_state(RunState.READY)
	DebugLog.info(&"Run", "reset_to_ready")


func get_state() -> RunState:
	return _state


func get_state_name() -> String:
	return RunState.keys()[_state]


func get_survival_time_seconds() -> float:
	return _survival_time_seconds


func get_last_death_reason() -> StringName:
	return _last_death_reason


func is_playing() -> bool:
	return _state == RunState.PLAYING


func _set_state(next_state: RunState) -> void:
	if _state == next_state:
		return

	var previous_state := _state
	_state = next_state
	run_state_changed.emit(previous_state, _state)
