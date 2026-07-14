class_name RunFeedbackOverlay
extends CanvasLayer

@export var run_controller_path: NodePath

var _run_controller: RunController
var _message_text := ""

@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	_run_controller = get_node_or_null(run_controller_path) as RunController
	if _run_controller == null:
		visible = false
		DebugLog.warn(&"RunFeedback", "missing run controller path")
		return

	_run_controller.run_started.connect(_on_run_started)
	_run_controller.run_restarted.connect(_on_run_restarted)
	_run_controller.run_died.connect(_on_run_died)
	visible = _run_controller.get_state() == RunController.RunState.DEAD
	if visible:
		_set_death_message(_run_controller.get_last_death_reason())


func get_message_text() -> String:
	return _message_text


func _on_run_started() -> void:
	_hide_feedback()


func _on_run_restarted() -> void:
	_hide_feedback()


func _on_run_died(reason: StringName) -> void:
	_set_death_message(reason)
	visible = true


func _hide_feedback() -> void:
	visible = false
	_message_text = ""
	_message_label.text = ""


func _set_death_message(reason: StringName) -> void:
	var reason_text := str(reason)
	if reason_text.is_empty():
		reason_text = "unknown"

	_message_text = "DEAD\nCause: %s\nPress R to restart" % reason_text
	_message_label.text = _message_text
