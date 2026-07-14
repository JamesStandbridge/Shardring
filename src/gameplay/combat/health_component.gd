class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal damaged(profile: DamageProfile, applied_amount: float)
signal depleted(reason: StringName)

@export var health_config: HealthConfig = HealthConfig.new()

var _current_health: float = 100.0
var _invulnerability_timer_seconds: float = 0.0
var _alive: bool = true
var _last_damage_type: DamageProfile.DamageType = DamageProfile.DamageType.GENERIC
var _last_damage_amount: float = 0.0
var _last_damage_reason: StringName = &""
var _resistance_multipliers: Array[float] = []


func _ready() -> void:
	_initialize_resistances()
	reset_to_full()


func _physics_process(delta: float) -> void:
	step_component_for_tests(delta)


func step_component_for_tests(delta: float) -> void:
	_invulnerability_timer_seconds = maxf(_invulnerability_timer_seconds - delta, 0.0)


func apply_damage(profile: DamageProfile, _source_position: Vector3 = Vector3.ZERO) -> float:
	if profile == null or not profile.is_valid_profile():
		return 0.0
	if not _alive:
		return 0.0
	if _is_invulnerable() and not profile.ignores_invulnerability:
		return 0.0

	var applied_amount := _calculate_applied_damage(profile)
	if applied_amount <= 0.0:
		return 0.0

	_current_health = maxf(_current_health - applied_amount, 0.0)
	_last_damage_type = profile.damage_type
	_last_damage_amount = applied_amount
	_last_damage_reason = profile.death_reason
	_invulnerability_timer_seconds = health_config.hit_invulnerability_seconds
	damaged.emit(profile, applied_amount)
	health_changed.emit(_current_health, health_config.max_health)
	(
		DebugLog
		. info(
			&"Health",
			(
				"damage type=%s amount=%.2f hp=%.2f/%.2f"
				% [
					DamageProfile.DamageType.keys()[profile.damage_type],
					applied_amount,
					_current_health,
					health_config.max_health,
				]
			)
		)
	)

	if is_zero_approx(_current_health):
		_alive = false
		depleted.emit(profile.death_reason)

	return applied_amount


func heal(amount: float) -> float:
	if amount <= 0.0 or not _alive:
		return 0.0

	var previous_health := _current_health
	_current_health = minf(_current_health + amount, health_config.max_health)
	var healed_amount := _current_health - previous_health
	if healed_amount > 0.0:
		health_changed.emit(_current_health, health_config.max_health)
	return healed_amount


func reset_to_full() -> void:
	_alive = true
	_current_health = health_config.max_health
	_invulnerability_timer_seconds = 0.0
	_last_damage_amount = 0.0
	_last_damage_reason = &""
	_last_damage_type = DamageProfile.DamageType.GENERIC
	health_changed.emit(_current_health, health_config.max_health)
	DebugLog.info(&"Health", "reset hp=%.2f" % _current_health)


func is_alive() -> bool:
	return _alive


func get_current_health() -> float:
	return _current_health


func get_max_health() -> float:
	return health_config.max_health


func get_health_ratio() -> float:
	if health_config.max_health <= 0.0:
		return 0.0
	return clampf(_current_health / health_config.max_health, 0.0, 1.0)


func get_invulnerability_seconds() -> float:
	return _invulnerability_timer_seconds


func get_last_damage_type() -> DamageProfile.DamageType:
	return _last_damage_type


func get_last_damage_type_name() -> String:
	return DamageProfile.DamageType.keys()[_last_damage_type]


func get_last_damage_amount() -> float:
	return _last_damage_amount


func get_last_damage_reason() -> StringName:
	return _last_damage_reason


func _initialize_resistances() -> void:
	_resistance_multipliers.resize(DamageProfile.DamageType.keys().size())
	for damage_type_index in range(_resistance_multipliers.size()):
		_resistance_multipliers[damage_type_index] = 1.0


func _calculate_applied_damage(profile: DamageProfile) -> float:
	var multiplier := 1.0
	var damage_type_index := int(profile.damage_type)
	if damage_type_index >= 0 and damage_type_index < _resistance_multipliers.size():
		multiplier = _resistance_multipliers[damage_type_index]
	return maxf(profile.amount * multiplier, 0.0)


func _is_invulnerable() -> bool:
	return _invulnerability_timer_seconds > 0.0
