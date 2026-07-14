class_name HealthHud
extends CanvasLayer

@export var health_component_path: NodePath
@export var player_path: NodePath
@export var stage_controller_path: NodePath

var _health_component: HealthComponent
var _player: PlayerController
var _stage_controller: StageController
var _flash_timer_seconds: float = 0.0
var _flash_duration_seconds: float = 0.0
var _flash_color := Color.TRANSPARENT

@onready var _bar: ProgressBar = $Panel/HealthBar
@onready var _label: Label = $Panel/HealthLabel
@onready var _stage_label: Label = get_node_or_null("Panel/StageLabel") as Label
@onready var _objective_label: Label = get_node_or_null("Panel/ObjectiveLabel") as Label
@onready var _speed_label: Label = get_node_or_null("Panel/SpeedLabel") as Label
@onready var _jump_label: Label = get_node_or_null("Panel/JumpLabel") as Label
@onready var _flash_overlay: ColorRect = get_node_or_null("Panel/FlashOverlay") as ColorRect


func _ready() -> void:
	_health_component = get_node_or_null(health_component_path) as HealthComponent
	if _health_component == null:
		visible = false
		DebugLog.warn(&"HealthHud", "missing health component path")
		return

	_player = get_node_or_null(player_path) as PlayerController
	_stage_controller = get_node_or_null(stage_controller_path) as StageController
	_health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(_health_component.get_current_health(), _health_component.get_max_health())
	_update_player_stats()
	_update_stage_stats()
	_update_flash_overlay()


func _process(delta: float) -> void:
	_update_player_stats()
	_update_stage_stats()

	if _flash_timer_seconds > 0.0:
		_flash_timer_seconds = maxf(_flash_timer_seconds - delta, 0.0)
		_update_flash_overlay()


func get_health_text() -> String:
	return _label.text


func request_flash(color: Color, duration_seconds: float) -> void:
	if _flash_overlay == null or duration_seconds <= 0.0:
		return

	_flash_color = color
	_flash_duration_seconds = duration_seconds
	_flash_timer_seconds = duration_seconds
	_update_flash_overlay()


func is_flashing() -> bool:
	return _flash_timer_seconds > 0.0


func _on_health_changed(current_health: float, max_health: float) -> void:
	_bar.max_value = max_health
	_bar.value = current_health
	_label.text = "%.0f / %.0f HP" % [current_health, max_health]


func _update_player_stats() -> void:
	if _player == null:
		_player = get_node_or_null(player_path) as PlayerController
	if _player == null:
		return

	if _speed_label != null:
		_speed_label.text = "SPEED %.1f" % _player.get_horizontal_speed()
	if _jump_label != null:
		_jump_label.text = "JUMPS %d" % _player.get_remaining_jumps()


func _update_stage_stats() -> void:
	if _stage_controller == null:
		_stage_controller = get_node_or_null(stage_controller_path) as StageController
	if _stage_controller == null:
		return

	if _stage_label != null:
		_stage_label.text = (
			"LEVEL %d  %s"
			% [
				_stage_controller.get_level_index(),
				_stage_controller.get_current_map_name(),
			]
		)

	if _objective_label != null:
		var exit_text := ""
		if _stage_controller.is_exit_available():
			exit_text = "  EXIT READY"
		_objective_label.text = (
			"THREAT %.0f / %.0f%s"
			% [
				_stage_controller.get_survived_threat_budget(),
				_stage_controller.get_required_threat_budget(),
				exit_text,
			]
		)


func _update_flash_overlay() -> void:
	if _flash_overlay == null:
		return

	if _flash_timer_seconds <= 0.0:
		_flash_overlay.visible = false
		_flash_overlay.color = Color.TRANSPARENT
		return

	var alpha_ratio := _flash_timer_seconds / maxf(_flash_duration_seconds, 0.001)
	var color := _flash_color
	color.a *= alpha_ratio
	_flash_overlay.visible = true
	_flash_overlay.color = color
