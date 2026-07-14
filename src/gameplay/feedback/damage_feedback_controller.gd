class_name DamageFeedbackController
extends Node

@export var feedback_config: DamageFeedbackConfig = DamageFeedbackConfig.new()
@export var health_component_path: NodePath
@export var camera_rig_path: NodePath
@export var health_hud_path: NodePath

var _health_component: HealthComponent
var _camera_rig: ThirdPersonCameraRig
var _health_hud: HealthHud
var _last_feedback_damage_type: DamageProfile.DamageType = DamageProfile.DamageType.GENERIC
var _last_feedback_strength: float = 0.0


func _ready() -> void:
	_health_component = get_node_or_null(health_component_path) as HealthComponent
	_camera_rig = get_node_or_null(camera_rig_path) as ThirdPersonCameraRig
	_health_hud = get_node_or_null(health_hud_path) as HealthHud

	if _health_component == null:
		DebugLog.warn(&"DamageFeedback", "missing health component path")
		return

	_health_component.damaged.connect(_on_damaged)


func get_last_feedback_damage_type_name() -> String:
	return DamageProfile.DamageType.keys()[_last_feedback_damage_type]


func get_last_feedback_strength() -> float:
	return _last_feedback_strength


func _on_damaged(profile: DamageProfile, applied_amount: float) -> void:
	if profile == null or feedback_config == null or not feedback_config.is_valid_config():
		return
	if applied_amount < feedback_config.minimum_damage_for_feedback:
		return

	var strength := _calculate_feedback_strength(applied_amount)
	_last_feedback_damage_type = profile.damage_type
	_last_feedback_strength = strength

	if _camera_rig != null:
		_camera_rig.request_shake(
			feedback_config.get_shake_for_damage_type(profile.damage_type), strength
		)

	if _health_hud != null:
		_health_hud.request_flash(
			feedback_config.health_flash_color, feedback_config.health_flash_duration_seconds
		)

	DebugLog.info(
		&"DamageFeedback",
		(
			"triggered type=%s strength=%.2f"
			% [DamageProfile.DamageType.keys()[profile.damage_type], strength]
		)
	)


func _calculate_feedback_strength(applied_amount: float) -> float:
	var raw_strength := applied_amount / feedback_config.reference_damage_amount
	return clampf(
		raw_strength,
		feedback_config.min_strength_multiplier,
		feedback_config.max_strength_multiplier
	)
