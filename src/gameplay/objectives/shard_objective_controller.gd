class_name ShardObjectiveController
extends Node3D

signal shard_spawned(shard_index: int, required_shards: int, position: Vector3, risk_tier: int)
signal shard_collected(collected_shards: int, required_shards: int, risk_tier: int)
signal objective_completed(required_shards: int)

@export var objective_config: ShardObjectiveConfig = ShardObjectiveConfig.new()
@export var shard_scene: PackedScene
@export var run_controller_path: NodePath
@export var arena_path: NodePath
@export var player_path: NodePath
@export var generation_seed: int = 5151

var _run_controller: RunController
var _arena: ArenaController
var _player: PlayerController
var _rng := RandomNumberGenerator.new()
var _visual: Node3D
var _level_index: int = 1
var _required_shards: int = 0
var _collected_shards: int = 0
var _current_risk_tier: int = 0
var _spawn_delay_timer_seconds: float = 0.0
var _objective_active := false
var _shard_active := false
var _objective_completed := false
var _current_shard_position := Vector3.ZERO


func _ready() -> void:
	_rng.seed = generation_seed
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_create_visual()
	_connect_run_controller()
	clear_objective()
	DebugLog.info(&"ShardObjective", "ready seed=%d" % generation_seed)


func _physics_process(delta: float) -> void:
	step_objective_for_tests(delta)


func step_objective_for_tests(delta: float) -> void:
	if not _objective_active or _objective_completed:
		return
	if _run_controller != null and not _run_controller.is_playing():
		return

	if _shard_active:
		_update_active_shard()
		return

	if _spawn_delay_timer_seconds > 0.0:
		_spawn_delay_timer_seconds = maxf(_spawn_delay_timer_seconds - delta, 0.0)
		if _spawn_delay_timer_seconds > 0.0:
			return

	_spawn_next_shard()


func start_objective(level_index: int, config: ShardObjectiveConfig = null) -> void:
	if config != null:
		objective_config = config
	if objective_config == null:
		objective_config = ShardObjectiveConfig.new()

	_level_index = maxi(level_index, 1)
	_required_shards = objective_config.get_required_shards_for_level(_level_index)
	_collected_shards = 0
	_current_risk_tier = 0
	_spawn_delay_timer_seconds = 0.0
	_objective_active = true
	_objective_completed = false
	_hide_shard()
	_spawn_next_shard()
	DebugLog.info(
		&"ShardObjective", "started level=%d required=%d" % [_level_index, _required_shards]
	)


func clear_objective() -> void:
	_objective_active = false
	_objective_completed = false
	_required_shards = 0
	_collected_shards = 0
	_current_risk_tier = 0
	_spawn_delay_timer_seconds = 0.0
	_hide_shard()


func force_collect_current_shard_for_tests() -> void:
	if _shard_active:
		_collect_current_shard()


func get_required_shards() -> int:
	return _required_shards


func get_collected_shards() -> int:
	return _collected_shards


func get_current_risk_tier() -> int:
	return _current_risk_tier


func has_active_shard() -> bool:
	return _shard_active


func is_objective_completed() -> bool:
	return _objective_completed


func get_current_shard_position() -> Vector3:
	return _current_shard_position


func get_objective_intensity_bonus() -> float:
	if objective_config == null:
		return 0.0
	return float(_collected_shards) * objective_config.intensity_bonus_per_collected_shard


func _connect_run_controller() -> void:
	if _run_controller == null:
		return
	_run_controller.run_died.connect(_on_run_died)
	_run_controller.run_restarted.connect(_on_run_restarted)


func _on_run_died(_reason: StringName) -> void:
	clear_objective()


func _on_run_restarted() -> void:
	clear_objective()


func _create_visual() -> void:
	if shard_scene != null:
		_visual = shard_scene.instantiate() as Node3D
	else:
		_visual = _create_fallback_visual()

	_visual.name = "ActiveShard"
	add_child(_visual)


func _create_fallback_visual() -> Node3D:
	var root := Node3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.88, 0.95, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.18, 0.88, 0.95, 1.0)
	material.emission_energy_multiplier = 1.3

	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.25
	mesh.radial_segments = 6
	mesh.rings = 4
	mesh.material = material

	var instance := MeshInstance3D.new()
	instance.name = "VisualRoot"
	instance.mesh = mesh
	root.add_child(instance)
	return root


func _update_active_shard() -> void:
	if _player == null:
		return
	if (
		_get_horizontal_distance(_player.global_position, _current_shard_position)
		<= (objective_config.pickup_radius_meters)
	):
		_collect_current_shard()
		return

	_animate_visual()


func _collect_current_shard() -> void:
	if not _shard_active:
		return

	_collected_shards = mini(_collected_shards + 1, _required_shards)
	_current_risk_tier = _collected_shards * objective_config.risk_tier_per_collected_shard
	_hide_shard()
	shard_collected.emit(_collected_shards, _required_shards, _current_risk_tier)
	DebugLog.info(
		&"ShardObjective",
		"collected=%d/%d risk=%d" % [_collected_shards, _required_shards, _current_risk_tier]
	)

	if _collected_shards >= _required_shards:
		_objective_completed = true
		_objective_active = false
		objective_completed.emit(_required_shards)
		return

	_spawn_delay_timer_seconds = objective_config.spawn_delay_after_collect_seconds


func _spawn_next_shard() -> bool:
	if _arena == null or _player == null or objective_config == null:
		return false

	for attempt in range(objective_config.spawn_search_attempts):
		var candidate := _arena.get_random_valid_position(_rng)
		if _is_valid_shard_position(candidate):
			_show_shard_at(candidate)
			return true

	_spawn_delay_timer_seconds = 0.25
	return false


func _is_valid_shard_position(candidate_position: Vector3) -> bool:
	if _arena == null:
		return false

	var horizontal := Vector2(candidate_position.x, candidate_position.z)
	if horizontal.length() < objective_config.center_safe_radius_meters:
		return false
	if (
		_get_horizontal_distance(candidate_position, _player.global_position)
		< (objective_config.min_distance_from_player_meters)
	):
		return false

	var cell := _arena.get_cell_at_position(candidate_position)
	return cell != null and cell.state == ArenaCell.ArenaCellState.NORMAL


func _show_shard_at(ground_position: Vector3) -> void:
	_current_shard_position = (
		ground_position + Vector3.UP * objective_config.visual_height_offset_meters
	)
	_shard_active = true
	if _visual != null:
		_visual.global_position = _current_shard_position
		_visual.visible = true
	shard_spawned.emit(
		_collected_shards + 1, _required_shards, _current_shard_position, _current_risk_tier
	)
	DebugLog.info(
		&"ShardObjective",
		(
			"spawned shard=%d/%d pos=%s"
			% [_collected_shards + 1, _required_shards, _current_shard_position]
		)
	)


func _hide_shard() -> void:
	_shard_active = false
	if _visual != null:
		_visual.visible = false


func _animate_visual() -> void:
	if _visual == null:
		return
	var time := Time.get_ticks_msec() / 1000.0
	var pulse := 1.0 + sin(time * TAU * 1.8) * 0.065
	_visual.scale = Vector3.ONE * pulse
	_visual.rotation.y += get_physics_process_delta_time() * 1.75


func _get_horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x, first.z).distance_to(Vector2(second.x, second.z))
