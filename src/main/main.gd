class_name MainScene
extends Node3D

@onready var _run_controller: RunController = $RunController
@onready var _player: PlayerController = $Player
@onready var _arena: ArenaController = get_node_or_null("Arena") as ArenaController


func _ready() -> void:
	DebugLog.info(&"Main", "ready")
	GameEvents.emit_game_bootstrapped()
	_run_controller.run_started.connect(_on_run_started)
	_run_controller.run_died.connect(_on_run_died)
	_run_controller.run_restarted.connect(_on_run_restarted)
	_run_controller.start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_run"):
		_run_controller.restart_run()


func _on_run_started() -> void:
	_place_player_at_spawn()
	_player.reset_to_spawn()
	_player.set_movement_enabled(true)


func _on_run_died(_reason: StringName) -> void:
	_player.set_movement_enabled(false)


func _on_run_restarted() -> void:
	_place_player_at_spawn()
	_player.reset_to_spawn()


func _place_player_at_spawn() -> void:
	if _arena == null:
		DebugLog.info(&"Main", "no arena node found; keeping player scene spawn")
		return

	var spawn_transform := _player.global_transform
	spawn_transform.origin = _arena.get_spawn_position()
	_player.set_spawn_transform(spawn_transform)
	DebugLog.info(&"Main", "player spawn=%s" % spawn_transform.origin)
