class_name PlayerHurtboxConfig
extends Resource

@export var radius_meters: float = 0.34
@export var height_meters: float = 1.7
@export var center_offset: Vector3 = Vector3.ZERO


func is_valid_config() -> bool:
	return radius_meters > 0.0 and height_meters >= radius_meters * 2.0


func get_capsule_segment_half_length() -> float:
	return maxf((height_meters * 0.5) - radius_meters, 0.0)
