extends GutTest


func test_damage_profile_defaults_are_valid() -> void:
	var profile := DamageProfile.new()
	var config := HealthConfig.new()

	assert_true(profile.is_valid_profile())
	assert_gt(profile.amount, 0.0)
	assert_eq(profile.damage_type, DamageProfile.DamageType.GENERIC)
	assert_false(profile.death_reason.is_empty())
	assert_false(profile.hit_label.is_empty())
	assert_true(config.is_valid_config())
	assert_gt(config.max_health, 0.0)
	assert_gte(config.hit_invulnerability_seconds, 0.0)


func test_health_starts_full_and_clamps_damage_and_heal() -> void:
	var health := _create_health_component(100.0, 0.0)
	add_child(health)
	await get_tree().process_frame

	assert_almost_eq(health.get_current_health(), 100.0, 0.001)

	var damage := _create_damage_profile(35.0)
	assert_almost_eq(health.apply_damage(damage), 35.0, 0.001)
	assert_almost_eq(health.get_current_health(), 65.0, 0.001)
	assert_almost_eq(health.heal(20.0), 20.0, 0.001)
	assert_almost_eq(health.get_current_health(), 85.0, 0.001)
	assert_almost_eq(health.heal(100.0), 15.0, 0.001)
	assert_almost_eq(health.get_current_health(), 100.0, 0.001)

	remove_child(health)
	health.free()


func test_health_depleted_emits_once_and_blocks_later_damage() -> void:
	var health := _create_health_component(50.0, 0.0)
	var depletion_state := {
		"count": 0,
		"reason": &"",
	}
	health.depleted.connect(
		func(reason: StringName) -> void:
			depletion_state["count"] = int(depletion_state["count"]) + 1
			depletion_state["reason"] = reason
	)
	add_child(health)
	await get_tree().process_frame

	var damage := _create_damage_profile(75.0, DamageProfile.DamageType.EXPLOSIVE, &"boom")
	assert_almost_eq(health.apply_damage(damage), 75.0, 0.001)
	assert_almost_eq(health.get_current_health(), 0.0, 0.001)
	assert_false(health.is_alive())
	assert_eq(depletion_state["count"], 1)
	assert_eq(depletion_state["reason"], &"boom")

	assert_almost_eq(health.apply_damage(damage), 0.0, 0.001)
	assert_eq(depletion_state["count"], 1)

	remove_child(health)
	health.free()


func test_hit_invulnerability_blocks_rapid_hits_unless_ignored() -> void:
	var health := _create_health_component(100.0, 0.25)
	add_child(health)
	await get_tree().process_frame

	var damage := _create_damage_profile(20.0)
	assert_almost_eq(health.apply_damage(damage), 20.0, 0.001)
	assert_almost_eq(health.apply_damage(damage), 0.0, 0.001)
	assert_almost_eq(health.get_current_health(), 80.0, 0.001)

	var piercing_damage := _create_damage_profile(15.0)
	piercing_damage.ignores_invulnerability = true
	assert_almost_eq(health.apply_damage(piercing_damage), 15.0, 0.001)
	assert_almost_eq(health.get_current_health(), 65.0, 0.001)

	health.step_component_for_tests(0.25)
	assert_almost_eq(health.apply_damage(damage), 20.0, 0.001)
	assert_almost_eq(health.get_current_health(), 45.0, 0.001)

	remove_child(health)
	health.free()


func test_many_damage_attempts_do_not_create_runtime_nodes() -> void:
	var health := _create_health_component(100.0, 0.25)
	add_child(health)
	await get_tree().process_frame

	var initial_node_count := health.get_child_count()
	var damage := _create_damage_profile(1.0)
	for hit_index in range(1000):
		health.apply_damage(damage)

	assert_eq(health.get_child_count(), initial_node_count)
	assert_almost_eq(health.get_current_health(), 99.0, 0.001)
	assert_almost_eq(health.get_last_damage_amount(), 1.0, 0.001)

	remove_child(health)
	health.free()


func _create_health_component(max_health: float, invulnerability_seconds: float) -> HealthComponent:
	var config := HealthConfig.new()
	config.max_health = max_health
	config.hit_invulnerability_seconds = invulnerability_seconds

	var health := HealthComponent.new()
	health.health_config = config
	return health


func _create_damage_profile(
	amount: float,
	damage_type: DamageProfile.DamageType = DamageProfile.DamageType.GENERIC,
	death_reason: StringName = &"damage"
) -> DamageProfile:
	var profile := DamageProfile.new()
	profile.amount = amount
	profile.damage_type = damage_type
	profile.death_reason = death_reason
	profile.hit_label = &"Test"
	return profile
