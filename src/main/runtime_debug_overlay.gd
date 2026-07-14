class_name RuntimeDebugOverlay
extends CanvasLayer

@export var run_controller_path: NodePath
@export var player_path: NodePath
@export var arena_path: NodePath
@export var projectile_system_path: NodePath

@onready var _label: Label = $DebugLabel


func _process(_delta: float) -> void:
	if not visible:
		return

	var run_controller := get_node_or_null(run_controller_path) as RunController
	var player := get_node_or_null(player_path) as PlayerController
	var arena := get_node_or_null(arena_path) as ArenaController
	var projectile_system := get_node_or_null(projectile_system_path) as ProjectileSystem

	var run_state := "unknown"
	var survival_time := 0.0
	var last_death_reason := ""
	if run_controller != null:
		run_state = run_controller.get_state_name()
		survival_time = run_controller.get_survival_time_seconds()
		last_death_reason = str(run_controller.get_last_death_reason())

	var horizontal_speed := 0.0
	var vertical_speed := 0.0
	var grounded := false
	var remaining_jumps := 0
	if player != null:
		horizontal_speed = player.get_horizontal_speed()
		vertical_speed = player.get_vertical_speed()
		grounded = player.is_grounded()
		remaining_jumps = player.get_remaining_jumps()

	var arena_cells := 0
	if arena != null:
		arena_cells = arena.get_cells().size()

	var active_launchers := 0
	var active_telegraphs := 0
	var active_projectiles := 0
	var skipped_spawns := 0
	var launcher_charge := 0.0
	var telegraph_length := 0.0
	var launcher_direction := Vector3.ZERO
	if projectile_system != null:
		active_launchers = projectile_system.get_active_launcher_count()
		active_telegraphs = projectile_system.get_active_telegraph_count()
		active_projectiles = projectile_system.get_active_projectile_count()
		skipped_spawns = projectile_system.get_skipped_spawn_count()
		launcher_charge = projectile_system.get_first_active_launcher_charge_ratio()
		telegraph_length = projectile_system.get_first_active_launcher_telegraph_length()
		launcher_direction = projectile_system.get_first_active_launcher_direction()

	_label.text = (
		(
			"Run: %s\nTime: %.2fs\nSpeed: %.2f\nY Speed: %.2f\nGrounded: %s\n"
			+ "Jumps: %d\nArena cells: %d\nLaunchers: %d\nTelegraphs: %d\n"
			+ "Projectiles: %d\nSkipped spawns: %d\nCharge: %.2f\nTelegraph: %.2fm\n"
			+ "Aim: %.2f, %.2f, %.2f\nDeath: %s"
		)
		% [
			run_state,
			survival_time,
			horizontal_speed,
			vertical_speed,
			grounded,
			remaining_jumps,
			arena_cells,
			active_launchers,
			active_telegraphs,
			active_projectiles,
			skipped_spawns,
			launcher_charge,
			telegraph_length,
			launcher_direction.x,
			launcher_direction.y,
			launcher_direction.z,
			last_death_reason,
		]
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible
