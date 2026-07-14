class_name ArenaCell
extends RefCounted

enum ArenaCellState {
	NORMAL,
	DESTROYED,
	LAVA,
	ICE,
	COLLAPSING,
}

var index: int
var polygon: PackedVector2Array
var thickness_meters: float
var state: ArenaCellState


func _init(
	initial_index: int,
	initial_polygon: PackedVector2Array,
	initial_thickness_meters: float,
	initial_state: ArenaCellState = ArenaCellState.NORMAL
) -> void:
	index = initial_index
	polygon = initial_polygon
	thickness_meters = initial_thickness_meters
	state = initial_state


func get_area() -> float:
	if polygon.size() < 3:
		return 0.0

	var double_area := 0.0
	for vertex_index in range(polygon.size()):
		var current := polygon[vertex_index]
		var next := polygon[(vertex_index + 1) % polygon.size()]
		double_area += current.x * next.y - next.x * current.y

	return absf(double_area) * 0.5


func get_center_position() -> Vector3:
	if polygon.is_empty():
		return Vector3.ZERO

	var centroid := Vector2.ZERO
	for vertex: Vector2 in polygon:
		centroid += vertex
	centroid /= float(polygon.size())

	return Vector3(centroid.x, 0.0, centroid.y)


func contains_horizontal_position(position: Vector3) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(position.x, position.z), polygon)
