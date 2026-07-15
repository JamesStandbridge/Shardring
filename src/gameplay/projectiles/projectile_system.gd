class_name ProjectileSystem
extends Node3D

signal projectile_near_missed(position: Vector3, distance: float, strength: float)

enum LauncherState {
	INACTIVE,
	TELEGRAPHING,
	WAITING_NEXT_SHOT,
	LINGERING,
	PERSISTENT,
}

const DEBUG_SKIP_LOG_INTERVAL := 25

@export var launcher_config: ProjectileLauncherConfig = ProjectileLauncherConfig.new()
@export var run_controller_path: NodePath
@export var arena_path: NodePath
@export var player_path: NodePath
@export var health_component_path: NodePath
@export var placement_service_path: NodePath
@export var generation_seed: int = 1337
@export var automatic_spawning_enabled: bool = true

var _run_controller: RunController
var _arena: ArenaController
var _player: PlayerController
var _health_component: HealthComponent
var _placement_service: DangerPlacementService
var _rng := RandomNumberGenerator.new()
var _spawn_timer_seconds: float = 0.0
var _visual_time_seconds: float = 0.0
var _skipped_spawn_count: int = 0
var _last_logged_skip_count: int = 0

var _launcher_active: Array[bool] = []
var _launcher_positions: Array[Vector3] = []
var _launcher_directions: Array[Vector3] = []
var _launcher_muzzle_positions: Array[Vector3] = []
var _launcher_target_positions: Array[Vector3] = []
var _launcher_telegraph_lengths: Array[float] = []
var _launcher_states: Array[int] = []
var _launcher_timers: Array[float] = []
var _launcher_shots_remaining: Array[int] = []
var _launcher_shot_cooldowns: Array[float] = []
var _launcher_lifetimes: Array[float] = []

var _projectile_active: Array[bool] = []
var _projectile_positions: Array[Vector3] = []
var _projectile_directions: Array[Vector3] = []
var _projectile_speeds: Array[float] = []
var _projectile_lifetimes: Array[float] = []
var _projectile_collision_radii: Array[float] = []
var _projectile_near_miss_emitted: Array[bool] = []

var _launcher_multimesh_instance: MultiMeshInstance3D
var _projectile_multimesh_instance: MultiMeshInstance3D
var _projectile_trail_multimesh_instance: MultiMeshInstance3D
var _telegraph_multimesh_instance: MultiMeshInstance3D
var _telegraph_muzzle_marker_multimesh_instance: MultiMeshInstance3D
var _telegraph_target_marker_multimesh_instance: MultiMeshInstance3D


func _ready() -> void:
	_rng.seed = generation_seed
	_run_controller = get_node_or_null(run_controller_path) as RunController
	_arena = get_node_or_null(arena_path) as ArenaController
	_player = get_node_or_null(player_path) as PlayerController
	_health_component = get_node_or_null(health_component_path) as HealthComponent
	_placement_service = get_node_or_null(placement_service_path) as DangerPlacementService
	_initialize_pools()
	_create_render_batches()
	_connect_run_controller()
	_spawn_timer_seconds = launcher_config.initial_spawn_delay_seconds
	var debug_message := (
		"ready launchers=%d projectiles=%d seed=%d"
		% [
			launcher_config.max_active_launchers,
			launcher_config.max_active_projectiles,
			generation_seed,
		]
	)
	DebugLog.info(&"Projectiles", debug_message)


func _physics_process(delta: float) -> void:
	if not _is_run_playing():
		return

	_visual_time_seconds += delta
	if automatic_spawning_enabled:
		_update_spawn_timer(delta)
	_update_launchers(delta)
	_update_projectiles(delta)
	_check_player_projectile_collision()
	_update_render_batches()


func get_active_launcher_count() -> int:
	var count := 0
	for is_active: bool in _launcher_active:
		if is_active:
			count += 1
	return count


func get_active_projectile_count() -> int:
	var count := 0
	for is_active: bool in _projectile_active:
		if is_active:
			count += 1
	return count


func get_skipped_spawn_count() -> int:
	return _skipped_spawn_count


func supports_danger_family(family: DangerDefinition.DangerFamily) -> bool:
	return family == DangerDefinition.DangerFamily.PROJECTILE_LAUNCHER


func request_spawn_danger(definition: DangerDefinition) -> bool:
	if definition == null or not supports_danger_family(definition.family):
		return false

	var requested_launcher_config := definition.specialized_config as ProjectileLauncherConfig
	if requested_launcher_config == null:
		return false

	return _request_spawn_launcher(requested_launcher_config, definition.placement_rules)


func get_active_danger_count(definition: DangerDefinition) -> int:
	if definition == null or not supports_danger_family(definition.family):
		return 0
	return get_active_launcher_count()


func get_total_active_danger_count() -> int:
	return get_active_launcher_count() + get_active_projectile_count()


func get_active_readability_pressure() -> int:
	return get_active_telegraph_count()


func get_active_telegraph_count() -> int:
	var count := 0
	for launcher_index in range(_launcher_active.size()):
		if (
			_launcher_active[launcher_index]
			and _launcher_states[launcher_index] == LauncherState.TELEGRAPHING
		):
			count += 1
	return count


func _get_runtime_node_count_for_tests() -> int:
	return get_child_count()


func get_first_active_launcher_charge_ratio() -> float:
	for launcher_index in range(_launcher_active.size()):
		if _launcher_active[launcher_index]:
			return _get_launcher_charge_ratio(launcher_index)
	return 0.0


func get_first_active_launcher_telegraph_length() -> float:
	for launcher_index in range(_launcher_active.size()):
		if _launcher_active[launcher_index]:
			return _get_visible_telegraph_length(launcher_index)
	return 0.0


func get_first_active_launcher_direction() -> Vector3:
	for launcher_index in range(_launcher_active.size()):
		if _launcher_active[launcher_index]:
			return _launcher_directions[launcher_index]
	return Vector3.ZERO


func clear_all() -> void:
	for launcher_index in range(_launcher_active.size()):
		_launcher_active[launcher_index] = false
		_launcher_states[launcher_index] = LauncherState.INACTIVE
		_launcher_muzzle_positions[launcher_index] = Vector3.ZERO
		_launcher_target_positions[launcher_index] = Vector3.ZERO
		_launcher_telegraph_lengths[launcher_index] = 0.0

	for projectile_index in range(_projectile_active.size()):
		_projectile_active[projectile_index] = false
		_projectile_near_miss_emitted[projectile_index] = false

	_spawn_timer_seconds = launcher_config.initial_spawn_delay_seconds
	_update_render_batches()
	DebugLog.info(&"Projectiles", "cleared")


func force_spawn_launcher_at(spawn_position: Vector3) -> bool:
	var player_position := _get_player_target_position()
	var direction := ProjectileTelegraphVisuals.direction_to_flat_target(
		spawn_position, player_position
	)
	return _spawn_launcher(spawn_position, direction)


func force_spawn_projectile(spawn_position: Vector3, direction: Vector3) -> bool:
	return _spawn_projectile(spawn_position, direction.normalized())


func _request_spawn_launcher(
	requested_launcher_config: ProjectileLauncherConfig = null,
	placement_rules: DangerPlacementRules = null
) -> bool:
	if requested_launcher_config != null:
		launcher_config = requested_launcher_config
	return _spawn_launcher_near_arena(placement_rules)


func step_system_for_tests(delta: float) -> void:
	_visual_time_seconds += delta
	_update_launchers(delta)
	_update_projectiles(delta)
	_check_player_projectile_collision()
	_update_render_batches()


func get_first_active_projectile_position() -> Vector3:
	for projectile_index in range(_projectile_active.size()):
		if _projectile_active[projectile_index]:
			return _projectile_positions[projectile_index]
	return Vector3.ZERO


func get_first_active_launcher_state() -> int:
	for launcher_index in range(_launcher_active.size()):
		if _launcher_active[launcher_index]:
			return _launcher_states[launcher_index]
	return LauncherState.INACTIVE


func _initialize_pools() -> void:
	var launcher_capacity := maxi(launcher_config.max_active_launchers, 1)
	var projectile_capacity := maxi(launcher_config.max_active_projectiles, 1)

	_launcher_active.resize(launcher_capacity)
	_launcher_positions.resize(launcher_capacity)
	_launcher_directions.resize(launcher_capacity)
	_launcher_muzzle_positions.resize(launcher_capacity)
	_launcher_target_positions.resize(launcher_capacity)
	_launcher_telegraph_lengths.resize(launcher_capacity)
	_launcher_states.resize(launcher_capacity)
	_launcher_timers.resize(launcher_capacity)
	_launcher_shots_remaining.resize(launcher_capacity)
	_launcher_shot_cooldowns.resize(launcher_capacity)
	_launcher_lifetimes.resize(launcher_capacity)

	for launcher_index in range(launcher_capacity):
		_launcher_active[launcher_index] = false
		_launcher_positions[launcher_index] = Vector3.ZERO
		_launcher_directions[launcher_index] = Vector3.FORWARD
		_launcher_muzzle_positions[launcher_index] = Vector3.ZERO
		_launcher_target_positions[launcher_index] = Vector3.ZERO
		_launcher_telegraph_lengths[launcher_index] = 0.0
		_launcher_states[launcher_index] = LauncherState.INACTIVE
		_launcher_timers[launcher_index] = 0.0
		_launcher_shots_remaining[launcher_index] = 0
		_launcher_shot_cooldowns[launcher_index] = 0.0
		_launcher_lifetimes[launcher_index] = 0.0

	_projectile_active.resize(projectile_capacity)
	_projectile_positions.resize(projectile_capacity)
	_projectile_directions.resize(projectile_capacity)
	_projectile_speeds.resize(projectile_capacity)
	_projectile_lifetimes.resize(projectile_capacity)
	_projectile_collision_radii.resize(projectile_capacity)
	_projectile_near_miss_emitted.resize(projectile_capacity)

	for projectile_index in range(projectile_capacity):
		_projectile_active[projectile_index] = false
		_projectile_positions[projectile_index] = Vector3.ZERO
		_projectile_directions[projectile_index] = Vector3.FORWARD
		_projectile_speeds[projectile_index] = 0.0
		_projectile_lifetimes[projectile_index] = 0.0
		_projectile_collision_radii[projectile_index] = 0.0
		_projectile_near_miss_emitted[projectile_index] = false


func _create_render_batches() -> void:
	_launcher_multimesh_instance = _create_launcher_batch()
	add_child(_launcher_multimesh_instance)

	_projectile_multimesh_instance = _create_projectile_batch()
	add_child(_projectile_multimesh_instance)

	_projectile_trail_multimesh_instance = _create_projectile_trail_batch()
	add_child(_projectile_trail_multimesh_instance)

	_telegraph_multimesh_instance = _create_telegraph_batch()
	add_child(_telegraph_multimesh_instance)

	_telegraph_muzzle_marker_multimesh_instance = _create_telegraph_marker_batch(
		"TelegraphMuzzleMarkerBatch",
		ProjectileTelegraphVisuals.get_muzzle_marker_radius(launcher_config)
	)
	add_child(_telegraph_muzzle_marker_multimesh_instance)

	_telegraph_target_marker_multimesh_instance = _create_telegraph_marker_batch(
		"TelegraphTargetMarkerBatch",
		ProjectileTelegraphVisuals.get_target_marker_radius(launcher_config)
	)
	add_child(_telegraph_target_marker_multimesh_instance)


func _create_launcher_batch() -> MultiMeshInstance3D:
	var launcher_mesh := _extract_first_mesh_from_scene(launcher_config.launcher_scene)
	var material: Material = null
	if launcher_mesh == null:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = launcher_config.launcher_visual_radius_meters
		sphere_mesh.height = launcher_config.launcher_visual_radius_meters * 2.0
		launcher_mesh = sphere_mesh

		var fallback_material := StandardMaterial3D.new()
		fallback_material.albedo_color = launcher_config.launcher_color
		fallback_material.emission_enabled = true
		fallback_material.emission = launcher_config.charge_color
		fallback_material.emission_energy_multiplier = launcher_config.emission_energy
		material = fallback_material

	return _create_multimesh_instance(
		"LauncherBatch", launcher_mesh, material, _launcher_active.size()
	)


func _create_projectile_batch() -> MultiMeshInstance3D:
	var projectile_mesh := _extract_first_mesh_from_scene(
		launcher_config.projectile_config.visual_scene
	)
	var material := _create_projectile_material()
	if projectile_mesh == null:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = launcher_config.projectile_config.visual_radius_meters
		sphere_mesh.height = launcher_config.projectile_config.visual_radius_meters * 2.0
		projectile_mesh = sphere_mesh

	return _create_multimesh_instance(
		"ProjectileBatch", projectile_mesh, material, _projectile_active.size()
	)


func _create_projectile_material() -> StandardMaterial3D:
	var projectile_config := launcher_config.projectile_config
	var material := StandardMaterial3D.new()
	material.albedo_color = projectile_config.danger_color
	material.roughness = 0.58
	material.emission_enabled = projectile_config.emission_energy > 0.0
	material.emission = projectile_config.danger_color
	material.emission_energy_multiplier = projectile_config.emission_energy
	if projectile_config.danger_color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _create_telegraph_batch() -> MultiMeshInstance3D:
	var cylinder_mesh := CylinderMesh.new()
	var radius := ProjectileTelegraphVisuals.get_beam_radius(launcher_config)
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = maxf(launcher_config.telegraph_visual_length_meters, 0.001)
	cylinder_mesh.radial_segments = 16

	var material := StandardMaterial3D.new()
	material.albedo_color = ProjectileTelegraphVisuals.get_beam_color(launcher_config)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = ProjectileTelegraphVisuals.get_beam_color(launcher_config)
	material.emission_energy_multiplier = ProjectileTelegraphVisuals.get_emission_energy(
		launcher_config
	)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = ProjectileTelegraphVisuals.get_no_depth_test(launcher_config)

	return _create_multimesh_instance(
		"TelegraphBatch",
		cylinder_mesh,
		material,
		_launcher_active.size() * ProjectileTelegraphVisuals.get_segment_count(launcher_config)
	)


func _create_telegraph_marker_batch(name_value: String, radius: float) -> MultiMeshInstance3D:
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = maxf(radius, 0.01)
	sphere_mesh.height = maxf(radius, 0.01) * 2.0

	var material := StandardMaterial3D.new()
	material.albedo_color = ProjectileTelegraphVisuals.get_marker_color(launcher_config)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = ProjectileTelegraphVisuals.get_marker_color(launcher_config)
	material.emission_energy_multiplier = (
		ProjectileTelegraphVisuals.get_emission_energy(launcher_config) * 1.15
	)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = ProjectileTelegraphVisuals.get_no_depth_test(launcher_config)

	return _create_multimesh_instance(name_value, sphere_mesh, material, _launcher_active.size())


func _create_projectile_trail_batch() -> MultiMeshInstance3D:
	var box_mesh := BoxMesh.new()
	var projectile_config := launcher_config.projectile_config
	box_mesh.size = Vector3(
		projectile_config.trail_width_meters,
		projectile_config.trail_width_meters,
		projectile_config.trail_length_meters
	)

	var material := StandardMaterial3D.new()
	material.albedo_color = projectile_config.trail_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = projectile_config.trail_color
	material.emission_energy_multiplier = projectile_config.trail_emission_energy
	if projectile_config.trail_color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return _create_multimesh_instance(
		"ProjectileTrailBatch", box_mesh, material, _projectile_active.size()
	)


func _create_multimesh_instance(
	name_value: String, mesh: Mesh, material: Material, capacity: int
) -> MultiMeshInstance3D:
	if material != null and mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, material)

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = capacity
	multimesh.visible_instance_count = 0
	multimesh.mesh = mesh

	var instance := MultiMeshInstance3D.new()
	instance.name = name_value
	instance.multimesh = multimesh
	return instance


func _extract_first_mesh_from_scene(scene: PackedScene) -> Mesh:
	return MeshSceneExtractor.extract_first_mesh(scene)


func _connect_run_controller() -> void:
	if _run_controller == null:
		if run_controller_path.is_empty():
			return
		DebugLog.warn(&"Projectiles", "missing run controller path")
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


func _update_spawn_timer(delta: float) -> void:
	_spawn_timer_seconds -= delta
	if _spawn_timer_seconds > 0.0:
		return

	_spawn_timer_seconds += launcher_config.spawn_interval_seconds
	_spawn_launcher_near_arena()


func _spawn_launcher_near_arena(placement_rules: DangerPlacementRules = null) -> bool:
	if _arena == null or _player == null:
		_increment_skipped_spawn()
		return false

	var player_position := _get_player_target_position()
	if _placement_service != null and placement_rules != null:
		var fair_position := _placement_service.get_random_fair_position(_rng, placement_rules)
		if not fair_position.is_finite():
			_increment_skipped_spawn()
			return false

		fair_position.y += launcher_config.spawn_height_meters
		var fair_direction := ProjectileTelegraphVisuals.direction_to_flat_target(
			fair_position, player_position
		)
		return _spawn_launcher(fair_position, fair_direction)

	for attempt in range(maxi(launcher_config.spawn_search_attempts, 1)):
		var candidate := _arena.get_random_valid_position(_rng)
		candidate.y += launcher_config.spawn_height_meters
		if candidate.distance_to(player_position) < launcher_config.min_distance_from_player_meters:
			continue

		var direction := ProjectileTelegraphVisuals.direction_to_flat_target(
			candidate, player_position
		)
		return _spawn_launcher(candidate, direction)

	_increment_skipped_spawn()
	return false


func _spawn_launcher(spawn_position: Vector3, direction: Vector3) -> bool:
	var launcher_index := _find_free_launcher_slot()
	if launcher_index == -1:
		_increment_skipped_spawn()
		return false

	_launcher_active[launcher_index] = true
	_launcher_positions[launcher_index] = spawn_position
	_launcher_directions[launcher_index] = ProjectileTelegraphVisuals.normalized_or_forward(
		direction
	)
	_launcher_muzzle_positions[launcher_index] = _calculate_muzzle_position(
		spawn_position, _launcher_directions[launcher_index]
	)
	_launcher_target_positions[launcher_index] = (
		spawn_position
		+ _launcher_directions[launcher_index] * launcher_config.telegraph_visual_length_meters
	)
	_launcher_telegraph_lengths[launcher_index] = launcher_config.telegraph_min_length_meters
	_launcher_states[launcher_index] = LauncherState.TELEGRAPHING
	_launcher_timers[launcher_index] = launcher_config.telegraph_duration_seconds
	_launcher_shots_remaining[launcher_index] = maxi(launcher_config.shot_count, 1)
	_launcher_shot_cooldowns[launcher_index] = 0.0
	_launcher_lifetimes[launcher_index] = launcher_config.launcher_lifetime_seconds
	_refresh_launcher_aim(launcher_index)
	_update_render_batches()
	(
		DebugLog
		. info(
			&"Projectiles",
			(
				"launcher spawned index=%d pos=%s telegraph=%.2f"
				% [
					launcher_index,
					spawn_position,
					_launcher_telegraph_lengths[launcher_index],
				]
			)
		)
	)
	return true


func _update_launchers(delta: float) -> void:
	for launcher_index in range(_launcher_active.size()):
		if not _launcher_active[launcher_index]:
			continue

		_launcher_lifetimes[launcher_index] -= delta
		if _should_expire_launcher_by_lifetime(launcher_index):
			_deactivate_launcher(launcher_index)
			continue

		match _launcher_states[launcher_index]:
			LauncherState.TELEGRAPHING:
				_update_telegraphing_launcher(launcher_index, delta)
			LauncherState.WAITING_NEXT_SHOT:
				_update_waiting_launcher(launcher_index, delta)
			LauncherState.LINGERING:
				_update_lingering_launcher(launcher_index, delta)
			LauncherState.PERSISTENT:
				_update_waiting_launcher(launcher_index, delta)
			LauncherState.INACTIVE:
				_deactivate_launcher(launcher_index)


func _should_expire_launcher_by_lifetime(launcher_index: int) -> bool:
	if launcher_config.launcher_type == ProjectileLauncherConfig.LauncherType.PERSISTENT:
		return false
	return (
		launcher_config.launcher_lifetime_seconds > 0.0
		and _launcher_lifetimes[launcher_index] <= 0.0
	)


func _update_telegraphing_launcher(launcher_index: int, delta: float) -> void:
	_refresh_launcher_aim(launcher_index)
	_launcher_timers[launcher_index] -= delta
	if _launcher_timers[launcher_index] > 0.0:
		return

	_fire_launcher(launcher_index)
	_advance_launcher_after_shot(launcher_index)


func _update_waiting_launcher(launcher_index: int, delta: float) -> void:
	_launcher_shot_cooldowns[launcher_index] -= delta
	if _launcher_shot_cooldowns[launcher_index] > 0.0:
		return

	_refresh_launcher_aim(launcher_index)
	_fire_launcher(launcher_index)
	_advance_launcher_after_shot(launcher_index)


func _update_lingering_launcher(launcher_index: int, delta: float) -> void:
	_launcher_timers[launcher_index] -= delta
	if _launcher_timers[launcher_index] <= 0.0:
		_deactivate_launcher(launcher_index)


func _advance_launcher_after_shot(launcher_index: int) -> void:
	if _launcher_shots_remaining[launcher_index] > 0:
		_launcher_states[launcher_index] = LauncherState.WAITING_NEXT_SHOT
		_launcher_shot_cooldowns[launcher_index] = launcher_config.shot_interval_seconds
		return

	if launcher_config.launcher_type == ProjectileLauncherConfig.LauncherType.PERSISTENT:
		_launcher_states[launcher_index] = LauncherState.PERSISTENT
		_launcher_shots_remaining[launcher_index] = maxi(launcher_config.shot_count, 1)
		_launcher_shot_cooldowns[launcher_index] = launcher_config.shot_interval_seconds
		return

	_launcher_states[launcher_index] = LauncherState.LINGERING
	_launcher_timers[launcher_index] = launcher_config.linger_after_last_shot_seconds


func _fire_launcher(launcher_index: int) -> void:
	if _launcher_shots_remaining[launcher_index] <= 0:
		return

	var shot_position := _get_launcher_muzzle_position(launcher_index)
	var direction := _launcher_directions[launcher_index]

	if _spawn_projectile(shot_position, direction):
		_launcher_shots_remaining[launcher_index] -= 1


func _spawn_projectile(spawn_position: Vector3, direction: Vector3) -> bool:
	if direction.is_zero_approx():
		return false

	var projectile_index := _find_free_projectile_slot()
	if projectile_index == -1:
		_increment_skipped_spawn()
		return false

	var projectile_config := launcher_config.projectile_config
	_projectile_active[projectile_index] = true
	_projectile_positions[projectile_index] = spawn_position
	_projectile_directions[projectile_index] = direction.normalized()
	_projectile_speeds[projectile_index] = projectile_config.speed_meters_per_second
	_projectile_lifetimes[projectile_index] = projectile_config.lifetime_seconds
	_projectile_collision_radii[projectile_index] = projectile_config.collision_radius_meters
	_projectile_near_miss_emitted[projectile_index] = false
	return true


func _update_projectiles(delta: float) -> void:
	for projectile_index in range(_projectile_active.size()):
		if not _projectile_active[projectile_index]:
			continue

		_projectile_positions[projectile_index] += (
			_projectile_directions[projectile_index] * _projectile_speeds[projectile_index] * delta
		)
		_projectile_lifetimes[projectile_index] -= delta
		if _projectile_lifetimes[projectile_index] <= 0.0:
			_projectile_active[projectile_index] = false
			_projectile_near_miss_emitted[projectile_index] = false


func _check_player_projectile_collision() -> void:
	if _player == null or _health_component == null:
		return
	if not launcher_config.projectile_config.damage_on_contact:
		return

	var damage_profile := launcher_config.projectile_config.damage_profile
	if damage_profile == null:
		return

	for projectile_index in range(_projectile_active.size()):
		if not _projectile_active[projectile_index]:
			continue
		if _player.is_sphere_intersecting_hurtbox(
			_projectile_positions[projectile_index], _projectile_collision_radii[projectile_index]
		):
			_projectile_active[projectile_index] = false
			_health_component.apply_damage(damage_profile, _projectile_positions[projectile_index])
			if not _health_component.is_alive():
				return
		else:
			_emit_projectile_near_miss_if_applicable(projectile_index)


func _emit_projectile_near_miss_if_applicable(projectile_index: int) -> void:
	if _projectile_near_miss_emitted[projectile_index]:
		return

	var projectile_config := launcher_config.projectile_config
	var near_miss := NearMissMath.evaluate_sphere_to_player_hurtbox(
		_player,
		_projectile_positions[projectile_index],
		_projectile_collision_radii[projectile_index],
		projectile_config.near_miss_radius_meters
	)
	if near_miss.x < 0.0:
		return

	_projectile_near_miss_emitted[projectile_index] = true
	projectile_near_missed.emit(_projectile_positions[projectile_index], near_miss.x, near_miss.y)


func _update_render_batches() -> void:
	if _launcher_multimesh_instance == null:
		return

	_update_launcher_batch()
	_update_projectile_batch()
	_update_projectile_trail_batch()
	_update_telegraph_batch()


func _update_launcher_batch() -> void:
	var visible_index := 0
	var multimesh := _launcher_multimesh_instance.multimesh
	for launcher_index in range(_launcher_active.size()):
		if not _launcher_active[launcher_index]:
			continue

		var scale_ratio := _get_launcher_charge_ratio(launcher_index)
		var direction_basis := _create_launcher_visual_basis(launcher_index)
		var instance_transform := Transform3D(
			direction_basis.scaled(Vector3.ONE * scale_ratio), _launcher_positions[launcher_index]
		)
		multimesh.set_instance_transform(visible_index, instance_transform)
		visible_index += 1

	multimesh.visible_instance_count = visible_index


func _update_projectile_batch() -> void:
	var visible_index := 0
	var multimesh := _projectile_multimesh_instance.multimesh
	for projectile_index in range(_projectile_active.size()):
		if not _projectile_active[projectile_index]:
			continue

		var direction := ProjectileTelegraphVisuals.normalized_or_forward(
			_projectile_directions[projectile_index]
		)
		multimesh.set_instance_transform(
			visible_index,
			Transform3D(
				ProjectileTelegraphVisuals.create_forward_basis(direction),
				_projectile_positions[projectile_index]
			)
		)
		visible_index += 1

	multimesh.visible_instance_count = visible_index


func _update_projectile_trail_batch() -> void:
	var visible_index := 0
	var multimesh := _projectile_trail_multimesh_instance.multimesh
	var projectile_config := launcher_config.projectile_config
	if not projectile_config.trail_enabled:
		multimesh.visible_instance_count = 0
		return

	for projectile_index in range(_projectile_active.size()):
		if not _projectile_active[projectile_index]:
			continue

		var direction := ProjectileTelegraphVisuals.normalized_or_forward(
			_projectile_directions[projectile_index]
		)
		var center := (
			_projectile_positions[projectile_index]
			- direction * (projectile_config.trail_length_meters * 0.5)
		)
		multimesh.set_instance_transform(
			visible_index,
			Transform3D(ProjectileTelegraphVisuals.create_forward_basis(direction), center)
		)
		visible_index += 1

	multimesh.visible_instance_count = visible_index


func _update_telegraph_batch() -> void:
	var beam_visible_index := 0
	var marker_visible_index := 0
	var multimesh := _telegraph_multimesh_instance.multimesh
	var muzzle_marker_multimesh := _telegraph_muzzle_marker_multimesh_instance.multimesh
	var target_marker_multimesh := _telegraph_target_marker_multimesh_instance.multimesh
	var segment_count := ProjectileTelegraphVisuals.get_segment_count(launcher_config)
	var beam_enabled := ProjectileTelegraphVisuals.is_beam_enabled(launcher_config)
	for launcher_index in range(_launcher_active.size()):
		if not _launcher_active[launcher_index]:
			continue
		if _launcher_states[launcher_index] != LauncherState.TELEGRAPHING:
			continue

		if beam_enabled:
			var visible_length := _get_visible_telegraph_length(launcher_index)
			var segment_step := visible_length / float(segment_count)
			var segment_length := maxf(
				(
					segment_step
					* (1.0 - ProjectileTelegraphVisuals.get_segment_gap_ratio(launcher_config))
				),
				0.001
			)
			for segment_index in range(segment_count):
				var segment_origin := (
					_get_telegraph_origin_position(launcher_index)
					+ _launcher_directions[launcher_index] * segment_step * float(segment_index)
				)
				var instance_transform := ProjectileTelegraphVisuals.create_segment_transform(
					launcher_config,
					segment_origin,
					_launcher_directions[launcher_index],
					segment_length,
					_visual_time_seconds,
					segment_index,
					launcher_index
				)
				multimesh.set_instance_transform(beam_visible_index, instance_transform)
				beam_visible_index += 1

		muzzle_marker_multimesh.set_instance_transform(
			marker_visible_index,
			Transform3D(Basis.IDENTITY, _get_launcher_muzzle_position(launcher_index))
		)
		target_marker_multimesh.set_instance_transform(
			marker_visible_index,
			Transform3D(Basis.IDENTITY, _launcher_target_positions[launcher_index])
		)
		marker_visible_index += 1

	multimesh.visible_instance_count = beam_visible_index
	muzzle_marker_multimesh.visible_instance_count = marker_visible_index
	target_marker_multimesh.visible_instance_count = marker_visible_index


func _get_launcher_charge_ratio(launcher_index: int) -> float:
	return lerpf(
		launcher_config.launcher_charge_scale_min,
		launcher_config.launcher_charge_scale_max,
		_get_launcher_charge_progress(launcher_index)
	)


func _get_launcher_charge_progress(launcher_index: int) -> float:
	if launcher_config.telegraph_duration_seconds <= 0.0:
		return 1.0
	if _launcher_states[launcher_index] != LauncherState.TELEGRAPHING:
		return 1.0

	var elapsed := launcher_config.telegraph_duration_seconds - _launcher_timers[launcher_index]
	return clampf(elapsed / launcher_config.telegraph_duration_seconds, 0.0, 1.0)


func _get_visible_telegraph_length(launcher_index: int) -> float:
	var base_length := maxf(_launcher_telegraph_lengths[launcher_index], 0.0)
	if _launcher_states[launcher_index] != LauncherState.TELEGRAPHING:
		return base_length

	var start_length := minf(base_length, maxf(launcher_config.telegraph_min_length_meters, 0.0))
	return lerpf(start_length, base_length, _get_launcher_charge_progress(launcher_index))


func _find_free_launcher_slot() -> int:
	for launcher_index in range(_launcher_active.size()):
		if not _launcher_active[launcher_index]:
			return launcher_index
	return -1


func _find_free_projectile_slot() -> int:
	for projectile_index in range(_projectile_active.size()):
		if not _projectile_active[projectile_index]:
			return projectile_index
	return -1


func _deactivate_launcher(launcher_index: int) -> void:
	_launcher_active[launcher_index] = false
	_launcher_states[launcher_index] = LauncherState.INACTIVE


func _get_launcher_muzzle_position(launcher_index: int) -> Vector3:
	return _launcher_muzzle_positions[launcher_index]


func _calculate_muzzle_position(root_position: Vector3, direction: Vector3) -> Vector3:
	var muzzle_offset := launcher_config.muzzle_local_offset
	if muzzle_offset.is_zero_approx():
		var shot_height_offset := maxf(
			launcher_config.shot_height_meters - launcher_config.spawn_height_meters, 0.0
		)
		return root_position + Vector3.UP * shot_height_offset
	return (
		root_position
		+ (
			ProjectileTelegraphVisuals.create_visual_basis_from_direction(
				launcher_config, direction
			)
			* muzzle_offset
		)
	)


func _get_telegraph_origin_position(launcher_index: int) -> Vector3:
	return _get_launcher_muzzle_position(launcher_index)


func _refresh_launcher_aim(launcher_index: int) -> void:
	var direction := _launcher_directions[launcher_index]
	var shot_position := _calculate_muzzle_position(_launcher_positions[launcher_index], direction)

	var target_position := _launcher_target_positions[launcher_index]
	if _player != null:
		target_position = _get_player_target_position()
	else:
		target_position = (
			shot_position + direction * launcher_config.telegraph_visual_length_meters
		)

	target_position.y = shot_position.y
	direction = ProjectileTelegraphVisuals.direction_to_target(shot_position, target_position)
	shot_position = _calculate_muzzle_position(_launcher_positions[launcher_index], direction)
	target_position.y = shot_position.y
	direction = ProjectileTelegraphVisuals.direction_to_target(shot_position, target_position)

	_launcher_muzzle_positions[launcher_index] = shot_position
	_launcher_target_positions[launcher_index] = target_position
	_launcher_directions[launcher_index] = direction
	_launcher_telegraph_lengths[launcher_index] = _calculate_telegraph_length(
		shot_position, target_position
	)


func _calculate_telegraph_length(from_position: Vector3, target_position: Vector3) -> float:
	var max_length := ProjectileTelegraphVisuals.get_base_length(launcher_config)
	var min_length := clampf(launcher_config.telegraph_min_length_meters, 0.0, max_length)
	if launcher_config.telegraph_mode == ProjectileLauncherConfig.TelegraphMode.FIXED_LENGTH:
		return max_length

	var from_flat := Vector2(from_position.x, from_position.z)
	var target_flat := Vector2(target_position.x, target_position.z)
	var target_length := (
		from_flat.distance_to(target_flat) + launcher_config.telegraph_target_padding_meters
	)
	return clampf(target_length, min_length, max_length)


func _create_launcher_visual_basis(launcher_index: int) -> Basis:
	return ProjectileTelegraphVisuals.create_visual_basis_from_direction(
		launcher_config, _launcher_directions[launcher_index]
	)


func _get_player_target_position() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	return _player.global_position + Vector3.UP * 0.7


func _increment_skipped_spawn() -> void:
	_skipped_spawn_count += 1
	if _skipped_spawn_count - _last_logged_skip_count < DEBUG_SKIP_LOG_INTERVAL:
		return

	_last_logged_skip_count = _skipped_spawn_count
	DebugLog.info(&"Projectiles", "skipped spawns=%d" % _skipped_spawn_count)
