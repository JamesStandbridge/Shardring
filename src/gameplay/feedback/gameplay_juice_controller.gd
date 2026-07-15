class_name GameplayJuiceController
extends Node

@export var chaser_enemy_system_path: NodePath
@export var projectile_system_path: NodePath
@export var shard_objective_path: NodePath
@export var camera_rig_path: NodePath
@export var health_hud_path: NodePath
@export var near_miss_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var shard_collect_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var exit_ready_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var dodge_callout_color: Color = Color(1.0, 0.58, 0.08, 1.0)
@export var shard_callout_color: Color = Color(0.24, 0.92, 1.0, 1.0)
@export var exit_callout_color: Color = Color(0.28, 1.0, 0.48, 1.0)
@export var dodge_callout_seconds: float = 0.38
@export var shard_callout_seconds: float = 0.42
@export var exit_callout_seconds: float = 0.75

var _chaser_enemy_system: ChaserEnemySystem
var _projectile_system: ProjectileSystem
var _shard_objective: ShardObjectiveController
var _camera_rig: ThirdPersonCameraRig
var _health_hud: HealthHud
var _last_event_name: StringName = &""
var _last_event_strength: float = 0.0


func _ready() -> void:
	_apply_default_shakes()
	_chaser_enemy_system = get_node_or_null(chaser_enemy_system_path) as ChaserEnemySystem
	_projectile_system = get_node_or_null(projectile_system_path) as ProjectileSystem
	_shard_objective = get_node_or_null(shard_objective_path) as ShardObjectiveController
	_camera_rig = get_node_or_null(camera_rig_path) as ThirdPersonCameraRig
	_health_hud = get_node_or_null(health_hud_path) as HealthHud
	_connect_sources()


func get_last_event_name() -> StringName:
	return _last_event_name


func get_last_event_strength() -> float:
	return _last_event_strength


func _connect_sources() -> void:
	if _chaser_enemy_system != null:
		_chaser_enemy_system.chaser_near_missed.connect(_on_chaser_near_missed)
	if _projectile_system != null:
		_projectile_system.projectile_near_missed.connect(_on_projectile_near_missed)
	if _shard_objective != null:
		_shard_objective.shard_collected.connect(_on_shard_collected)
		_shard_objective.objective_completed.connect(_on_objective_completed)


func _on_chaser_near_missed(_position: Vector3, _distance: float, strength: float) -> void:
	_trigger_juice(
		&"chaser_near_miss",
		"DODGE",
		dodge_callout_color,
		dodge_callout_seconds,
		near_miss_shake,
		strength
	)


func _on_projectile_near_missed(_position: Vector3, _distance: float, strength: float) -> void:
	_trigger_juice(
		&"projectile_near_miss",
		"DODGE",
		dodge_callout_color,
		dodge_callout_seconds,
		near_miss_shake,
		strength
	)


func _on_shard_collected(_collected: int, _required: int, _risk_tier: int) -> void:
	_trigger_juice(
		&"shard_collected",
		"SHARD",
		shard_callout_color,
		shard_callout_seconds,
		shard_collect_shake,
		0.75
	)


func _on_objective_completed(_required: int) -> void:
	_trigger_juice(
		&"objective_completed",
		"EXIT READY",
		exit_callout_color,
		exit_callout_seconds,
		exit_ready_shake,
		1.0
	)


func _trigger_juice(
	event_name: StringName,
	callout_text: String,
	callout_color: Color,
	callout_seconds: float,
	shake_config: CameraShakeConfig,
	strength: float
) -> void:
	var safe_strength := clampf(strength, 0.0, 1.35)
	_last_event_name = event_name
	_last_event_strength = safe_strength

	if _camera_rig != null:
		_camera_rig.request_shake(shake_config, safe_strength)
	if _health_hud != null:
		_health_hud.request_callout(callout_text, callout_color, callout_seconds)


func _apply_default_shakes() -> void:
	if near_miss_shake == null:
		near_miss_shake = CameraShakeConfig.new()
	near_miss_shake.duration_seconds = 0.13
	near_miss_shake.amplitude_meters = 0.075
	near_miss_shake.angular_amplitude_degrees = 0.42
	near_miss_shake.frequency_hz = 26.0
	near_miss_shake.decay_power = 1.7
	near_miss_shake.vertical_axis_ratio = 0.45

	if shard_collect_shake == null:
		shard_collect_shake = CameraShakeConfig.new()
	shard_collect_shake.duration_seconds = 0.16
	shard_collect_shake.amplitude_meters = 0.045
	shard_collect_shake.angular_amplitude_degrees = 0.25
	shard_collect_shake.frequency_hz = 19.0
	shard_collect_shake.decay_power = 1.55
	shard_collect_shake.vertical_axis_ratio = 0.8

	if exit_ready_shake == null:
		exit_ready_shake = CameraShakeConfig.new()
	exit_ready_shake.duration_seconds = 0.24
	exit_ready_shake.amplitude_meters = 0.08
	exit_ready_shake.angular_amplitude_degrees = 0.55
	exit_ready_shake.frequency_hz = 15.0
	exit_ready_shake.decay_power = 1.45
	exit_ready_shake.vertical_axis_ratio = 0.7
