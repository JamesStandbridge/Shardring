class_name ChaserEnemySystem
extends Node3D

signal actor_enemy_resolved(family: DangerDefinition.DangerFamily, resolution_reason: StringName)
signal chaser_dash_started(position: Vector3)
signal chaser_near_missed(position: Vector3, distance: float, strength: float)

enum ChaserState {
	INACTIVE,
	CHASING,
	WINDUP,
	DASHING,
	RECOVERING,
	PRIMING,
	EXPLODING,
}

const TERRAIN_COLLISION_MASK := 1 << 1
const DANGER_COLLISION_LAYER := 1 << 2
const DEBUG_SKIP_LOG_INTERVAL := 20

@export var chaser_config: ExplosiveChaserConfig = ExplosiveChaserConfig.new()
@export var run_controller_path: NodePath
@export var arena_path: NodePath
@export var player_path: NodePath
@export var health_component_path: NodePath
@export var placement_service_path: NodePath
@export var generation_seed: int = 7331

var _run_controller: RunController
var _arena: ArenaController
var _player: PlayerController
var _health_component: HealthComponent
var _placement_service: DangerPlacementService
var _rng := RandomNumberGenerator.new()
var _enemy_bodies: Array[CharacterBody3D] = []
var _enemy_meshes: Array[MeshInstance3D] = []
var _explosion_meshes: Array[MeshInstance3D] = []
var _enemy_materials: Array[StandardMaterial3D] = []
var _explosion_materials: Array[StandardMaterial3D] = []
var _enemy_active: Array[bool] = []
var _enemy_states: Array[int] = []
var _enemy_timers: Array[float] = []
var _enemy_lifetimes: Array[float] = []
var _enemy_animation_phases: Array[float] = []
var _enemy_spawn_timers: Array[float] = []
var _enemy_weave_signs: Array[float] = []
var _enemy_visual_base_scales: Array[Vector3] = []
var _enemy_dash_directions: Array[Vector3] = []
var _enemy_dash_targets: Array[Vector3] = []
var _enemy_dash_cooldowns: Array[float] = []
var _enemy_near_miss_emitted: Array[bool] = []
var _skipped_spawn_count: int = 0
var _last_logged_skip_count: int = 0
var _triggered_explosion_count: int = 0


func _ready() -> void:
	_rng.seed = generation_seed
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_health_component = get_node_or_null(health_component_path) as HealthComponent
	_placement_service = get_node_or_null(placement_service_path) as DangerPlacementService
	_initialize_pool()
	_connect_run_controller()
	DebugLog.info(
		&"ChaserEnemies", "ready capacity=%d seed=%d" % [_enemy_bodies.size(), generation_seed]
	)


func _physics_process(delta: float) -> void:
	if not _is_run_playing():
		return
	_update_enemies(delta)


func supports_danger_family(family: DangerDefinition.DangerFamily) -> bool:
	return family == DangerDefinition.DangerFamily.ACTOR_ENEMY


func request_spawn_danger(definition: DangerDefinition) -> bool:
	if definition == null or not supports_danger_family(definition.family):
		return false

	var requested_config := definition.specialized_config as ExplosiveChaserConfig
	if requested_config == null:
		return false

	chaser_config = requested_config
	return spawn_enemy_near_arena(definition.placement_rules)


func get_active_danger_count(definition: DangerDefinition) -> int:
	if definition == null or not supports_danger_family(definition.family):
		return 0
	return get_active_enemy_count()


func get_total_active_danger_count() -> int:
	return get_active_enemy_count()


func get_active_readability_pressure() -> int:
	return get_windup_enemy_count() + get_priming_enemy_count() + get_exploding_enemy_count()


func get_active_enemy_count() -> int:
	var count := 0
	for is_active: bool in _enemy_active:
		if is_active:
			count += 1
	return count


func get_priming_enemy_count() -> int:
	var count := 0
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index] and _enemy_states[enemy_index] == ChaserState.PRIMING:
			count += 1
	return count


func get_windup_enemy_count() -> int:
	var count := 0
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index] and _enemy_states[enemy_index] == ChaserState.WINDUP:
			count += 1
	return count


func get_dashing_enemy_count() -> int:
	var count := 0
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index] and _enemy_states[enemy_index] == ChaserState.DASHING:
			count += 1
	return count


func get_exploding_enemy_count() -> int:
	var count := 0
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index] and _enemy_states[enemy_index] == ChaserState.EXPLODING:
			count += 1
	return count


func get_triggered_explosion_count() -> int:
	return _triggered_explosion_count


func get_skipped_spawn_count() -> int:
	return _skipped_spawn_count


func _get_runtime_node_count_for_tests() -> int:
	return get_child_count()


func get_first_active_enemy_position() -> Vector3:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _enemy_bodies[enemy_index].global_position
	return Vector3.ZERO


func _get_first_active_enemy_horizontal_speed_for_tests() -> float:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			var velocity := _enemy_bodies[enemy_index].velocity
			return Vector2(velocity.x, velocity.z).length()
	return 0.0


func get_first_active_enemy_state() -> int:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _enemy_states[enemy_index]
	return ChaserState.INACTIVE


func _get_first_active_enemy_forward_direction_for_tests() -> Vector3:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _get_enemy_forward_direction(enemy_index)
	return Vector3.ZERO


func _get_first_active_enemy_visual_local_position_for_tests() -> Vector3:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _enemy_meshes[enemy_index].position
	return Vector3.ZERO


func _get_first_active_enemy_visual_scale_for_tests() -> Vector3:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _enemy_meshes[enemy_index].scale
	return Vector3.ZERO


func _get_first_active_enemy_visual_local_rotation_for_tests() -> Vector3:
	for enemy_index in range(_enemy_active.size()):
		if _enemy_active[enemy_index]:
			return _enemy_meshes[enemy_index].rotation
	return Vector3.ZERO


func clear_all() -> void:
	for enemy_index in range(_enemy_active.size()):
		_deactivate_enemy(enemy_index)
	DebugLog.info(&"ChaserEnemies", "cleared")


func force_spawn_enemy_at(spawn_position: Vector3) -> bool:
	return _spawn_enemy(spawn_position)


func spawn_enemy_near_arena(placement_rules: DangerPlacementRules = null) -> bool:
	if _arena == null or _player == null:
		_increment_skipped_spawn()
		return false

	if _placement_service != null and placement_rules != null:
		var fair_position := _placement_service.get_random_fair_position(_rng, placement_rules)
		if not fair_position.is_finite():
			_increment_skipped_spawn()
			return false

		fair_position.y += chaser_config.spawn_height_offset_meters
		return _spawn_enemy(fair_position)

	var player_position := _player.global_position
	for attempt in range(maxi(chaser_config.spawn_search_attempts, 1)):
		var candidate := _arena.get_random_valid_position(_rng)
		candidate.y += chaser_config.spawn_height_offset_meters
		if (
			_get_horizontal_distance(candidate, player_position)
			< chaser_config.min_spawn_distance_from_player_meters
		):
			continue
		return _spawn_enemy(candidate)

	_increment_skipped_spawn()
	return false


func step_system_for_tests(delta: float) -> void:
	_update_enemies(delta)


func _initialize_pool() -> void:
	var capacity := maxi(chaser_config.max_active_enemies, 1)
	_enemy_bodies.resize(capacity)
	_enemy_meshes.resize(capacity)
	_explosion_meshes.resize(capacity)
	_enemy_materials.resize(capacity)
	_explosion_materials.resize(capacity)
	_enemy_active.resize(capacity)
	_enemy_states.resize(capacity)
	_enemy_timers.resize(capacity)
	_enemy_lifetimes.resize(capacity)
	_enemy_animation_phases.resize(capacity)
	_enemy_spawn_timers.resize(capacity)
	_enemy_weave_signs.resize(capacity)
	_enemy_visual_base_scales.resize(capacity)
	_enemy_dash_directions.resize(capacity)
	_enemy_dash_targets.resize(capacity)
	_enemy_dash_cooldowns.resize(capacity)
	_enemy_near_miss_emitted.resize(capacity)

	for enemy_index in range(capacity):
		var body := _create_enemy_body(enemy_index)
		_enemy_bodies[enemy_index] = body
		_enemy_active[enemy_index] = false
		_enemy_states[enemy_index] = ChaserState.INACTIVE
		_enemy_timers[enemy_index] = 0.0
		_enemy_lifetimes[enemy_index] = 0.0
		_enemy_animation_phases[enemy_index] = 0.0
		_enemy_spawn_timers[enemy_index] = 0.0
		_enemy_weave_signs[enemy_index] = 1.0 if enemy_index % 2 == 0 else -1.0
		_enemy_visual_base_scales[enemy_index] = Vector3.ONE
		_enemy_dash_directions[enemy_index] = Vector3.ZERO
		_enemy_dash_targets[enemy_index] = Vector3.ZERO
		_enemy_dash_cooldowns[enemy_index] = 0.0
		_enemy_near_miss_emitted[enemy_index] = false
		add_child(body)
		_deactivate_enemy(enemy_index)


func _create_enemy_body(enemy_index: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "Chaser%02d" % enemy_index
	body.collision_layer = DANGER_COLLISION_LAYER
	body.collision_mask = TERRAIN_COLLISION_MASK
	body.floor_snap_length = 0.35
	body.floor_stop_on_slope = true
	body.max_slides = 4

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = chaser_config.body_color
	body_material.emission_enabled = true
	body_material.emission = chaser_config.body_color
	body_material.emission_energy_multiplier = chaser_config.emission_energy
	_enemy_materials[enemy_index] = body_material

	var body_mesh := _extract_first_mesh_from_scene(chaser_config.body_scene)
	if body_mesh == null:
		var fallback_mesh := CapsuleMesh.new()
		fallback_mesh.radius = chaser_config.visual_radius_meters
		fallback_mesh.height = chaser_config.collision_height_meters
		body_mesh = fallback_mesh
	if body_mesh.get_surface_count() > 0:
		body_mesh.surface_set_material(0, body_material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Body"
	mesh_instance.mesh = body_mesh
	body.add_child(mesh_instance)
	_enemy_meshes[enemy_index] = mesh_instance

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "Collision"
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = chaser_config.collision_radius_meters
	capsule_shape.height = chaser_config.collision_height_meters
	collision_shape.shape = capsule_shape
	body.add_child(collision_shape)

	var explosion_material := StandardMaterial3D.new()
	explosion_material.albedo_color = chaser_config.explosion_color
	explosion_material.emission_enabled = true
	explosion_material.emission = chaser_config.explosion_color
	explosion_material.emission_energy_multiplier = chaser_config.emission_energy
	explosion_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_explosion_materials[enemy_index] = explosion_material

	var explosion_mesh := SphereMesh.new()
	explosion_mesh.radius = 1.0
	explosion_mesh.height = 2.0
	explosion_mesh.material = explosion_material

	var explosion_instance := MeshInstance3D.new()
	explosion_instance.name = "ExplosionPreview"
	explosion_instance.mesh = explosion_mesh
	explosion_instance.visible = false
	body.add_child(explosion_instance)
	_explosion_meshes[enemy_index] = explosion_instance

	return body


func _connect_run_controller() -> void:
	if _run_controller == null:
		if not run_controller_path.is_empty():
			DebugLog.warn(&"ChaserEnemies", "missing run controller path")
		return

	_run_controller.run_started.connect(_on_run_started)
	_run_controller.run_died.connect(_on_run_died)
	_run_controller.run_restarted.connect(_on_run_restarted)


func _on_run_started() -> void:
	clear_all()


func _on_run_died(_reason: StringName) -> void:
	clear_all()


func _on_run_restarted() -> void:
	clear_all()


func _is_run_playing() -> bool:
	return _run_controller != null and _run_controller.is_playing()


func _spawn_enemy(spawn_position: Vector3) -> bool:
	var enemy_index := _find_free_enemy_slot()
	if enemy_index == -1:
		_increment_skipped_spawn()
		return false

	var body := _enemy_bodies[enemy_index]
	body.global_position = spawn_position
	body.velocity = Vector3.ZERO
	body.visible = true
	_enemy_active[enemy_index] = true
	_enemy_states[enemy_index] = ChaserState.CHASING
	_enemy_timers[enemy_index] = 0.0
	_enemy_lifetimes[enemy_index] = chaser_config.lifetime_seconds
	_enemy_animation_phases[enemy_index] = 0.0
	_enemy_spawn_timers[enemy_index] = chaser_config.spawn_pop_duration_seconds
	_enemy_weave_signs[enemy_index] = 1.0 if enemy_index % 2 == 0 else -1.0
	_enemy_dash_directions[enemy_index] = Vector3.ZERO
	_enemy_dash_targets[enemy_index] = Vector3.ZERO
	_enemy_dash_cooldowns[enemy_index] = 0.0
	_enemy_near_miss_emitted[enemy_index] = false
	_face_player(enemy_index, 0.0, true)
	_set_body_visual(enemy_index, chaser_config.body_color, Vector3.ONE)
	_explosion_meshes[enemy_index].visible = false
	DebugLog.info(&"ChaserEnemies", "spawned index=%d pos=%s" % [enemy_index, spawn_position])
	return true


func _update_enemies(delta: float) -> void:
	for enemy_index in range(_enemy_active.size()):
		if not _enemy_active[enemy_index]:
			continue

		_enemy_lifetimes[enemy_index] -= delta
		_enemy_dash_cooldowns[enemy_index] = maxf(_enemy_dash_cooldowns[enemy_index] - delta, 0.0)
		_enemy_spawn_timers[enemy_index] = maxf(_enemy_spawn_timers[enemy_index] - delta, 0.0)
		if (
			_enemy_lifetimes[enemy_index] <= 0.0
			and _enemy_states[enemy_index] != ChaserState.EXPLODING
		):
			_trigger_explosion(enemy_index)
			continue

		match _enemy_states[enemy_index]:
			ChaserState.CHASING:
				_update_chasing_enemy(enemy_index, delta)
			ChaserState.WINDUP:
				_update_windup_enemy(enemy_index, delta)
			ChaserState.DASHING:
				_update_dashing_enemy(enemy_index, delta)
			ChaserState.RECOVERING:
				_update_recovering_enemy(enemy_index, delta)
			ChaserState.PRIMING:
				_update_priming_enemy(enemy_index, delta)
			ChaserState.EXPLODING:
				_update_exploding_enemy(enemy_index, delta)
			ChaserState.INACTIVE:
				_deactivate_enemy(enemy_index)


func _update_chasing_enemy(enemy_index: int, delta: float) -> void:
	if _player == null:
		return

	var body := _enemy_bodies[enemy_index]
	var direction := _get_flat_direction_to_player(body.global_position)
	var distance_to_player := _get_horizontal_distance(
		body.global_position, _player.global_position
	)
	var excitement_ratio := _get_excitement_ratio(distance_to_player)
	var target_speed := lerpf(
		chaser_config.walk_speed_meters_per_second,
		chaser_config.chase_speed_meters_per_second,
		excitement_ratio
	)
	var target_velocity := _get_chase_target_velocity(
		enemy_index, direction, target_speed, excitement_ratio
	)
	var horizontal_velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)
	horizontal_velocity = horizontal_velocity.move_toward(
		target_velocity, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	body.velocity.x = horizontal_velocity.x
	body.velocity.z = horizontal_velocity.z
	_apply_gravity(body, delta)
	body.move_and_slide()
	_face_player(enemy_index, delta)
	_update_movement_animation(enemy_index, delta, excitement_ratio)

	var post_move_distance := _get_horizontal_distance(
		body.global_position, _player.global_position
	)
	if post_move_distance <= chaser_config.prime_trigger_radius_meters:
		_start_priming(enemy_index)
		return

	if _should_start_dash(enemy_index, post_move_distance):
		_start_windup(enemy_index)


func _update_windup_enemy(enemy_index: int, delta: float) -> void:
	var body := _enemy_bodies[enemy_index]
	body.velocity.x = move_toward(
		body.velocity.x, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	body.velocity.z = move_toward(
		body.velocity.z, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	_apply_gravity(body, delta)
	body.move_and_slide()
	_face_direction(enemy_index, _enemy_dash_directions[enemy_index], delta)

	_enemy_timers[enemy_index] -= delta
	var windup_progress := (
		1.0 - maxf(_enemy_timers[enemy_index], 0.0) / chaser_config.dash_windup_seconds
	)
	_update_windup_animation(enemy_index, delta, windup_progress)
	if _enemy_timers[enemy_index] <= 0.0:
		_start_dashing(enemy_index)


func _update_dashing_enemy(enemy_index: int, delta: float) -> void:
	var body := _enemy_bodies[enemy_index]
	body.velocity.x = (
		_enemy_dash_directions[enemy_index].x * chaser_config.dash_speed_meters_per_second
	)
	body.velocity.z = (
		_enemy_dash_directions[enemy_index].z * chaser_config.dash_speed_meters_per_second
	)
	_apply_gravity(body, delta)
	body.move_and_slide()
	_face_direction(enemy_index, _enemy_dash_directions[enemy_index], delta)
	_update_dash_animation(enemy_index, delta)

	if (
		_get_horizontal_distance(body.global_position, _player.global_position)
		<= chaser_config.prime_trigger_radius_meters
	):
		_start_priming(enemy_index)
		return

	_enemy_timers[enemy_index] -= delta
	if _enemy_timers[enemy_index] <= 0.0:
		_start_recovering(enemy_index)


func _update_recovering_enemy(enemy_index: int, delta: float) -> void:
	var body := _enemy_bodies[enemy_index]
	body.velocity.x = move_toward(
		body.velocity.x, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	body.velocity.z = move_toward(
		body.velocity.z, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	_apply_gravity(body, delta)
	body.move_and_slide()
	_face_player(enemy_index, delta)
	_update_recovery_animation(enemy_index, delta)

	if (
		_get_horizontal_distance(body.global_position, _player.global_position)
		<= chaser_config.prime_trigger_radius_meters
	):
		_start_priming(enemy_index)
		return

	_enemy_timers[enemy_index] -= delta
	if _enemy_timers[enemy_index] <= 0.0:
		_enemy_states[enemy_index] = ChaserState.CHASING


func _update_priming_enemy(enemy_index: int, delta: float) -> void:
	var body := _enemy_bodies[enemy_index]
	body.velocity.x = move_toward(
		body.velocity.x, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	body.velocity.z = move_toward(
		body.velocity.z, 0.0, chaser_config.chase_acceleration_meters_per_second_squared * delta
	)
	_apply_gravity(body, delta)
	body.move_and_slide()
	_face_player(enemy_index, delta)

	_enemy_timers[enemy_index] -= delta
	var charge_ratio := (
		1.0 - maxf(_enemy_timers[enemy_index], 0.0) / chaser_config.prime_duration_seconds
	)
	var charge_scale := lerpf(1.0, chaser_config.priming_scale_multiplier, charge_ratio)
	_set_body_visual(enemy_index, chaser_config.priming_color, Vector3.ONE * charge_scale)
	_update_priming_animation(enemy_index, delta, charge_ratio)
	if _enemy_timers[enemy_index] <= 0.0:
		_trigger_explosion(enemy_index)


func _update_exploding_enemy(enemy_index: int, delta: float) -> void:
	_enemy_timers[enemy_index] -= delta
	if _enemy_timers[enemy_index] <= 0.0:
		actor_enemy_resolved.emit(DangerDefinition.DangerFamily.ACTOR_ENEMY, &"exploded")
		_deactivate_enemy(enemy_index)


func _start_priming(enemy_index: int) -> void:
	if (
		_enemy_states[enemy_index] == ChaserState.INACTIVE
		or _enemy_states[enemy_index] == ChaserState.PRIMING
		or _enemy_states[enemy_index] == ChaserState.EXPLODING
	):
		return

	_enemy_states[enemy_index] = ChaserState.PRIMING
	_enemy_timers[enemy_index] = chaser_config.prime_duration_seconds
	_enemy_near_miss_emitted[enemy_index] = false
	_set_body_visual(enemy_index, chaser_config.priming_color, Vector3.ONE)


func _start_windup(enemy_index: int) -> void:
	if _player == null:
		return
	if _enemy_states[enemy_index] != ChaserState.CHASING:
		return

	var body := _enemy_bodies[enemy_index]
	_enemy_dash_targets[enemy_index] = _player.global_position
	_enemy_dash_directions[enemy_index] = _get_flat_direction_to_position(
		body.global_position, _enemy_dash_targets[enemy_index]
	)
	if _enemy_dash_directions[enemy_index].is_zero_approx():
		_enemy_dash_directions[enemy_index] = _get_enemy_forward_direction(enemy_index)

	_enemy_states[enemy_index] = ChaserState.WINDUP
	_enemy_timers[enemy_index] = chaser_config.dash_windup_seconds
	_set_body_visual(enemy_index, chaser_config.priming_color, Vector3.ONE)


func _start_dashing(enemy_index: int) -> void:
	_enemy_states[enemy_index] = ChaserState.DASHING
	_enemy_timers[enemy_index] = chaser_config.dash_duration_seconds
	_enemy_dash_cooldowns[enemy_index] = chaser_config.dash_cooldown_seconds
	chaser_dash_started.emit(_enemy_bodies[enemy_index].global_position)


func _start_recovering(enemy_index: int) -> void:
	_enemy_states[enemy_index] = ChaserState.RECOVERING
	_enemy_timers[enemy_index] = chaser_config.dash_recovery_seconds


func _trigger_explosion(enemy_index: int) -> void:
	_enemy_states[enemy_index] = ChaserState.EXPLODING
	_enemy_timers[enemy_index] = chaser_config.explosion_linger_seconds
	_triggered_explosion_count += 1
	_enemy_bodies[enemy_index].velocity = Vector3.ZERO
	_set_body_visual(enemy_index, chaser_config.explosion_color, Vector3.ONE * 0.35)
	_explosion_meshes[enemy_index].scale = Vector3.ONE * chaser_config.explosion_radius_meters
	_explosion_meshes[enemy_index].visible = true
	DebugLog.info(&"ChaserEnemies", "exploded index=%d" % enemy_index)

	var player_was_hit := _is_player_in_explosion_radius(enemy_index)
	if (
		chaser_config.damage_on_explosion
		and _player != null
		and _health_component != null
		and chaser_config.damage_profile != null
		and player_was_hit
	):
		_health_component.apply_damage(
			chaser_config.damage_profile, _enemy_bodies[enemy_index].global_position
		)
	elif not player_was_hit:
		_emit_near_miss_if_applicable(enemy_index)


func _deactivate_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_active.size():
		return

	_enemy_active[enemy_index] = false
	_enemy_states[enemy_index] = ChaserState.INACTIVE
	_enemy_timers[enemy_index] = 0.0
	_enemy_lifetimes[enemy_index] = 0.0
	_enemy_animation_phases[enemy_index] = 0.0
	_enemy_spawn_timers[enemy_index] = 0.0
	_enemy_visual_base_scales[enemy_index] = Vector3.ONE
	_enemy_dash_directions[enemy_index] = Vector3.ZERO
	_enemy_dash_targets[enemy_index] = Vector3.ZERO
	_enemy_dash_cooldowns[enemy_index] = 0.0
	_enemy_near_miss_emitted[enemy_index] = false
	if _enemy_bodies[enemy_index] != null:
		_enemy_bodies[enemy_index].velocity = Vector3.ZERO
		_enemy_bodies[enemy_index].visible = false
	if _enemy_meshes[enemy_index] != null:
		_apply_enemy_visual_pose(enemy_index, Vector3.ZERO, Vector3.ZERO, Vector3.ONE)
	if _explosion_meshes[enemy_index] != null:
		_explosion_meshes[enemy_index].visible = false


func _apply_gravity(body: CharacterBody3D, delta: float) -> void:
	if body.is_on_floor() and body.velocity.y < 0.0:
		body.velocity.y = 0.0
		return

	var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float
	body.velocity.y = maxf(
		body.velocity.y - gravity * chaser_config.gravity_multiplier * delta,
		-chaser_config.max_fall_speed_meters_per_second
	)


func _set_body_visual(enemy_index: int, color: Color, visual_scale: Vector3) -> void:
	_enemy_visual_base_scales[enemy_index] = visual_scale
	_apply_enemy_visual_pose(enemy_index, Vector3.ZERO, Vector3.ZERO, Vector3.ONE)
	_enemy_materials[enemy_index].albedo_color = color
	_enemy_materials[enemy_index].emission = color


func _update_movement_animation(enemy_index: int, delta: float, excitement_ratio: float) -> void:
	var frequency := lerpf(
		chaser_config.movement_bob_frequency_walk_hz,
		chaser_config.movement_bob_frequency_run_hz,
		excitement_ratio
	)
	_enemy_animation_phases[enemy_index] = fmod(
		_enemy_animation_phases[enemy_index] + delta * frequency * TAU, TAU
	)

	var phase := _enemy_animation_phases[enemy_index]
	var step_sine := sin(phase)
	var lift := absf(step_sine)
	var bob_height := chaser_config.movement_bob_height_meters * lerpf(0.65, 1.0, excitement_ratio)
	var roll := (
		deg_to_rad(chaser_config.movement_roll_degrees)
		* step_sine
		* lerpf(0.65, 1.25, excitement_ratio)
	)
	var pitch := (
		deg_to_rad(chaser_config.movement_roll_degrees * 0.35)
		* cos(phase)
		* lerpf(0.7, 1.35, excitement_ratio)
	)
	var excitement_scale := lerpf(
		1.0, chaser_config.run_excitement_scale_multiplier, excitement_ratio
	)
	var squash := 1.0 - 0.08 * lift * excitement_ratio
	var stretch := 1.0 + 0.12 * lift * excitement_ratio

	_apply_enemy_visual_pose(
		enemy_index,
		Vector3(0.0, lift * bob_height, 0.0),
		Vector3(pitch, 0.0, roll),
		Vector3(stretch, excitement_scale * squash, stretch)
	)


func _update_priming_animation(enemy_index: int, delta: float, charge_ratio: float) -> void:
	_enemy_animation_phases[enemy_index] = fmod(
		(
			_enemy_animation_phases[enemy_index]
			+ delta * chaser_config.movement_bob_frequency_run_hz * TAU
		),
		TAU
	)

	var phase := _enemy_animation_phases[enemy_index]
	var shake := sin(phase)
	var jitter := sin(phase * 2.7) * charge_ratio
	_apply_enemy_visual_pose(
		enemy_index,
		Vector3(0.0, absf(shake) * chaser_config.movement_bob_height_meters * charge_ratio, 0.0),
		Vector3(
			deg_to_rad(chaser_config.movement_roll_degrees * 0.35) * jitter,
			0.0,
			deg_to_rad(chaser_config.movement_roll_degrees * 1.65) * shake
		),
		Vector3(1.0 + 0.08 * charge_ratio, 1.0 - 0.05 * charge_ratio, 1.0 + 0.08 * charge_ratio)
	)


func _update_windup_animation(enemy_index: int, delta: float, windup_progress: float) -> void:
	_enemy_animation_phases[enemy_index] = fmod(
		(
			_enemy_animation_phases[enemy_index]
			+ delta * chaser_config.movement_bob_frequency_run_hz * TAU * 1.35
		),
		TAU
	)

	var phase := _enemy_animation_phases[enemy_index]
	var wobble := sin(phase) * clampf(windup_progress, 0.0, 1.0)
	var anticipation := clampf(windup_progress, 0.0, 1.0)
	_apply_enemy_visual_pose(
		enemy_index,
		Vector3(0.0, 0.03 * sin(phase * 2.0), -0.08 * anticipation),
		Vector3(
			deg_to_rad(chaser_config.movement_roll_degrees * 0.75) * wobble,
			0.0,
			deg_to_rad(chaser_config.movement_roll_degrees * 2.1) * wobble
		),
		Vector3(1.0 + 0.18 * anticipation, 1.0 - 0.13 * anticipation, 1.0 + 0.12 * anticipation)
	)


func _update_dash_animation(enemy_index: int, delta: float) -> void:
	_enemy_animation_phases[enemy_index] = fmod(
		(
			_enemy_animation_phases[enemy_index]
			+ delta * chaser_config.movement_bob_frequency_run_hz * TAU * 1.8
		),
		TAU
	)
	var phase := _enemy_animation_phases[enemy_index]
	_apply_enemy_visual_pose(
		enemy_index,
		Vector3(0.0, 0.08 + 0.03 * sin(phase), 0.0),
		Vector3(
			deg_to_rad(-8.0), 0.0, deg_to_rad(chaser_config.movement_roll_degrees) * sin(phase)
		),
		Vector3(0.88, 0.92, 1.42)
	)


func _update_recovery_animation(enemy_index: int, delta: float) -> void:
	_enemy_animation_phases[enemy_index] = fmod(
		(
			_enemy_animation_phases[enemy_index]
			+ delta * chaser_config.movement_bob_frequency_walk_hz * TAU
		),
		TAU
	)
	var bounce := absf(sin(_enemy_animation_phases[enemy_index]))
	_apply_enemy_visual_pose(
		enemy_index,
		Vector3(0.0, bounce * chaser_config.movement_bob_height_meters * 0.45, 0.0),
		Vector3(
			0.0,
			0.0,
			(
				deg_to_rad(chaser_config.movement_roll_degrees * 0.45)
				* sin(_enemy_animation_phases[enemy_index])
			)
		),
		Vector3(1.0 + 0.05 * bounce, 1.0 - 0.08 * bounce, 1.0 + 0.05 * bounce)
	)


func _apply_enemy_visual_pose(
	enemy_index: int, local_position: Vector3, local_rotation: Vector3, scale_multiplier: Vector3
) -> void:
	var mesh := _enemy_meshes[enemy_index]
	var spawn_ratio := _get_spawn_pop_ratio(enemy_index)
	var spawn_lift := sin(spawn_ratio * PI) * chaser_config.spawn_pop_height_meters
	var spawn_scale := lerpf(0.72, 1.0, clampf(spawn_ratio * 1.45, 0.0, 1.0))
	spawn_scale += sin(spawn_ratio * PI) * 0.08
	mesh.position = local_position + Vector3.UP * spawn_lift
	mesh.rotation = Vector3(
		local_rotation.x,
		local_rotation.y + deg_to_rad(chaser_config.visual_yaw_offset_degrees),
		local_rotation.z
	)
	mesh.scale = _enemy_visual_base_scales[enemy_index] * scale_multiplier * spawn_scale


func _face_player(enemy_index: int, delta: float, instant: bool = false) -> void:
	if _player == null:
		return
	var direction := _get_flat_direction_to_player(_enemy_bodies[enemy_index].global_position)
	_face_direction(enemy_index, direction, delta, instant)


func _face_direction(
	enemy_index: int, direction: Vector3, delta: float, instant: bool = false
) -> void:
	if direction.is_zero_approx():
		return
	if enemy_index < 0 or enemy_index >= _enemy_bodies.size():
		return

	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.is_zero_approx():
		return
	flat_direction = flat_direction.normalized()

	var body := _enemy_bodies[enemy_index]
	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	if instant or is_zero_approx(chaser_config.face_player_lerp_speed):
		body.rotation.y = target_yaw
		return

	var interpolation_weight := clampf(chaser_config.face_player_lerp_speed * delta, 0.0, 1.0)
	body.rotation.y = lerp_angle(body.rotation.y, target_yaw, interpolation_weight)


func _get_enemy_forward_direction(enemy_index: int) -> Vector3:
	if enemy_index < 0 or enemy_index >= _enemy_bodies.size():
		return Vector3.ZERO

	var forward := -_enemy_bodies[enemy_index].global_basis.z
	forward.y = 0.0
	if forward.is_zero_approx():
		return Vector3.ZERO
	return forward.normalized()


func _extract_first_mesh_from_scene(scene: PackedScene) -> Mesh:
	return MeshSceneExtractor.extract_first_mesh(scene)


func _is_player_in_explosion_radius(enemy_index: int) -> bool:
	var hurtbox_radius := 0.0
	if _player != null:
		hurtbox_radius = _player.get_hurtbox_radius()
	return (
		_get_horizontal_distance(
			_enemy_bodies[enemy_index].global_position, _player.global_position
		)
		<= chaser_config.explosion_radius_meters + hurtbox_radius
	)


func _emit_near_miss_if_applicable(enemy_index: int) -> void:
	if _enemy_near_miss_emitted[enemy_index]:
		return
	var enemy_position := _enemy_bodies[enemy_index].global_position
	var near_miss := NearMissMath.evaluate_horizontal_explosion(
		_player,
		enemy_position,
		chaser_config.explosion_radius_meters,
		chaser_config.near_miss_min_distance_from_damage_radius,
		chaser_config.near_miss_radius_meters
	)
	if near_miss.x < 0.0:
		return

	_enemy_near_miss_emitted[enemy_index] = true
	chaser_near_missed.emit(enemy_position, near_miss.x, near_miss.y)


func _get_flat_direction_to_player(origin: Vector3) -> Vector3:
	if _player == null:
		return Vector3.ZERO

	return _get_flat_direction_to_position(origin, _player.global_position)


func _get_flat_direction_to_position(origin: Vector3, target_position: Vector3) -> Vector3:
	var offset := target_position - origin
	offset.y = 0.0
	if offset.is_zero_approx():
		return Vector3.ZERO
	return offset.normalized()


func _get_chase_target_velocity(
	enemy_index: int, direction: Vector3, target_speed: float, excitement_ratio: float
) -> Vector3:
	var forward_velocity := direction * target_speed
	if chaser_config.weave_strength_meters_per_second <= 0.0 or direction.is_zero_approx():
		return forward_velocity

	var perpendicular := Vector3(-direction.z, 0.0, direction.x)
	var phase := (
		_enemy_animation_phases[enemy_index] * maxf(chaser_config.weave_frequency_hz, 0.0) * 0.5
	)
	var weave_ratio := sin(phase) * _enemy_weave_signs[enemy_index]
	var weave_speed := (
		chaser_config.weave_strength_meters_per_second
		* weave_ratio
		* lerpf(0.35, 1.0, excitement_ratio)
	)
	return forward_velocity + perpendicular * weave_speed


func _get_horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x, first.z).distance_to(Vector2(second.x, second.z))


func _get_excitement_ratio(distance_to_player: float) -> float:
	var trigger_radius := maxf(
		chaser_config.run_trigger_radius_meters, chaser_config.agitated_radius_meters
	)
	if distance_to_player > trigger_radius:
		return 0.0

	var ramp_distance := maxf(trigger_radius - chaser_config.prime_trigger_radius_meters, 0.001)
	var raw_ratio := clampf((trigger_radius - distance_to_player) / ramp_distance, 0.0, 1.0)
	var smoothed_ratio := raw_ratio * raw_ratio * (3.0 - 2.0 * raw_ratio)
	return pow(smoothed_ratio, chaser_config.excitement_ramp_exponent)


func _should_start_dash(enemy_index: int, distance_to_player: float) -> bool:
	return (
		chaser_config.dash_trigger_radius_meters > chaser_config.prime_trigger_radius_meters
		and distance_to_player <= chaser_config.dash_trigger_radius_meters
		and distance_to_player > chaser_config.prime_trigger_radius_meters
		and _enemy_dash_cooldowns[enemy_index] <= 0.0
	)


func _get_spawn_pop_ratio(enemy_index: int) -> float:
	if chaser_config.spawn_pop_duration_seconds <= 0.0:
		return 1.0

	var elapsed_ratio := (
		1.0 - _enemy_spawn_timers[enemy_index] / chaser_config.spawn_pop_duration_seconds
	)
	return clampf(elapsed_ratio, 0.0, 1.0)


func _find_free_enemy_slot() -> int:
	for enemy_index in range(_enemy_active.size()):
		if not _enemy_active[enemy_index]:
			return enemy_index
	return -1


func _increment_skipped_spawn() -> void:
	_skipped_spawn_count += 1
	if _skipped_spawn_count - _last_logged_skip_count < DEBUG_SKIP_LOG_INTERVAL:
		return

	_last_logged_skip_count = _skipped_spawn_count
	DebugLog.info(&"ChaserEnemies", "skipped spawns=%d" % _skipped_spawn_count)
