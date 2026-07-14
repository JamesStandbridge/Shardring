class_name HealthConfig
extends Resource

@export var max_health: float = 100.0
@export var hit_invulnerability_seconds: float = 0.25


func is_valid_config() -> bool:
	return max_health > 0.0 and hit_invulnerability_seconds >= 0.0
