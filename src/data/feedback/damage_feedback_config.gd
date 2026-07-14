class_name DamageFeedbackConfig
extends Resource

@export var generic_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var projectile_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var explosive_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var fire_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var laser_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var terrain_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var contact_shake: CameraShakeConfig = CameraShakeConfig.new()
@export var health_flash_color: Color = Color(1.0, 0.12, 0.06, 0.45)
@export var health_flash_duration_seconds: float = 0.16
@export var reference_damage_amount: float = 50.0
@export var min_strength_multiplier: float = 0.35
@export var max_strength_multiplier: float = 1.35
@export var minimum_damage_for_feedback: float = 0.01


func is_valid_config() -> bool:
	return (
		generic_shake != null
		and generic_shake.is_valid_config()
		and projectile_shake != null
		and projectile_shake.is_valid_config()
		and explosive_shake != null
		and explosive_shake.is_valid_config()
		and fire_shake != null
		and fire_shake.is_valid_config()
		and laser_shake != null
		and laser_shake.is_valid_config()
		and terrain_shake != null
		and terrain_shake.is_valid_config()
		and contact_shake != null
		and contact_shake.is_valid_config()
		and health_flash_duration_seconds > 0.0
		and reference_damage_amount > 0.0
		and min_strength_multiplier >= 0.0
		and max_strength_multiplier >= min_strength_multiplier
		and minimum_damage_for_feedback >= 0.0
	)


func get_shake_for_damage_type(damage_type: DamageProfile.DamageType) -> CameraShakeConfig:
	var shake_config := generic_shake
	match damage_type:
		DamageProfile.DamageType.PROJECTILE:
			shake_config = projectile_shake
		DamageProfile.DamageType.EXPLOSIVE:
			shake_config = explosive_shake
		DamageProfile.DamageType.FIRE:
			shake_config = fire_shake
		DamageProfile.DamageType.LASER:
			shake_config = laser_shake
		DamageProfile.DamageType.TERRAIN:
			shake_config = terrain_shake
		DamageProfile.DamageType.CONTACT:
			shake_config = contact_shake

	return shake_config
