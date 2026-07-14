class_name GameEventsBus
extends Node

signal game_bootstrapped


func emit_game_bootstrapped() -> void:
	game_bootstrapped.emit()
