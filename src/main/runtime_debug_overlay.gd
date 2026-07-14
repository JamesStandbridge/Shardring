class_name RuntimeDebugOverlay
extends CanvasLayer

@export var run_controller_path: NodePath
@export var player_path: NodePath
@export var arena_path: NodePath
@export var projectile_system_path: NodePath
@export var danger_director_path: NodePath
@export var chaser_enemy_system_path: NodePath
@export var stage_controller_path: NodePath
@export var exit_gate_path: NodePath
@export var health_component_path: NodePath
@export var camera_rig_path: NodePath
@export var damage_feedback_controller_path: NodePath

@onready var _label: Label = $DebugLabel


func _process(_delta: float) -> void:
	if not visible:
		return

	var run_controller := get_node_or_null(run_controller_path) as RunController
	var player := get_node_or_null(player_path) as PlayerController
	var arena := get_node_or_null(arena_path) as ArenaController
	var projectile_system := get_node_or_null(projectile_system_path) as ProjectileSystem
	var danger_director := get_node_or_null(danger_director_path) as DangerDirector
	var chaser_enemy_system := get_node_or_null(chaser_enemy_system_path) as ChaserEnemySystem
	var stage_controller := get_node_or_null(stage_controller_path) as StageController
	var exit_gate := get_node_or_null(exit_gate_path) as ExitGateController
	var health_component := get_node_or_null(health_component_path) as HealthComponent
	var camera_rig := get_node_or_null(camera_rig_path) as ThirdPersonCameraRig
	var damage_feedback := (
		get_node_or_null(damage_feedback_controller_path) as DamageFeedbackController
	)

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

	var danger_credits := 0.0
	var active_dangers := 0
	var skipped_dangers := 0
	var last_danger_id := ""
	var next_danger_decision := 0.0
	var danger_phase := ""
	var danger_credit_multiplier := 1.0
	var danger_decision_multiplier := 1.0
	var exit_pressure_enabled := false
	if danger_director != null:
		danger_credits = danger_director.get_available_credits()
		active_dangers = danger_director.get_active_danger_count()
		skipped_dangers = danger_director.get_skipped_spawn_count()
		last_danger_id = str(danger_director.get_last_spawned_danger_id())
		next_danger_decision = danger_director.get_next_decision_seconds()
		danger_phase = danger_director.get_pressure_phase_name()
		danger_credit_multiplier = danger_director.get_credit_pressure_multiplier()
		danger_decision_multiplier = danger_director.get_decision_interval_pressure_multiplier()
		exit_pressure_enabled = danger_director.is_exit_pressure_enabled()

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

	var active_enemies := 0
	var priming_chasers := 0
	var exploding_chasers := 0
	var chaser_explosions := 0
	var skipped_chasers := 0
	if chaser_enemy_system != null:
		active_enemies = chaser_enemy_system.get_active_enemy_count()
		priming_chasers = chaser_enemy_system.get_priming_enemy_count()
		exploding_chasers = chaser_enemy_system.get_exploding_enemy_count()
		chaser_explosions = chaser_enemy_system.get_triggered_explosion_count()
		skipped_chasers = chaser_enemy_system.get_skipped_spawn_count()

	var stage_state := ""
	var level_index := 0
	var map_id := ""
	var survived_threat_budget := 0.0
	var required_threat_budget := 0.0
	if stage_controller != null:
		stage_state = stage_controller.get_stage_state_name()
		level_index = stage_controller.get_level_index()
		map_id = str(stage_controller.get_current_map_id())
		survived_threat_budget = stage_controller.get_survived_threat_budget()
		required_threat_budget = stage_controller.get_required_threat_budget()

	var exit_gate_available := false
	var exit_gate_open := 0.0
	var exit_gate_distance := 0.0
	if exit_gate != null:
		exit_gate_available = exit_gate.is_gate_available()
		exit_gate_open = exit_gate.get_open_amount()
		exit_gate_distance = exit_gate.get_distance_to_player()

	var current_health := 0.0
	var max_health := 0.0
	var invulnerability_seconds := 0.0
	var last_damage_type := ""
	var last_damage_amount := 0.0
	if health_component != null:
		current_health = health_component.get_current_health()
		max_health = health_component.get_max_health()
		invulnerability_seconds = health_component.get_invulnerability_seconds()
		last_damage_type = health_component.get_last_damage_type_name()
		last_damage_amount = health_component.get_last_damage_amount()

	var shake_intensity := 0.0
	if camera_rig != null:
		shake_intensity = camera_rig.get_current_shake_intensity()

	var last_feedback_type := ""
	var last_feedback_strength := 0.0
	if damage_feedback != null:
		last_feedback_type = damage_feedback.get_last_feedback_damage_type_name()
		last_feedback_strength = damage_feedback.get_last_feedback_strength()

	_label.text = (
		(
			"Run: %s\nTime: %.2fs\nSpeed: %.2f\nY Speed: %.2f\nGrounded: %s\n"
			+ "HP: %.0f / %.0f\nInvuln: %.2fs\nLast damage: %s %.2f\n"
			+ "Shake: %.3f\nFeedback: %s %.2f\n"
			+ "Jumps: %d\nArena cells: %d\nDanger credits: %.2f\n"
			+ "Danger active: %d\nDanger skipped: %d\nDanger last: %s\n"
			+ "Danger phase: %s credit x%.2f decision x%.2f exit=%s\n"
			+ "Danger next: %.2fs\nLaunchers: %d\nTelegraphs: %d\n"
			+ "Projectiles: %d\nSkipped spawns: %d\nCharge: %.2f\nTelegraph: %.2fm\n"
			+ "Aim: %.2f, %.2f, %.2f\nEnemies: %d\nChasers priming: %d\n"
			+ "Chasers exploding: %d\nChaser explosions: %d\nSkipped chasers: %d\n"
			+ "Stage: %s L%d %s\nStage threat: %.1f / %.1f\n"
			+ "Exit gate: %s open=%.2f dist=%.2f\n"
			+ "Death: %s"
		)
		% [
			run_state,
			survival_time,
			horizontal_speed,
			vertical_speed,
			grounded,
			current_health,
			max_health,
			invulnerability_seconds,
			last_damage_type,
			last_damage_amount,
			shake_intensity,
			last_feedback_type,
			last_feedback_strength,
			remaining_jumps,
			arena_cells,
			danger_credits,
			active_dangers,
			skipped_dangers,
			last_danger_id,
			danger_phase,
			danger_credit_multiplier,
			danger_decision_multiplier,
			str(exit_pressure_enabled),
			next_danger_decision,
			active_launchers,
			active_telegraphs,
			active_projectiles,
			skipped_spawns,
			launcher_charge,
			telegraph_length,
			launcher_direction.x,
			launcher_direction.y,
			launcher_direction.z,
			active_enemies,
			priming_chasers,
			exploding_chasers,
			chaser_explosions,
			skipped_chasers,
			stage_state,
			level_index,
			map_id,
			survived_threat_budget,
			required_threat_budget,
			str(exit_gate_available),
			exit_gate_open,
			exit_gate_distance,
			last_death_reason,
		]
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		visible = not visible
