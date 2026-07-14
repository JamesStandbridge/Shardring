class_name ProjectileTelegraphVisuals
extends RefCounted


static func get_segment_count(config: ProjectileLauncherConfig) -> int:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return 1
	return maxi(visual_config.segment_count, 1)


static func get_segment_gap_ratio(config: ProjectileLauncherConfig) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return 0.0
	return clampf(visual_config.segment_gap_ratio, 0.0, 0.8)


static func get_pulse_scale(
	config: ProjectileLauncherConfig,
	visual_time_seconds: float,
	segment_index: int,
	launcher_index: int
) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null or visual_config.pulse_speed_hz <= 0.0:
		return 1.0

	var phase := (
		visual_time_seconds * visual_config.pulse_speed_hz * TAU
		+ float(segment_index) * 0.72
		+ float(launcher_index) * 0.19
	)
	return 1.0 + sin(phase) * visual_config.pulse_scale_strength


static func get_beam_radius(config: ProjectileLauncherConfig) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return maxf(config.telegraph_visual_width_meters * 0.5, 0.01)
	return maxf(visual_config.beam_radius_meters, 0.01)


static func get_muzzle_marker_radius(config: ProjectileLauncherConfig) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return maxf(config.telegraph_muzzle_marker_radius_meters, 0.01)
	return maxf(visual_config.muzzle_marker_radius_meters, 0.01)


static func get_target_marker_radius(config: ProjectileLauncherConfig) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return maxf(config.telegraph_target_marker_radius_meters, 0.01)
	return maxf(visual_config.target_marker_radius_meters, 0.01)


static func get_beam_color(config: ProjectileLauncherConfig) -> Color:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return config.telegraph_color
	return visual_config.beam_color


static func get_marker_color(config: ProjectileLauncherConfig) -> Color:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return config.telegraph_color
	return visual_config.marker_color


static func get_emission_energy(config: ProjectileLauncherConfig) -> float:
	var visual_config := config.telegraph_visual_config
	if visual_config == null:
		return config.emission_energy
	return visual_config.emission_energy


static func get_no_depth_test(config: ProjectileLauncherConfig) -> bool:
	var visual_config := config.telegraph_visual_config
	return visual_config != null and visual_config.no_depth_test


static func create_segment_transform(
	config: ProjectileLauncherConfig,
	origin_position: Vector3,
	direction: Vector3,
	visible_length: float,
	visual_time_seconds: float,
	segment_index: int,
	launcher_index: int
) -> Transform3D:
	var safe_direction := normalized_or_forward(direction)
	var clamped_length := maxf(visible_length, 0.001)
	var center := origin_position + safe_direction * (clamped_length * 0.5)
	var length_scale := clamped_length / get_base_length(config)
	var pulse_scale := get_pulse_scale(config, visual_time_seconds, segment_index, launcher_index)
	var basis := create_y_axis_basis(safe_direction).scaled(
		Vector3(pulse_scale, length_scale, pulse_scale)
	)
	return Transform3D(basis, center)


static func get_base_length(config: ProjectileLauncherConfig) -> float:
	return maxf(config.telegraph_visual_length_meters, 0.001)


static func direction_to_flat_target(from_position: Vector3, target_position: Vector3) -> Vector3:
	var flat_target := target_position
	flat_target.y = from_position.y
	return direction_to_target(from_position, flat_target)


static func direction_to_target(from_position: Vector3, target_position: Vector3) -> Vector3:
	return normalized_or_forward(target_position - from_position)


static func normalized_or_forward(direction: Vector3) -> Vector3:
	if direction.is_zero_approx():
		return Vector3.FORWARD
	return direction.normalized()


static func create_forward_basis(direction: Vector3) -> Basis:
	var safe_direction := normalized_or_forward(direction)
	var up_direction := Vector3.UP
	if absf(safe_direction.dot(up_direction)) > 0.98:
		up_direction = Vector3.RIGHT
	return Basis.looking_at(safe_direction, up_direction)


static func create_visual_basis_from_direction(
	config: ProjectileLauncherConfig, direction: Vector3
) -> Basis:
	var direction_basis := create_forward_basis(direction)
	if is_zero_approx(config.visual_yaw_offset_degrees):
		return direction_basis
	return direction_basis * Basis(Vector3.UP, deg_to_rad(config.visual_yaw_offset_degrees))


static func create_y_axis_basis(direction: Vector3) -> Basis:
	var y_axis := normalized_or_forward(direction)
	var x_axis := Vector3.UP.cross(y_axis)
	if x_axis.is_zero_approx():
		x_axis = Vector3.RIGHT.cross(y_axis)
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)
