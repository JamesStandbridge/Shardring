class_name DangerDefinition
extends Resource

enum DangerFamily {
	PROJECTILE_LAUNCHER,
	ACTOR_ENEMY,
	BALLISTIC_ATTACK,
	SKY_ATTACK,
	TERRAIN_HAZARD,
	SPECIAL_EVENT,
}

@export var danger_id: StringName = &"basic_projectile"
@export var family: DangerFamily = DangerFamily.PROJECTILE_LAUNCHER
@export var spawn_cost: float = 1.0
@export var selection_weight: float = 1.0
@export var cooldown_seconds: float = 2.75
@export var minimum_intensity: float = 1.0
@export var max_active_instances: int = 1
@export var readability_tags: PackedStringArray = PackedStringArray(["telegraphed", "directional"])
@export var specialized_config: Resource


func is_valid_definition() -> bool:
	return (
		not str(danger_id).is_empty()
		and spawn_cost > 0.0
		and selection_weight > 0.0
		and cooldown_seconds >= 0.0
		and minimum_intensity >= 0.0
		and max_active_instances > 0
	)


func can_unlock_at_intensity(intensity: float) -> bool:
	return intensity >= minimum_intensity
