class_name NearMissMath
extends RefCounted

const NO_NEAR_MISS := Vector2(-1.0, 0.0)


static func evaluate_horizontal_explosion(
	player: PlayerController,
	origin: Vector3,
	damage_radius_meters: float,
	min_edge_distance_meters: float,
	near_miss_radius_meters: float
) -> Vector2:
	if player == null or near_miss_radius_meters <= 0.0:
		return NO_NEAR_MISS

	var distance := Vector2(origin.x, origin.z).distance_to(
		Vector2(player.global_position.x, player.global_position.z)
	)
	var edge_distance := distance - (damage_radius_meters + player.get_hurtbox_radius())
	return _evaluate_edge_distance(edge_distance, min_edge_distance_meters, near_miss_radius_meters)


static func evaluate_sphere_to_player_hurtbox(
	player: PlayerController,
	sphere_position: Vector3,
	sphere_radius_meters: float,
	near_miss_radius_meters: float
) -> Vector2:
	if player == null or near_miss_radius_meters <= 0.0:
		return NO_NEAR_MISS

	var distance_to_capsule := _distance_point_to_segment(
		sphere_position, player.get_hurtbox_segment_start(), player.get_hurtbox_segment_end()
	)
	var edge_distance := distance_to_capsule - player.get_hurtbox_radius() - sphere_radius_meters
	return _evaluate_edge_distance(edge_distance, 0.0, near_miss_radius_meters)


static func _evaluate_edge_distance(
	edge_distance: float, min_edge_distance: float, near_miss_radius: float
) -> Vector2:
	if edge_distance < min_edge_distance or edge_distance > near_miss_radius:
		return NO_NEAR_MISS

	var usable_radius := maxf(near_miss_radius - min_edge_distance, 0.001)
	var strength := 1.0 - clampf((edge_distance - min_edge_distance) / usable_radius, 0.0, 1.0)
	return Vector2(edge_distance, strength)


static func _distance_point_to_segment(point: Vector3, start: Vector3, end: Vector3) -> float:
	var segment := end - start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_to(start)

	var ratio := clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)
