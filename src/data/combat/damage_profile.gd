class_name DamageProfile
extends Resource

enum DamageType {
	GENERIC,
	PROJECTILE,
	EXPLOSIVE,
	FIRE,
	LASER,
	TERRAIN,
	CONTACT,
}

@export var amount: float = 10.0
@export var damage_type: DamageType = DamageType.GENERIC
@export var death_reason: StringName = &"damage"
@export var hit_label: StringName = &"Damage"
@export var ignores_invulnerability: bool = false


func is_valid_profile() -> bool:
	return amount > 0.0 and not death_reason.is_empty() and not hit_label.is_empty()
